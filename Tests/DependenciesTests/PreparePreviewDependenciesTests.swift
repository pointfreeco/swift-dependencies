#if canImport(SwiftUI) && canImport(Testing)
  import Dependencies
  import Testing

  @Suite struct PreparePreviewDependenciesTests {
    @Test func outsideOfPreviewContextReportsIssue() {
      withKnownIssue {
        _ = preparePreviewDependencies { $0.previewCounter = 1 }
      }
      @Dependency(\.previewCounter) var previewCounter
      #expect(previewCounter == 0)
    }

    @Test func previewContextPreparesDependency() {
      withDependencies {
        $0.context = .preview
      } operation: {
        _ = preparePreviewDependencies { $0.previewCounter = 42 }
        @Dependency(\.previewCounter) var previewCounter
        #expect(previewCounter == 42)
      }
    }

    @Test func thrownErrorIsSurfacedInsteadOfTrapping() {
      withDependencies {
        $0.context = .preview
      } operation: {
        _ = preparePreviewDependencies { _ in throw PreviewFailure() }
      }
    }
  }

  private struct PreviewFailure: Error {}

  extension DependencyValues {
    fileprivate var previewCounter: Int {
      get { self[PreviewCounterKey.self] }
      set { self[PreviewCounterKey.self] = newValue }
    }
  }

  private enum PreviewCounterKey: DependencyKey {
    static let liveValue = 0
    static let previewValue = 0
    static let testValue = 0
  }
#endif
