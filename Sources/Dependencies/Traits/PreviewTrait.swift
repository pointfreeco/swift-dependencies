#if canImport(SwiftUI) && compiler(>=6)
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
      _ value: @autoclosure @escaping () throws -> Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = try value() }
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
      _ value: @autoclosure @escaping () throws -> Value
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies { $0[Value.self] = try value() }
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
      _ updateValuesForPreview: @escaping (inout DependencyValues) throws -> Void
    ) -> PreviewTrait {
      .modifier(DependenciesPreviewModifier(operation: updateValuesForPreview))
    }
  }

  private struct DependenciesPreviewModifier: PreviewModifier {
    @Environment(\.dependenciesCount) var dependenciesCount
    let operation: (inout DependencyValues) throws -> Void

    func body(content: Content, context: ()) -> some View {
      ZStack {
        content
        if let error = prepareDependencies() {
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
      .environment(\.dependenciesCount, dependenciesCount + 1)
    }

    func prepareDependencies() -> (any Error)? {
      if dependenciesCount == 0 {
        DependencyValues._current.cachedValues.resetCache()
      }
      do {
        try Dependencies.prepareDependencies(operation)
        return nil
      } catch {
        return error
      }
    }
  }

  extension EnvironmentValues {
    @Entry fileprivate var dependenciesCount = 0
  }
#endif
