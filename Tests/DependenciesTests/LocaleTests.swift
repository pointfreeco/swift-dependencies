import Dependencies
import Foundation
import XCTest

final class LocaleDependencyTests: XCTestCase {
  @Dependency(\.preferredLocales) var preferredLocales

  func testOverriding_PreferredLocales() {
    let locales = [Locale(identifier: "es-ES"), Locale(identifier: "en-US")]

    withDependencies {
      $0.preferredLocales = locales
    } operation: {
      XCTAssertEqual(self.preferredLocales, locales)
    }
  }
}
