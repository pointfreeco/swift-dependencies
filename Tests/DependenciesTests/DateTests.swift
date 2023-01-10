import Dependencies
import XCTest
import XCTestDynamicOverlay

final class DateDependencyTests: XCTestCase {
  @Dependency(\.date) var date
  @Dependency(\.date.now) var now
  
  func testOverriding_Now() {
    withDependencies {
      $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
    } operation: {
      XCTAssertEqual(self.now, Date(timeIntervalSinceReferenceDate: 0))
      XCTAssertEqual(self.date(), Date(timeIntervalSinceReferenceDate: 0))
    }
  }
  
  func testIncrementing() {
    withDependencies {
      $0.date = .incrementing(by: 1, offset: 0)
    } operation: {
      XCTAssertEqual(self.date(), Date(timeIntervalSinceReferenceDate: 0))
      XCTAssertEqual(self.date(), Date(timeIntervalSinceReferenceDate: 1))
    }
  }
}
