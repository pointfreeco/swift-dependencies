#if os(iOS)
  import SwiftUI

  @available(iOS 15, *)
  private let sendable: @Sendable () async -> AsyncStream<Void> = {
    await NotificationCenter.default
      .notifications(named: UIApplication.userDidTakeScreenshotNotification)
      .map { _ in }
      .eraseToStream()
  }

  @available(iOS 15, *)
  private let mainActor: @MainActor () -> AsyncStream<Void> = {
    NotificationCenter.default
      .notifications(named: UIApplication.userDidTakeScreenshotNotification)
      .map { _ in }
      .eraseToStream()
  }

  @available(iOS 15, *)
  private let sendableThrowing: @Sendable () async -> AsyncThrowingStream<Void, Error> = {
    await NotificationCenter.default
      .notifications(named: UIApplication.userDidTakeScreenshotNotification)
      .map { _ in }
      .eraseToThrowingStream()
  }

  @available(iOS 15, *)
  private let mainActorThrowing: @MainActor () -> AsyncThrowingStream<Void, Error> = {
    NotificationCenter.default
      .notifications(named: UIApplication.userDidTakeScreenshotNotification)
      .map { _ in }
      .eraseToThrowingStream()
  }
#endif
