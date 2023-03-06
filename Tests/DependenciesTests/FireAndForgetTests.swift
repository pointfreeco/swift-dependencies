import Dependencies
import XCTest

@MainActor
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

  func testTestContext_Cancellation() async throws {
    let didExecute = ActorIsolated(false)

    let task = Task {
      await self.fireAndForget {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        await didExecute.setValue(true)
      }
    }
    try await Task.sleep(nanoseconds: 500_000_000)
    task.cancel()
    await task.value

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

  #if !os(Linux)
    func testLiveContext_DependencyAccess() async {
      await withDependencies {
        $0.context = .live
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
      } operation: {
        let date = ActorIsolated<Date?>(nil)

        await self.fireAndForget {
          @Dependency(\.date.now) var now: Date
          await date.setValue(now)
        }

        while await date.value == nil {}
        let value = await date.value
        XCTAssertEqual(value, Date(timeIntervalSince1970: 1_234_567_890))
      }
    }
  #endif
}
