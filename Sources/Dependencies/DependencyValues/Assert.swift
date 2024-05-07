extension DependencyValues {
  /// A dependency for handling assertions.
  ///
  /// Useful as a controllable and testable substitute for Swift's `assert` function that calls
  /// `XCTFail` in tests instead of terminating the executable.
  ///
  /// ```swift
  /// func operate(_ n: Int) {
  ///   @Dependency(\.assert) var assert
  ///   assert(n > 0, "Number must be greater than zero")
  ///   // ...
  /// }
  /// ```
  ///
  /// Tests can assert against this precondition using `XCTExpectFailure`:
  ///
  /// ```swift
  /// XCTExpectFailure {
  ///   operate(n)
  /// } issueMatcher: {
  ///   $0.compactDescription = "Number must be greater than zero"
  /// }
  /// ```
  public var assert: any AssertionEffect {
    get { self[AssertKey.self] }
    set { self[AssertKey.self] = newValue }
  }

  /// A dependency for failing an assertion.
  ///
  /// Equivalent to passing a `false` condition to ``DependencyValues/assert``.
  public var assertionFailure: any AssertionFailureEffect {
    AssertionFailure(base: self.assert)
  }

  /// A dependency for handling preconditions.
  ///
  /// Useful as a controllable and testable substitute for Swift's `precondition` function that
  /// calls `XCTFail` in tests instead of terminating the executable.
  ///
  /// ```swift
  /// func operate(_ n: Int) {
  ///   @Dependency(\.precondition) var precondition
  ///   precondition(n > 0, "Number must be greater than zero")
  ///   // ...
  /// }
  /// ```
  ///
  /// Tests can assert against this precondition using `XCTExpectFailure`:
  ///
  /// ```swift
  /// XCTExpectFailure {
  ///   operate(n)
  /// } issueMatcher: {
  ///   $0.compactDescription = "Number must be greater than zero"
  /// }
  /// ```
  public var precondition: any AssertionEffect {
    get { self[PreconditionKey.self] }
    set { self[PreconditionKey.self] = newValue }
  }

  /// A dependency for failing a precondition.
  ///
  /// Equivalent to passing a `false` condition to ``DependencyValues/precondition``.
  public var preconditionFailure: any AssertionFailureEffect {
    AssertionFailure(base: self.assert)
  }
}

/// A type for creating an assertion or precondition.
///
/// See ``DependencyValues/assert`` or ``DependencyValues/precondition`` for more information.
public protocol AssertionEffect: Sendable {
  func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  )
}

extension AssertionEffect {
  @_transparent
  public func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.callAsFunction(condition(), "", file: file, line: line)
  }
}

private struct LiveAssertionEffect: AssertionEffect {
  @_transparent
  func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  ) {
    Swift.assert(condition(), message(), file: file, line: line)
  }
}

private struct LivePreconditionEffect: AssertionEffect {
  @_transparent
  func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  ) {
    Swift.precondition(condition(), message(), file: file, line: line)
  }
}

private struct TestAssertionEffect: AssertionEffect {
  @_transparent
  func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  ) {
    guard condition() else { return XCTFail(message(), file: file, line: line) }
  }
}

public protocol AssertionFailureEffect: Sendable {
  func callAsFunction(
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  )
}

extension AssertionFailureEffect {
  @_transparent
  public func callAsFunction(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.callAsFunction("", file: file, line: line)
  }
}

private struct AssertionFailure: AssertionFailureEffect {
  let base: any AssertionEffect

  @_transparent
  func callAsFunction(
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  ) {
    self.base(false, message(), file: file, line: line)
  }
}

private enum AssertKey: DependencyKey {
  public static let liveValue: any AssertionEffect = LiveAssertionEffect()
  public static let testValue: any AssertionEffect = TestAssertionEffect()
}

private enum PreconditionKey: DependencyKey {
  public static let liveValue: any AssertionEffect = LivePreconditionEffect()
  public static let testValue: any AssertionEffect = TestAssertionEffect()
}

/// An ``AssertionEffect`` that invokes the given closure.
public struct AnyAssertionEffect: AssertionEffect {
  private let assert: @Sendable (
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    _ file: StaticString,
    _ line: UInt
  ) -> Void

  public init(
    _ assert: @escaping @Sendable (
      _ condition: @autoclosure () -> Bool,
      _ message: @autoclosure () -> String,
      _ file: StaticString,
      _ line: UInt
    ) -> Void
  ) {
    self.assert = assert
  }

  public func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  ) {
    self.assert(condition(), message(), file, line)
  }
}
