#if canImport(DependenciesMacros)
  import Dependencies
  import DependenciesMacros
  import XCTest

  final class DependencyEndpointTests: XCTestCase {
    #if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
      func testUnimplemented() {
        @DependencyClient
        struct Client {
          @DependencyEndpoint
          var endpoint: () -> Void
        }
        let client = Client()
        XCTExpectFailure {
          client.endpoint()
        } issueMatcher: {
          $0.compactDescription == """
            failed - Unimplemented: 'Client.endpoint'
            """
        }
      }
    #endif
  }
#endif
