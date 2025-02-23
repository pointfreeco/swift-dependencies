#if canImport(Testing) && compiler(>=6)
  import ConcurrencyExtras
  import Dependencies
  import Testing

  #if swift(>=6.1)
    @_documentation(visibility: private)
    public struct _DependenciesScopeTrait: TestScoping, TestTrait, SuiteTrait {
      let updateValues: @Sendable (inout DependencyValues) throws -> Void

      public var isRecursive: Bool { true }
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
      ) async throws {
        try await withDependencies {
          try updateValues(&$0)
        } operation: {
          try await function()
        }
      }
    }

    extension Trait where Self == _DependenciesScopeTrait {
      public static var resetDependencies: Self {
        Self { $0 = DependencyValues() }
      }
      public static func dependency<Value>(
        _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
        _ value: @autoclosure @escaping @Sendable () throws -> Value
      ) -> Self {
        Self {
          $0[keyPath: keyPath] = try value()
        }
      }
      public static func dependency<Value: TestDependencyKey>(
        _ value: @autoclosure @escaping @Sendable () throws -> Value
      ) -> Self where Value == Value.Value {
        Self { $0[Value.self] = try value() }
      }
      public static func dependencies(
        _ updateValues: @escaping @Sendable (inout DependencyValues) -> Void
      ) -> Self {
        Self(updateValues: updateValues)
      }
    }
  #else
    @_documentation(visibility: private)
    public struct _DependenciesTrait: Sendable {
      package let updateValues: @Sendable (inout DependencyValues) throws -> Void

      package init(_ updateValues: @escaping @Sendable (inout DependencyValues) throws -> Void) {
        self.updateValues = updateValues
      }
    }

    extension Trait where Self == _DependenciesTrait {
      /// A trait that overrides a test's or suite's dependency.
      ///
      /// Useful for overriding a dependency in a test without incurring the nesting and
      /// indentation of ``withDependencies(_:operation:)-4uz6m``.
      ///
      /// ```swift
      /// @Test(
      ///   .dependency(\.continuousClock, .immediate)
      /// )
      /// func feature() {
      ///   // ...
      /// }
      /// ```
      ///
      /// > Important: Due to [a Swift bug](https://github.com/swiftlang/swift/issues/76409), it is
      /// > not possible to specify a closure directly inside a `@Suite` or `@Test` macro:
      /// >
      /// > ```swift
      /// > @Suite(
      /// >   .dependency(\.apiClient.fetchUser, { _ in .mock })  // 🛑
      /// > )
      /// > struct FeatureTests { /* ... */ }
      /// > ```
      /// >
      /// > To work around: extract the closure so that it is created outside the macro:
      /// >
      /// ```swift
      /// > private let fetchUser: @Sendable (Int) async throws -> User = { _ in .mock }
      /// > @Suite(
      /// >   .dependency(\.apiClient.fetchUser, fetchUser)
      /// > )
      /// > struct FeatureTests { /* ... */ }
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
      /// @Test(
      ///   .dependency(Client.mock)
      /// )
      /// func feature() {
      ///   // ...
      /// }
      /// ```
      ///
      /// > Important: Due to [a Swift bug](https://github.com/swiftlang/swift/issues/76409), it is
      /// > not possible to specify a closure directly inside a `@Suite` or `@Test` macro:
      /// >
      /// > ```swift
      /// > @Suite(
      /// >   .dependency(Client { _ in .mock })  // 🛑
      /// > )
      /// > struct FeatureTests { /* ... */ }
      /// > ```
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
      public static func dependencies(
        _ updateValues: @escaping @Sendable (inout DependencyValues) -> Void
      ) -> Self {
        Self(updateValues)
      }
    }

    extension _DependenciesTrait: SuiteTrait, TestTrait {
      public var isRecursive: Bool { true }

      public func prepare(for test: Test) async throws {
        try testValuesByTestID.withValue {
          try self.updateValues(&$0[test.id, default: DependencyValues(context: .test)])
        }
      }
    }
  #endif
#endif
