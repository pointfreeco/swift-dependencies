#if canImport(Combine)
  import Foundation

  extension DependencyValues {
    /// The "main" run loop.
    ///
    /// Introduce controllable timing to your features by using the ``Dependency`` property wrapper
    /// with a key path to this property. The wrapped value is a Combine scheduler with the time
    /// type and options of a run loop. By default, `RunLoop.main` will be provided, with the
    /// exception of XCTest cases, in which an "unimplemented" scheduler will be provided.
    ///
    /// For example, you could introduce controllable timing to an observable object model that
    /// counts the number of seconds it's onscreen:
    ///
    /// ```
    /// struct TimerModel: ObservableObject {
    ///   @Published var elapsed = 0
    ///
    ///   @Dependency(\.mainRunLoop) var mainRunLoop
    ///
    ///   @MainActor
    ///   func onAppear() async {
    ///     for await _ in self.mainRunLoop.timer(interval: .seconds(1)) {
    ///       self.elapsed += 1
    ///     }
    ///   }
    /// }
    /// ```
    ///
    /// And you could test this model by overriding its main run loop with a test scheduler:
    ///
    /// ```
    /// func testFeature() {
    ///   let mainRunLoop = RunLoop.test
    ///   let model = withDependencies {
    ///     $0.mainRunLoop = mainRunLoop
    ///   } operation: {
    ///     TimerModel()
    ///   }
    ///
    ///   Task { await model.onAppear() }
    ///
    ///   mainRunLoop.advance(by: .seconds(1))
    ///   XCTAssertEqual(model.elapsed, 1)
    ///
    ///   mainRunLoop.advance(by: .seconds(4))
    ///   XCTAssertEqual(model.elapsed, 5)
    /// }
    /// ```
    public var mainRunLoop: AnySchedulerOf<RunLoop> {
      get { self[MainRunLoopKey.self] }
      set { self[MainRunLoopKey.self] = newValue }
    }

    private enum MainRunLoopKey: DependencyKey {
      static let liveValue = AnySchedulerOf<RunLoop>.main
      static let testValue = AnySchedulerOf<RunLoop>.unimplemented(#"@Dependency(\.mainRunLoop)"#)
    }
  }
#endif
