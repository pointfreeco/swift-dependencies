import XCTest

@testable import Dependencies

final class DependencyTests: XCTestCase {
  func testExtendingLifetimeToChildModels() {
    @Dependency(\.int) var int: Int
    XCTAssertEqual(int, 42)
    XCTAssertEqual(42, Model().int)
    XCTAssertEqual("goodbye", Model().string)

    let model = withDependencies { $0.int = 1729 } operation: {
      withDependencies { $0.string = "howdy" } operation: {
        Model()
      }
    }
    XCTAssertEqual(1729, model.int)
    XCTAssertEqual("howdy", model.string)
    withDependencies {
      $0.int = 0
      $0.string = "cya"
    } operation: {
      XCTAssertEqual(0, model.int)
      XCTAssertEqual("cya", model.string)
    }
    XCTAssertEqual(1729, model.int)
    XCTAssertEqual("howdy", model.string)

    let child = model.child()
    XCTAssertEqual(1729, child.int)
    XCTAssertEqual("howdy", child.string)
    withDependencies {
      $0.int = 0
      $0.string = "cya"
    } operation: {
      XCTAssertEqual(0, child.int)
      XCTAssertEqual("cya", child.string)
    }
    XCTAssertEqual(1729, child.int)
    XCTAssertEqual("howdy", child.string)

    let grandchild = child.child()
    XCTAssertEqual(1729, grandchild.int)
    XCTAssertEqual("howdy", grandchild.string)
    withDependencies {
      $0.int = 0
      $0.string = "cya"
    } operation: {
      XCTAssertEqual(0, grandchild.int)
      XCTAssertEqual("cya", grandchild.string)
    }
    XCTAssertEqual(1729, grandchild.int)
    XCTAssertEqual("howdy", grandchild.string)

    let greatGrandchild = withDependencies {
      $0.int = 9000
      $0.string = "cool"
    } operation: {
      grandchild.child()
    }
    XCTAssertEqual(9000, greatGrandchild.int)
    XCTAssertEqual("cool", greatGrandchild.string)
    withDependencies {
      $0.int = 0
      $0.string = "cya"
    } operation: {
      XCTAssertEqual(0, greatGrandchild.int)
      XCTAssertEqual("cya", greatGrandchild.string)
    }
    XCTAssertEqual(9000, greatGrandchild.int)
    XCTAssertEqual("cool", greatGrandchild.string)
  }

  func testInvalidScope() {
    #if DEBUG && !os(Linux)
      XCTExpectFailure {
        withDependencies(from: self) {}
      } issueMatcher: {
        $0.compactDescription == """
          You are trying to propagate dependencies to a child model from a model with no \
          dependencies. To fix this, the given 'DependencyTests' must be returned from another \
          'withDependencies' closure, or the class must hold at least one '@Dependency' property.
          """
      }
    #endif
  }

  func testExtendingLifetimeToChildModels_Async() async {
    @Dependency(\.int) var int: Int
    XCTAssertEqual(int, 42)
    XCTAssertEqual(42, Model().int)
    XCTAssertEqual("goodbye", Model().string)

    let model = await withDependencies {
      await Task.yield()
      $0.int = 1729
    } operation: {
      await withDependencies {
        await Task.yield()
        $0.string = "howdy"
      } operation: {
        await Task.yield()
        return Model()
      }
    }
    XCTAssertEqual(1729, model.int)
    XCTAssertEqual("howdy", model.string)
    await withDependencies {
      $0.int = 0
      $0.string = "cya"
    } operation: {
      await Task.yield()
      XCTAssertEqual(0, model.int)
      XCTAssertEqual("cya", model.string)
    }
    XCTAssertEqual(1729, model.int)
    XCTAssertEqual("howdy", model.string)

    let child = await model.child()
    XCTAssertEqual(1729, child.int)
    XCTAssertEqual("howdy", child.string)
    await withDependencies {
      await Task.yield()
      $0.int = 0
      $0.string = "cya"
    } operation: {
      await Task.yield()
      XCTAssertEqual(0, child.int)
      XCTAssertEqual("cya", child.string)
    }
    XCTAssertEqual(1729, child.int)
    XCTAssertEqual("howdy", child.string)

    let grandchild = await child.child()
    XCTAssertEqual(1729, grandchild.int)
    XCTAssertEqual("howdy", grandchild.string)
    await withDependencies {
      await Task.yield()
      $0.int = 0
      $0.string = "cya"
    } operation: {
      await Task.yield()
      XCTAssertEqual(0, grandchild.int)
      XCTAssertEqual("cya", grandchild.string)
    }
    XCTAssertEqual(1729, grandchild.int)
    XCTAssertEqual("howdy", grandchild.string)

    let greatGrandchild = await withDependencies {
      await Task.yield()
      $0.int = 9000
      $0.string = "cool"
    } operation: {
      await grandchild.child()
    }
    XCTAssertEqual(9000, greatGrandchild.int)
    XCTAssertEqual("cool", greatGrandchild.string)
    await withDependencies {
      await Task.yield()
      $0.int = 0
      $0.string = "cya"
    } operation: {
      await Task.yield()
      XCTAssertEqual(0, greatGrandchild.int)
      XCTAssertEqual("cya", greatGrandchild.string)
    }
    XCTAssertEqual(9000, greatGrandchild.int)
    XCTAssertEqual("cool", greatGrandchild.string)
  }

  func testInvalidScope_Async() async {
    #if DEBUG && !os(Linux)
      await withDependencies(from: self) {
        await Task.yield()
      }
      XCTExpectFailure {
        $0.compactDescription == """
          You are trying to propagate dependencies to a child model from a model with no \
          dependencies. To fix this, the given 'DependencyTests' must be returned from another \
          'withDependencies' closure, or the class must hold at least one '@Dependency' property.
          """
      }
    #endif
  }
}
private class Model {
  @Dependency(\.int) var int
  @Dependency(\.string) var string
  func child() -> Model {
    withDependencies(from: self) {
      Model()
    }
  }
  func child() async -> Model {
    await withDependencies(from: self) {
      await Task.yield()
      return Model()
    }
  }
}

extension DependencyValues {
  fileprivate var int: Int {
    get { self[IntKey.self] }
    set { self[IntKey.self] = newValue }
  }
}

private enum IntKey: DependencyKey {
  static let liveValue = -1
  static let testValue = 42
}

extension DependencyValues {
  fileprivate var string: String {
    get { self[StringKey.self] }
    set { self[StringKey.self] = newValue }
  }
}

private enum StringKey: DependencyKey {
  static let liveValue = "hello"
  static let testValue = "goodbye"
}
