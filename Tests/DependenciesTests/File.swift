import Dependencies
import DependenciesMacros

//extension DependencyValues {
//  public var myClient: TestClient {
//    get { self[TestClient.self] }
//    set { self[TestClient.self] = newValue }
//  }
//}

//@DependencyClient
public struct TestClient: Sendable {
  @DependencyEndpoint
  public var isConnected: @Sendable (Int) -> Bool = { _ in false }
  public var isConnected2: @Sendable (Int) -> Void = { _ in }

//  private var _isConnected: @Sendable () -> Bool = {
//    XCTestDynamicOverlay.XCTFail("Unimplemented: 'isConnected'")
//    return false
//  }
//  public var isConnected: @Sendable () -> Bool {
//    @storageRestrictions(initializes: _isConnected)
//    init(initialValue) {
//      _isConnected = initialValue
//    }
//    get {
//      _isConnected
//    }
//    set {
//      _isConnected = newValue
//    }
//  }
//  public init() {}
}

//extension TestClient: TestDependencyKey {
//  public static var testValue = TestClient()
//}


/*
 public struct TestClient: Sendable {
 public var isConnected: @Sendable () -> Bool
 }

 extension TestClient: TestDependencyKey {
 public static var testValue = TestClient(
 isConnected: unimplemented("isConnected")
 )
 }
 */


import Dependencies
import XCTest

final class MyLibraryTests: XCTestCase {
  func testExample() throws {
    TestClient().isConnected(42)
    TestClient().isConnected2(42)
//    @Dependency(\.myClient) var myClient
//    _ = myClient.isConnected(42)
//    _ = myClient.isConnected2(42)
  }
}
