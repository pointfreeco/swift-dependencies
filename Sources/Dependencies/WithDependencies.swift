//
//  WithDependencies.swift
//  Dependencies
//
//  Created by Robert Nash on 03/02/2026.
//  Copyright © 2026 ABA Systems. All rights reserved.
//

/// Updates the current dependencies for the duration of a synchronous operation.
///
/// Any mutations made to ``DependencyValues`` inside `updateValuesForOperation` will be visible to
/// everything executed in the operation. For example, if you wanted to force a dependency to be
/// a particular value, you can do:
///
/// ```swift
/// withDependencies {
///   $0.apiClient = .mock
/// } operation: {
///   // References to apiClient in here use the mock
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
  var dependencies = DependencyValues._current
  try updateValuesForOperation(&dependencies)
  return try DependencyValues.$_current.withValue(dependencies) {
    try operation()
  }
}

/// Updates the current dependencies for the duration of an asynchronous operation.
///
/// Any mutations made to ``DependencyValues`` inside `updateValuesForOperation` will be visible
/// to everything executed in the operation. For example, if you wanted to force a dependency to be
/// a particular value, you can do:
///
/// ```swift
/// await withDependencies {
///   $0.apiClient = .mock
/// } operation: {
///   // References to apiClient in here use the mock
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
  _ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
  operation: () async throws -> R
) async rethrows -> R {
  var dependencies = DependencyValues._current
  try await updateValuesForOperation(&dependencies)
  return try await DependencyValues.$_current.withValue(dependencies) {
    try await operation()
  }
}
