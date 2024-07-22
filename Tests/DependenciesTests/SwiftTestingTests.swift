#if canImport(Testing)
import Dependencies
import Testing

struct SwiftTestingTests {
  @Test
  func cachePollution1() async {
    await withDependencies {
      $0 = DependencyValues()
    } operation: {
      @Dependency(\.cachedDependency) var cachedDependency: CachedDependency
      let value = await cachedDependency.increment()
      #expect(value == 1)
    }
  }

  @Test
  func cachePollution2() async {
    await withDependencies {
      $0 = DependencyValues()
    } operation: {
      @Dependency(\.cachedDependency) var cachedDependency: CachedDependency
      let value = await cachedDependency.increment()
      // NB: Wasm has different behavior here.
#if os(WASI)
      #expect(value == 2)
#else
      #expect(value == 1)
#endif
    }
  }
}
#endif
