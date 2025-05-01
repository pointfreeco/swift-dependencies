#if canImport(SwiftUI) && compiler(>=6)
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    public static func dependency<Value>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: @autoclosure @escaping @Sendable () throws -> Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = try value() }
    }

    public static func dependency<Value: TestDependencyKey>(
      _ value: @autoclosure @escaping @Sendable () throws -> Value
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies { $0[Value.self] = try value() }
    }

    public static func dependencies(
      _ updateValuesForPreview: @escaping @Sendable (inout DependencyValues) throws -> Void
    ) -> PreviewTrait {
      return .modifier(DependenciesPreviewModifier(updateValuesForPreview: updateValuesForPreview))
    }
  }

  private struct DependenciesPreviewModifier: PreviewModifier {
    let updateValuesForPreview: @Sendable (inout DependencyValues) throws -> Void

    func body(content: Content, context: ()) -> some View {
      let error: (any Error)? = {
        do {
          try prepareDependencies(updateValuesForPreview)
          return nil
        } catch {
          return error
        }
      }()
      ZStack {
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
