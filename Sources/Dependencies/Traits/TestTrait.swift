public struct _DependenciesTrait: Sendable {
  package let operation: @Sendable (inout DependencyValues) -> Void

  package init(_ operation: @escaping @Sendable (inout DependencyValues) -> Void) {
    self.operation = operation
  }

  package static let all = LockIsolated<[AnyHashable: DependencyValues]>([:])
}
