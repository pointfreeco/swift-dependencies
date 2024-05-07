import Dependencies
import XCTest

final class AssertTests: XCTestCase {
  @Dependency(\.assert) var assert

  func testPass() {
    assert(true)
    assert(true, "Must be true")
  }

  func testFail() {
    XCTExpectFailure {
      assert(false)
    }
    XCTExpectFailure {
      assert(false, "Must be true")
    } issueMatcher: {
      $0.compactDescription == "Must be true"
    }
  }

  func testCustom() {
    let expectation = self.expectation(description: "assert")
    withDependencies {
      $0.assert = Assert { condition, message, file, line in
        expectation.fulfill()
      }
    } operation: {
      assert(true)
      self.wait(for: [expectation], timeout: 0)
    }
  }
}
