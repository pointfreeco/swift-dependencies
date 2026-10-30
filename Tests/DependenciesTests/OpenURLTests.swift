#if os(macOS)
  @testable import Dependencies
  import Foundation
  import XCTest

  final class OpenURLTests: XCTestCase {
    @MainActor
    func testLiveOpenURLUsesWorkspace() async {
      let url = URL(string: "https://example.com")!
      var openedURL: URL?
      let openURL = OpenURLPlatform.liveValue {
        openedURL = $0
        return true
      }
      let didOpen = await openURL(url)

      XCTAssertTrue(didOpen)
      XCTAssertEqual(openedURL, url)
    }

    @MainActor
    func testLiveOpenURLReturnsWorkspaceFailure() async {
      let openURL = OpenURLPlatform.liveValue { _ in false }
      let didOpen = await openURL(URL(string: "https://example.com")!)

      XCTAssertFalse(didOpen)
    }
  }
#endif
