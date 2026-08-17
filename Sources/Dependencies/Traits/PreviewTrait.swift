#if canImport(SwiftUI) && compiler(>=6)
  public import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
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
    /// Before applying the overrides, this trait resets all cached dependencies back to their
    /// defaults so that multiple previews in a single file do not interfere with each other. For
    /// this reason, use at most one `.dependencies` trait per preview: a second trait's reset
    /// would discard the first trait's overrides.
    ///
    /// If the closure throws, the error is rendered directly in the preview instead of crashing
    /// it.
    ///
    /// - Parameter updateValuesForPreview: A closure for updating the current dependency values
    ///   for the lifetime of the preview.
    public static func dependencies(
      _ updateValuesForPreview: (inout DependencyValues) throws -> Void
    ) -> PreviewTrait {
      let error: (any Error)? = {
        do {
          DependencyValues._current.cachedValues.resetCache()
          try prepareDependencies(updateValuesForPreview)
          return nil
        } catch {
          return error
        }
      }()
      return .modifier(DependenciesPreviewModifier(error: error))
    }
  }

  private struct DependenciesPreviewModifier: PreviewModifier {
    let error: (any Error)?

    func body(content: Content, context: ()) -> some View {
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
