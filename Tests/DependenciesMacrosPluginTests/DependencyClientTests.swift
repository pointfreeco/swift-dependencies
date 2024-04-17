import DependenciesMacros
import XCTest

final class DependencyClientTests: BaseTestCase {
  func testUnimplementedEndpoint() throws {
    let client = Client()

    XCTExpectFailure {
      $0.compactDescription == """
        Unimplemented: 'Client.fetch'
        """
    }

    do {
      let _ = try client.fetch()
      XCTFail("Client.fetch should throw an error.")
    } catch {
    }
  }

  func testSwiftBug() {
    let client = ClientWithNonThrowingEndpoint()

    // NB: This should cause a test failure but currently does not due to a Swift compiler bug:
    //     https://github.com/apple/swift/issues/71070
    XCTAssertEqual(client.fetch(), 42)

    XCTExpectFailure {
      XCTAssertEqual(client.fetchWithUnimplemented(), 42)
    } issueMatcher: {
      $0.compactDescription == """
        Unimplemented …

          Defined at:
            DependenciesMacrosPluginTests/DependencyClientTests.swift:\(ClientWithNonThrowingEndpoint.line + 1)
        """
    }
  }
}

@DependencyClient
struct Client {
  var fetch: () throws -> Int
}

@DependencyClient
struct ClientWithNonThrowingEndpoint {
  var fetch: () -> Int = { 42 }
  static let line = #line
  var fetchWithUnimplemented: () -> Int = { unimplemented(placeholder: 42) }
}
