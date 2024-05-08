import Dependencies
import XCTest

final class AssertTests: XCTestCase {
  @Dependency(\.assert) var assert
  @Dependency(\.assertionFailure) var assertionFailure
  @Dependency(\.precondition) var precondition

  func testPass() {
    assert(true)
    assert(true, "Must be true")
    precondition(true)
    precondition(true, "Must be true")
  }

  #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    func testFail() {
      XCTExpectFailure {
        assert(false)
      }
      XCTExpectFailure {
        assert(false, "Must be true")
      } issueMatcher: {
        $0.compactDescription == "Must be true"
      }
      XCTExpectFailure {
        assertionFailure("Failure")
      } issueMatcher: {
        $0.compactDescription == "Failure"
      }
      XCTExpectFailure {
        precondition(false)
      }
      XCTExpectFailure {
        precondition(false, "Must be true")
      } issueMatcher: {
        $0.compactDescription == "Must be true"
      }
    }
  #endif

  func testCustom() {
    let expectation = self.expectation(description: "assert")
    withDependencies {
      $0.assert = AnyAssertionEffect { condition, message, file, line in
        expectation.fulfill()
      }
    } operation: {
      assert(true)
      self.wait(for: [expectation], timeout: 0)
    }
  }
}
