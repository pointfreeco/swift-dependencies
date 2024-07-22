//import Dependencies
//@_spi(Experimental) import Testing
//
//@_spi(Experimental)
//public struct ResetDependenciesTrait: CustomExecutionTrait, TestTrait, SuiteTrait {
//  public let isRecursive = true
//  public func execute(
//    _ function: @escaping @Sendable () async throws -> Void,
//    for test: Test,
//    testCase: Test.Case?
//  ) async throws {
//    DependencyValues._current.cachedValues.cached = [:]
//    defer { DependencyValues._current.cachedValues.cached = [:] }
//    try await function()
//  }
//}
//
//@_spi(Experimental)
//extension SuiteTrait where Self == ResetDependenciesTrait {
//  public static var resetDependencies: Self { Self() }
//}
