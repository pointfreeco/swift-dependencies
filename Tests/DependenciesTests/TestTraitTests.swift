#if canImport(Testing)
  import Dependencies
  import DependenciesTestSupport
  import Foundation
  import Testing

//  @Suite(.dependency(\.uuid, .incrementing))
  struct TestTraitTests {
    @Dependency(\.uuid) var uuid

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test func statefulDependency1() async throws {
      for index in 0...100 {
        #expect(uuid() == UUID(index))
        try await Task.sleep(for: .milliseconds(1))
      }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test func statefulDependency2() async throws {
      for index in 0...100 {
        #expect(uuid() == UUID(index))
        try await Task.sleep(for: .milliseconds(1))
      }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test func statefulDependency3() async throws {
      for index in 0...100 {
        #expect(uuid() == UUID(index))
        try await Task.sleep(for: .milliseconds(1))
      }
    }
  }
#endif
