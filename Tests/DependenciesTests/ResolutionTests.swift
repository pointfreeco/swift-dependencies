import Dependencies
import XCTest

final class ResolutionTests: XCTestCase {
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
      $0.nestedChild.value = 1
    } operation: {
      Model()
    }

    XCTAssertEqual(model.nestedParent.value, 1)
    XCTAssertEqual(model.nestedChild.value, 1)

    withDependencies {
      $0.nestedChild.value = 42
    } operation: {
      XCTAssertEqual(model.nestedParent.value, 42)
      XCTAssertEqual(model.nestedChild.value, 42)
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
  @Dependency(\.nestedChild) var child
  var value: Int { self.child.value }
  static var testValue = Self()
}
private struct NestedChildDependency: TestDependencyKey {
  var value: Int
  static var testValue = Self(value: 1729)
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
}
