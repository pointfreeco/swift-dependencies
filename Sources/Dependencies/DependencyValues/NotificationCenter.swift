import Foundation

extension DependencyValues {
  /// The current notification center to be used for delivering notifications.
  ///
  /// By default, the notificationCenter returned from `NotificationCenter.default` is supplied. When used
  /// in a testing context, access will call to `XCTFail` when invoked, unless explicitly overridden
  /// using ``withDependencies(_:operation:)-4uz6m``:
  ///
  /// ```swift
  /// // Provision model with overridden dependencies
  /// let notificationCenter: NotificationCenter = .init()
  /// let model = withDependencies {
  ///   $0.notificationCenter = notificationCenter
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Make assertions with model...
  /// ```
  public var notificationCenter: NotificationCenter {
    get { self[NotificationCenterKey.self] }
    set { self[NotificationCenterKey.self] = newValue }
  }

  private enum NotificationCenterKey: DependencyKey {
    static let liveValue = NotificationCenter.default
  }
}
