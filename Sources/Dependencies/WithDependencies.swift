import Foundation

/// Prepares global dependencies for the lifetime of your application.
///
/// > Important: A dependency key can be prepared at most a single time, and _must_ be prepared
/// > before it has been accessed. Call `prepareDependencies` as early as possible in your
/// > application, for example in your SwiftUI entry point:
/// >
/// > ```swift
/// > @main
/// > struct MyApp: App {
/// >   init() {
/// >     prepareDependencies {
/// >       $0.defaultDatabase = try! DatabaseQueue(/* ... */)
/// >     }
/// >   }
/// >
/// >   // ...
/// > }
/// > ```
/// >
/// > Or your app delegate:
/// >
/// > ```swift
/// > @main
/// > class AppDelegate: UIResponder, UIApplicationDelegate {
/// >   func application(
/// >     _ application: UIApplication,
/// >     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
/// >   ) -> Bool {
/// >     prepareDependencies {
/// >       $0.defaultDatabase = try! DatabaseQueue(/* ... */)
/// >     }
/// >     // Override point for customization after application launch.
/// >     return true
/// >   }
/// >
/// >   // ...
/// > }
/// > ```
///
/// - Parameter updateValues: A closure for updating the current dependency values for the
///   lifetime of your application.
public func prepareDependencies<R>(
  _ updateValues: (inout DependencyValues) throws -> R
) rethrows -> R {
  var dependencies = DependencyValues._current
  return try DependencyValues.$preparationID.withValue(UUID()) {
    try updateValues(&dependencies)
  }
}

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
  try isSetting(true) {
    var dependencies = DependencyValues._current
    try updateValuesForOperation(&dependencies)
    return try DependencyValues.$_current.withValue(dependencies) {
      try isSetting(false) {
        let result = try operation()
        if R.self is AnyClass {
          dependencyObjects.store(result as AnyObject)
        }
        return result
      }
    }
  }
}

#if swift(>=6)
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
  ///   - isolation: The isolation associated with the operation.
  ///   - updateValuesForOperation: A closure for updating the current dependency values for the
  ///     duration of the operation.
  ///   - operation: An operation to perform wherein dependencies have been overridden.
  /// - Returns: The result returned from `operation`.
  @discardableResult
  public func withDependencies<R>(
    isolation: isolated (any Actor)? = #isolation,
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R
  ) async rethrows -> R {
    #if DEBUG
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
    #else
      var dependencies = DependencyValues._current
      try await updateValuesForOperation(&dependencies)
      return try await DependencyValues.$_current.withValue(dependencies) {
        let result = try await operation()
        if R.self is AnyClass {
          dependencyObjects.store(result as AnyObject)
        }
        return result
      }
    #endif
  }
#else
  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await isSetting(true) {
      var dependencies = DependencyValues._current
      try await updateValuesForOperation(&dependencies)
      return try await DependencyValues.$_current.withValue(dependencies) {
        try await isSetting(false) {
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
///   - fileID: The source `#fileID` associated with the operation.
///   - filePath: The source `#filePath` associated with the operation.
///   - line: The source `#line` associated with the operation.
///   - column: The source `#column` associated with the operation.
/// - Returns: The result returned from `operation`.
@discardableResult
public func withDependencies<Model: AnyObject, R>(
  from model: Model,
  _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
  operation: () throws -> R,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) rethrows -> R {
  guard let values = dependencyObjects.values(from: model)
  else {
    reportIssue(
      """
      You are trying to propagate dependencies to a child model from a model with no dependencies. \
      To fix this, the given '\(Model.self)' must be returned from another 'withDependencies' \
      closure, or the class must hold at least one '@Dependency' property.
      """,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
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
///   - fileID: The source `#fileID` associated with the operation.
///   - filePath: The source `#filePath` associated with the operation.
///   - line: The source `#line` associated with the operation.
///   - column: The source `#column` associated with the operation.
/// - Returns: The result returned from `operation`.
@discardableResult
public func withDependencies<Model: AnyObject, R>(
  from model: Model,
  operation: () throws -> R,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) rethrows -> R {
  try withDependencies(
    from: model,
    { _ in },
    operation: operation,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

#if swift(>=6)
  /// Updates the current dependencies for the duration of an asynchronous operation by taking the
  /// dependencies tied to a given object.
  ///
  /// - Parameters:
  ///   - model: An object with dependencies. The given model should have at least one `@Dependency`
  ///     property, or should have been initialized and returned from a `withDependencies`
  ///       operation.
  ///   - isolation: The isolation associated with the operation.
  ///   - updateValuesForOperation: A closure for updating the current dependency values for the
  ///     duration of the operation.
  ///   - operation: The operation to run with the updated dependencies.
  ///   - fileID: The source `#fileID` associated with the operation.
  ///   - filePath: The source `#filePath` associated with the operation.
  ///   - line: The source `#line` associated with the operation.
  ///   - column: The source `#column` associated with the operation.
  /// - Returns: The result returned from `operation`.
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    isolation: (any Actor)? = #isolation,
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) async rethrows -> R {
    guard let values = dependencyObjects.values(from: model)
    else {
      reportIssue(
        """
        You are trying to propagate dependencies to a child model from a model with no \
        dependencies. To fix this, the given '\(Model.self)' must be returned from another \
        'withDependencies' closure, or the class must hold at least one '@Dependency' property.
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
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

  /// Updates the current dependencies for the duration of an asynchronous operation by taking the
  /// dependencies tied to a given object.
  ///
  /// - Parameters:
  ///   - model: An object with dependencies. The given model should have at least one `@Dependency`
  ///     property, or should have been initialized and returned from a `withDependencies`
  ///     operation.
  ///   - isolation: The isolation associated with the operation.
  ///   - operation: The operation to run with the updated dependencies.
  ///   - fileID: The source `#fileID` associated with the operation.
  ///   - filePath: The source `#filePath` associated with the operation.
  ///   - line: The source `#line` associated with the operation.
  ///   - column: The source `#column` associated with the operation.
  /// - Returns: The result returned from `operation`.
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    isolation: (any Actor)? = #isolation,
    operation: () async throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) async rethrows -> R {
    try await withDependencies(
      from: model,
      { _ in },
      operation: operation,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
#else
  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
    operation: () async throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) async rethrows -> R {
    guard let values = dependencyObjects.values(from: model)
    else {
      reportIssue(
        """
        You are trying to propagate dependencies to a child model from a model with no \
        dependencies. To fix this, the given '\(Model.self)' must be returned from another \
        'withDependencies' closure, or the class must hold at least one '@Dependency' property.
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
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

  @_unsafeInheritExecutor
  @discardableResult
  public func withDependencies<Model: AnyObject, R>(
    from model: Model,
    operation: () async throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) async rethrows -> R {
    try await withDependencies(
      from: model,
      { _ in },
      operation: operation,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
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
///       // All code in here will use dependencies at the time of calling withEscapedDependencies.
///     }
///   }
/// }
/// ```
///
/// As a general rule, you should surround _all_ escaping code that may access dependencies with
/// this helper, and you should use ``DependencyValues/Continuation/yield(_:)-42ttb`` _immediately_
/// inside the escaping closure. Otherwise you run the risk of the escaped code using the wrong
/// dependencies. But, you should also try your hardest to keep your code in the structured world
/// using Swift's tools of structured concurrency, and should avoid using escaping closures.
///
/// If you need to further override dependencies in the escaped closure, do so inside the
/// ``DependencyValues/Continuation/yield(_:)-42ttb`` and not outside:
///
/// ```swift
/// withEscapedDependencies { dependencies in
///   DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
///     dependencies.yield {
///       withDependencies {
///         $0.apiClient = .mock
///       } operation: {
///         // All code in here will use dependencies at the time of calling
///         // withEscapedDependencies except the API client will be mocked.
///       }
///     }
///   }
/// }
/// ```
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
    let dependencies = DependencyValues._current

    /// Access the propagated dependencies in an escaping context.
    ///
    /// See the docs of ``withEscapedDependencies(_:)-5xvi3`` for more information.
    /// - Parameter operation: A closure which will have access to the propagated dependencies.
    public func yield<R>(_ operation: () throws -> R) rethrows -> R {
      // TODO: Should `yield` be renamed to `restore`?
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

private final class DependencyObjects: Sendable {
  private let storage = LockIsolated<[ObjectIdentifier: DependencyObject]>([:])

  internal init() {}

  func store(_ object: AnyObject) {
    let dependencyObject = DependencyObject(
      object: object,
      dependencyValues: DependencyValues._current
    )
    self.storage.withValue { [id = ObjectIdentifier(object)] storage in
      storage[id] = dependencyObject
      Task {
        self.storage.withValue { storage in
          for (id, object) in storage where object.isNil {
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
      ?? self.storage.withValue({ [id = ObjectIdentifier(object)] in
        $0[id]?.dependencyValues
      })
  }
}

private struct DependencyObject: @unchecked Sendable {
  private weak var object: AnyObject?
  let dependencyValues: DependencyValues
  init(object: AnyObject, dependencyValues: DependencyValues) {
    self.object = object
    self.dependencyValues = dependencyValues
  }
  var isNil: Bool {
    object == nil
  }
}

@_transparent
private func isSetting<R>(
  _ value: Bool,
  operation: () throws -> R
) rethrows -> R {
  #if DEBUG
    try DependencyValues.$isSetting.withValue(value, operation: operation)
  #else
    try operation()
  #endif
}

#if swift(<6)
  @_transparent
  private func isSetting<R>(
    _ value: Bool,
    operation: () async throws -> R
  ) async rethrows -> R {
    #if DEBUG
      try await DependencyValues.$isSetting.withValue(value, operation: operation)
    #else
      try await operation()
    #endif
  }
#endif
