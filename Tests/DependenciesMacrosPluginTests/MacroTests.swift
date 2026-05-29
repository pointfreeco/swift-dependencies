import Dependencies
import DependenciesMacros
import IssueReporting

private enum PackageACL {
  @DependencyClient
  package struct Client {
    @DependencyEndpoint
    package var endpoint: (_ id: Int) -> Void
  }
}
