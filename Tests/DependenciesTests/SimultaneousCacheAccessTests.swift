@_spi(Internals) import Dependencies
import XCTest

final class SimultaneousCacheAccessTests: XCTestCase {
  // Test dependency holds onto a mock Product. Resetting the cache causes the mock Product to be
  // released triggering the simultaneous access from Product's deinit.
  func testDeinitCacheAccess() {
    XCTExpectFailure {
      @Dependency(FactoryDependency.self) var factory
      _ = factory
      
      // Reset the cache to trigger Product deinit
      DependencyValues._current.cachedValues.resetCache()
    } issueMatcher: { issue in
      // Accessing a value during cache reset accesses both DependencyContextKey and the accessed
      // dependency. Just match on the end of the error message to cover both keys.
      issue.compactDescription.hasSuffix(
        "Accessing a dependency during a cache reset will always return a new and uncached instance of the dependency."
      )
    }
  }
  
  // The live dependency does not hold onto a Product, so there's no simultaneous access on reset.
  func testLiveDeinit() {
    withDependencies {
      $0.context = .live
    } operation: {
      @Dependency(FactoryDependency.self) var factory
      _ = factory
      
      // Reset the cache to validate that a Product deinit is not triggered
      DependencyValues._current.cachedValues.resetCache()
    }
  }
}

struct NestedDependency: TestDependencyKey {
  static let testValue = NestedDependency()
}

// Product accesses a dependency in its deinit method.
// This is fine as long as its deinit isn't called during cache reset
final class Product: Sendable {
  deinit {
    @Dependency(NestedDependency.self) var nested
    _ = nested
  }
}

// Factory dependency that vends Product instances
protocol Factory: Sendable {
  func makeProduct() -> Product
}

enum FactoryDependency: DependencyKey {
  static let liveValue: Factory = LiveFactory()
  static var testValue: Factory { MockFactory() }
}

// Live factory instantiates a new product for each call
struct LiveFactory: Factory {
  func makeProduct() -> Product { Product() }
}

// Mock factory holds onto a mock Product.
// This results in the mock Product being released during cache reset.
final class MockFactory: Factory {
  let mockProduct = LockIsolated(Product())
  
  func makeProduct() -> Product { mockProduct.value }
}
