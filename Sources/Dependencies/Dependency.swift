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
  private let file: StaticString
  private let fileID: StaticString
  private let line: UInt

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
    _ keyPath: KeyPath<DependencyValues, Value>,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) {
    self.initialValues = DependencyValues._current
    self.keyPath = keyPath
    self.file = file
    self.fileID = fileID
    self.line = line
  }

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
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) where Key.Value == Value {
    self.init(
      \DependencyValues.[HashableType<Key>(file: file, line: line)],
      file: file,
      fileID: fileID,
      line: line
    )
  }

  /// The current value of the dependency property.
  public var wrappedValue: Value {
    #if DEBUG
      var currentDependency = DependencyValues.currentDependency
      currentDependency.file = self.file
      currentDependency.fileID = self.fileID
      currentDependency.line = self.line
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

private struct HashableType<T>: Hashable {
  let file: StaticString
  let line: UInt
  static func == (lhs: Self, rhs: Self) -> Bool {
    true
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(T.self))
  }
}

fileprivate extension DependencyValues {
  subscript<Key: TestDependencyKey>(key: HashableType<Key>) -> Key.Value {
    get { self[Key.self, file: key.file, line: key.line] }
    set { self[Key.self, file: key.file, line: key.line] = newValue }
  }
}

protocol _HasInitialValues {
  var initialValues: DependencyValues { get }
}
