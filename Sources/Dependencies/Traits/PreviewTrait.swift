#if canImport(SwiftUI) && compiler(>=6)
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    /// A trait that overrides a preview's dependency.
    ///
    /// Useful for overriding a dependency in a preview without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// #Preview(
    ///   .dependency(\.continuousClock, .immediate)
    /// ) {
    ///   TimerView()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a dependency value.
    ///   - value: A dependency value to override for the lifetime of the preview.
    public static func dependency<Value>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = value }
    }

    /// A trait that overrides a preview's dependency.
    /// 
    /// - Parameter value: A dependency value to override for the test.
    public static func dependency<Value: TestDependencyKey>(
      _ value: Value
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies { $0[Value.self] = value }
    }

    /// A trait that overrides a preview's dependencies.
    ///
    /// Useful for overriding several dependencies in a preview without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// #Preview(
    ///   .dependencies {
    ///     $0.continuousClock = .immediate
    ///     $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
    ///   }
    /// ) {
    ///   TimerView()
    /// }
    /// ```
    ///
    /// - Parameter updateValuesForPreview: A closure for updating the current dependency values for
    ///   the lifetime of the preview.
    public static func dependencies(
      _ updateValuesForPreview: (inout DependencyValues) -> Void
    ) -> PreviewTrait {
      var copy = previewValues
      defer { previewValues = copy }
      updateValuesForPreview(&copy)
      return PreviewTrait()
    }
  }

  nonisolated(unsafe) var previewValues = DependencyValues(context: .preview)
#endif
