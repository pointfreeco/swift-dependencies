#if canImport(Testing)
  import Dependencies
  import Testing

  extension Trait where Self == _DependenciesTrait {
    public static func dependency<Value: Sendable>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: Value
    ) -> Self {
      Self { $0[keyPath: keyPath] = value }
    }

    public static func dependencies(
      _ operation: @escaping @Sendable (inout DependencyValues) -> Void
    ) -> Self {
      Self(operation)
    }
  }

  extension _DependenciesTrait: SuiteTrait, TestTrait {
    public var isRecursive: Bool { true }

    public func prepare(for test: Test) async throws {
      Self.all.withValue { self.operation(&$0[test.id, default: DependencyValues(context: .test)]) }
    }
  }
#endif
