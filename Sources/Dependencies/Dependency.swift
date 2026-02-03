//
//  Dependency.swift
//  Dependencies
//
//  Created by Robert Nash on 03/02/2026.
//  Copyright © 2026 ABA Systems. All rights reserved.
//

/// A property wrapper for accessing dependencies.
///
/// All dependencies are stored in ``DependencyValues`` and one uses this property wrapper to gain
/// access to a particular dependency:
///
/// ```swift
/// @Observable
/// final class FeatureModel {
///   @ObservationIgnored
///   @Dependency(\.apiClient) var apiClient
///
///   func loadUser() async throws {
///     let user = try await apiClient.fetchUser(id: 42)
///     // ...
///   }
/// }
/// ```
@propertyWrapper
public struct Dependency<Value>: Sendable {
  private let initialValues: DependencyValues
  private let keyPath: KeyPath<DependencyValues, Value> & Sendable

  /// Creates a dependency property to read the specified key path.
  ///
  /// Don't call this initializer directly. Instead, declare a property with the `Dependency`
  /// property wrapper, and provide the key path of the dependency value that the property should
  /// reflect:
  ///
  /// ```swift
  /// @Dependency(\.apiClient) var apiClient
  /// ```
  public init(_ keyPath: KeyPath<DependencyValues, Value> & Sendable) {
    self.initialValues = DependencyValues._current
    self.keyPath = keyPath
  }

  /// The current value of the dependency property.
  public var wrappedValue: Value {
    let dependencies = self.initialValues.merging(DependencyValues._current)
    return DependencyValues.$_current.withValue(dependencies) {
      DependencyValues._current[keyPath: self.keyPath]
    }
  }
}

extension Dependency {
  /// Creates a dependency property to read a dependency object.
  ///
  /// For example, given a dependency key:
  ///
  /// ```swift
  /// final class Settings: DependencyKey {
  ///   static let liveValue = Settings()
  ///   // ...
  /// }
  /// ```
  ///
  /// One can access the dependency using this property wrapper:
  ///
  /// ```swift
  /// @Dependency(Settings.self) var settings
  /// ```
  public init<Key: TestDependencyKey>(_ key: Key.Type) where Key.Value == Value {
    self.init(\DependencyValues.[key: HashableType<Key>()])
  }
}

private struct HashableType<T>: Hashable, Sendable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    true
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(T.self))
  }
}

extension DependencyValues {
  fileprivate subscript<Key: TestDependencyKey>(key key: HashableType<Key>) -> Key.Value {
    get { self[Key.self] }
    set { self[Key.self] = newValue }
  }
}
