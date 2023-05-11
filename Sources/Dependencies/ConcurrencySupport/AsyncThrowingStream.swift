extension AsyncThrowingStream where Failure == Error {
  /// Produces an `AsyncThrowingStream` from an `AsyncSequence` by consuming the sequence till it
  /// terminates, rethrowing any failure.
  ///
  /// - Parameter sequence: An async sequence.
  public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
    var iterator: S.AsyncIterator?
    self.init {
      if iterator == nil {
        iterator = sequence.makeAsyncIterator()
      }
      return try await iterator?.next()
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
    /// var _continuation: AsyncThrowingStream<Int, Error>.Continuation!
    /// let stream = AsyncThrowingStream<Int, Error> { continuation = $0 }
    /// let continuation = _continuation!
    ///
    /// // vs.
    ///
    /// let (stream, continuation) = AsyncThrowingStream.makeStream(of: Int.self)
    /// ```
    ///
    /// This tool is usually used for tests where we need to supply an async sequence to a
    /// dependency endpoint and get access to its continuation so that we can emulate the dependency
    /// emitting data. For example, suppose you have a dependency exposing an async sequence for
    /// listening to notifications. To test this you can use `makeStream`:
    ///
    /// ```swift
    /// func testScreenshots() {
    ///   let screenshots = AsyncThrowingStream.makeStream(of: Void.self)
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
    /// > Warning: ⚠️ `AsyncThrowingStream` does not support multiple subscribers, therefore you can
    /// > only use this helper to test features that do not subscribe multiple times to the
    /// > dependency endpoint.
    ///
    /// [se-0388]: https://github.com/apple/swift-evolution/blob/main/proposals/0388-async-stream-factory.md
    ///
    /// - Parameters:
    ///   - elementType: The type of element the `AsyncThrowingStream` produces.
    ///   - failureType: The type of failure the `AsyncThrowingStream` throws.
    ///   - limit: A Continuation.BufferingPolicy value to set the stream’s buffering behavior. By
    ///     default, the stream buffers an unlimited number of elements. You can also set the policy
    ///     to buffer a specified number of oldest or newest elements.
    /// - Returns: An `AsyncThrowingStream`.
    public static func makeStream(
      of elementType: Element.Type = Element.self,
      throwing failureType: Failure.Type = Failure.self,
      bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: Self, continuation: Continuation) {
      var continuation: Continuation!
      return (Self(elementType, bufferingPolicy: limit) { continuation = $0 }, continuation)
    }
  #endif

  /// An `AsyncThrowingStream` that never emits and never completes unless cancelled.
  public static var never: Self {
    Self { _ in }
  }

  /// An `AsyncThrowingStream` that completes immediately.
  ///
  /// - Parameter error: An optional error the stream completes with.
  public static func finished(throwing error: Failure? = nil) -> Self {
    Self { $0.finish(throwing: error) }
  }
}

extension AsyncSequence {
  /// Erases this async sequence to an async throwing stream that produces elements till this
  /// sequence terminates, rethrowing any error on failure.
  public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
    AsyncThrowingStream(self)
  }
}
