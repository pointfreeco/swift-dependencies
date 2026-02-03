//
//  DependencyValues.swift
//  Dependencies
//
//  Created by Robert Nash on 03/02/2026.
//  Copyright © 2026 ABA Systems. All rights reserved.
//

import Foundation

/// A collection of dependencies that is globally available.
///
/// To access a particular dependency from the collection you use the ``Dependency`` property
/// wrapper:
///
/// ```swift
/// @Dependency(\.apiClient) var apiClient
/// // ...
/// let user = try await apiClient.fetchUser(id: 42)
/// ```
///
/// To change a dependency for a well-defined scope you can use the
/// ``withDependencies(_:operation:)-sync`` method:
///
/// ```swift
/// withDependencies {
///   $0.apiClient = .mock
/// } operation: {
///   // Use mocked apiClient here
/// }
/// ```
///
/// To register a dependency inside ``DependencyValues``, you first create a type to conform to the
/// ``DependencyKey`` protocol:
///
/// ```swift
/// private enum APIClientKey: DependencyKey {
///   static let liveValue = APIClient.live
/// }
/// ```
///
/// Then extend ``DependencyValues`` with a computed property:
///
/// ```swift
/// extension DependencyValues {
///   var apiClient: APIClient {
///     get { self[APIClientKey.self] }
///     set { self[APIClientKey.self] = newValue }
///   }
/// }
/// ```
public struct DependencyValues: Sendable {
  @TaskLocal public static var _current = Self()

  var cachedValues = CachedValues()
  private var storage: [ObjectIdentifier: any Sendable] = [:]

  /// Creates a dependency values instance.
  public init() {}

  init(context: DependencyContext) {
    self.init()
    self.context = context
  }

  /// Accesses the dependency value associated with a custom key.
  ///
  /// This subscript is typically only used when adding a computed property to ``DependencyValues``
  /// for registering custom dependencies.
  public subscript<Key: TestDependencyKey>(key: Key.Type) -> Key.Value {
    get {
      guard let base = self.storage[ObjectIdentifier(key)], let dependency = base as? Key.Value
      else {
        let context = self.storage[ObjectIdentifier(DependencyContextKey.self)] as? DependencyContext
          ?? self.cachedValues.value(for: DependencyContextKey.self, context: defaultContext)

        return self.cachedValues.value(for: Key.self, context: context)
      }
      return dependency
    }
    set {
      self.storage[ObjectIdentifier(key)] = newValue
    }
  }

  /// A collection of "live" dependencies.
  public static var live: Self {
    var values = Self()
    values.context = .live
    return values
  }

  /// A collection of "preview" dependencies.
  public static var preview: Self {
    var values = Self()
    values.context = .preview
    return values
  }

  /// A collection of "test" dependencies.
  public static var test: Self {
    var values = Self()
    values.context = .test
    return values
  }

  func merging(_ other: Self) -> Self {
    var values = self
    values.storage.merge(other.storage, uniquingKeysWith: { $1 })
    return values
  }
}

final class CachedValues: @unchecked Sendable {
  struct CacheKey: Hashable, Sendable {
    let id: ObjectIdentifier
    let context: DependencyContext

    init<Key>(_ key: Key.Type, context: DependencyContext) {
      self.id = ObjectIdentifier(key)
      self.context = context
    }
  }

  private let lock = NSRecursiveLock()
  private var cached: [CacheKey: any Sendable] = [:]

  func resetCache() {
    lock.lock()
    defer { lock.unlock() }
    cached = [:]
  }

  func value<Key: TestDependencyKey>(
    for key: Key.Type,
    context: DependencyContext
  ) -> Key.Value {
    lock.lock()
    defer { lock.unlock() }

    let cacheKey = CacheKey(key, context: context)

    guard let base = cached[cacheKey], let value = base as? Key.Value else {
      let value: Key.Value
      switch context {
      case .live:
        value = (key as? any DependencyKey.Type)?.liveValue as? Key.Value ?? Key.testValue
      case .preview:
        value = Key.previewValue
      case .test:
        value = Key.testValue
      }

      cached[cacheKey] = value
      return value
    }

    return value
  }
}

// MARK: - Context

extension DependencyValues {
  /// The current dependency context.
  public var context: DependencyContext {
    get { self[DependencyContextKey.self] }
    set { self[DependencyContextKey.self] = newValue }
  }
}

enum DependencyContextKey: DependencyKey {
  static let liveValue = DependencyContext.live
  static let previewValue = DependencyContext.preview
  static let testValue = DependencyContext.test
}

// MARK: - Context Detection

private let defaultContext: DependencyContext = {
  let environment = ProcessInfo.processInfo.environment

  if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
    return .preview
  } else if isTesting {
    return .test
  } else {
    return .live
  }
}()

private let isTesting: Bool = {
  NSClassFromString("XCTestCase") != nil
    || NSClassFromString("XCTest.XCTestCase") != nil
    || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
}()
