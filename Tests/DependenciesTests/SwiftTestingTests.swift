import ConcurrencyExtras

#if canImport(Testing)
  import Dependencies
  import DependenciesTestSupport
  import Foundation
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
    
    // NB: This is to prove that a new instance of the dependency is used for each test.
    struct NewClassInstanceSuite {
      @Suite(.serialized, .dependency(\.classClient, ClassClient()))
      struct DependencyValues {
        @Test
        func test1() {
          @Dependency(\.classClient) var client
          client.count += 1
          #expect(client.count == 1)
        }
        
        @Test
        func test2() {
          @Dependency(\.classClient) var client
          client.count += 1
          #expect(client.count == 1)
        }
      }
      
      @Suite(.serialized, .dependency(SendableClassClient()))
      struct DependencyKey {
        @Test
        func test1() {
          @Dependency(SendableClassClient.self) var client
          client.count.withValue { $0 += 1 }
          #expect(client.count.value == 1)
        }
        
        @Test
        func test2() {
          @Dependency(SendableClassClient.self) var client
          client.count.withValue { $0 += 1 }
          #expect(client.count.value == 1)
        }
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

  private final class SendableClassClient: TestDependencyKey, Sendable {
    static var testValue: SendableClassClient { .init() }
    let count = LockIsolated(0)
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
