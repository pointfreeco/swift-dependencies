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
  @available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
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
  @available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
  fileprivate subscript<Existential, Concrete>(
    keyPath: KeyPath<DependencyValues, Existential>,
    as hashableType: HashableType<Concrete>
  ) -> Concrete {
    let existential = self[keyPath: keyPath]
    func open<T>(_ type: T) -> String {
      "\(T.self)"
    }
    let actualConcreteType: String = _openExistential(existential as Any, do: open)
    guard let value = existential as? Concrete
    else {
      fatalError(
        """
        Could not cast '\(actualConcreteType)' to '\(Concrete.self)'. Make sure to \
        override the dependency in your test or suite traits:
        
          @Suite(
            .dependencies {
              $0.\(keyPath.debugDescription.dropFirst(18)) = \(Concrete.self)(…)
            )
          )
        """
      )
    }
    return value
  }

  fileprivate subscript<Key: TestDependencyKey, Concrete>(
    key key: HashableType<Key>,
    as _: HashableType<Concrete>
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
