import Dependencies
import XCTest

#if !arch(wasm32)
final class BaseTestCaseTests: DerivedBaseTestCase {
  override func setUp() async throws {
    try await super.setUp()
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }

  func testBasics() {
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }

  func testBasicsAsync() async {
    try? await Task.sleep(nanoseconds: 1)
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }

  func testBasicsThrows() throws {
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }

  func testBasicsAsyncThrows() async throws {
    try await Task.sleep(nanoseconds: 1)
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }
}
#endif

#if !arch(wasm32)
class DerivedBaseTestCase: BaseTestCase {
  override func setUp() async throws {
    try await super.setUp()
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
    XCTAssertEqual(DependencyValues._current.date.now, .mock)
  }

  override func invokeTest() {
    withDependencies {
      $0.date.now = .mock
    } operation: {
      super.invokeTest()
    }
  }
}
#endif

class BaseTestCase: XCTestCase {
  override func setUp() async throws {
    try await super.setUp()
    XCTAssertEqual(DependencyValues._current.context, .test)
    XCTAssertEqual(DependencyValues._current.uuid(), .deadbeef)
  }

#if !arch(wasm32)
  override func invokeTest() {
    withDependencies {
      $0.uuid = .constant(.deadbeef)
    } operation: {
      super.invokeTest()
    }
  }
#endif
}

extension UUID {
  fileprivate static let deadbeef = Self(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
}
extension Date {
  fileprivate static let mock = Self(timeIntervalSince1970: 1_234_567_890)
}
