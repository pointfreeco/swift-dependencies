import Foundation

/// Updates the current dependencies for the duration of a synchronous operation.
///
/// Any mutations made to ``DependencyValues`` inside `updateValuesForOperation` will be visible to
/// everything executed in the operation. For example, if you wanted to force the
/// ``DependencyValues/date`` dependency to be a particular date, you can do:
///
/// ```swift
/// withDependencies {
///   $0.date.now = Date(timeIntervalSince1970: 1234567890)
/// } operation: {
///   // References to date in here are pinned to 1234567890.
/// }
/// ```
///
/// - Parameters:
///   - updateValuesForOperation: A closure for updating the current dependency values for the
///     duration of the operation.
///   - operation: An operation to perform wherein dependencies have been overridden.
/// - Returns: The result returned from `operation`.
@discardableResult
public func withDependencies<R>(
  _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
  operation: () throws -> R
) rethrows -> R {
  try DependencyValues.$isSetting.withValue(true) {
    var dependencies = DependencyValues._current
    try updateValuesForOperation(&dependencies)
    return try DependencyValues.$_current.withValue(dependencies) {
      try DependencyValues.$isSetting.withValue(false) {
        let result = try operation()
        if R.self is AnyClass {
          dependencyObjects.store(result as AnyObject)
        }
        return result
      }
    }
  }
}

#if swift(>=5.7)
  /// Updates the current dependencies for the duration of an asynchronous operation.
  ///
  /// Any mutations made to ``DependencyValues`` inside `updateValuesForOperation` will be visible
  /// to everything executed in the operation. For example, if you wanted to force the
  /// ``DependencyValues/date`` dependency to be a particular date, you can do:
  ///
  /// ```swift
  /// await withDependencies {
  ///   $0.date.now = Date(timeIntervalSince1970: 1234567890)
  /// } operation: {
  ///   // References to date in here are pinned to 1234567890.
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - updateValuesForOperation: A closure for updating the current dependency values for the
  ///     duration of the operation.
  ///   - operation: An operation to perform wherein dependencies have been overridden.
  /// - Returns: The result returned from `operation`.
  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await DependencyValues.$isSetting.withValue(true) {
      var dependencies = DependencyValues._current
      try await updateValuesForOperation(&dependencies)
      return try await DependencyValues.$_current.withValue(dependencies) {
        try await DependencyValues.$isSetting.withValue(false) {
          let result = try await operation()
          if R.self is AnyClass {
            dependencyObjects.store(result as AnyObject)
          }
          return result
        }
      }
    }
  }
#else
  @discardableResult
  public func withDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await DependencyValues.$isSetting.withValue(true) {
      var dependencies = DependencyValues._current
      try await updateValuesForOperation(&dependencies)
      return try await DependencyValues.$_current.withValue(dependencies) {
        try await DependencyValues.$isSetting.withValue(false) {
          let result = try await operation()
          if R.self is AnyClass {
            dependencyObjects.store(result as AnyObject)
          }
          return result
        }
      }
    }
  }
#endif

/// Updates the current dependencies for the duration of a synchronous operation by taking the
/// dependencies tied to a given object.
///
/// - Parameters:
///   - model: An object with dependencies. The given model should have at least one `@Dependency`
///     property, or should have been initialized and returned from a `withDependencies` operation.
///   - updateValuesForOperation: A closure for updating the current dependency values for the
///     duration of the operation.
///   - operation: The operation to run with the updated dependencies.
/// - Returns: The result returned from `operation`.
@discardableResult
public func withDependencies<Model: AnyObject, R>(
  from model: Model,
  _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
  operation: () throws -> R,
  file: StaticString? = nil,
  line: UInt? = nil
) rethrows -> R {
  guard let values = dependencyObjects.values(from: model)
  else {
    runtimeWarn(
      """
      You are trying to propagate dependencies to a child model from a model with no dependencies. \
      To fix this, the given '\(Model.self)' must be returned from another 'withDependencies' \
      closure, or the class must hold at least one '@Dependency' property.
      """,
      file: file,
      line: line
    )
    return try operation()
  }
  return try withDependencies {
    $0 = values.merging(DependencyValues._current)
    try updateValuesForOperation(&$0)
  } operation: {
    let result = try operation()
    if R.self is AnyClass {
      dependencyObjects.store(result as AnyObject)
    }
    return result
  }
}

/// Updates the current dependencies for the duration of a synchronous operation by taking the
/// dependencies tied to a given object.
///
/// - Parameters:
///   - model: An object with dependencies. The given model should have at least one `@Dependency`
///     property, or should have been initialized and returned from a `withDependencies` operation.
///   - operation: The operation to run with the updated dependencies.
/// - Returns: The result returned from `operation`.
@discardableResult
public func withDependencies<Model: AnyObject, R>(
  from model: Model,
  operation: () throws -> R,
  file: StaticString? = nil,
  line: UInt? = nil
) rethrows -> R {
  try withDependencies(
    from: model,
    { _ in },
    operation: operation,
    file: file,
    line: line
  )
}

#if swift(>=5.7)
  /// Updates the current dependencies for the duration of an asynchronous operation by taking the
  /// dependencies tied to a given object.
  ///
  /// - Parameters:
  ///   - model: An object with dependencies. The given model should have at least one `@Dependency`
  ///     property, or should have been initialized and returned from a `withDependencies`
  ///       operation.
  ///   - updateValuesForOperation: A closure for updating the current dependency values for the
  ///     duration of the operation.
  ///   - operation: The operation to run with the updated dependencies.
  /// - Returns: The result returned from `operation`.
  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R,
    file: StaticString? = nil,
    line: UInt? = nil
  ) async rethrows -> R {
    guard let values = dependencyObjects.values(from: model)
    else {
      runtimeWarn(
        """
        You are trying to propagate dependencies to a child model from a model with no \
        dependencies. To fix this, the given '\(Model.self)' must be returned from another \
        'withDependencies' closure, or the class must hold at least one '@Dependency' property.
        """,
        file: file,
        line: line
      )
      return try await operation()
    }
    return try await withDependencies {
      $0 = values.merging(DependencyValues._current)
      try await updateValuesForOperation(&$0)
    } operation: {
      let result = try await operation()
      if R.self is AnyClass {
        dependencyObjects.store(result as AnyObject)
      }
      return result
    }
  }
#else
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R,
    file: StaticString? = nil,
    line: UInt? = nil
  ) async rethrows -> R {
    guard let values = dependencyObjects.values(from: model)
    else {
      runtimeWarn(
        """
        You are trying to propagate dependencies to a child model from a model with no \
        dependencies. To fix this, the given '\(Model.self)' must be returned from another \
        'withDependencies' closure, or the class must hold at least one '@Dependency' property.
        """,
        file: file,
        line: line
      )
      return try await operation()
    }
    return try await withDependencies {
      $0 = values.merging(DependencyValues._current)
      try await updateValuesForOperation(&$0)
    } operation: {
      let result = try await operation()
      if R.self is AnyClass {
        dependencyObjects.store(result as AnyObject)
      }
      return result
    }
  }
#endif

#if swift(>=5.7)
  /// Updates the current dependencies for the duration of an asynchronous operation by taking the
  /// dependencies tied to a given object.
  ///
  /// - Parameters:
  ///   - model: An object with dependencies. The given model should have at least one `@Dependency`
  ///     property, or should have been initialized and returned from a `withDependencies`
  ///     operation.
  ///   - operation: The operation to run with the updated dependencies.
  /// - Returns: The result returned from `operation`.
  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    operation: () async throws -> R,
    file: StaticString? = nil,
    line: UInt? = nil
  ) async rethrows -> R {
    try await withDependencies(
      from: model,
      { _ in },
      operation: operation,
      file: file,
      line: line
    )
  }
#else
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    operation: () async throws -> R,
    file: StaticString? = nil,
    line: UInt? = nil
  ) async rethrows -> R {
    try await withDependencies(
      from: model,
      { _ in },
      operation: operation,
      file: file,
      line: line
    )
  }
#endif

/// Propagates the current dependencies to an escaping context.
///
/// This helper takes a trailing closure that is provided an ``DependencyValues/Continuation``
/// value, which can be used to access dependencies in an escaped context. It is useful in
/// situations where you cannot leverage structured concurrency and must use escaping closures.
/// Dependencies do not automatically propagate across escaping boundaries like they do in
/// structured contexts and in `Task`s.
///
/// For example, suppose you want to use `DispatchQueue.main.asyncAfter` to execute some logic after
/// a delay, and that logic needs to make use of dependencies. In order to guarantee that
/// dependencies used in the escaping closure of `asyncAfter` reflect the correct values, you should
/// use `withEscapedDependencies`:
///
/// ```swift
/// withEscapedDependencies { dependencies in
///   DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
///     dependencies.yield {
///       // All code in here will use dependencies at the time of
///       // calling DependencyValues.escape.
///     }
///   }
/// }
/// ```
///
/// As a general rule, you should surround _all_ escaping code that may access dependencies with
/// this helper. Otherwise you run the risk of the escaped code using the wrong dependencies. But,
/// you should also try your hardest to keep your code in the structured world using Swift's tools
/// of structured concurrency, and should avoid using escaping closures.
///
/// - Parameter operation: A closure that takes a ``DependencyValues/Continuation`` value for
///   propagating dependencies past an escaping closure boundary.
public func withEscapedDependencies<R>(
  _ operation: (DependencyValues.Continuation) throws -> R
) rethrows -> R {
  try operation(DependencyValues.Continuation())
}

/// Propagates the current dependencies to an escaping context.
///
/// See the documentation of ``withEscapedDependencies(_:)-5xvi3`` for more information.
///
/// - Parameter operation: A closure that takes a ``DependencyValues/Continuation`` value for
///   propagating dependencies past an escaping closure boundary.
public func withEscapedDependencies<R>(
  _ operation: (DependencyValues.Continuation) async throws -> R
) async rethrows -> R {
  try await operation(DependencyValues.Continuation())
}

extension DependencyValues {
  /// A capture of dependencies to use in an escaping context.
  ///
  /// See the docs of ``withEscapedDependencies(_:)-5xvi3`` for more information.
  public struct Continuation: Sendable {
    @Dependency(\.self) private var dependencies

    /// Access the propagated dependencies in an escaping context.
    ///
    /// See the docs of ``withEscapedDependencies(_:)-5xvi3`` for more information.
    /// - Parameter operation: A closure which will have access to the propagated dependencies.
    public func yield<R>(_ operation: () throws -> R) rethrows -> R {
      try withDependencies {
        $0 = self.dependencies
      } operation: {
        try operation()
      }
    }

    /// Access the propagated dependencies in an escaping context.
    ///
    /// See the docs of ``withEscapedDependencies(_:)-5xvi3`` for more information.
    /// - Parameter operation: A closure which will have access to the propagated dependencies.
    public func yield<R>(_ operation: () async throws -> R) async rethrows -> R {
      try await withDependencies {
        $0 = self.dependencies
      } operation: {
        try await operation()
      }
    }
  }
}

private let dependencyObjects = DependencyObjects()

private class DependencyObjects: @unchecked Sendable {
  private var storage = LockIsolated<[ObjectIdentifier: DependencyObject]>([:])

  internal init() {}

  func store(_ object: AnyObject) {
    self.storage.withValue { storage in
      storage[ObjectIdentifier(object)] = DependencyObject(
        object: object,
        dependencyValues: DependencyValues._current
      )
      Task {
        self.storage.withValue { storage in
          for (id, box) in storage where box.object == nil {
            storage.removeValue(forKey: id)
          }
        }
      }
    }
  }

  func values(from object: AnyObject) -> DependencyValues? {
    Mirror(reflecting: object).children
      .lazy
      .compactMap({ $1 as? _HasInitialValues })
      .first?
      .initialValues
      ?? self.storage.withValue({ $0[ObjectIdentifier(object)]?.dependencyValues })
  }
}

private struct DependencyObject {
  weak var object: AnyObject?
  let dependencyValues: DependencyValues
}
