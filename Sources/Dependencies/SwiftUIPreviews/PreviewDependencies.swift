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
  /// ```swift
  /// #Preview {
  ///   previewDependencies {
  ///     $0.defaultDatabase = try DatabaseQueue(/* ... */)
  ///   }
  ///
  ///   FeatureView()
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - updateValues: A closure for updating the current dependency values for the lifetime of the
  ///     preview.
  ///   - errorView: (optional) view builder to render errors thrown from`updateValues`.
  /// - Returns: A view that displays any error thrown while preparing dependencies.
  @ViewBuilder
  public func previewDependencies<R, ErrorView: View>(
    _ updateValues: (inout DependencyValues) throws -> R,
    @ViewBuilder errorView: (any Error) -> ErrorView = { PreviewErrorView($0) },
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

      let site = PreparationSite(fileID: "\(fileID)", line: line, column: column)
      guard
        lastPreparationSite.withValue({ lastSite -> Bool in
          guard lastSite != site else { return false }
          lastSite = site
          return true
        })
      else {
        // Short circuit to avoid resetting previews across state change
        return nil
      }

      DependencyValues._current.cachedValues.resetPreviewCache()

      do {
        _ = try prepareDependencies(updateValues)
        return nil
      } catch {
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
  public struct PreviewErrorView: View {
    let error: any Error

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
