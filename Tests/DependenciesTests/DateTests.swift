import Dependencies
import XCTest
import XCTestDynamicOverlay

final class DateDependencyTests: XCTestCase {
@Dependency(.date) var date
@Dependency(.date.now) var now

func testOverriding_Now() {
withDependencies {
$0.date.now = Date(timeIntervalSinceReferenceDate: 0)
} operation: {
XCTAssertEqual(self.now, Date(timeIntervalSinceReferenceDate: 0))
XCTAssertEqual(self.date(), Date(timeIntervalSinceReferenceDate: 0))
}
}

func testDateComparison() {
withDependencies {
$0.date.now = Date(timeIntervalSinceReferenceDate: 0)
} operation: {
let date1 = self.date()
let date2 = self.date()
XCTAssertLessThan(date1, date2)
}
}

func testAddingTimeInterval() {
withDependencies {
$0.date.now = Date(timeIntervalSinceReferenceDate: 0)
} operation: {
let date = self.date()
let interval: TimeInterval = 60
let futureDate = date.addingTimeInterval(interval)
XCTAssertEqual(futureDate, Date(timeIntervalSinceReferenceDate: interval))
}
}

func testChangingTimeZone() {
withDependencies {
$0.date.now = Date(timeIntervalSinceReferenceDate: 0)
} operation: {
let date = self.date()
let timeZone = TimeZone(abbreviation: "UTC")!
let dateInUTC = date.convertToTimeZone(timeZone)
XCTAssertEqual(dateInUTC.timeZone, timeZone)
}
}
}




