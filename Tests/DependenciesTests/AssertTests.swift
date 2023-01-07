import Dependencies
import XCTest

final class AssertTests: XCTestCase {
  @Dependency(\.assert) var assert

  func testTestContext() async throws {
    let subject = Subject()

    subject.callAssert(condition: true)
    XCTExpectFailure {
      subject.callAssert(condition: false)
    }
  }

  func testLiveContext() async throws {
    let subject = withDependencies {
      $0.context = .live
    } operation: {
      Subject()
    }

    subject.callAssert(condition: true)
    // Can't test live failure
  }
}

final class Subject {
  @Dependency(\.assert) var assert

  func callAssert(condition: Bool) {
    self.assert(condition)
  }
}
