import Dependencies
import XCTest

final class ActorIsolatedTests: XCTestCase {
  func testAsyncWithValue() async {
    let numbers = ActorIsolated<Set<Int>>([])

    let task1 = Task {
      await numbers.withValue {
        _ = $0.insert(1)
      }
    }
    let task2 = Task {
      await numbers.withValue {
        _ = $0.insert(2)
      }
    }
    let task3 = Task {
      await numbers.withValue {
        _ = $0.insert(3)
      }
    }

    await task1.value
    await task2.value
    await task3.value
    let value = await numbers.value
    XCTAssertEqual(value, [1, 2, 3])
  }
}
