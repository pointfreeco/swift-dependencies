/// A generic wrapper for isolating a mutable value to an actor.
///
/// This type is most useful when writing tests for when you want to inspect what happens inside an
/// effect. For example, suppose you have a feature such that when a button is tapped you track some
/// analytics:
///
/// ```swift
/// class FeatureModel: ObservableObject {
///   @Dependency(\.analytics) var analytics
///   // ...
///   func buttonTapped() {
///     // ...
///     await self.analytics.track("Button tapped")
///   }
/// }
/// ```
///
/// Then, in tests we can construct an analytics client that appends events to a mutable array
/// rather than actually sending events to an analytics server. However, in order to do this in a
/// safe way we should use an actor, and `ActorIsolated` makes this easy:
///
/// ```swift
/// func testAnalytics() async {
///   let events = ActorIsolated<[String]>([])
///   let model = withDependencies {
///     $0.analytics = AnalyticsClient(
///       track: { event in await events.withValue { $0.append(event) } }
///     )
///   } operation: {
///     FeatureModel()
///   }
///
///   model.buttonTapped()
///   await events.withValue {
///     XCTAssertEqual($0, ["Button tapped"])
///   }
/// }
/// ```
///
/// To synchronously isolate a value, see ``LockIsolated``.
@dynamicMemberLookup
public final actor ActorIsolated<Value> {
  /// The actor-isolated value.
  public var value: Value

  /// Initializes actor-isolated state around a value.
  ///
  /// - Parameter value: A value to isolate in an actor.
  public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
    self.value = try value()
  }

  public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.value[keyPath: keyPath]
  }

  /// Perform an operation with isolated access to the underlying value.
  ///
  /// Useful for modifying a value in a single transaction.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// let count = ActorIsolated(0)
  ///
  /// func increment() async {
  ///   // Safely increment it:
  ///   await self.count.withValue { $0 += 1 }
  /// }
  /// ```
  ///
  /// > Tip: Because XCTest assertions don't play nicely with Swift concurrency, `withValue` also
  /// > provides a handy interface to peek at an actor-isolated value and assert against it:
  /// >
  /// > ```swift
  /// > let didOpenSettings = ActorIsolated(false)
  /// > let model = withDependencies {
  /// >   $0.openSettings = { await didOpenSettings.setValue(true) }
  /// > } operation: {
  /// >   FeatureModel()
  /// > }
  /// > await model.settingsButtonTapped()
  /// > await didOpenSettings.withValue { XCTAssertTrue($0) }
  /// > ```
  ///
  /// - Parameters: operation: An operation to be performed on the actor with the underlying value.
  /// - Returns: The result of the operation.
  public func withValue<T>(
    _ operation: @Sendable (inout Value) throws -> T
  ) rethrows -> T {
    var value = self.value
    defer { self.value = value }
    return try operation(&value)
  }

  /// Overwrite the isolated value with a new value.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// let count = ActorIsolated(0)
  ///
  /// func reset() async {
  ///   // Reset it:
  ///   await self.count.setValue(0)
  /// }
  /// ```
  ///
  /// > Tip: Use ``withValue(_:)-805p`` instead of `setValue` if the value being set is derived from
  /// > the current value. This isolates the entire transaction and avoids data races between
  /// > reading and writing the value.
  ///
  /// - Parameter newValue: The value to replace the current isolated value with.
  public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
    self.value = try newValue()
  }
}
