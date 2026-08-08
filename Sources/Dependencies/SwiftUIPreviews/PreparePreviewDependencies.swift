#if canImport(SwiftUI)
  import Foundation
  import IssueReporting
  public import SwiftUI

  /// Prepares global dependencies for an Xcode preview.
  ///
  /// This is a convenience over ``prepareDependencies(_:)`` for use in Xcode previews. Because
  /// ``prepareDependencies(_:)`` does not return a view, it must be bound to `let _` in order to
  /// play nicely with result builders:
  ///
  /// ```swift
  /// #Preview {
  ///   let _ = prepareDependencies {
  ///     $0.defaultDatabase = try! DatabaseQueue(/* ... */)
  ///   }
  ///   FeatureView()
  /// }
  /// ```
  ///
  /// This helper returns a view instead, and so it can be used directly in a preview's view
  /// builder:
  ///
  /// ```swift
  /// #Preview {
  ///   preparePreviewDependencies {
  ///     $0.defaultDatabase = try DatabaseQueue(/* ... */)
  ///   }
  ///   FeatureView()
  /// }
  /// ```
  ///
  /// Any error thrown while preparing dependencies is rendered in the preview as a
  /// ``PreviewErrorView`` rather than trapping, which is why the example above can use `try`
  /// instead of `try!`. To render the error differently, use
  /// ``preparePreviewDependencies(_:errorView:fileID:filePath:line:column:)``.
  ///
  /// > Important: A dependency key can be prepared at most a single time, and _must_ be prepared
  /// > before it has been accessed. If you attempt to prepare a dependency that has previously been
  /// > overridden or accessed, a runtime warning will be emitted.
  ///
  /// > Note: This helper only prepares dependencies when the current ``DependencyValues/context``
  /// > is ``DependencyContext/preview``. If it is invoked from any other context a runtime warning
  /// > will be emitted and dependencies will be left untouched. To prepare dependencies for the
  /// > lifetime of your application, use ``prepareDependencies(_:)`` instead.
  ///
  /// - Parameters:
  ///   - updateValues: A closure for updating the current dependency values for the lifetime of the
  ///     preview.
  ///   - fileID: The source `#fileID` associated with the preparation.
  ///   - filePath: The source `#filePath` associated with the preparation.
  ///   - line: The source `#line` associated with the preparation.
  ///   - column: The source `#column` associated with the preparation.
  /// - Returns: A view that displays any error thrown while preparing dependencies.
  public func preparePreviewDependencies<R>(
    _ updateValues: (inout DependencyValues) throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> some View {
    preparePreviewDependencies(
      updateValues,
      errorView: { PreviewErrorView($0) },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  /// Prepares global dependencies for an Xcode preview, displaying any error with a custom view.
  ///
  /// This is a variant of ``preparePreviewDependencies(_:fileID:filePath:line:column:)`` that lets
  /// you render errors thrown while preparing dependencies however you like, rather than with the
  /// default ``PreviewErrorView``:
  ///
  /// ```swift
  /// #Preview {
  ///   preparePreviewDependencies {
  ///     $0.defaultDatabase = try DatabaseQueue(/* ... */)
  ///   } errorView: { error in
  ///     Text("Failed to prepare preview: \(error)")
  ///   }
  ///   FeatureView()
  /// }
  /// ```
  ///
  /// See the documentation of ``preparePreviewDependencies(_:fileID:filePath:line:column:)`` for
  /// more information.
  ///
  /// - Parameters:
  ///   - updateValues: A closure for updating the current dependency values for the lifetime of the
  ///     preview.
  ///   - errorView: A view builder that is handed any error thrown by `updateValues`.
  ///   - fileID: The source `#fileID` associated with the preparation.
  ///   - filePath: The source `#filePath` associated with the preparation.
  ///   - line: The source `#line` associated with the preparation.
  ///   - column: The source `#column` associated with the preparation.
  /// - Returns: A view that displays any error thrown while preparing dependencies.
  @ViewBuilder
  public func preparePreviewDependencies<R, ErrorView: View>(
    _ updateValues: (inout DependencyValues) throws -> R,
    @ViewBuilder errorView: (any Error) -> ErrorView,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> some View {
    let error: (any Error)? = {
      guard DependencyValues._current.context == .preview
      else {
        reportIssue(
          """
          You are trying to prepare preview dependencies from outside an Xcode preview, and so \
          this will have no effect. To fix this, either move this call into a preview, or use \
          'prepareDependencies' to prepare dependencies for the lifetime of your application.
          """,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
        return nil
      }

      do {
        _ = try prepareDependencies(updateValues)
        return nil
      } catch {
        return error
      }
    }()

    if let error {
      errorView(error)
    }
  }

  /// The view used by ``preparePreviewDependencies(_:fileID:filePath:line:column:)`` to display an
  /// error thrown while preparing an Xcode preview's dependencies.
  ///
  /// You can use this view directly if you want to augment the default presentation, for example by
  /// wrapping it in another container:
  ///
  /// ```swift
  /// #Preview {
  ///   preparePreviewDependencies {
  ///     $0.defaultDatabase = try DatabaseQueue(/* ... */)
  ///   } errorView: { error in
  ///     PreviewErrorView(error)
  ///       .background(Color.black)
  ///   }
  ///   FeatureView()
  /// }
  /// ```
  public struct PreviewErrorView: View {
    let error: any Error

    /// Creates a view that displays the given error.
    ///
    /// - Parameter error: The error to display.
    nonisolated public init(_ error: any Error) {
      self.error = error
    }

    public var body: some View {
      ScrollView {
        Text(error.localizedDescription)
          .foregroundColor(.red)
          .padding(.horizontal, 12)
      }
      .foregroundColor(.white)
    }
  }

// MARK: - Preview examples

fileprivate struct CurrentDateView: View {
  @Dependency(\.calendar) var calendar
  @Dependency(\.date) var now
  
  var body: some View {
    Text(dateString(from: now()))
    Text(timeString(from: now()))
  }
  
  func dateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
  
  func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }
}

fileprivate struct PrepareError: Error, LocalizedError {
  var errorDescription: String? {
    """
    An error was thrown during the prepare step!
    
    Display the localized description of the error in line. 
    """
  }
}

#Preview {
  preparePreviewDependencies {
    let timeZone = TimeZone(identifier: "America/New_York")!
    var components = DateComponents()
    components.year = 1969
    components.month = 8
    components.day = 15
    components.hour = 17
    components.minute = 07
    var calendar = Calendar(identifier: .gregorian)
  
    $0.timeZone = timeZone
    $0.date.now = calendar.date(from: components)!
  }

  // Prepared view
  CurrentDateView()
}

#Preview {
  preparePreviewDependencies { _ in
    throw PrepareError()
  }

  // Prepared view
  CurrentDateView()
}

#endif
