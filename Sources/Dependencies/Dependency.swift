#if swift(>=6)
  /// A property wrapper for accessing dependencies.
  ///
  /// All dependencies are stored in ``DependencyValues`` and one uses this property wrapper to gain
  /// access to a particular dependency. Typically it used to provide dependencies to features such as
  /// an observable object:
  ///
  /// ```swift
  /// @Observable
  /// final class FeatureModel {
  ///   @ObservationIgnored
  ///   @Dependency(\.apiClient) var apiClient
  ///   @ObservationIgnored
  ///   @Dependency(\.continuousClock) var clock
  ///   @ObservationIgnored
  ///   @Dependency(\.uuid) var uuid
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// Or, if you are using [the Composable Architecture][tca]:
  ///
  /// ```swift
  /// @Reducer
  /// struct Feature {
  ///   @Dependency(\.apiClient) var apiClient
  ///   @Dependency(\.continuousClock) var clock
  ///   @Dependency(\.uuid) var uuid
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// But it can be used in other situations too, such as a helper function:
  ///
  /// ```swift
  /// func sharedEffect() async throws -> Action {
  ///   @Dependency(\.apiClient) var apiClient
  ///   @Dependency(\.continuousClock) var clock
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// > Warning: There are caveats to using `@Dependency` in this style, especially for applications
  /// not built in the Composable Architecture or that are not structured around a "single point of
  /// entry" concept. See the articles <doc:Lifetimes> and <doc:SingleEntryPointSystems> for more
  /// information.
  ///
  /// > Important: Do **not** use `@Dependency` with "static" properties, _e.g._:
  /// >
  /// > ```swift
  /// > struct User {
  /// >   @Dependency(\.uuid) static var uuid
  /// >   // ...
  /// > }
  /// > ```
  /// >
  /// > Static properties are lazily initialized in Swift, and so a static `@Dependency` will lazily
  /// > capture its dependency values wherever it is first accessed, and will likely produce
  /// > unexpected behavior.
  ///
  /// For the complete list of dependency values provided by the library, see the properties of the
  /// ``DependencyValues`` structure.
  ///
  /// [tca]: https://github.com/pointfreeco/swift-composable-architecture
  @propertyWrapper
  public struct Dependency<Value>: Sendable, _HasInitialValues {
    let initialValues: DependencyValues
    private let keyPath: KeyPath<DependencyValues, Value> & Sendable
    private let filePath: StaticString
    private let fileID: StaticString
    private let line: UInt
    private let column: UInt

    /// Creates a dependency property to read the specified key path.
    ///
    /// Don't call this initializer directly. Instead, declare a property with the `Dependency`
    /// property wrapper, and provide the key path of the dependency value that the property should
    /// reflect:
    ///
    /// ```swift
    /// @Observable
    /// final class FeatureModel {
    ///   @ObservationIgnored
    ///   @Dependency(\.date) var date
    ///
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameters
    ///   - keyPath: A key path to a specific resulting value.
    ///   - fileID: The source `#fileID` associated with the dependency.
    ///   - filePath: The source `#filePath` associated with the dependency.
    ///   - line: The source `#line` associated with the dependency.
    ///   - column: The source `#column` associated with the dependency.
    public init(
      _ keyPath: KeyPath<DependencyValues, Value> & Sendable,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) {
      self.initialValues = DependencyValues._current
      self.keyPath = keyPath
      self.filePath = filePath
      self.fileID = fileID
      self.line = line
      self.column = column
    }

    /// The current value of the dependency property.
    public var wrappedValue: Value {
      _wrappedValue
    }
  }
#else
  @propertyWrapper
  public struct Dependency<Value>: @unchecked Sendable, _HasInitialValues {
    let initialValues: DependencyValues
    // NB: Key paths do not conform to sendable and are instead diagnosed at the time of forming the
    //     literal.
    private let keyPath: KeyPath<DependencyValues, Value>
    private let filePath: StaticString
    private let fileID: StaticString
    private let line: UInt
    private let column: UInt

    public init(
      _ keyPath: KeyPath<DependencyValues, Value>,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) {
      self.initialValues = DependencyValues._current
      self.keyPath = keyPath
      self.filePath = filePath
      self.fileID = fileID
      self.line = line
      self.column = column
    }

    /// The current value of the dependency property.
    public var wrappedValue: Value {
      _wrappedValue
    }
  }
#endif

extension Dependency {
  /// Creates a dependency property to read a dependency object.
  ///
  /// Don't call this initializer directly. Instead, declare a property with the `Dependency`
  /// property wrapper, and provide the dependency key of the value that the property should
  /// reflect.
  ///
  /// For example, given a dependency key:
  ///
  /// ```swift
  /// final class Settings: DependencyKey {
  ///   static let liveValue = Settings()
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// One can access the dependency using this property wrapper:
  ///
  /// ```swift
  /// @Observable
  /// final class FeatureModel {
  ///   @ObservationIgnored
  ///   @Dependency(Settings.self) var settings
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// - Parameters
  ///   - key: A dependency key to a specific resulting value.
  ///   - fileID: The source `#fileID` associated with the dependency.
  ///   - filePath: The source `#filePath` associated with the dependency.
  ///   - line: The source `#line` associated with the dependency.
  ///   - column: The source `#column` associated with the dependency.
  public init<Key: TestDependencyKey>(
    _ key: Key.Type,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) where Key.Value == Value {
    self.init(
      \DependencyValues.[
        key: HashableType<Key>(fileID: fileID, filePath: filePath, line: line, column: column)
      ],
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  fileprivate var _wrappedValue: Value {
    #if DEBUG
      var currentDependency = DependencyValues.currentDependency
      currentDependency.fileID = self.fileID
      currentDependency.filePath = self.filePath
      currentDependency.line = self.line
      currentDependency.column = self.column
      return DependencyValues.$currentDependency.withValue(currentDependency) {
        let dependencies = self.initialValues.merging(DependencyValues._current)
        return DependencyValues.$_current.withValue(dependencies) {
          DependencyValues._current[keyPath: self.keyPath]
        }
      }
    #else
      let dependencies = self.initialValues.merging(DependencyValues._current)
      return DependencyValues.$_current.withValue(dependencies) {
        DependencyValues._current[keyPath: self.keyPath]
      }
    #endif
  }
}

package struct HashableType<T>: Hashable, Sendable {
  package let fileID: StaticString
  package let filePath: StaticString
  package let line: UInt
  package let column: UInt
  package init(fileID: StaticString, filePath: StaticString, line: UInt, column: UInt) {
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
  package static func == (lhs: Self, rhs: Self) -> Bool {
    true
  }
  package func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(T.self))
  }
}

extension DependencyValues {
  fileprivate subscript<Key: TestDependencyKey>(key key: HashableType<Key>) -> Key.Value {
    get {
      self[
        Key.self,
        fileID: key.fileID,
        filePath: key.filePath,
        line: key.line,
        column: key.column
      ]
    }
    set {
      self[
        Key.self,
        fileID: key.fileID,
        filePath: key.filePath,
        line: key.line,
        column: key.column
      ] = newValue
    }
  }
}

protocol _HasInitialValues {
  var initialValues: DependencyValues { get }
}
