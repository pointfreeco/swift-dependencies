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
    get { self[CalendarKey.self] }
    set { self[CalendarKey.self] = newValue }
  }

  private enum CalendarKey: DependencyKey {
    static let liveValue = Calendar.autoupdatingCurrent
  }
}
