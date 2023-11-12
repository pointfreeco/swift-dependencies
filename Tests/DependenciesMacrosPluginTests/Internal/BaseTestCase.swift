import MacroTesting
import XCTest

class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      //isRecording: true
    ) {
      super.invokeTest()
    }
  }
}
