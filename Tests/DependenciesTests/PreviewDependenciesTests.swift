#if canImport(SwiftUI) && canImport(Testing)
  import Dependencies
  import Testing

  // Serialized because preparing dependencies for a preview clears the process-wide cache of
  // preview values and records the call site that prepared them, both of which these tests share.
  @Suite(.serialized) struct PreviewDependenciesTests {
    @Test func outsideOfPreviewContextReportsIssue() {
      withKnownIssue {
        _ = previewDependencies { $0.previewCounter = 1 }
      }
      @Dependency(\.previewCounter) var previewCounter
      #expect(previewCounter == 0)
    }

    @Test func previewContextPreparesDependency() {
      withDependencies {
        $0.context = .preview
      } operation: {
        _ = previewDependencies { $0.previewCounter = 42 }
        @Dependency(\.previewCounter) var previewCounter
        #expect(previewCounter == 42)
      }
    }

    @Test func thrownErrorIsSurfacedInsteadOfTrapping() {
      withDependencies {
        $0.context = .preview
      } operation: {
        _ = previewDependencies { _ in throw PreviewFailure() }
      }
    }

    @Test func preparationDoesNotLeakAcrossPreviews() {
      withDependencies {
        $0.context = .preview
      } operation: {
        // Stands in for the first preview rendered in the process.
        _ = previewDependencies { $0.previewCounter = 1 }
        do {
          @Dependency(\.previewCounter) var previewCounter
          #expect(previewCounter == 1)
        }

        // Stands in for a second preview rendered in the same process.
        _ = previewDependencies { $0.previewCounter = 2 }
        do {
          @Dependency(\.previewCounter) var previewCounter
          #expect(previewCounter == 2)
        }
      }
    }

    @Test func dependencyLeftUnpreparedFallsBackToPreviewValue() {
      withDependencies {
        $0.context = .preview
      } operation: {
        // The first preview prepares one dependency and accesses another it did not prepare.
        _ = previewDependencies { $0.previewCounter = 1 }
        do {
          @Dependency(\.previewCounter) var previewCounter
          @Dependency(\.previewStamp) var previewStamp
          #expect(previewCounter == 1)
          #expect(previewStamp == 0)
        }

        // The second preview prepares only the dependency the first one accessed.
        _ = previewDependencies { $0.previewStamp = 99 }
        do {
          @Dependency(\.previewCounter) var previewCounter
          @Dependency(\.previewStamp) var previewStamp
          #expect(previewCounter == 0)
          #expect(previewStamp == 99)
        }
      }
    }

    @Test func reEvaluatingTheSamePreviewDoesNotPrepareAgain() {
      withDependencies {
        $0.context = .preview
      } operation: {
        var preparations = 0
        // A single call site, evaluated repeatedly, stands in for a preview whose body SwiftUI
        // recomputes as its '@Previewable' state changes.
        for value in 1...3 {
          _ = previewDependencies {
            preparations += 1
            $0.previewCounter = value
          }
        }
        @Dependency(\.previewCounter) var previewCounter
        #expect(preparations == 1)
        #expect(previewCounter == 1)
      }
    }

    @Test func thrownErrorIsSurfacedOnEveryReEvaluation() {
      withDependencies {
        $0.context = .preview
      } operation: {
        var attempts = 0
        for _ in 1...3 {
          _ = previewDependencies { _ in
            attempts += 1
            throw PreviewFailure()
          }
        }
        #expect(attempts == 3)
      }
    }

    @Test func valuesCachedOutsideOfPreviewsSurvivePreparation() {
      // Resolves and caches a value for the test context.
      @Dependency(\.previewToken) var previewToken
      let token = previewToken

      withDependencies {
        $0.context = .preview
      } operation: {
        _ = previewDependencies { $0.previewCounter = 1 }
      }

      // Preparing a preview only clears preview values, so the test value is still cached.
      #expect(previewToken === token)
    }
  }

  private struct PreviewFailure: Error {}

  extension DependencyValues {
    fileprivate var previewCounter: Int {
      get { self[PreviewCounterKey.self] }
      set { self[PreviewCounterKey.self] = newValue }
    }

    fileprivate var previewStamp: Int {
      get { self[PreviewStampKey.self] }
      set { self[PreviewStampKey.self] = newValue }
    }

    fileprivate var previewToken: PreviewToken {
      get { self[PreviewTokenKey.self] }
      set { self[PreviewTokenKey.self] = newValue }
    }
  }

  /// A dependency resolved to a fresh instance every time it is not served from the cache, so that
  /// identity reveals whether it was cleared.
  private final class PreviewToken: Sendable {}

  private enum PreviewTokenKey: TestDependencyKey {
    static var testValue: PreviewToken { PreviewToken() }
  }

  private enum PreviewCounterKey: DependencyKey {
    static let liveValue = 0
    static let previewValue = 0
    static let testValue = 0
  }

  private enum PreviewStampKey: DependencyKey {
    static let liveValue = 0
    static let previewValue = 0
    static let testValue = 0
  }
#endif
