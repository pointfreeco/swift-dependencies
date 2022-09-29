#if swift(>=5.7) && (canImport(RegexBuilder) || !os(macOS) && !targetEnvironment(macCatalyst))
  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  extension DependencyValues {
    /// The current clock that features should use when a `ContinuousClock` would be appropriate.
    ///
    /// This clock is type-erased so that it can be swapped out in previews and tests for another
    /// clock, like [`ImmediateClock`][immediate-clock] and [`TestClock`][test-clock] that come with
    /// the [Clocks][swift-clocks] library (which is automatically imported and available when you
    /// import this library).
    ///
    /// By default, a live `ContinuousClock` is supplied. When used in a testing context, an
    /// [`UnimplementedClock`][unimplemented-clock] is provided, which generates an XCTest failure
    /// when used, unless explicitly overridden using ``withDependencies(_:operation:)-4uz6m``:
    ///
    /// ```swift
    /// // Provision model with overridden dependencies
    /// let model = withDependencies {
    ///   $0.continuousClock = ImmediateClock()
    /// } operation: {
    ///   FeatureModel()
    /// }
    ///
    /// // Make assertions with model...
    /// ```
    ///
    /// See ``suspendingClock`` to override a feature's `SuspendingClock`, instead.
    ///
    /// [immediate-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/immediateclock/
    /// [test-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/testclock/
    /// [swift-clocks]: https://github.com/pointfreeco/swift-clocks
    /// [unimplemented-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/unimplementedclock/
    public var continuousClock: any Clock<Duration> {
      get { self[ContinuousClockKey.self] }
      set { self[ContinuousClockKey.self] = newValue }
    }

    /// The current clock that features should use when a `SuspendingClock` would be appropriate.
    ///
    /// This clock is type-erased so that it can be swapped out in previews and tests for another
    /// clock, like [`ImmediateClock`][immediate-clock] and [`TestClock`][test-clock] that come with
    /// the [Clocks][swift-clocks] library (which is automatically imported and available when you
    /// import this library).
    ///
    /// By default, a live `SuspendingClock` is supplied. When used in a testing context, an
    /// [`UnimplementedClock`][unimplemented-clock] is provided, which generates an XCTest failure
    /// when used, unless explicitly overridden using ``withDependencies(_:operation:)-4uz6m``:
    ///
    /// ```swift
    /// // Provision model with overridden dependencies
    /// let model = withDependencies {
    ///   $0.suspendingClock = ImmediateClock()
    /// } operation: {
    ///   FeatureModel()
    /// }
    ///
    /// // Make assertions with model...
    /// ```
    ///
    /// See ``continuousClock`` to override a feature's `ContinuousClock`, instead.
    ///
    /// [immediate-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/immediateclock/
    /// [test-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/testclock/
    /// [swift-clocks]: https://github.com/pointfreeco/swift-clocks
    /// [unimplemented-clock]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/unimplementedclock/
    public var suspendingClock: any Clock<Duration> {
      get { self[SuspendingClockKey.self] }
      set { self[SuspendingClockKey.self] = newValue }
    }

    private enum ContinuousClockKey: DependencyKey {
      static let liveValue: any Clock<Duration> = ContinuousClock()
      static let testValue: any Clock<Duration> = UnimplementedClock(name: "ContinuousClock")
    }

    private enum SuspendingClockKey: DependencyKey {
      static let liveValue: any Clock<Duration> = SuspendingClock()
      static let testValue: any Clock<Duration> = UnimplementedClock(name: "SuspendingClock")
    }
  }
#endif
