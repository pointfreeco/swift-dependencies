#if canImport(SwiftUI) && compiler(>=6)
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    public static func dependency<Value>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: @autoclosure @escaping @Sendable () -> Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = value() }
    }

    public static func dependency<Value: TestDependencyKey>(
      _ value: Value
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies { $0[Value.self] = value }
    }

    public static func dependencies(
      _ updateValuesForPreview: @escaping @Sendable (inout DependencyValues) -> Void
    ) -> PreviewTrait {
      return .modifier(DependenciesPreviewModifier(updateValuesForPreview: updateValuesForPreview))
    }
  }

  private struct DependenciesPreviewModifier: PreviewModifier {
    let updateValuesForPreview: @Sendable (inout DependencyValues) -> Void

    func body(content: Content, context: ()) -> some View {
      prepareDependencies(updateValuesForPreview)
      return content
    }
  }
#endif
