import Dependencies
import Testing
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
        $0.compactDescription == "failed - Must be true"
      }
      XCTExpectFailure {
        assertionFailure("Failure")
      } issueMatcher: {
        $0.compactDescription == "failed - Failure"
      }
      XCTExpectFailure {
        precondition(false)
      }
      XCTExpectFailure {
        precondition(false, "Must be true")
      } issueMatcher: {
        $0.compactDescription == "failed - Must be true"
      }
    }
  #endif
}

struct AssertTests_SwiftTesting {
  @Dependency(\.assert) var assert

  @Test func assertDependency() {
    withKnownIssue {
      assert(false)
    }
    withKnownIssue {
      assert(false, "This shouldn't happen.")
    }
  }
}
