#if Foundation
  public import Foundation

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
    /// @Observable
    /// final class FeatureModel {
    ///   @ObservationIgnored
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

    /// The preferred locales that features should use for content-language selection.
    ///
    /// By default, locales created from `Locale.preferredLanguages` are supplied. Unlike ``locale``,
    /// which represents the locale to use for formatting and regional conventions, this ordered
    /// list represents the user's preferred content languages. When used in tests, access will call
    /// to `reportIssue` when invoked, unless explicitly overridden.
    ///
    /// You can access the preferred locales from a feature by introducing a ``Dependency`` property
    /// wrapper to the property:
    ///
    /// ```swift
    /// @Observable
    /// final class FeatureModel {
    ///   @ObservationIgnored
    ///   @Dependency(\.preferredLocales) var preferredLocales
    ///   // ...
    /// }
    /// ```
    ///
    /// To override the preferred locales in tests, use ``withValues(_:assert:)-1egh6``:
    ///
    /// ```swift
    /// // Provision model with overridden dependencies
    /// let model = withDependencies {
    ///   $0.preferredLocales = [Locale(identifier: "es-ES")]
    /// } operation: {
    ///   FeatureModel()
    /// }
    ///
    /// // Make assertions with model...
    /// ```
    public var preferredLocales: [Locale] {
      get { self[PreferredLocalesKey.self].preferredLocales }
      set { self[PreferredLocalesKey.self] = PreferredLocales(constantLocales: newValue) }
    }

    private enum LocaleKey: DependencyKey {
      static var liveValue: Locale { .autoupdatingCurrent }
    }

    private enum PreferredLocalesKey: DependencyKey {
      static var liveValue: PreferredLocales {
        PreferredLocales()
      }
    }

    private struct PreferredLocales: Sendable {
      var constantLocales: [Locale]?
      var preferredLocales: [Locale] {
        constantLocales
          ?? Locale.preferredLanguages.compactMap {
            Locale(identifier: $0)
          }
      }
    }
  }
#endif
