#if canImport(Combine)
  import Foundation

  extension DependencyValues {
    /// The "main" queue.
    ///
    /// Introduce controllable timing to your features by using the ``Dependency`` property wrapper
    /// with a key path to this property. The wrapped value is a Combine scheduler with the time
    /// type and options of a dispatch queue. By default, a variant of `DispatchQueue.main` that
    /// forwards dependencies will be provided, with the exception of XCTest cases, in which an
    /// "unimplemented" scheduler will be provided.
    ///
    /// For example, you could introduce controllable timing to an observable object model that
    /// counts the number of seconds it's onscreen:
    ///
    /// ```
    /// final class TimerModel: ObservableObject {
    ///   @Published var elapsed = 0
    ///
    ///   @Dependency(\.mainQueue) var mainQueue
    ///
    ///   @MainActor
    ///   func onAppear() async {
    ///     for await _ in self.mainQueue.timer(interval: .seconds(1)) {
    ///       self.elapsed += 1
    ///     }
    ///   }
    /// }
    /// ```
    ///
    /// And you could test this model by overriding its main queue with a test scheduler:
    ///
    /// ```
    /// func testFeature() {
    ///   let mainQueue = DispatchQueue.test
    ///   let model = withDependencies {
    ///     $0.mainQueue = mainQueue.eraseToAnyScheduler()
    ///   } operation: {
    ///     TimerModel()
    ///   }
    ///
    ///   Task { await model.onAppear() }
    ///
    ///   mainQueue.advance(by: .seconds(1))
    ///   XCTAssertEqual(model.elapsed, 1)
    ///
    ///   mainQueue.advance(by: .seconds(4))
    ///   XCTAssertEqual(model.elapsed, 5)
    /// }
    /// ```
    public var mainQueue: AnySchedulerOf<DispatchQueue> {
      get { self[MainQueueKey.self] }
      set { self[MainQueueKey.self] = newValue }
    }

    private enum MainQueueKey: DependencyKey {
      static let liveValue = DispatchQueue.main.dependencies()
      static let testValue = AnySchedulerOf<DispatchQueue>
        .unimplemented(#"@Dependency(\.mainQueue)"#)
    }
  }
#endif
