#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    public static func dependency<Value: Sendable>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = value }
    }

    public static func dependencies(
      _ operation: @Sendable (inout DependencyValues) -> Void
    ) -> PreviewTrait {
      previewValues.withValue {
        operation(&$0)
      }
      return PreviewTrait()
    }
  }

  let previewValues = LockIsolated(DependencyValues())
#endif
