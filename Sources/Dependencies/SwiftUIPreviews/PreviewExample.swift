//
//  PreviewExample.swift
//  swift-dependencies
//
//  Created by Pete Schuette on 8/8/26.
//

#if canImport(SwiftUI)
  #if Foundation
    import SwiftUI

    /// Displays the current date, formatted with the current calendar.
    private struct CurrentDateView: View {
      @Dependency(\.calendar) var calendar
      @Dependency(\.date.now) var now

      var body: some View {
        VStack(spacing: 4) {
          Text(dateString(from: now))
            .font(.headline)
          Text(timeString(from: now))
            .font(.system(.largeTitle, design: .monospaced))
          Text(calendar.timeZone.identifier)
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
        An error was thrown from preparePreviewDependencies!

        Display the localized description to the implementer for insights.
        """
      }
    }

    #Preview {
      preparePreviewDependencies {
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
      CurrentDateView()
    }

    #Preview {
      preparePreviewDependencies { _ in
        throw SampleError()
      }

      // Prepared view
      CurrentDateView()
    }
  #endif
#endif
