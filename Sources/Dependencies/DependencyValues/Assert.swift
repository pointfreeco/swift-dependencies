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
  public var assert: Assert {
    get { self[AssertKey.self] }
    set { self[AssertKey.self] = newValue }
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
  public var precondition: Assert {
    get { self[PreconditionKey.self] }
    set { self[PreconditionKey.self] = newValue }
  }}

/// A type for creating an assertion or precondition.
///
/// See ``DependencyValues/assert`` or ``DependencyValues/precondition`` for more information.
public struct Assert: Sendable {
  public let assert: @Sendable (
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
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.assert(condition(), message(), file, line)
  }
}

private enum AssertKey: DependencyKey {
  public static let liveValue = Assert { condition, message, file, line in
    Swift.assert(condition(), message(), file: file, line: line)
  }
  public static let testValue = Assert { condition, message, file, line in
    guard condition() else { return XCTFail(message(), file: file, line: line) }
  }
}

private enum PreconditionKey: DependencyKey {
  public static let liveValue = Assert { condition, message, file, line in
    Swift.precondition(condition(), message(), file: file, line: line)
  }
  public static let testValue = Assert { condition, message, file, line in
    guard condition() else { return XCTFail(message(), file: file, line: line) }
  }
}
