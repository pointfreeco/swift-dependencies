#if canImport(Combine)
  import Dependencies
  import Dispatch
  import XCTest

  final class SchedulerTests: XCTestCase {
    func testDependencyPropagation() {
      // we have to use live schedulers here because a test scheduler would
      // propagate dependencies anyway, since it's immediate.
      let queue = DispatchQueue.global(qos: .userInteractive)
      let scheduler1 = queue.dependencies()
      let scheduler2 = queue.dependencies { $0.int = 7 }

      var value1a, value1b, value2: Int?
      let expectation = self.expectation(description: "schedulers")
      expectation.expectedFulfillmentCount = 3

      @Dependency(\.int) var int
      scheduler1.schedule {
        value1a = int
        expectation.fulfill()
      }
      withDependencies {
        $0.int = 5
      } operation: {
        scheduler1.schedule {
          value1b = int
          expectation.fulfill()
        }
        scheduler2.schedule {
          value2 = int
          expectation.fulfill()
        }
      }

      self.wait(for: [expectation], timeout: 1)
      XCTAssertEqual(value1a, 42)
      XCTAssertEqual(value1b, 5)
      XCTAssertEqual(value2, 7)
    }
  }

  extension DependencyValues {
    fileprivate var int: Int {
      get { self[IntKey.self] }
      set { self[IntKey.self] = newValue }
    }
  }

  private enum IntKey: TestDependencyKey {
    static let testValue = 42
  }
#endif
