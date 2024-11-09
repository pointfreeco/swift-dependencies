#if canImport(DependenciesMacros)
  import Dependencies
  import DependenciesMacros
  import XCTest

  final class DependencyEndpointTests: XCTestCase {
    #if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
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
            failed - Unimplemented: 'Client.endpoint'
            """
        }
      }

      func testUnimplementedWithDefault() {
        struct Client {
          @DependencyEndpoint
          var endpoint: () -> Int = { 42 }
        }
        let client = Client()
        // NB: This invocation of 'endpoint' *should* fail, but it does not due to a bug in the
        //     Swift compiler: https://github.com/apple/swift/issues/71070
        let output = client.endpoint()
        XCTAssert(output == 42)
      }
    #endif
  }
#endif
