import Dependencies

extension Dependency {
  /// Creates a dependency property to read the specified key path and cast to a concrete type.
  ///
  /// Useful in tests for when you know a dependency has been overridden with a test-friendly
  /// version of the dependency, and you want access to that concrete type.
  ///
  /// Don't call this initializer directly. Instead, declare a property with the `@Dependency`
  /// property wrapper, and provide the key path of the dependency value that the property should
  /// reflect, as well as the type to cast it to:
  ///
  /// ```swift
  /// @Suite(
  ///   .dependencies {
  ///     $0.continuousClock = TestClock()
  ///   }
  /// )
  /// struct FeatureTests {
  ///   @Dependency(\.continuousClock, as: TestClock<Duration>.self) var clock
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// If the dependency specified by the key path cannot be cast to the type given, a `fatalError`
  /// will be emitted.
  ///
  /// - Parameters:
  ///   - keyPath: A key path to a specific resulting value.
  ///   - type: The type to cast the dependency value to.
  ///   - fileID: The source `#fileID` associated with the dependency.
  ///   - filePath: The source `#filePath` associated with the dependency.
  ///   - line: The source `#line` associated with the dependency.
  ///   - column: The source `#column` associated with the dependency.
  public init<T>(
    _ keyPath: KeyPath<DependencyValues, T> & Sendable,
    as type: Value.Type,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      \.[
        keyPath,
        as: HashableType<Value>(
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      ],
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  /// Creates a dependency property to read a dependency object.
  ///
  /// Useful in tests for when you know a dependency has been overridden with a test-friendly
  /// version of the dependency, and you want access to that concrete type.
  ///
  /// Don't call this initializer directly. Instead, declare a property with the `Dependency`
  /// property wrapper, and provide the dependency key of the value that the property should
  /// reflect, as well as the type to cast it to:
  ///
  /// ```swift
  /// @Suite(
  ///   .dependencies {
  ///     $0[ClientKey.self] = TestClient()
  ///   }
  /// )
  /// struct FeatureTests {
  ///   @Dependency(ClientKey.self, as: TestClient.self) var client
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// If the dependency specified by the key cannot be cast to the type given, a `fatalError`
  /// will be emitted.
  ///
  /// - Parameters
  ///   - key: A dependency key to a specific resulting value.
  ///   - type: The type to cast the dependency value to.
  ///   - fileID: The source `#fileID` associated with the dependency.
  ///   - filePath: The source `#filePath` associated with the dependency.
  ///   - line: The source `#line` associated with the dependency.
  ///   - column: The source `#column` associated with the dependency.
  public init<Key: TestDependencyKey>(
    _ key: Key.Type,
    as type: Value.Type,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      \DependencyValues.[
        key: HashableType<Key>(fileID: fileID, filePath: filePath, line: line, column: column),
        as: HashableType<Value>(fileID: fileID, filePath: filePath, line: line, column: column)
      ],
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

extension DependencyValues {
  fileprivate subscript<Existential, Concrete>(
    keyPath: KeyPath<DependencyValues, Existential>,
    as type: HashableType<Concrete>
  ) -> Concrete {
    guard let value = self[keyPath: keyPath] as? Concrete
    else {
      fatalError(
        """
        Could not cast \(Swift.type(of: self[keyPath: keyPath])) to \(Concrete.self).
        """
      )
    }
    return value
  }

  fileprivate subscript<Key: TestDependencyKey, Concrete>(
    key key: HashableType<Key>,
    as type: HashableType<Concrete>
  ) -> Concrete {
    guard let value = self[Key.self] as? Concrete
    else {
      fatalError(
        """
        Could not cast \(Swift.type(of: self[Key.self])) to \(Concrete.self).
        """
      )
    }
    return value
  }
}
