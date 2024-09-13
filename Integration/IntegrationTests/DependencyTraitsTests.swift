#if canImport(Testing)
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@Suite
struct DependencyTraitTests {
  @Test(
    .dependency(\.date.now, Date(timeIntervalSince1970: 0))
  )
  func traitOverride() {
    @Dependency(\.date) var date
    #expect(date.now == Date(timeIntervalSince1970: 0))
  }
}
#endif
