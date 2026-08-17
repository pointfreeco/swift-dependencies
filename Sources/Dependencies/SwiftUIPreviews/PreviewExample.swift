//
//  PreviewExample.swift
//  swift-dependencies
//
//  Created by Pete Schuette on 8/8/26.
//

#if canImport(SwiftUI)
  #if Foundation
    import ConcurrencyExtras
    import SwiftUI

    /// Displays the current date, formatted with the current calendar.
    private struct CurrentDateView: View {
      @Dependency(\.calendar) var calendar
      @Dependency(\.date.now) var now
      @Dependency(\.ticketOffice) var ticketOffice

      let name: String

      @State private var ticketsBought = 0

      var body: some View {
        Text(name)
          .font(.system(.largeTitle, design: .monospaced))

        VStack(spacing: 4) {
          Text(dateString(from: now))
            .font(.headline)
          Text(timeString(from: now))
            .font(.system(.title, design: .monospaced))
          Text(calendar.timeZone.identifier)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()

        VStack(spacing: 4) {
          Button("Buy ticket") {
            ticketOffice.buyTicket()
            ticketsBought = ticketOffice.ticketsBought
          }
          Text("Tickets bought: \(ticketsBought)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
      }

      private func dateString(from date: Date) -> String {
        formatter(dateStyle: .medium).string(from: date)
      }

      private func timeString(from date: Date) -> String {
        formatter(timeStyle: .medium).string(from: date)
      }

      private func formatter(
        dateStyle: DateFormatter.Style = .none,
        timeStyle: DateFormatter.Style = .none
      ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
      }
    }

    private struct SampleError: Error, LocalizedError {
      var errorDescription: String? {
        """
        An error was thrown from previewDependencies!

        Display the localized description to the implementer for insights.
        """
      }
    }

    #Preview("Woodstock") {
      previewDependencies {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.locale = Locale(identifier: "en_US")

        var components = DateComponents()
        components.year = 1969
        components.month = 8
        components.day = 15
        components.hour = 17
        components.minute = 7

        $0.calendar = calendar
        $0.date.now = calendar.date(from: components)!
      }

      // Prepared view
      CurrentDateView(name: "Woodstock")
    }

    #Preview("Live Aid") {
      previewDependencies {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.locale = Locale(identifier: "en_UK")

        var components = DateComponents()
        components.year = 1985
        components.month = 7
        components.day = 13
        components.hour = 12
        components.minute = 0

        $0.calendar = calendar
        $0.date.now = calendar.date(from: components)!
      }
      
      // Prepared view
      CurrentDateView(name: "Live Aid")
    }

    #Preview("Preview error") {
      previewDependencies { _ in
        throw SampleError()
      }

      // Prepared view
      CurrentDateView(name: "Local time")
    }

    // MARK: - Ticket office dependency

    /// POC dependency driven state state lives across view renders
    private final class TicketOffice: Sendable {
      private let count = LockIsolated(0)
      
      var ticketsBought: Int { count.value }
      
      func buyTicket() {
        count.withValue { $0 += 1 }
      }
    }

    private enum TicketOfficeKey: TestDependencyKey {
      static var testValue: TicketOffice { TicketOffice() }
    }

    extension DependencyValues {
      fileprivate var ticketOffice: TicketOffice {
        get { self[TicketOfficeKey.self] }
        set { self[TicketOfficeKey.self] = newValue }
      }
    }
  #endif
#endif
