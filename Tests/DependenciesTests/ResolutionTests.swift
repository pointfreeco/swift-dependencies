import Dependencies
import XCTest

final class ResolutionTests: XCTestCase {
  // NB: It doesn't seem possible to detect a test context from Wasm:
  //     https://github.com/swiftwasm/carton/issues/400
  #if os(WASI)
    override func invokeTest() {
      withDependencies {
        $0.context = .test
      } operation: {
        super.invokeTest()
      }
    }
  #endif

  func testDependencyDependingOnDependency_Eager() {
    @Dependency(\.eagerParent) var eagerParent: EagerParentDependency
    @Dependency(\.eagerChild) var eagerChild: EagerChildDependency

    XCTAssertEqual(eagerParent.value, 1729)
    XCTAssertEqual(eagerChild.value, 1729)

    withDependencies {
      $0.eagerChild.value = 42
    } operation: {
      XCTAssertEqual(eagerParent.value, 1729)
      XCTAssertEqual(eagerChild.value, 42)
    }
  }

  func testDependencyDependingOnDependency_Lazy() {
    @Dependency(\.lazyParent) var lazyParent: LazyParentDependency
    @Dependency(\.lazyChild) var lazyChild: LazyChildDependency

    XCTAssertEqual(lazyParent.value(), 1729)
    XCTAssertEqual(lazyChild.value(), 1729)

    withDependencies {
      $0.lazyChild.value = { 42 }
    } operation: {
      XCTAssertEqual(lazyParent.value(), 42)
      XCTAssertEqual(lazyChild.value(), 42)
    }

    withDependencies {
      $0.lazyParent.value = { 42 }
    } operation: {
      XCTAssertEqual(lazyParent.value(), 42)
      XCTAssertEqual(lazyChild.value(), 1729)
    }

    withDependencies {
      $0.lazyParent.value = { 42 }
      $0.lazyChild.value = { -42 }
    } operation: {
      XCTAssertEqual(lazyParent.value(), 42)
      XCTAssertEqual(lazyChild.value(), -42)
    }
  }

  func testDependencyDependingOnDependency_Nested() {
    struct Model {
      @Dependency(\.nestedParent) var nestedParent: NestedParentDependency
      @Dependency(\.nestedChild) var nestedChild: NestedChildDependency
    }

    let model = withDependencies {
      $0.nestedChild.value = { 1 }
    } operation: {
      Model()
    }

    XCTAssertEqual(model.nestedParent.value(), 1)
    XCTAssertEqual(model.nestedChild.value(), 1)

    withDependencies {
      $0.nestedChild.value = { 42 }
    } operation: {
      XCTAssertEqual(model.nestedParent.value(), 42)
      XCTAssertEqual(model.nestedChild.value(), 42)
    }
  }

  func testFirstAccessBehavior() {
    @Dependency(\.nestedParent) var nestedParent: NestedParentDependency
    struct Model {
      @Dependency(\.nestedParent) var nestedParent: NestedParentDependency
      @Dependency(\.nestedChild) var nestedChild: NestedChildDependency
    }

    let model = withDependencies {
      $0.nestedChild.value = { 1 }
    } operation: {
      Model()
    }

    // NB: Wasm has different behavior here.
    #if os(WASI)
      let expected = 1
    #else
      let expected = 1729
    #endif
    XCTAssertEqual(nestedParent.value(), expected)
    XCTAssertEqual(model.nestedParent.value(), expected)
    XCTAssertEqual(model.nestedChild.value(), 1)

    withDependencies {
      $0.nestedChild.value = { 42 }
    } operation: {
      XCTAssertEqual(model.nestedParent.value(), 42)
      XCTAssertEqual(model.nestedChild.value(), 42)
    }
  }

  @MainActor
  func testParentChildScoping() {
    withDependencies {
      $0.context = .live
    } operation: {
      @Dependency(\.date) var date
      let _ = date.now

      @MainActor
      class ParentModel {
        @Dependency(\.date) var date
        var child1: Child1Model?
        var child2: Child2Model?
        func goToChild1() {
          self.child1 = withDependencies(from: self) { Child1Model() }
        }
        func goToChild2() {
          self.child2 = withDependencies(from: self) { Child2Model() }
        }
      }
      @MainActor
      class Child1Model {
        @Dependency(\.date) var date
      }
      @MainActor
      class Child2Model {
        @Dependency(\.date) var date
      }

      let model = withDependencies {
        $0.date = .constant(Date(timeIntervalSince1970: 1))
      } operation: {
        ParentModel()
      }

      withDependencies {
        $0.date = .constant(Date(timeIntervalSince1970: 2))
      } operation: {
        model.goToChild1()
      }
      withDependencies {
        $0.date = .constant(Date(timeIntervalSince1970: 3))
      } operation: {
        model.goToChild2()
      }

      XCTAssertEqual(model.date.now.timeIntervalSince1970, 1)
      XCTAssertEqual(model.child1?.date.now.timeIntervalSince1970, 2)
      XCTAssertEqual(model.child2?.date.now.timeIntervalSince1970, 3)
    }
  }

  func testDependencyDiamond() {
    @Dependency(\.diamondA) var diamondA: DiamondDependencyA
    @Dependency(\.diamondB1) var diamondB1: DiamondDependencyB1
    @Dependency(\.diamondB2) var diamondB2: DiamondDependencyB2
    @Dependency(\.diamondC) var diamondC: DiamondDependencyC

    XCTAssertEqual(diamondA.value(), 1 + 1 + 42 + 1729)
    XCTAssertEqual(diamondB1.value(), 1 + 42)
    XCTAssertEqual(diamondB2.value(), 1 + 1729)
    XCTAssertEqual(diamondC.value(), 1)

    withDependencies {
      $0.diamondC.value = { 2 }
    } operation: {
      XCTAssertEqual(diamondA.value(), 2 + 2 + 42 + 1729)
      XCTAssertEqual(diamondB1.value(), 2 + 42)
      XCTAssertEqual(diamondB2.value(), 2 + 1729)
      XCTAssertEqual(diamondC.value(), 2)
    }

    withDependencies {
      $0.diamondB1.value = { 100 }
      $0.diamondB2.value = { 200 }
    } operation: {
      XCTAssertEqual(diamondA.value(), 100 + 200)
      XCTAssertEqual(diamondB1.value(), 100)
      XCTAssertEqual(diamondB2.value(), 200)
      XCTAssertEqual(diamondC.value(), 1)
    }
  }

  func testClientWithDependency() {
    @Dependency(\.clientWithDependency) var clientWithDependency: ClientWithDependency
    withDependencies {
      $0.eagerChild.value = 99
    } operation: {
      XCTAssertEqual(clientWithDependency.value(), 99)
      withDependencies {
        $0.eagerChild.value = 42
      } operation: {
        XCTAssertEqual(clientWithDependency.value(), 42)
      }
    }
  }

  // TODO: investigate using callstack to find dependency cycles
  //  func testCyclic() {
  //    @Dependency(\.cyclic1) var cyclic1: CyclicDependency1
  //    @Dependency(\.cyclic2) var cyclic2: CyclicDependency2
  //
  //    XCTAssertEqual(cyclic1.value(), 3)
  //  }
}

private struct EagerParentDependency: TestDependencyKey {
  var value: Int

  static var testValue: Self {
    @Dependency(\.eagerChild) var child
    return Self(value: child.value)
  }
}
private struct EagerChildDependency: TestDependencyKey {
  var value: Int
  static let testValue = Self(value: 1729)
}
private struct LazyParentDependency: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.lazyChild) var child
    return child.value()
  }
}
private struct LazyChildDependency: TestDependencyKey {
  var value: @Sendable () -> Int

  static let testValue = Self { 1729 }
}
private struct NestedParentDependency: TestDependencyKey {
  var value: @Sendable () -> Int
  static var testValue: NestedParentDependency {
    @Dependency(\.nestedChild) var child
    return Self {
      return child.value()
    }
  }
}
private struct NestedChildDependency: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self { 1729 }
}
private struct DiamondDependencyA: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.diamondB1) var diamondB1
    @Dependency(\.diamondB2) var diamondB2
    return diamondB1.value() + diamondB2.value()
  }
}
private struct DiamondDependencyB1: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.diamondC) var diamondC
    return diamondC.value() + 42
  }
}
private struct DiamondDependencyB2: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.diamondC) var diamondC
    return diamondC.value() + 1729
  }
}
private struct DiamondDependencyC: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self { 1 }
}
private struct CyclicDependency1: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.cyclic2) var cyclic2
    return cyclic2.value() + 1
  }
}
private struct CyclicDependency2: TestDependencyKey {
  var value: @Sendable () -> Int
  static let testValue = Self {
    @Dependency(\.cyclic1) var cyclic1
    return cyclic1.value() + 2
  }
}
private struct ClientWithDependency: TestDependencyKey {
  @Dependency(\.eagerChild) var eagerChild
  var onValue: @Sendable (EagerChildDependency) -> Int = { $0.value }
  func value() -> Int {
    self.onValue(self.eagerChild)
  }
  static let testValue = Self()
}

extension DependencyValues {
  fileprivate var eagerParent: EagerParentDependency {
    get { self[EagerParentDependency.self] }
    set { self[EagerParentDependency.self] = newValue }
  }
  fileprivate var eagerChild: EagerChildDependency {
    get { self[EagerChildDependency.self] }
    set { self[EagerChildDependency.self] = newValue }
  }
  fileprivate var lazyParent: LazyParentDependency {
    get { self[LazyParentDependency.self] }
    set { self[LazyParentDependency.self] = newValue }
  }
  fileprivate var lazyChild: LazyChildDependency {
    get { self[LazyChildDependency.self] }
    set { self[LazyChildDependency.self] = newValue }
  }
  fileprivate var nestedParent: NestedParentDependency {
    get { self[NestedParentDependency.self] }
    set { self[NestedParentDependency.self] = newValue }
  }
  fileprivate var nestedChild: NestedChildDependency {
    get { self[NestedChildDependency.self] }
    set { self[NestedChildDependency.self] = newValue }
  }
  fileprivate var diamondA: DiamondDependencyA {
    get { self[DiamondDependencyA.self] }
    set { self[DiamondDependencyA.self] = newValue }
  }
  fileprivate var diamondB1: DiamondDependencyB1 {
    get { self[DiamondDependencyB1.self] }
    set { self[DiamondDependencyB1.self] = newValue }
  }
  fileprivate var diamondB2: DiamondDependencyB2 {
    get { self[DiamondDependencyB2.self] }
    set { self[DiamondDependencyB2.self] = newValue }
  }
  fileprivate var diamondC: DiamondDependencyC {
    get { self[DiamondDependencyC.self] }
    set { self[DiamondDependencyC.self] = newValue }
  }
  fileprivate var cyclic1: CyclicDependency1 {
    get { self[CyclicDependency1.self] }
    set { self[CyclicDependency1.self] = newValue }
  }
  fileprivate var cyclic2: CyclicDependency2 {
    get { self[CyclicDependency2.self] }
    set { self[CyclicDependency2.self] = newValue }
  }
  fileprivate var clientWithDependency: ClientWithDependency {
    get { self[ClientWithDependency.self] }
    set { self[ClientWithDependency.self] = newValue }
  }
}
