#if canImport(DependenciesMacros)
  import Dependencies
  import DependenciesMacros
  import XCTest

  final class DependencyEndpointTests: XCTestCase {
    #if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
      func testUnimplemented() {
        @DependencyClient
        struct Client {
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

      func testUnimplementedWithDefault() {
        @DependencyClient
        struct Client {
          var endpoint: () -> Int = { 42 }
        }
        let client = Client()
        XCTExpectFailure {
          let output = client.endpoint()
          XCTAssert(output == 42)
        } issueMatcher: {
          $0.compactDescription == """
            failed - Unimplemented: 'Client.endpoint'
            """
        }
      }
    #endif
  }
#endif
