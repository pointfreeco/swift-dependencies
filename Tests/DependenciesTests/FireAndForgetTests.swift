import Dependencies
import XCTest

final class FireAndForgetTests: XCTestCase {
  @Dependency(\.fireAndForget) var fireAndForget

  func testTestContext() async throws {
    let didExecute = ActorIsolated(false)

    await self.fireAndForget {
      try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
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
        try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
        await didExecute.setValue(true)
      }

      var value = await didExecute.value
      XCTAssertEqual(value, false)

      try await Task.sleep(nanoseconds: 200 * NSEC_PER_MSEC)
      value = await didExecute.value
      XCTAssertEqual(value, true)
    }
  }
}
