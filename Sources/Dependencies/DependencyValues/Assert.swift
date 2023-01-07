import XCTestDynamicOverlay

public struct AssertAction {
  public let action: (@autoclosure () -> Bool, @autoclosure () -> String, StaticString, UInt) -> ()

  public init(action: @escaping (() -> Bool, () -> String, StaticString, UInt) -> Void) {
    self.action = action
  }

  @inline(__always)
  public func callAsFunction(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    action(condition(), message(), file, line)
  }
}

extension DependencyValues {
  public var assert: AssertAction {
    get { self[AssertKey.self] }
    set { self[AssertKey.self] = newValue }
  }

  private enum AssertKey: DependencyKey {
    static let liveValue = AssertAction(action: Swift.assert)
    static let testValue = AssertAction { condition, message, file, line in
      if !condition() {
        XCTFail(message(), file: file, line: line)
      }
    }
  }
}
