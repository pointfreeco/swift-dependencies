import XCTest

final class IntegrationUITests: XCTestCase {
  let app = XCUIApplication()

  override func setUpWithError() throws {
    self.continueAfterFailure = false
  }

  func testOverrideContext_Live() {
    self.app.launchEnvironment["SWIFT_DEPENDENCIES_CONTEXT"] = "live"
    self.app.launch()
    XCTAssertEqual(self.app.staticTexts["Live"].exists, true)
  }

  func testOverrideContext_Preview() {
    self.app.launchEnvironment["SWIFT_DEPENDENCIES_CONTEXT"] = "preview"
    self.app.launch()
    XCTAssertEqual(self.app.staticTexts["Preview"].exists, true)
  }

  func testOverrideContext_Test() {
    self.app.launchEnvironment["SWIFT_DEPENDENCIES_CONTEXT"] = "test"
    self.app.launch()
    XCTAssertEqual(self.app.staticTexts["Test"].exists, true)
  }
}
