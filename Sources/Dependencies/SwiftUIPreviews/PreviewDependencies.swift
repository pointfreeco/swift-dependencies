#if canImport(SwiftUI)
  import ConcurrencyExtras
  import Foundation
  import IssueReporting
  public import SwiftUI

  /// The source location of the ``previewDependencies(_:fileID:filePath:line:column:)`` call that
  /// most recently prepared dependencies, used to tell one preview apart from another.
  private struct PreparationSite: Equatable, Sendable {
    let fileID: String
    let line: UInt
    let column: UInt
  }

  private let lastPreparationSite = LockIsolated<PreparationSite?>(nil)

  /// Prepares global dependencies for an Xcode preview.
  ///
  /// Call this at the top of a preview's view builder to override dependencies for every view the
  /// preview renders:
  ///
  /// ```swift
  /// #Preview {
  ///   previewDependencies {
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
  /// ``previewDependencies(_:errorView:fileID:filePath:line:column:)``.
  ///
  /// > Important: Preparing discards the dependencies prepared and cached by a previously rendered
  /// > preview, so that previews sharing a process do not inherit each other's state. Only the
  /// > first evaluation of a given call site prepares: re-evaluating the same preview, as happens
  /// > whenever its `@Previewable` state changes, leaves its dependencies exactly as they were, so
  /// > a stateful dependency keeps the state it accumulated. Editing the values in the closure
  /// > therefore does not take effect until the preview is restarted, which is also how
  /// > ``prepareDependencies(_:)`` behaves in a preview.
  ///
  /// > Note: Call this at most once per preview. Two calls in one preview are two call sites, and
  /// > each re-evaluation of the preview's body hands the dependencies back and forth between
  /// > them. Previews rendered _simultaneously_ in a single process, such as preview variants,
  /// > share one set of dependencies for the same reason.
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
  public func previewDependencies<R>(
    _ updateValues: (inout DependencyValues) throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> some View {
    previewDependencies(
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
  ///   previewDependencies {
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
  /// > Important: Preparing discards the dependencies prepared and cached by a previously rendered
  /// > preview, so that previews sharing a process do not inherit each other's state. Only the
  /// > first evaluation of a given call site prepares: re-evaluating the same preview, as happens
  /// > whenever its `@Previewable` state changes, leaves its dependencies exactly as they were, so
  /// > a stateful dependency keeps the state it accumulated. Editing the values in the closure
  /// > therefore does not take effect until the preview is restarted, which is also how
  /// > ``prepareDependencies(_:)`` behaves in a preview.
  ///
  /// > Note: Call this at most once per preview. Two calls in one preview are two call sites, and
  /// > each re-evaluation of the preview's body hands the dependencies back and forth between
  /// > them. Previews rendered _simultaneously_ in a single process, such as preview variants,
  /// > share one set of dependencies for the same reason.
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
  public func previewDependencies<R, ErrorView: View>(
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

      // A preview's body is re-evaluated whenever its '@Previewable' state changes, which would
      // otherwise hand the preview a brand new set of dependencies on every interaction. Only the
      // first evaluation of a given call site prepares.
      let site = PreparationSite(fileID: "\(fileID)", line: line, column: column)
      guard
        lastPreparationSite.withValue({ lastSite -> Bool in
          guard lastSite != site else { return false }
          lastSite = site
          return true
        })
      else { return nil }

      // Every preview in a file is rendered by a single process that shares one dependency cache,
      // so discard anything a previously rendered preview prepared or accessed before preparing
      // this one.
      DependencyValues._current.cachedValues.resetPreviewCache()

      do {
        _ = try prepareDependencies(updateValues)
        return nil
      } catch {
        // Forget the call site so that a re-evaluated preview tries again and keeps rendering the
        // error, rather than silently falling back to preview values.
        lastPreparationSite.setValue(nil)
        return error
      }
    }()

    if let error {
      errorView(error)
    }
  }

  /// The view used by ``previewDependencies(_:fileID:filePath:line:column:)`` to display an
  /// error thrown while preparing an Xcode preview's dependencies.
  ///
  /// You can use this view directly if you want to augment the default presentation, for example by
  /// wrapping it in another container:
  ///
  /// ```swift
  /// #Preview {
  ///   previewDependencies {
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
