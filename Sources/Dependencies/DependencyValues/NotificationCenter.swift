#if canImport(Foundation) && !os(WASI)
  import Foundation

  extension DependencyValues {
    /// The notification center that features should use.
    ///
    /// By default, `NotificationCenter.default` is provided. When used in tests, a task-local
    /// center is provided, instead.
    ///
    /// You can access notification center from a feature by introducing a ``Dependency`` property
    /// wrapper to the property:
    ///
    /// ```swift
    /// @Observable
    /// final class FeatureModel {
    ///   @ObservationIgnored
    ///   @Dependency(\.notificationCenter) var notificationCenter
    ///   // ...
    /// }
    /// ```
    public var notificationCenter: NotificationCenter {
      get { self[NotificationCenterKey.self] }
      set { self[NotificationCenterKey.self] = newValue }
    }

    private enum NotificationCenterKey: DependencyKey {
      static let liveValue = NotificationCenter.default
      static var testValue: NotificationCenter { NotificationCenter() }
    }
  }
#endif
