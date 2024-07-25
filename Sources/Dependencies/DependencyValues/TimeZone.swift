import Foundation

extension DependencyValues {
  /// The current time zone that features should use when handling dates.
  ///
  /// By default, the time zone returned from `TimeZone.autoupdatingCurrent` is supplied. When used
  /// in tests, access will call to `reportIssue` when invoked, unless explicitly overridden:
  ///
  /// ```swift
  /// // Provision model with overridden dependencies
  /// let model = withDependencies {
  ///   $0.timeZone = TimeZone(secondsFromGMT: 0)
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Make assertions with model...
  /// ```
  public var timeZone: TimeZone {
    get {
      #if canImport(Darwin)
        self[TimeZoneKey.self]
      #else
        self[TimeZoneKey.self].wrappedValue
      #endif
    }
    set {
      #if canImport(Darwin)
        self[TimeZoneKey.self] = newValue
      #else
        self[TimeZoneKey.self].newValue
      #endif
    }
  }

  private enum TimeZoneKey: DependencyKey {
    #if canImport(Darwin)
      static let liveValue = TimeZone.autoupdatingCurrent
    #else
      // NB: 'TimeZone' sendability is not yet available in a 'swift-corelibs-foundation' release
      static let liveValue = UncheckedSendable(TimeZone.autoupdatingCurrent)
    #endif
  }
}
