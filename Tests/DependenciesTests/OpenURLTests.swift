import Dependencies
import XCTest
import XCTestDynamicOverlay

final class OpenURLTests: XCTestCase {
  func testOpenUrl() async {
    let urlToOpenIsolated = ActorIsolated<URL?>(nil)

    let viewModel = withDependencies {
      $0.openURL = .init { url in
        await urlToOpenIsolated.setValue(url)
        return true
      }
    } operation: {
      ViewModel()
    }

    var urlToOpen = await urlToOpenIsolated.value
    XCTAssertNil(urlToOpen)

    await viewModel.openMailApp()
    urlToOpen = await urlToOpenIsolated.value
    XCTAssertEqual(urlToOpen, .mailApp)

    await viewModel.openSomeUrl()
    urlToOpen = await urlToOpenIsolated.value
    XCTAssertEqual(urlToOpen, URL(string: "https://example.com"))
  }
}

private final class ViewModel {
  @Dependency(\.openURL) var openURL

  func openMailApp() async {
    await openURL(.mailApp)
  }

  func openSomeUrl() async {
    await openURL(URL(string: "https://example.com")!)
  }
}

extension URL {
  fileprivate static var mailApp: Self {
    URL(string: "message://")!
  }
}
