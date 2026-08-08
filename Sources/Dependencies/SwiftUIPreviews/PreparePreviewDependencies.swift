#if canImport(SwiftUI)
  import Foundation
  import IssueReporting
  public import SwiftUI

  /// Prepares global dependencies for an Xcode preview.
  ///
  /// Call this at the top of a preview's view builder to override dependencies for every view the
  /// preview renders:
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
  /// It returns a view, so it composes directly into the preview alongside the views under
  /// development. Any error thrown while preparing is handed to a ``PreviewErrorView`` and rendered
  /// in place rather than trapping, which is why the example above can use `try` instead of `try!`.
  /// To render the error with your own view, use
  /// ``preparePreviewDependencies(_:errorView:fileID:filePath:line:column:)``.
  ///
  /// > Important: A dependency key can be prepared at most a single time, and _must_ be prepared
  /// > before it has been accessed. If you attempt to prepare a dependency that has previously been
  /// > overridden or accessed, a runtime warning will be emitted.
  ///
  /// > Note: Dependencies are only prepared when the current ``DependencyValues/context`` is
  /// > ``DependencyContext/preview``. If this is invoked from any other context a runtime warning
  /// > is emitted and dependencies are left untouched.
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
  /// Call this at the top of a preview's view builder to override dependencies for every view the
  /// preview renders, and supply a view builder to render any error thrown while preparing:
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
  /// Because the error is handed to `errorView` and rendered in place rather than trapping, the
  /// closure above can use `try` instead of `try!`.
  ///
  /// > Important: A dependency key can be prepared at most a single time, and _must_ be prepared
  /// > before it has been accessed. If you attempt to prepare a dependency that has previously been
  /// > overridden or accessed, a runtime warning will be emitted.
  ///
  /// > Note: Dependencies are only prepared when the current ``DependencyValues/context`` is
  /// > ``DependencyContext/preview``. If this is invoked from any other context a runtime warning
  /// > is emitted and dependencies are left untouched.
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

#endif
