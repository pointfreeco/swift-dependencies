import Foundation

extension DependencyValues {
  /// The current time zone that features should use when handling dates.
  ///
  /// By default, the time zone returned from `TimeZone.autoupdatingCurrent` is supplied. When used
  /// in tests, access will call to `XCTFail` when invoked, unless explicitly overridden:
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
    get { self[TimeZoneKey.self] }
    set { self[TimeZoneKey.self] = newValue }
  }

  private enum TimeZoneKey: DependencyKey {
    static let liveValue = TimeZone.autoupdatingCurrent
  }
}
