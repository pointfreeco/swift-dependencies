// MARK: - Deprecated after 1.6.3

#if canImport(SwiftUI) && compiler(>=6)
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension PreviewTrait where T == Preview.ViewTraits {
    @available(
      *, deprecated,
      message: """
        Use 'withDependencies' or 'prepareDependencies' from the body of the preview, instead.
        """
    )
    @_documentation(visibility: private)
    public static func dependency<Value>(
      _ keyPath: WritableKeyPath<DependencyValues, Value> & Sendable,
      _ value: Value
    ) -> PreviewTrait {
      .dependencies { $0[keyPath: keyPath] = value }
    }

    @available(
      *, deprecated,
      message: """
        Use 'withDependencies' or 'prepareDependencies' from the body of the preview, instead.
        """
    )
    @_documentation(visibility: private)
    public static func dependency<Value: TestDependencyKey>(
      _ value: Value
    ) -> PreviewTrait where Value == Value.Value {
      .dependencies { $0[Value.self] = value }
    }

    @available(
      *, deprecated,
      message: """
        Use 'withDependencies' or 'prepareDependencies' from the body of the preview, instead.
        """
    )
    @_documentation(visibility: private)
    public static func dependencies(
      _ updateValuesForPreview: (inout DependencyValues) -> Void
    ) -> PreviewTrait {
      var copy = previewValues
      defer { previewValues = copy }
      updateValuesForPreview(&copy)
      return PreviewTrait()
    }
  }

  nonisolated(unsafe) var previewValues = DependencyValues(context: .preview)
#endif

// MARK: - Deprecated after 0.4.2

extension AsyncStream {
  @available(*, deprecated, renamed: "makeStream(of:bufferingPolicy:)")
  @_documentation(visibility: private)
  public static func streamWithContinuation(
    _ elementType: Element.Type = Element.self,
    bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
  ) -> (stream: Self, continuation: Continuation) {
    var continuation: Continuation!
    return (Self(elementType, bufferingPolicy: limit) { continuation = $0 }, continuation)
  }
}

extension AsyncThrowingStream where Failure == Error {
  @available(*, deprecated, renamed: "makeStream(of:throwing:bufferingPolicy:)")
  @_documentation(visibility: private)
  public static func streamWithContinuation(
    _ elementType: Element.Type = Element.self,
    bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
  ) -> (stream: Self, continuation: Continuation) {
    var continuation: Continuation!
    return (Self(elementType, bufferingPolicy: limit) { continuation = $0 }, continuation)
  }
}

// MARK: -

extension ActorIsolated {
  @available(
    *,
    deprecated,
    message: "Use the non-async version of 'withValue'."
  )
  @_documentation(visibility: private)
  public func withValue<T: Sendable>(
    _ operation: @Sendable (inout Value) async throws -> T
  ) async rethrows -> T where Value: Sendable {
    var value = self.value
    defer { self.value = value }
    return try await operation(&value)
  }
}

extension AsyncStream where Element: Sendable {
  @available(
    *,
    deprecated,
    message: "Do not configure streams with a buffering policy 'limit' parameter."
  )
  @_documentation(visibility: private)
  public init<S: AsyncSequence & Sendable>(
    _ sequence: S,
    bufferingPolicy limit: Continuation.BufferingPolicy
  ) where S.Element == Element, S.Element: Sendable {
    self.init(bufferingPolicy: limit) { (continuation: Continuation) in
      let task = Task {
        do {
          for try await element in sequence {
            continuation.yield(element)
          }
          continuation.finish()
        } catch {
          continuation.finish()
        }
      }
      continuation.onTermination =
        { _ in
          task.cancel()
        }
    }
  }
}

extension AsyncThrowingStream where Element: Sendable, Failure == Error {
  @available(
    *,
    deprecated,
    message: "Do not configure streams with a buffering policy 'limit' parameter."
  )
  @_documentation(visibility: private)
  public init<S: AsyncSequence & Sendable>(
    _ sequence: S,
    bufferingPolicy limit: Continuation.BufferingPolicy
  ) where S.Element == Element, S.Element: Sendable {
    self.init(bufferingPolicy: limit) { (continuation: Continuation) in
      let task = Task {
        do {
          for try await element in sequence {
            continuation.yield(element)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination =
        { _ in
          task.cancel()
        }
    }
  }
}

extension DependencyValues {
  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withValue<Value, R>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    _ value: @autoclosure () -> Value,
    operation: () throws -> R
  ) rethrows -> R {
    try withDependencies {
      $0[keyPath: keyPath] = value()
    } operation: {
      try operation()
    }
  }

  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withValue<Value, R: Sendable>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    _ value: @autoclosure () -> Value,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await withDependencies {
      $0[keyPath: keyPath] = value()
    } operation: {
      try await operation()
    }
  }

  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withValues<R>(
    _ updateValuesForOperation: (inout Self) throws -> Void,
    operation: () throws -> R
  ) rethrows -> R {
    try withDependencies(updateValuesForOperation, operation: operation)
  }

  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withValues<R: Sendable>(
    _ updateValuesForOperation: (inout Self) throws -> Void,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await withDependencies(updateValuesForOperation, operation: operation)
  }

  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withTestValues<R>(
    _ updateValuesForOperation: (inout Self) throws -> Void,
    assert operation: () throws -> R
  ) rethrows -> R {
    try withDependencies(updateValuesForOperation, operation: operation)
  }

  @available(*, deprecated, message: "Use 'withDependencies' instead.")
  public static func withTestValues<R: Sendable>(
    _ updateValuesForOperation: (inout Self) async throws -> Void,
    assert operation: () async throws -> R
  ) async rethrows -> R {
    try await withDependencies(updateValuesForOperation, operation: operation)
  }
}
