#if compiler(>=6.1) && canImport(Testing)
  import Dependencies
  import Foundation
  import Testing

  @Suite struct RootResettingTests {
    @Suite
    struct ResetsAtRootTests {
      @Test(.dependencies, arguments: [1, 2, 3])
      func freshDependencies(argument: Int) {
        @Dependency(Client.self) var client
        #expect(client.increment() == 1)
      }
    }

    @Suite(.dependency(\.date.now, Date(timeIntervalSince1970: 123)))
    struct ResetsOnlyAtRootTests {
      @Test(.dependencies) func date() {
        @Dependency(\.date.now) var now
        #expect(now == Date(timeIntervalSince1970: 123))
      }
    }
  }

  private struct Client: TestDependencyKey {
    var increment: @Sendable () -> Int
    static var testValue: Client {
      let count = LockIsolated(0)
      return Self {
        count.withValue {
          $0 += 1
          return $0
        }
      }
    }
  }
#endif
