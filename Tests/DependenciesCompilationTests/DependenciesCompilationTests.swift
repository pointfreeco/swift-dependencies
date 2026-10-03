import Testing
import CompilationTesting

extension BaseSuite {
  @Suite struct DependenciesCompilationTests {
    @Test func `@DependencyEntry diagnoses main actor isolation`() async {
      await assertCompilation(
        flags: [.defaultIsolation(MainActor.self)]
      ) {
        """
        @DependencyClient struct Client {
          var fetch: @Sendable () async throws -> Int
        }
        extension DependencyValues {
          @DependencyEntry var client = Client()
        }
        """
      } diagnostics: {
        """
        import Dependencies
        import DependenciesMacros

        ˄
        ╰─ error: call to main actor-isolated initializer 'init()' in a synchronous nonisolated context [#ActorIsolatedCall]
        @DependencyClient struct Client {
            ˄
            ╰─ error: client must be 'nonisolated struct' when default isolation is '@MainActor' (from macro 'IsolationCheck')
          var fetch: @Sendable () async throws -> Int
        }
        extension DependencyValues {
          @DependencyEntry var client = Client()
                                                ˄
                                                ╰─ error: main actor-isolated default value in a nonisolated context
              ˄
              ╰─ error: entry must be 'nonisolated var' when default isolation is '@MainActor' (from macro 'IsolationCheck')
        }
        """
      }
    }
  }
}
