import Foundation

extension DependencyValues {
  /// The current locale that features should use.
  ///
  /// By default, the locale returned from `Locale.autoupdatingCurrent` is supplied. When used in
  /// tests, access will call to `XCTFail` when invoked, unless explicitly overridden.
  ///
  /// You can access the current locale from a feature by introducing a ``Dependency`` property
  /// wrapper to the property:
  ///
  /// ```swift
  /// final class FeatureModel: ObservableObject {
  ///   @Dependency(\.locale) var locale
  ///   // ...
  /// }
  /// ```
  ///
  /// To override the current locale in tests, use ``withValues(_:assert:)-1egh6``:

  /// ```swift
  /// // Provision model with overridden dependencies
  /// let model = withDependencies {
  ///   $0.locale = Locale(identifier: "en_US")
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Make assertions with model...
  /// ```
  public var locale: Locale {
    get { self[LocaleKey.self] }
    set { self[LocaleKey.self] = newValue }
  }

  private enum LocaleKey: DependencyKey {
    static let liveValue = Locale.autoupdatingCurrent
  }
}
