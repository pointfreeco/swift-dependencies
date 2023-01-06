import Dependencies
import XCTest

final class DependencyValuesTests: XCTestCase {
  func testMissingLiveValue() {
    #if DEBUG && !os(Linux)
      var line = 0
      XCTExpectFailure {
        withDependencies {
          $0.context = .live
        } operation: {
          line = #line + 1
          @Dependency(\.missingLiveDependency) var missingLiveDependency: Int
          _ = missingLiveDependency
        }
      } issueMatcher: {
        $0.compactDescription == """
          "@Dependency(\\.missingLiveDependency)" has no live implementation, but was accessed \
          from a live context.

            Location:
              DependenciesTests/DependencyValuesTests.swift:\(line)
            Key:
              TestKey
            Value:
              Int

          Every dependency registered with the library must conform to "DependencyKey", and that \
          conformance must be visible to the running application.

          To fix, make sure that "TestKey" conforms to "DependencyKey" by providing a live \
          implementation of your dependency, and make sure that the conformance is linked with \
          this current application.
          """
      }
    #endif
  }

  func testWithValues() {
    let date = withDependencies {
      $0.date = .constant(someDate)
    } operation: { () -> Date in
      @Dependency(\.date) var date
      return date.now
    }

    let defaultDate = withDependencies {
      $0.context = .live
    } operation: { () -> Date in
      @Dependency(\.date) var date
      return date.now
    }

    XCTAssertEqual(date, someDate)
    XCTAssertNotEqual(defaultDate, someDate)
  }

  func testWithValue() {
    withDependencies {
      $0.context = .live
    } operation: {
      let date = withDependencies {
        $0.date = .constant(someDate)
      } operation: { () -> Date in
        @Dependency(\.date) var date
        return date.now
      }

      XCTAssertEqual(date, someDate)
      XCTAssertNotEqual(DependencyValues._current.date.now, someDate)
    }
  }

  func testDependencyDefaultIsReused() {
    withDependencies {
      $0 = .init()
    } operation: {
      withDependencies {
        $0.context = .test
      } operation: {
        @Dependency(\.reuseClient) var reuseClient: ReuseClient

        XCTAssertEqual(reuseClient.count(), 0)
        reuseClient.setCount(42)
        XCTAssertEqual(reuseClient.count(), 42)
      }
    }
  }

  #if !os(Linux)
    func testDependencyDefaultIsReused_SegmentedByContext() {
      withDependencies {
        $0 = .init()
      } operation: {
        withDependencies {
          $0.context = .test
        } operation: {
          @Dependency(\.reuseClient) var reuseClient: ReuseClient

          XCTAssertEqual(reuseClient.count(), 0)
          reuseClient.setCount(42)
          XCTAssertEqual(reuseClient.count(), 42)

          withDependencies {
            $0.context = .preview
          } operation: {
            XCTAssertEqual(reuseClient.count(), 0)
            reuseClient.setCount(1729)
            XCTAssertEqual(reuseClient.count(), 1729)
          }

          XCTAssertEqual(reuseClient.count(), 42)

          withDependencies {
            $0.context = .live
          } operation: {
            #if DEBUG
              XCTExpectFailure {
                $0.compactDescription.contains(
                  """
                  @Dependency(\\.reuseClient)" has no live implementation, but was accessed from a live \
                  context.
                  """
                )
              }
            #endif
            XCTAssertEqual(reuseClient.count(), 0)
            reuseClient.setCount(-42)
            XCTAssertEqual(
              reuseClient.count(),
              0,
              "Don't cache dependency when using a test value in a live context"
            )
          }

          XCTAssertEqual(reuseClient.count(), 42)
        }
      }
    }
  #endif

  func testAccessingTestDependencyFromLiveContext_WhenUpdatingDependencies() {
    @Dependency(\.reuseClient) var reuseClient: ReuseClient

    #if !os(Linux)
      withDependencies {
        $0.context = .live
      } operation: {
        withDependencies {
          XCTAssertEqual($0.reuseClient.count(), 0)
          XCTAssertEqual(reuseClient.count(), 0)
        } operation: {
          #if DEBUG
            XCTExpectFailure {
              $0.compactDescription.contains(
                """
                @Dependency(\\.reuseClient)" has no live implementation, but was accessed from a live \
                context.
                """
              )
            }
          #endif
          XCTAssertEqual(reuseClient.count(), 0)
        }
      }
    #endif
  }

  func testBinding() {
    withDependencies {
      $0.context = .test
    } operation: {
      @Dependency(\.childDependencyEarlyBinding) var childDependencyEarlyBinding:
        ChildDependencyEarlyBinding
      @Dependency(\.childDependencyLateBinding) var childDependencyLateBinding:
        ChildDependencyLateBinding

      XCTAssertEqual(childDependencyEarlyBinding.fetch(), 42)
      XCTAssertEqual(childDependencyLateBinding.fetch(), 42)

      withDependencies {
        $0.someDependency.fetch = { 1729 }
      } operation: {
        XCTAssertEqual(childDependencyEarlyBinding.fetch(), 1729)
        XCTAssertEqual(childDependencyLateBinding.fetch(), 1729)
      }

      var childDependencyEarlyBindingEscaped: ChildDependencyEarlyBinding!
      var childDependencyLateBindingEscaped: ChildDependencyLateBinding!

      withDependencies {
        $0.someDependency.fetch = { 999 }
      } operation: {
        @Dependency(\.childDependencyEarlyBinding) var childDependencyEarlyBinding2:
          ChildDependencyEarlyBinding
        @Dependency(\.childDependencyLateBinding) var childDependencyLateBinding2:
          ChildDependencyLateBinding

        childDependencyEarlyBindingEscaped = childDependencyEarlyBinding
        childDependencyLateBindingEscaped = childDependencyLateBinding

        XCTAssertEqual(childDependencyEarlyBinding2.fetch(), 999)
        XCTAssertEqual(childDependencyLateBinding2.fetch(), 999)
      }

      XCTAssertEqual(childDependencyEarlyBindingEscaped.fetch(), 42)
      XCTAssertEqual(childDependencyLateBindingEscaped.fetch(), 42)

      withDependencies {
        $0.someDependency.fetch = { 1_000 }
      } operation: {
        XCTAssertEqual(childDependencyEarlyBindingEscaped.fetch(), 1_000)
        XCTAssertEqual(childDependencyLateBindingEscaped.fetch(), 1_000)
      }
    }
  }

  func testWithTestValues() {
    class FeatureModel /*: ObservableObject*/ {
      @Dependency(\.fullDependency) var fullDependency
    }

    let model = FeatureModel()

    XCTAssertEqual(model.fullDependency.value, 3)

    withDependencies {
      $0.context = .preview
    } operation: {
      XCTAssertEqual(model.fullDependency.value, 2)
    }
    withDependencies {
      $0.context = .live
    } operation: {
      XCTAssertEqual(model.fullDependency.value, 1)
    }
    withDependencies {
      $0.fullDependency.value = -1
    } operation: {
      XCTAssertEqual(model.fullDependency.value, -1)
    }
  }

  func testNestedWithTestValues() {
    withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        XCTAssertEqual(
          DependencyValues._current.date.now,
          Date(timeIntervalSince1970: 1_234_567_890)
        )
        XCTAssertEqual(
          DependencyValues._current.uuid(),
          UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        )
        XCTAssertEqual(DependencyValues._current.context, .test)
      }
    }
  }

  func testNestedWithTestValues_Async() async throws {
    try await withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
      try await withDependencies {
        $0.uuid = .incrementing
      } operation: {
        XCTAssertEqual(
          DependencyValues._current.date.now,
          Date(timeIntervalSince1970: 1_234_567_890)
        )
        XCTAssertEqual(
          DependencyValues._current.uuid(),
          UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        )
        XCTAssertEqual(DependencyValues._current.context, .test)
        try await Task.sleep(nanoseconds: 0)
      }
    }
  }

  func testEscape() {
    let expectation = self.expectation(description: "escape")
    withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      withEscapedDependencies { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          continuation.yield {
            @Dependency(\.fullDependency.value) var value: Int
            XCTAssertEqual(value, 42)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              continuation.yield {
                @Dependency(\.fullDependency.value) var value: Int
                XCTAssertEqual(value, 42)
                expectation.fulfill()
              }
            }
          }
        }
      }
    }

    self.wait(for: [expectation], timeout: 1)
  }

  @MainActor
  func testEscapingInFeatureModel_InstanceVariablePropagated() {
    let expectation = self.expectation(description: "escape")

    @MainActor
    class FeatureModel /*: ObservableObject*/ {
      @Dependency(\.fullDependency) var fullDependency
      func doSomething(expectation: XCTestExpectation) {
        DispatchQueue.main.async {
          XCTAssertEqual(self.fullDependency.value, 42)
          expectation.fulfill()
        }
      }
    }

    let model = withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      FeatureModel()
    }

    model.doSomething(expectation: expectation)
    self.wait(for: [expectation], timeout: 1)
  }

  @MainActor
  func testEscapingInFeatureModel_NotPropagated() {
    let expectation = self.expectation(description: "escape")

    @MainActor
    class FeatureModel /*: ObservableObject*/ {
      /*@Published */var value = 0
      func doSomething(expectation: XCTestExpectation) {
        DispatchQueue.main.async {
          @Dependency(\.fullDependency) var fullDependency: FullDependency
          self.value = fullDependency.value
          expectation.fulfill()
        }
      }
    }

    let model = withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      FeatureModel()
    }

    model.doSomething(expectation: expectation)
    self.wait(for: [expectation], timeout: 1)
    XCTAssertEqual(model.value, 3)
  }

  @MainActor
  func testEscapingInFeatureModelWithOverride() {
    let expectation = self.expectation(description: "escape")

    @MainActor
    class FeatureModel /*: ObservableObject*/ {
      @Dependency(\.fullDependency) var fullDependency
      func doSomething(expectation: XCTestExpectation) {
        withEscapedDependencies { continuation in
          DispatchQueue.main.async {
            continuation.yield {
              XCTAssertEqual(self.fullDependency.value, 42)
              expectation.fulfill()
            }
          }
        }
      }
    }

    let model = FeatureModel()

    withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      model.doSomething(expectation: expectation)
    }
    self.wait(for: [expectation], timeout: 1)
  }

  @MainActor
  func testEscapingInFeatureModelWithOverride_OverideEscaped() {
    let expectation = self.expectation(description: "escape")

    @MainActor
    class FeatureModel /*: ObservableObject*/ {
      /*@Published */var value = 0
      @Dependency(\.fullDependency) var fullDependency
      func doSomething(expectation: XCTestExpectation) {
        withEscapedDependencies { continuation in
          DispatchQueue.main.async {
            withDependencies {
              $0.fullDependency.value = 999
            } operation: {
              continuation.yield {
                self.value = self.fullDependency.value
                expectation.fulfill()
              }
            }
          }
        }
      }
    }

    let model = FeatureModel()

    withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      model.doSomething(expectation: expectation)
    }
    self.wait(for: [expectation], timeout: 1)
    XCTAssertEqual(model.value, 999)
  }

  @MainActor
  func testEscapingInFeatureModelWithOverride_NotPropagated() {
    let expectation = self.expectation(description: "escape")

    @MainActor
    class FeatureModel /*: ObservableObject*/ {
      /*@Published */var value = 0
      @Dependency(\.fullDependency) var fullDependency
      func doSomething(expectation: XCTestExpectation) {
        DispatchQueue.main.async {
          self.value = self.fullDependency.value
          expectation.fulfill()
        }
      }
    }

    let model = FeatureModel()

    withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      model.doSomething(expectation: expectation)
    }
    self.wait(for: [expectation], timeout: 1)
    XCTAssertEqual(model.value, 3)
  }

  func testTaskPropagation() async throws {
    let expectation = self.expectation(description: "escape")

    withDependencies {
      $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
    } operation: {
      @Dependency(\.date.now) var now: Date
      XCTAssertEqual(now.timeIntervalSinceReferenceDate, 1_234_567_890)
      Task {
        XCTAssertEqual(now.timeIntervalSinceReferenceDate, 1_234_567_890)
        @Dependency(\.date.now) var now: Date
        XCTAssertEqual(now.timeIntervalSinceReferenceDate, 1_234_567_890)
        expectation.fulfill()
      }
    }

    self.wait(for: [expectation], timeout: 0)
  }

  func testTaskGroupPropagation() async {
    let value = await withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      await withTaskGroup(of: Int.self, returning: Int?.self) { group in
        group.addTask {
          @Dependency(\.fullDependency.value) var value: Int
          XCTAssertEqual(DependencyValues._current.fullDependency.value, 42)
          return value
        }
        return await group.next()
      }
    }

    XCTAssertEqual(value, 42)
  }

  func testAsyncStreamUnfoldingWithoutEscapedDependencies() async {
    let stream = withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      var isDone = false
      return AsyncStream(unfolding: {
        defer { isDone = true }
        @Dependency(\.fullDependency.value) var value
        return isDone ? nil : value
      })
    }

    let values = await stream.reduce([]) { $0 + [$1] }
    XCTAssertEqual(values, [3], "Dependency change does not propagate.")
  }

  func testAsyncStreamUnfoldingWithEscapedDependencies() async {
    let stream = withDependencies {
      $0.fullDependency.value = 42
    } operation: {
      var isDone = false
      return withEscapedDependencies { continuation in
        AsyncStream(unfolding: {
          continuation.yield {
            defer { isDone = true }
            @Dependency(\.fullDependency.value) var value
            return isDone ? nil : value
          }
        })
      }
    }

    let values = await stream.reduce([]) { $0 + [$1] }
    XCTAssertEqual(values, [42], "Dependency change does propagate.")
  }

  func testParentModelWithoutDependencies() {
    class Child {
      @Dependency(\.date) var date
    }
    class Parent {
      func child() -> Child {
        withDependencies(from: self) {
          Child()
        }
      }
    }

    let parent = withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
      Parent()
    }

    let child = parent.child()

    XCTAssertEqual(child.date.now, Date(timeIntervalSince1970: 1_234_567_890))
  }

  #if DEBUG
    func testCachePollution1() async {
      @Dependency(\.cachedDependency) var cachedDependency: CachedDependency
      let value = await cachedDependency.increment()
      XCTAssertEqual(value, 1)
    }

    func testCachePollution2() async {
      @Dependency(\.cachedDependency) var cachedDependency: CachedDependency
      let value = await cachedDependency.increment()
      XCTAssertEqual(value, 1)
    }
  #endif
}

actor CachedDependency: TestDependencyKey {
  static var testValue: CachedDependency {
    CachedDependency()
  }

  private var count = 0

  func increment() -> Int {
    self.count += 1
    return self.count
  }
}

struct SomeDependency: TestDependencyKey {
  var fetch: @Sendable () -> Int
  static let testValue = Self { 42 }
}
struct ChildDependencyEarlyBinding: TestDependencyKey {
  var fetch: @Sendable () -> Int
  static var testValue: Self {
    @Dependency(\.someDependency) var someDependency
    return Self { someDependency.fetch() }
  }
}
struct ChildDependencyLateBinding: TestDependencyKey {
  var fetch: @Sendable () -> Int
  static var testValue: Self {
    return Self {
      @Dependency(\.someDependency) var someDependency
      return someDependency.fetch()
    }
  }
}
extension DependencyValues {
  var cachedDependency: CachedDependency {
    get { self[CachedDependency.self] }
    set { self[CachedDependency.self] = newValue }
  }
  var someDependency: SomeDependency {
    get { self[SomeDependency.self] }
    set { self[SomeDependency.self] = newValue }
  }
  var childDependencyEarlyBinding: ChildDependencyEarlyBinding {
    get { self[ChildDependencyEarlyBinding.self] }
    set { self[ChildDependencyEarlyBinding.self] = newValue }
  }
  var childDependencyLateBinding: ChildDependencyLateBinding {
    get { self[ChildDependencyLateBinding.self] }
    set { self[ChildDependencyLateBinding.self] = newValue }
  }
}

private let someDate = Date(timeIntervalSince1970: 1_234_567_890)

extension DependencyValues {
  fileprivate var missingLiveDependency: Int {
    self[TestKey.self]
  }
}

private enum TestKey: TestDependencyKey {
  static let testValue = 42
}

extension DependencyValues {
  fileprivate var reuseClient: ReuseClient {
    get { self[ReuseClient.self] }
    set { self[ReuseClient.self] = newValue }
  }
}
struct ReuseClient: TestDependencyKey {
  var count: @Sendable () -> Int
  var setCount: @Sendable (Int) -> Void
  init(
    count: @escaping @Sendable () -> Int,
    setCount: @escaping @Sendable (Int) -> Void
  ) {
    self.count = count
    self.setCount = setCount
  }
  static var testValue: Self {
    let count = LockIsolated(0)
    return Self(
      count: { count.value },
      setCount: { count.setValue($0) }
    )
  }
}

private struct FullDependency: DependencyKey {
  var value: Int
  static var liveValue: FullDependency {
    Self(value: 1)
  }
  static var previewValue: FullDependency {
    Self(value: 2)
  }
  static var testValue: FullDependency {
    Self(value: 3)
  }
}
extension DependencyValues {
  fileprivate var fullDependency: FullDependency {
    get { self[FullDependency.self] }
    set { self[FullDependency.self] = newValue }
  }
}
