import DependenciesMacros
import XCTest

final class DependencyEndpointTests: XCTestCase {
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

  func testExpected() {
    struct Client {
      @DependencyEndpoint
      var endpoint: () -> Void
    }
    XCTExpectFailure {
      $0.compactDescription == """
        'endpoint' called 0 times (expected at least 1 time)
        """
    }
    var client = Client()
    client.$endpoint {}
  }

  func testExpectedTwice() {
    struct Client {
      @DependencyEndpoint
      var endpoint: () -> Void
    }
    XCTExpectFailure {
      $0.compactDescription == """
        'endpoint' called 1 time (expected at least 2 times)
        """
    }
    var client = Client()
    client.$endpoint(expectedCount: 2) {}
    client.endpoint()
  }

  func testExpectedExactlyTwice() {
    struct Client {
      @DependencyEndpoint
      var endpoint: () -> Void
    }
    XCTExpectFailure {
      $0.compactDescription == """
        'endpoint' called 3 times (expected 2 times)
        """
    }
    var client = Client()
    client.$endpoint(expectedCount: 2, exactCount: true) {}
    client.endpoint()
    client.endpoint()
    client.endpoint()
  }
}
