import Dependencies
import DependenciesMacros
import IssueReporting

@DependencyClient private struct ClientWithClosuresBeforeNonClosures {
  var endpoint1: () async throws -> Int
  var endpoint2: () async throws -> Int
  var identifier: String
}

#if compiler(>=6.2) && canImport(SwiftSyntax602)
  @DependencyClient
  struct ClientWithNonisolatedNonsendingEndpoints {
    var fetch: nonisolated(nonsending) @Sendable (_ id: Int) async throws -> String
    @DependencyEndpoint(method: "load")
    var loadEndpoint: nonisolated(nonsending) @Sendable (Int) async -> Void
  }
#endif
