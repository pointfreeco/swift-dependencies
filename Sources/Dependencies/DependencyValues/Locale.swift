#if Foundation
  import ConcurrencyExtras
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
          self[LocaleKey.self].wrappedValue = newValue
        #endif
      }
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
      get { self[PreferredLocalesKey.self]() }
      set {
        #if canImport(Darwin)
          self[PreferredLocalesKey.self] = { newValue }
        #else
          let newValue = UncheckedSendable(newValue)
          self[PreferredLocalesKey.self] = { newValue.wrappedValue }
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

    private enum PreferredLocalesKey: DependencyKey {
      static let liveValue: @Sendable () -> [Locale] = {
        Locale.preferredLanguages.compactMap {
          Locale(identifier: $0)
        }
      }
    }
  }
#endif
