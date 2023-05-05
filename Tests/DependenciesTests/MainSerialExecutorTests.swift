#if !os(WASI) && !os(Windows)
  @_spi(Concurrency) import Dependencies
  import XCTest

  final class MainSerialExecutorTests: XCTestCase {
    func testSerializedExecution() async {
      let xs = LockIsolated<[Int]>([])
      await withMainSerialExecutor {
        await withTaskGroup(of: Void.self) { group in
          for x in 1...1000 {
            group.addTask {
              xs.withValue { $0.append(x) }
            }
          }
        }
      }
      xs.withValue { XCTAssertEqual(Array(1...1000), $0) }
    }

    func testSerializedExecution_UnstructuredTasks() async {
      await withMainSerialExecutor {
        let xs = LockIsolated<[Int]>([])
        for x in 1...1000 {
          Task { xs.withValue { $0.append(x) } }
        }
        while xs.count < 1_000 { await Task.yield() }
        xs.withValue { XCTAssertEqual(Array(1...1000), $0) }
      }
    }
  }
#endif
