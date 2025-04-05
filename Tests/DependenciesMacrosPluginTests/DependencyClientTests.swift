#if canImport(ObjectiveC)
import DependenciesMacros
import XCTest

final class DependencyClientTests: BaseTestCase {
  func testUnimplementedEndpoint() throws {
    let client = Client()

    XCTExpectFailure {
      $0.compactDescription == """
        failed - Unimplemented: 'Client.fetch'
        """
    }

    do {
      let _ = try client.fetch()
      XCTFail("Client.fetch should throw an error.")
    } catch {
    }
  }

  func testUnimplementedWithNonThrowingEndpoint() {
    let client = ClientWithNonThrowingEndpoint()

    XCTExpectFailure {
      XCTAssertEqual(client.fetch(), 42)
    } issueMatcher: {
      $0.compactDescription == """
        failed - Unimplemented: \'ClientWithNonThrowingEndpoint.fetch\'
        """
    }

    XCTExpectFailure {
      XCTAssertEqual(client.fetchWithUnimplemented(), 42)
    } issueMatcher: {
      $0.compactDescription == """
        failed - Unimplemented: \'ClientWithNonThrowingEndpoint.fetchWithUnimplemented\'
        """ ||
      $0.compactDescription == """
        failed - Unimplemented …

          Defined in 'ClientWithNonThrowingEndpoint' at:
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
#endif
