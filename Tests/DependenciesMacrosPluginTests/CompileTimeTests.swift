import Dependencies
import DependenciesMacros
import IssueReporting

@DependencyClient private struct ClientWithClosuresBeforeNonClosures {
  var endpoint1: () async throws -> Int
  var endpoint2: () async throws -> Int
  var identifier: String
}
