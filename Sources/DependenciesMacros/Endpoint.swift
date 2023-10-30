public struct Endpoint<Value> {
  public var rawValue: Value
  private let _override: (Value) -> Value

  public init(
    initialValue: Value,
    override: @escaping (Value) -> Value = { $0 }
  ) {
    self.rawValue = initialValue
    self._override = override
  }

  public mutating func set(_ operation: Value) {
    self.rawValue = self._override(operation)
  }

  public mutating func callAsFunction(_ operation: Value) {
    self.set(operation)
  }
}

public final class _$Implemented: @unchecked Sendable {
  private let description: @Sendable () -> String
  private var fulfilled = false
  public init(_ description: @autoclosure @escaping @Sendable () -> String) {
    self.description = description
  }
  public func fulfill() {
    self.fulfilled = true
  }
  deinit {
    if !self.fulfilled {
      XCTFail("Uncalled: '\(self.description())'")
    }
  }
}

public struct Unimplemented: Error {
  let endpoint: String

  public init(_ endpoint: String) {
    self.endpoint = endpoint
  }
}
