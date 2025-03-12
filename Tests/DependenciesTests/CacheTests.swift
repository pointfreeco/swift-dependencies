@_spi(Internals) import Dependencies
import XCTest

final class CachedValueTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    CacheLocals.$skipFailure.withValue(true) {
      DependencyValues._current.cachedValues.resetCache()
    }
  }

  func testCacheWithReEntrantAccess() {
    @Dependency(OuterDependencyTests.self) var outerDependency
    _ = outerDependency
  }
  
  func testDeinitCacheAccess() {
    struct NestedDependency: TestDependencyKey {
      static let testValue = NestedDependency()
    }
    
    final class RefDependency: TestDependencyKey, Sendable {
      deinit {
        @Dependency(NestedDependency.self) var nested
        _ = nested
      }
      
      static var testValue: RefDependency { RefDependency() }
    }

    XCTExpectFailure {
      @Dependency(RefDependency.self) var refDependency
      _ = refDependency
      
      // Reset the cache to trigger RefDependency deinit
      DependencyValues._current.cachedValues.resetCache()
    } issueMatcher: { issue in
      // Accessing a value during cache reset accesses both DependencyContextKey and the accessed
      // dependency. Just match on the end of the error message to cover both keys.
      issue.compactDescription.hasSuffix(
        "Accessing a dependency during a cache reset will always return a new and uncached instance of the dependency."
      )
    }
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
