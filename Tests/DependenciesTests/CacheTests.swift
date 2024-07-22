import Dependencies
import XCTest

final class CachedValueTests: XCTestCase {
  func testCacheWithReEntrantAccess() {
    @Dependency(OuterDependencyTests.self) var outerDependency
    _ = outerDependency
  }
}

struct OuterDependencyTests: TestDependencyKey {
  static var testValue: OuterDependencyTests {
    @Dependency(InnerDependency.self) var innerDependency
    innerDependency.perform()
    return Self()
  }
}
struct InnerDependency: TestDependencyKey {
  let perform: @Sendable () -> Void
  static var testValue: InnerDependency {
    final class Ref: Sendable {
      deinit {
        XCTFail("This should not deinit")
      }
    }
    let ref = Ref()
    return Self {
      _ = ref
    }
  }
}
