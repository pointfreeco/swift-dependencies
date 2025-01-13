import Foundation

extension DependencyValues {
  /// A dependency that returns the current date.
  ///
  /// By default, a "live" generator is supplied, which returns the current system date when called
  /// by invoking `Date.init` under the hood. When used in tests, an "unimplemented" generator that
  /// additionally reports test failures is supplied, unless explicitly overridden.
  ///
  /// You can access the current date from a feature by introducing a ``Dependency`` property
  /// wrapper to the generator's ``DateGenerator/now`` property:
  ///
  /// ```swift
  /// @Observable
  /// final class FeatureModel {
  ///   @ObservationIgnored
  ///   @Dependency(\.date.now) var now
  ///   // ...
  /// }
  /// ```
  ///
  /// To override the current date in tests, you can override the generator using
  /// ``withDependencies(_:operation:)-4uz6m``:
  ///
  /// ```swift
  /// // Provision model with overridden dependencies
  /// let model = withDependencies {
  ///   $0.date.now = Date(timeIntervalSince1970: 1234567890)
  /// } operation: {
  ///   FeatureModel()
  /// }
  ///
  /// // Make assertions with model...
  /// ```
  public var date: DateGenerator {
    get { self[DateGeneratorKey.self] }
    set { self[DateGeneratorKey.self] = newValue }
  }

  private enum DateGeneratorKey: DependencyKey {
    static let liveValue = DateGenerator { Date() }
    static let testValue = DateGenerator {
      reportIssue(#"Unimplemented: @Dependency(\.date)"#)
      return Date()
    }
  }
}

/// A dependency that generates a date.
///
/// See ``DependencyValues/date`` for more information.
public struct DateGenerator: Sendable {
  private var generate: @Sendable () -> Date

  /// A generator that returns a constant date.
  ///
  /// - Parameter now: A date to return.
  /// - Returns: A generator that always returns the given date.
  public static func constant(_ now: Date) -> Self {
    Self { now }
  }

  /// The current date.
  public var now: Date {
    get { self.generate() }
    set { self.generate = { newValue } }
  }

  /// Initializes a date generator that generates a date from a closure.
  ///
  /// - Parameter generate: A closure that returns the current date when called.
  public init(_ generate: @escaping @Sendable () -> Date) {
    self.generate = generate
  }

  public func callAsFunction() -> Date {
    self.generate()
  }
}
