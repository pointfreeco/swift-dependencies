#if swift(<6)
  /// A property wrapper for accessing dependencies.
  ///
  /// All dependencies are stored in ``DependencyValues`` and one uses this property wrapper to gain
  /// access to a particular dependency. Typically it used to provide dependencies to features such as
  /// an observable object:
  ///
  /// ```swift
  /// final class FeatureModel: ObservableObject {
  ///   @Dependency(\.apiClient) var apiClient
  ///   @Dependency(\.continuousClock) var clock
  ///   @Dependency(\.uuid) var uuid
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// Or, if you are using [the Composable Architecture][tca]:
  ///
  /// ```swift
  /// struct Feature: ReducerProtocol {
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
#else
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
    /// final class FeatureModel: ObservableObject {
    ///   @Dependency(\.date) var date
    ///
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A key path to a specific resulting value.
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
  /// final class FeatureModel: ObservableObject {
  ///   @Dependency(Settings.self) var settings
  ///
  ///   // ...
  /// }
  /// ```
  ///
  /// - Parameter key: A dependency key to a specific resulting value.
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

private struct HashableType<T>: Hashable, Sendable {
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt
  static func == (lhs: Self, rhs: Self) -> Bool {
    true
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(T.self))
  }
}

extension DependencyValues {
  fileprivate subscript<Key: TestDependencyKey>(key key: HashableType<Key>) -> Key.Value {
    get {
      self[
        Key.self,
        key.fileID,
        key.filePath,
        key.line,
        key.column
      ]
    }
    set {
      self[
        Key.self,
        key.fileID,
        key.filePath,
        key.line,
        key.column
      ] = newValue
    }
  }
}

protocol _HasInitialValues {
  var initialValues: DependencyValues { get }
}
