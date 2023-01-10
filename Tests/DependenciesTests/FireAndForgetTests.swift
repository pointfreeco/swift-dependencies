import Dependencies
import XCTest

final class FireAndForgetTests: XCTestCase {
  @Dependency(\.fireAndForget) var fireAndForget

  func testTestContext() async throws {
    let didExecute = ActorIsolated(false)

    await self.fireAndForget {
      try await Task.sleep(nanoseconds: 100_000_000)
      await didExecute.setValue(true)
    }

    let value = await didExecute.value
    XCTAssertEqual(value, true)
  }

  func testLiveContext() async throws {
    try await withDependencies {
      $0.context = .live
    } operation: {
      let didExecute = ActorIsolated(false)

      await self.fireAndForget {
        try await Task.sleep(nanoseconds: 100_000_000)
        await didExecute.setValue(true)
      }

      var value = await didExecute.value
      XCTAssertEqual(value, false)

      try await Task.sleep(nanoseconds: 500_000_000)
      value = await didExecute.value
      XCTAssertEqual(value, true)
    }
  }
}
