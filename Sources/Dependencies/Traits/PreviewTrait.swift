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
    public static func dependency<Value: Sendable>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = value }
    }

    public static func dependency<Key: TestDependencyKey>(
      _ key: Key.Type,
      _ value: Key.Value
    ) -> PreviewTrait {
      .dependencies { $0[key] = value }
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
      _ updateValuesForPreview: @Sendable (inout DependencyValues) -> Void
    ) -> PreviewTrait {
      previewValues.withValue {
        updateValuesForPreview(&$0)
      }
      return PreviewTrait()
    }
  }
#endif

let previewValues = LockIsolated(DependencyValues(context: .preview))
