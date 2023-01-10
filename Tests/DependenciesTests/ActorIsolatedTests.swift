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

  // Could work without conformances,
  // but then you could have other libraries override your `Int` dependency

  func testUnsafe() {

    struct Session: UnsafeDependencyKey {}

    struct OK {
      @Dependency var session: Session
    }

    withDependencies {
      $0.assign(Session())
    } operation: {
      OK().session
    }

  }

  func testOptional() {

    struct Session: UnsafeDependencyKey {}

    struct OK {
      @Dependency var session: Session?
    }

    dump(OK().session)

    withDependencies {
      $0.assign(Session())
    } operation: {
      dump(OK().session)
    }

  }
}
