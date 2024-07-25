import Foundation

extension DependencyValues {
  /// The current calendar that features should use when handling dates.
  ///
  /// By default, the calendar returned from `Calendar.autoupdatingCurrent` is supplied. When used
  /// in a testing context, access will call to `reportIssue` when invoked, unless explicitly
  /// overridden using ``withDependencies(_:operation:)-4uz6m``:
  ///
  /// ```swift
  /// // Provision model with overridden dependencies
  /// let model = withDependencies {
  ///   $0.calendar = Calendar(identifier: .gregorian)
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Make assertions with model...
  /// ```
  public var calendar: Calendar {
    get {
      #if canImport(Darwin)
        self[CalendarKey.self]
      #else
        self[CalendarKey.self].wrappedValue
      #endif
    }
    set {
      #if canImport(Darwin)
        self[CalendarKey.self] = newValue
      #else
        self[CalendarKey.self].newValue
      #endif
    }
  }

  private enum CalendarKey: DependencyKey {
    #if canImport(Darwin)
      static let liveValue = Calendar.autoupdatingCurrent
    #else
      // NB: 'Calendar' sendability is not yet available in a 'swift-corelibs-foundation' release
      static let liveValue = UncheckedSendable(Calendar.autoupdatingCurrent)
    #endif
  }
}
