#if canImport(Testing)
  import Dependencies
  import Testing

  struct SwiftTestingTests {
    @Test(.serialized, arguments: 1...5)
    func parameterizedCachePollution(_ argument: Int) {
      @Dependency(Client.self) var client
      let value = client.increment()
      if argument == 1 {
        #expect(value == 1)
      } else {
        withKnownIssue {
          #expect(value == 1)
        }
      }
    }

    @Test(arguments: 1...5)
    func parameterizedCachePollution_ResetDependencies(_ argument: Int) {
      withDependencies {
        $0 = DependencyValues()
      } operation: {
        @Dependency(Client.self) var client
        let value = client.increment()
        #expect(value == 1)
      }
    }

    @Test
    func cachePollution1() {
      @Dependency(Client.self) var client
      let value = client.increment()
      #expect(value == 1)
    }

    @Test
    func cachePollution2() {
      @Dependency(Client.self) var client
      let value = client.increment()
      // NB: Wasm has different behavior here.
      #if os(WASI)
        #expect(value == 2)
      #else
        #expect(value == 1)
      #endif
    }
  }

private struct Client: TestDependencyKey {
  var increment: @Sendable () -> Int
  static var testValue: Client {
    let count = LockIsolated(0)
    return Self {
      count.withValue { $0 += 1; return $0 }
    }
  }
}
#endif
