import Foundation

extension DependencyValues {
  /// The `NotificationCenter` object features should observe notifications with.
  ///
  /// By default, the notification center returned from `NotificationCenter.default` is supplied. When used
  /// in tests, access will call to `XCTFail` when invoked, unless explicitly overridden:
  ///
  /// ```swift
  /// // Provision model with overridden dependencies
  /// let testCenter = NotificationCenter()
  /// let model = withDependencies {
  ///   $0.notificationCenter = testCenter
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Send notifications and make assertions with model...
  /// ```
  public var notificationCenter: NotificationCenter {
    get { self[NotificationCenterKey.self] }
    set { self[NotificationCenterKey.self] = newValue }
  }

  private enum NotificationCenterKey: DependencyKey {
    static let liveValue = NotificationCenter.default
  }
}
