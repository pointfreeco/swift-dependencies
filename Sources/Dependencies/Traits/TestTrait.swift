public struct _DependenciesTrait: Sendable {
  package let updateValues: @Sendable (inout DependencyValues) -> Void

  package init(_ updateValues: @escaping @Sendable (inout DependencyValues) -> Void) {
    self.updateValues = updateValues
  }

}

package let testValuesByTestID = LockIsolated<[AnyHashable: DependencyValues]>([:])
