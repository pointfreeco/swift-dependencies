#if canImport(Testing) || canImport(XCTest)
  import Foundation
  import Dependencies

  /// A property wrapper that safely casts a dependency to a specific mock type.
  ///
  /// This is useful when you've explicitly overridden a dependency with a mock
  /// at the test suite level and want type-safe access to mock-specific methods.
  ///
  /// ```swift
  /// @Suite(.dependency(\.apiClient, APIClientMock()))
  /// struct MyTests {
  ///     @DependencyMock(\.apiClient) var apiClient: APIClientMock
  ///     
  ///     @Test func testFeature() {
  ///         apiClient.shouldFail = true // Access mock-specific properties
  ///         // ... test code
  ///     }
  /// }
  /// ```
  @propertyWrapper
  public struct DependencyMock<Value, Mock> {
    public var wrappedValue: Mock { 
      guard let mock = dependency as? Mock else {
        let actualType = String(describing: type(of: dependency))
        let expectedType = String(describing: Mock.self)
        fatalError("""
          @DependencyMock expected \(expectedType) but got \(actualType).
          
          Make sure you've overridden the dependency with the expected mock type:
          @Suite(.dependency(keyPath, \(expectedType)()))
          or
          withDependencies { $0[keyPath: keyPath] = \(expectedType)() }
          """)
      }
      return mock
    }

    @Dependency private var dependency: Value

    public init(
      _ keyPath: KeyPath<DependencyValues, Value> & Sendable,
      as _: Mock.Type = Mock.self,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) {
      _dependency = .init(keyPath, fileID: fileID, filePath: filePath, line: line, column: column)
    }
  }
#endif
