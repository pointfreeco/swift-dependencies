extension DependencyValues {
  /// A dependency for handling assertions.
  ///
  /// Useful as a controllable and testable substitute for Swift's `assert` function that calls
  /// `reportIssue` in tests instead of terminating the executable.
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
    self[AssertKey.self]
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
  /// calls `reportIssue` in tests instead of terminating the executable.
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
    self[PreconditionKey.self]
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
  @_disfavoredOverload
  @_transparent
  public func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.callAsFunction(condition(), message(), file: file, line: line)
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
    guard condition() else {
      reportIssue(message(), fileID: file, filePath: file, line: line, column: 0)
      return
    }
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
  @_disfavoredOverload
  @_transparent
  public func callAsFunction(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.callAsFunction(message(), file: file, line: line)
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
