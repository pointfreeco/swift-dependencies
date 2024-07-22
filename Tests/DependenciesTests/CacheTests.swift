@_spi(Internals) import Dependencies
import XCTest

final class CachedValueTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    CacheLocals.$skipFailure.withValue(true) {
      DependencyValues._current.cachedValues.cached = [:]
    }
  }

  func testCacheWithReEntrantAccess() {
    @Dependency(OuterDependencyTests.self) var outerDependency
    _ = outerDependency
  }
}

private struct OuterDependencyTests: TestDependencyKey {
  static var testValue: OuterDependencyTests {
    @Dependency(InnerDependency.self) var innerDependency
    _ = innerDependency
    return Self()
  }
}
private struct InnerDependency: TestDependencyKey {
  let perform: @Sendable () -> Void
  static var testValue: InnerDependency {
    final class Ref: Sendable {
      deinit {
        guard !CacheLocals.skipFailure
        else { return }
        XCTFail("This should not deinit")
      }
    }
    let ref = Ref()
    return Self {
      _ = ref
    }
  }
}

private enum CacheLocals {
  @TaskLocal static var skipFailure = false
}
