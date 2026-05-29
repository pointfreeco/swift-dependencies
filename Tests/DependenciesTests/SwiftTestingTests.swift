#if canImport(Testing)
  import ConcurrencyExtras
  import Dependencies
  import DependenciesTestSupport
  import Foundation
  import Testing

  @Suite struct SwiftTestingTests {
    #if compiler(>=6.1)
      @Test(.dependencies, .serialized, arguments: 1...5)
      func parameterizedCachePollution(_ argument: Int) {
        @Dependency(Client.self) var client
        let value = client.increment()
        #expect(value == 1)
      }

      @Test(.dependencies) func repeatedTest() {
        @Dependency(Client.self) var client
        let value = client.increment()
        #expect(value == 1)
      }
    #else
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
    #endif

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
    
    @Test
    func cacheTargetedKeypathReset_liveContext() {
      withDependencies {
        $0.context = .live
      } operation: {
        @Dependency(Client.self) var client
        var value = client.increment()
        #expect(value == 1)
        value = client.increment()
        #expect(value == 2)
        DependencyValues.reset(\.client)
        value = client.increment()
        #expect(value == 1)
      }
    }
    
    @Test
    func cacheTargetedTypeReset_liveContext() {
      withDependencies {
        $0.context = .live
      } operation: {
        @Dependency(Client.self) var client
        var value = client.increment()
        #expect(value == 1)
        value = client.increment()
        #expect(value == 2)
        DependencyValues.reset(Client.self)
        value = client.increment()
        #expect(value == 1)
      }
    }

    @Test(.dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 0)))
    func trait() {
      @Dependency(\.date.now) var now
      #expect(now == Date(timeIntervalSinceReferenceDate: 0))
    }

    @Suite(.dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 0)))
    struct InnerSuite {
      @Test
      func traitInherited() {
        @Dependency(\.date.now) var now
        #expect(now == Date(timeIntervalSinceReferenceDate: 0))
      }

      @Test(.dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 1)))
      func traitOverridden() {
        @Dependency(\.date.now) var now
        #expect(now == Date(timeIntervalSinceReferenceDate: 1))
      }

      @Test(.dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 1)))
      func traitOverriddenWithDependencies() {
        withDependencies {
          $0.date.now = Date(timeIntervalSinceReferenceDate: 2)
        } operation: {
          @Dependency(\.date.now) var now
          #expect(now == Date(timeIntervalSinceReferenceDate: 2))
        }
      }
    }

    private static let mockClient = Client { 42 }
    @Test(.dependency(mockClient))
    func dependencyKeyTypeTrait() {
      @Dependency(Client.self) var client
      #expect(client.increment() == 42)
    }

    @Test(.dependency(\.classClient, ClassClient()))
    func dependencyKeyNonSendableValue() {
      // NB: This test is to prove this trait compiles with a non-sendable type.
    }
  }

  private struct Client: DependencyKey {
    var increment: @Sendable () -> Int
    static var liveValue: Client {
      getClient()
    }
    
    static var testValue: Client {
      getClient()
    }
    
    static func getClient() -> Client {
      let count = LockIsolated(0)
      return Self {
        count.withValue {
          $0 += 1
          return $0
        }
      }
    }
  }
  private extension DependencyValues {
    var client: Client {
      get { self[Client.self] }
      set { self[Client.self] = newValue }
    }
  }

  class ClassClient {
    var count = 0
  }
  extension DependencyValues {
    var classClient: ClassClient {
      get { self[ClassClientKey.self].wrappedValue }
      set { self[ClassClientKey.self] = UncheckedSendable(newValue) }
    }
  }
  enum ClassClientKey: TestDependencyKey {
    static var testValue: UncheckedSendable<ClassClient> {
      UncheckedSendable(ClassClient())
    }
  }
#endif
