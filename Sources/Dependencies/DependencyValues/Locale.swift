import Foundation

extension DependencyValues {
  /// The current locale that features should use.
  ///
  /// By default, the locale returned from `Locale.autoupdatingCurrent` is supplied. When used in
  /// tests, access will call to `reportIssue` when invoked, unless explicitly overridden.
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
    get {
      #if canImport(Darwin)
        self[LocaleKey.self]
      #else
        self[LocaleKey.self].wrappedValue
      #endif
    }
    set {
      #if canImport(Darwin)
        self[LocaleKey.self] = newValue
      #else
        self[LocaleKey.self].newValue
      #endif
    }
  }

  private enum LocaleKey: DependencyKey {
    #if canImport(Darwin)
      static let liveValue = Locale.autoupdatingCurrent
    #else
    // NB: 'Locale' sendability is not yet available in a 'swift-corelibs-foundation' release
      static let liveValue = UncheckedSendable(Locale.autoupdatingCurrent)
    #endif
  }
}
