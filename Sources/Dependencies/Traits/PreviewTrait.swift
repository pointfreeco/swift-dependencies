#if canImport(SwiftUI) && compiler(>=6)
  import Foundation
  public import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    /// A trait that overrides a preview's dependency.
    ///
    /// Useful for overriding a dependency in a preview without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// #Preview(
    ///   traits: .dependency(\.continuousClock, ImmediateClock())
    /// ) {
    ///   TimerView()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a dependency value.
    ///   - value: A dependency value to override for the lifetime of the preview.
    public static func dependency<Value>(
      _ keyPath: any WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: @autoclosure () throws -> Value,
      fileID: StaticString = #fileID,
      line: UInt = #line,
      column: UInt = #column
    ) -> PreviewTrait {
      .dependencies(fileID: fileID, line: line, column: column) {
        $0[keyPath: keyPath] = try value()
      }
    }

    /// A trait that overrides a preview's dependency.
    ///
    /// Useful for overriding a dependency in a preview without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// struct Client: DependencyKey { … }
    /// #Preview(
    ///   traits: .dependency(Client.mock)
    /// ) {
    ///   FeatureView()
    /// }
    /// ```
    ///
    /// - Parameter value: A dependency value to override for the lifetime of the preview.
    public static func dependency<Value: TestDependencyKey>(
      _ value: @autoclosure () throws -> Value,
      fileID: StaticString = #fileID,
      line: UInt = #line,
      column: UInt = #column
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies(fileID: fileID, line: line, column: column) {
        $0[Value.self] = try value()
      }
    }

    /// A trait that overrides a preview's dependencies.
    ///
    /// Useful for overriding several dependencies in a preview without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// #Preview(
    ///   traits: .dependencies {
    ///     $0.continuousClock = ImmediateClock()
    ///     $0.date.now = Date(timeIntervalSince1970: 1234567890)
    ///   }
    /// ) {
    ///   TimerView()
    /// }
    /// ```
    ///
    /// If the closure throws, the error is rendered directly in the preview instead of crashing
    /// it.
    ///
    /// - Parameter updateValuesForPreview: A closure for updating the current dependency values
    ///   for the lifetime of the preview.
    public static func dependencies(
      fileID: StaticString = #fileID,
      line: UInt = #line,
      column: UInt = #column,
      _ updateValuesForPreview: (inout DependencyValues) throws -> Void
    ) -> PreviewTrait {
      .modifier(
        DependenciesPreviewModifier(
          previewID: PreviewID(fileID: "\(fileID)", line: line, column: column),
          operation: updateValuesForPreview
        )
      )
    }
  }

  private struct PreviewID: Hashable {
    let fileID: String
    let line: UInt
    let column: UInt
  }

  private struct DependenciesPreviewModifier: PreviewModifier {
    private struct Preparation {
      let id = UUID()
      let previewID: PreviewID
      var hasRendered = false
    }
    private static var preparation: Preparation?
    private let error: (any Error)?

    init(previewID: PreviewID, operation: (inout DependencyValues) throws -> Void) {
      let preparation: Preparation
      if let currentPreparation = Self.preparation,
        currentPreparation.previewID == previewID,
        !currentPreparation.hasRendered
      {
        preparation = currentPreparation
      } else {
        DependencyValues._current.cachedValues.resetCache()
        preparation = Preparation(previewID: previewID)
        Self.preparation = preparation
      }
      do {
        try Dependencies.prepareDependencies(preparationID: preparation.id, operation)
        error = nil
      } catch {
        self.error = error
      }
    }

    func body(content: Content, context: Void) -> some View {
      Self.preparation?.hasRendered = true
      return ZStack {
        content
        if let error {
          VStack {
            Text("Preview Trait Failure")
              .font(.headline.bold())
            Text(error.localizedDescription)
              .font(.subheadline)
          }
          .foregroundColor(Color.white)
          .padding()
          .background(Color.red)
          .cornerRadius(8)
          .opacity(0.75)
        }
      }
    }
  }
#endif
