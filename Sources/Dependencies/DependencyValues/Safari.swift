#if canImport(SafariServices) && canImport(SwiftUI)
import SafariServices
import SwiftUI

extension DependencyValues {
  /// A dependency that opens a URL in SFSafariViewController.
  ///
  /// In iOS, `SFSafariViewController` in UIKit context is used since navigation in SwiftUI context is not completly work well. Otherwise use openURL in environment values
  ///
  /// - SeeAlso: [How to use SFSafariViewController in SwiftUI ](https://sarunw.com/posts/sfsafariviewcontroller-in-swiftui/) by Sarunw.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public var safari: SafariEffect {
    get { self[SafariKey.self] }
    set { self[SafariKey.self] = newValue }
  }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
private enum SafariKey: DependencyKey {
  static let liveValue = SafariEffect { url in
    let stream = AsyncStream<Bool> { continuation in
      let task = Task { @MainActor in
#if os(iOS)
        let vc = SFSafariViewController(url: url)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
        continuation.yield(true)
        continuation.finish()
#else
        EnvironmentValues().openURL(url)
        continuation.yield(true)
        continuation.finish()
#endif
      }
      continuation.onTermination = { @Sendable _ in
        task.cancel()
      }
    }
    return await stream.first(where: { _ in true }) ?? false
  }
  static let testValue = SafariEffect { _ in
    XCTFail(#"Unimplemented: @Dependency(\.safari)"#)
    return false
  }
}

public struct SafariEffect: Sendable {
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

#if canImport(UIKit)
import UIKit

extension UIApplication {
  @available(iOS 14.0, *)
  var firstKeyWindow: UIWindow? {
    if #available(iOS 15.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }
        .first?.keyWindow
    } else {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }
        .first?.windows
        .first(where: \.isKeyWindow)
    }
  }
}

#endif
