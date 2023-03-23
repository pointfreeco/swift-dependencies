import Dependencies
import XCTest
import XCTestDynamicOverlay

final class UUIDDependencyTests: XCTestCase {
  @Dependency(\.uuid) var uuid

  func testIncrementing() {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      XCTAssertEqual(self.uuid(), UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
      XCTAssertEqual(self.uuid(), UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    }
  }

  func testInitIntValue() {
    XCTAssertEqual(UUID(0), UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    XCTAssertEqual(UUID(1), UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    XCTAssertEqual(UUID(15), UUID(uuidString: "00000000-0000-0000-0000-00000000000F"))
    XCTAssertEqual(UUID(256), UUID(uuidString: "00000000-0000-0000-0000-000000000100"))
  }
}
