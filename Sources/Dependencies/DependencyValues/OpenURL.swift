#if canImport(SwiftUI)
  import SwiftUI

  extension DependencyValues {
    /// A dependency that opens a URL.
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    public var openURL: OpenURLEffect {
      get { self[OpenURLKey.self] }
      set { self[OpenURLKey.self] = newValue }
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  internal enum OpenURLKey: DependencyKey {
    static let liveValue = OpenURLEffect { url in
      let stream = AsyncStream<Bool> { continuation in
        let task = Task { @MainActor in
          #if os(watchOS)
            EnvironmentValues().openURL(url)
            continuation.yield(true)
            continuation.finish()
          #elseif os(macOS)
            /// On macOS Sequoia, invokng `EnvironmentValues().openURL(_:completion:)`
            /// i.e. with the completion handler, causes an `EXC_BREAKPOINT (SIGTRAP), KERN_INVALID_ADDRESS`
            /// runtime crash with `_dispatch_assert_queue_fail` on a non-main thread.
            if #available(macOS 15.0, *) {
              let openURL = OpenURLAction { url in
                EnvironmentValues().openURL(url)
                  /// However, using `.systemAction` (which may be needed to indicate whether an app
                  /// is available to handle a URL scheme), seems to cause the completion handler to never return...
                  /// Therefore, this implementation is actually equivalent to the  watchOS one, which always
                  /// yields `true`.
                  return .handled
              }
                
              openURL(url) { canOpen in
                  continuation.yield(canOpen)
                  continuation.finish()
              }
            } else {
              EnvironmentValues().openURL(url) { canOpen in
                continuation.yield(canOpen)
                continuation.finish()
              }
            }
          #else
            EnvironmentValues().openURL(url) { canOpen in
              continuation.yield(canOpen)
              continuation.finish()
            }
          #endif
        }
        continuation.onTermination = { @Sendable _ in
          task.cancel()
        }
      }
      return await stream.first(where: { _ in true }) ?? false
    }
    static let testValue = OpenURLEffect { _ in
      reportIssue(#"Unimplemented: @Dependency(\.openURL)"#)
      return false
    }
  }

  public struct OpenURLEffect: Sendable {
    private let handler: @Sendable (URL) async -> Bool

    public init(handler: @escaping @Sendable (URL) async -> Bool) {
      self.handler = handler
    }

    @available(watchOS, unavailable)
    @discardableResult
    public func callAsFunction(_ url: URL) async -> Bool {
      await self.handler(url)
    }

    @_disfavoredOverload
    public func callAsFunction(_ url: URL) async {
      _ = await self.handler(url)
    }
  }
#endif
