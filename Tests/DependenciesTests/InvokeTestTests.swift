import Dependencies
import XCTest

@MainActor
final class InvokeTestTests: XCTestCase {
  override func invokeTest() {
    withDependencies {
      $0.date = .constant(Date(timeIntervalSince1970: 1))
    } operation: {
      super.invokeTest()
    }
  }

  func testOverride() {
    class Model {
      @Dependency(\.date.now) var now
      func getDate() -> Date { self.now }
    }

    let model = withDependencies {
      $0.date = .constant(Date(timeIntervalSince1970: 2))
    } operation: {
      Model()
    }

    #if !os(Linux) && !os(WASI) && !os(Windows)
      XCTExpectFailure {
        XCTAssertEqual(model.getDate().timeIntervalSince1970, 2)
      }
    #else
      XCTAssertEqual(model.getDate().timeIntervalSince1970, 1)
    #endif
  }
}
