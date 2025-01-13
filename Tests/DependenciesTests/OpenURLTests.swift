import XCTest

@testable import Dependencies

class OpenURLTests: XCTestCase {
  @Dependency(\.openURL) var openURL
  
  /// Please note that running this test may cause side-effects, such as actually opening the
  /// given webpage on the Mac that is running the test.
  func testOpenURL_liveValue() async {
    await withDependencies {
      $0.openURL = OpenURLKey.liveValue
    } operation: {
      let url = URL(string: "https://www.pointfree.co/")!
      let result = await self.openURL(url)
        XCTAssert(result)
    }
  }
}
