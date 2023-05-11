extension AsyncStream {
  /// Produces an `AsyncStream` from an `AsyncSequence` by consuming the sequence till it
  /// terminates, ignoring any failure.
  ///
  /// Useful as a kind of type eraser for live `AsyncSequence`-based dependencies.
  ///
  /// For example, your feature may want to subscribe to screenshot notifications. You can model
  /// this as a dependency client that returns an `AsyncStream`:
  ///
  /// ```swift
  /// struct ScreenshotsClient {
  ///   var screenshots: () -> AsyncStream<Void>
  ///   func callAsFunction() -> AsyncStream<Void> { self.screenshots() }
  /// }
  /// ```
  ///
  /// The "live" implementation of the dependency can supply a stream by erasing the appropriate
  /// `NotificationCenter.Notifications` async sequence:
  ///
  /// ```swift
  /// extension ScreenshotsClient {
  ///   static let live = Self(
  ///     screenshots: {
  ///       AsyncStream(
  ///         NotificationCenter.default
  ///           .notifications(named: UIApplication.userDidTakeScreenshotNotification)
  ///           .map { _ in }
  ///       )
  ///     }
  ///   )
  /// }
  /// ```
  ///
  /// While your tests can use `AsyncStream.makeStream` to spin up a controllable stream for tests:
  ///
  /// ```swift
  /// func testScreenshots() {
  ///   let screenshots = AsyncStream.makeStream(of: Void.self)
  ///
  ///   let model = withDependencies {
  ///     $0.screenshots = { screenshots.stream }
  ///   } operation: {
  ///     FeatureModel()
  ///   }
  ///
  ///   XCTAssertEqual(model.screenshotCount, 0)
  ///   screenshots.continuation.yield()  // Simulate a screenshot being taken.
  ///   XCTAssertEqual(model.screenshotCount, 1)
  /// }
  /// ```
  ///
  /// - Parameter sequence: An async sequence.
  public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
    var iterator: S.AsyncIterator?
    self.init {
      if iterator == nil {
        iterator = sequence.makeAsyncIterator()
      }
      return try? await iterator?.next()
    }
  }

  #if swift(<5.9)
    /// Constructs and returns a stream along with its backing continuation.
    ///
    /// A back-port of [SE-0388: Convenience Async[Throwing]Stream.makeStream methods][se-0388].
    ///
    /// This is handy for immediately escaping the continuation from an async stream, which
    /// typically requires multiple steps:
    ///
    /// ```swift
    /// var _continuation: AsyncStream<Int>.Continuation!
    /// let stream = AsyncStream<Int> { continuation = $0 }
    /// let continuation = _continuation!
    ///
    /// // vs.
    ///
    /// let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
    /// ```
    ///
    /// This tool is usually used for tests where we need to supply an async sequence to a
    /// dependency endpoint and get access to its continuation so that we can emulate the dependency
    /// emitting data. For example, suppose you have a dependency exposing an async sequence for
    /// listening to notifications. To test this you can use `makeStream`:
    ///
    /// ```swift
    /// func testScreenshots() {
    ///   let screenshots = AsyncStream.makeStream(of: Void.self)
    ///
    ///   let model = withDependencies {
    ///     $0.screenshots = { screenshots.stream }
    ///   } operation: {
    ///     FeatureModel()
    ///   }
    ///
    ///   XCTAssertEqual(model.screenshotCount, 0)
    ///   screenshots.continuation.yield()  // Simulate a screenshot being taken.
    ///   XCTAssertEqual(model.screenshotCount, 1)
    /// }
    /// ```
    ///
    /// > Warning: ⚠️ `AsyncStream` does not support multiple subscribers, therefore you can only
    /// > use this helper to test features that do not subscribe multiple times to the dependency
    /// > endpoint.
    ///
    /// [se-0388]: https://github.com/apple/swift-evolution/blob/main/proposals/0388-async-stream-factory.md
    ///
    /// - Parameters:
    ///   - elementType: The type of element the `AsyncStream` produces.
    ///   - limit: A Continuation.BufferingPolicy value to set the stream’s buffering behavior. By
    ///     default, the stream buffers an unlimited number of elements. You can also set the policy
    ///     to buffer a specified number of oldest or newest elements.
    /// - Returns: An `AsyncStream`.
    public static func makeStream(
      of elementType: Element.Type = Element.self,
      bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: Self, continuation: Continuation) {
      var continuation: Continuation!
      return (Self(elementType, bufferingPolicy: limit) { continuation = $0 }, continuation)
    }
  #endif

  /// An `AsyncStream` that never emits and never completes unless cancelled.
  public static var never: Self {
    Self { _ in }
  }

  /// An `AsyncStream` that never emits and completes immediately.
  public static var finished: Self {
    Self { $0.finish() }
  }
}

extension AsyncSequence {
  /// Erases this async sequence to an async stream that produces elements till this sequence
  /// terminates (or fails).
  public func eraseToStream() -> AsyncStream<Element> {
    AsyncStream(self)
  }
}
