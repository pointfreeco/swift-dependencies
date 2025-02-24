#if canImport(Testing)
  import Dependencies
  import Foundation
  import Testing

  @Suite struct PrepareDependenciesTests {
    @Test(
      .serialized,
      .dependency(\.uuid, .incrementing),
      arguments: [1, 2, 3]
    )
    func uuid(value: Int) {
      @Dependency(\.uuid) var uuid
      if value == 1 {
        #expect(uuid() == UUID(0))
      } else {
        withKnownIssue {
          #expect(uuid() == UUID(0))
        }
      }
    }

    @Test func isolation1() {
      prepareDependencies {
        $0.date.now = Date(timeIntervalSince1970: 1)
      }
      @Dependency(\.date.now) var now
      #expect(now.timeIntervalSince1970 == 1)
    }

    @Test func isolation2() {
      prepareDependencies {
        $0.date.now = Date(timeIntervalSince1970: 2)
      }
      @Dependency(\.date.now) var now
      #expect(now.timeIntervalSince1970 == 2)
    }

    @Test func isolation3() {
      prepareDependencies {
        $0.date.now = Date(timeIntervalSince1970: 3)
      }
      @Dependency(\.date.now) var now
      #expect(now.timeIntervalSince1970 == 3)
    }

    @Test func isolation4() {
      prepareDependencies {
        $0.date.now = Date(timeIntervalSince1970: 4)
      }
      @Dependency(\.date.now) var now
      #expect(now.timeIntervalSince1970 == 4)
    }
  }
#endif
