#if canImport(Testing)
  import Dependencies
  import Testing

  @_documentation(visibility: private)
  public struct _DependenciesTrait: TestScoping, TestTrait, SuiteTrait {
    let updateValues: @Sendable (inout DependencyValues) async throws -> Void

    @TaskLocal static var isRoot = true

    public var isRecursive: Bool { true }
    public func provideScope(
      for test: Test,
      testCase: Test.Case?,
      performing function: @Sendable () async throws -> Void
    ) async throws {
      try await withDependencies {
        if Self.isRoot {
          $0 = DependencyValues()
        }
        try await updateValues(&$0)
      } operation: {
        try await Self.$isRoot.withValue(false) {
          try await function()
        }
      }
    }
  }

  extension Trait where Self == _DependenciesTrait {
    /// A trait that quarantines a test's dependencies from other tests.
    ///
    /// When applied to a `@Suite` (or `@Test`), the dependencies used for that suite (or test)
    /// will be kept separate from any other suites (and tests) running in parallel.
    ///
    /// It is recommended to use a base `@Suite` to apply this to all tests. You can do this by
    /// defining a `@Suite` with the trait:
    ///
    /// ```swift
    /// @Suite(.dependencies) struct BaseSuite {}
    /// ```
    ///
    /// Then any suite or test you write can be nested inside the base suite:
    ///
    /// ```swift
    /// extension BaseSuite {
    ///   @Suite struct MyTests {
    ///     @Test func login() {
    ///       // Dependencies accessed in here are independent from 'logout' tests.
    ///     }
    ///
    ///     @Test func logout() {
    ///       // Dependencies accessed in here are independent from 'login' tests.
    ///     }
    ///   }
    /// }
    /// ```
    public static var dependencies: Self {
      Self { _ in }
    }

    /// A trait that overrides a test's or suite's dependency.
    ///
    /// Useful for overriding a dependency in a test without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// @Test(.dependency(\.continuousClock, .immediate))
    /// func feature() {
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a dependency value.
    ///   - value: A dependency value to override for the test.
    public static func dependency<Value>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: @autoclosure @escaping @Sendable () throws -> Value
    ) -> Self {
      Self {
        $0[keyPath: keyPath] = try value()
      }
    }

    /// A trait that overrides a test's or suite's dependency.
    ///
    /// Useful for overriding a dependency in a test without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// struct Client: DependencyKey { … }
    /// @Test(.dependency(Client.mock))
    /// func feature() {
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a dependency value.
    ///   - value: A dependency value to override for the test.
    public static func dependency<Value: TestDependencyKey>(
      _ value: @autoclosure @escaping @Sendable () throws -> Value
    ) -> Self where Value == Value.Value {
      Self { $0[Value.self] = try value() }
    }

    /// A trait that overrides a test's or suite's dependencies.
    ///
    /// Useful for overriding a dependency in a test without incurring the nesting and
    /// indentation of ``withDependencies(_:operation:)-4uz6m``.
    ///
    /// ```swift
    /// @Test(.dependencies {
    ///   $0.date.now = Date(timeIntervalSince1970: 1234567890)
    ///   $0.uuid = .incrementing
    /// })
    /// func feature() {
    ///   // ...
    /// }
    /// ```
    ///
    public static func dependencies(
      _ updateValues: @escaping @Sendable (inout DependencyValues) async throws -> Void
    ) -> Self {
      Self(updateValues: updateValues)
    }
  }
#endif
