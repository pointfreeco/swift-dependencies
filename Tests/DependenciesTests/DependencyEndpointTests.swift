#if canImport(DependenciesMacros)
  import Dependencies
  import DependenciesMacros
  import XCTest

  final class DependencyEndpointTests: XCTestCase {
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
      func testUnimplemented() {
        struct Client {
          @DependencyEndpoint
          var endpoint: () -> Void
        }
        let client = Client()
        XCTExpectFailure {
          client.endpoint()
        } issueMatcher: {
          $0.compactDescription == """
            Unimplemented: 'endpoint'
            """
        }
      }
    #endif
  }
#endif
