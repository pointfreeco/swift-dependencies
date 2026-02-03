//
//  DependencyKey.swift
//  Dependencies
//
//  Created by Robert Nash on 03/02/2026.
//  Copyright © 2026 ABA Systems. All rights reserved.
//

/// A key for accessing test dependencies.
///
/// This protocol allows you to define a dependency's interface and provide
/// test and preview values.
public protocol TestDependencyKey<Value> {
  /// The associated type representing the type of the dependency key's value.
  associatedtype Value: Sendable = Self

  /// The preview value for the dependency key.
  static var previewValue: Value { get }

  /// The test value for the dependency key.
  static var testValue: Value { get }
}

/// A key for accessing dependencies.
///
/// Types conform to this protocol to extend ``DependencyValues`` with custom dependencies.
///
/// `DependencyKey` has one main requirement, ``liveValue``, which must return a default value for
/// your dependency that is used when the application is run in a simulator or device.
public protocol DependencyKey<Value>: TestDependencyKey {
  /// The live value for the dependency key.
  static var liveValue: Value { get }
}

extension DependencyKey {
  /// Default implementation that provides the ``liveValue`` to Xcode previews.
  public static var previewValue: Value { Self.liveValue }

  /// Default implementation that provides the ``previewValue`` to test runs.
  public static var testValue: Value {
    fatalError(
      """
      A dependency has no test implementation, but was accessed from a test context.

      Dependencies registered with the library are not allowed to use their default, live \
      implementations when run from tests.

      To fix, override the dependency with a test value using 'withDependencies'.
      """
    )
  }
}

extension TestDependencyKey {
  /// Default implementation that provides the ``testValue`` to Xcode previews.
  public static var previewValue: Value { Self.testValue }
}
