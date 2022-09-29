#if os(iOS)
  import SwiftUI

  @available(iOS 15, *)
  private let sendable: @Sendable () -> AsyncStream<Void> = {
    AsyncStream {
      await NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    }
  }

  @available(iOS 15, *)
  private let mainActor: @MainActor () -> AsyncStream<Void> = {
    AsyncStream {
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    }
  }

  @available(iOS 15, *)
  private let sendableThrowing: @Sendable () -> AsyncThrowingStream<Void, Error> = {
    AsyncThrowingStream {
      await NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    }
  }

  @available(iOS 15, *)
  private let mainActorThrowing: @MainActor () -> AsyncThrowingStream<Void, Error> = {
    AsyncThrowingStream {
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    }
  }
#endif
