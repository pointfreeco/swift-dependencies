import Observation

public struct Endpoint<Value> {
  public var rawValue: Value
  private let _override: (_$Expectation.Configuration, Value) -> Value

  public init(
    initialValue: Value,
    override: @escaping (_$Expectation.Configuration, Value) -> Value = { $1 }
  ) {
    self.rawValue = initialValue
    self._override = override
  }

  public mutating func set(
    expectedCount: Int = 1,
    exactCount: Bool = false,
    _ newValue: Value,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    self.rawValue = self._override(
      _$Expectation.Configuration(
        expectedCount: expectedCount,
        exactCount: exactCount,
        filePath: file,
        line: line
      ),
      newValue
    )
  }

  public mutating func callAsFunction(
    expectedCount: Int = 1,
    exactCount: Bool = false,
    _ newValue: Value,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    self.set(
      expectedCount: expectedCount,
      exactCount: exactCount,
      newValue,
      file: file,
      line: line
    )
  }
}

public final class _$Expectation: @unchecked Sendable {
  public struct Configuration {
    let expectedCount: Int
    let exactCount: Bool
    let filePath: StaticString
    let line: UInt
  }

  private let description: @Sendable () -> String
  private let configuration: Configuration
  private var count = 0

  public init(
    _ description: @autoclosure @escaping @Sendable () -> String,
    configuration: Configuration
  ) {
    self.description = description
    self.configuration = configuration
  }

  deinit {
    func pluralize(_ count: Int) -> String {
      count == 1 ? "time" : "times"
    }
    if self.isUnderfulfilled || self.isOverfulfilled {
      XCTFail(
        """
        '\(self.description())' called \(pluralize(self.count)) (expected \
        \(self.configuration.exactCount ? "" : "at least ")\
        \(pluralize(self.configuration.expectedCount)))
        """,
        file: self.configuration.filePath,
        line: self.configuration.line
      )
    }
  }

  private var isUnderfulfilled: Bool {
    self.count < self.configuration.expectedCount
  }

  private var isOverfulfilled: Bool {
    self.configuration.exactCount && self.count > self.configuration.expectedCount
  }

  public func fulfill() {
    self.count += 1
  }
}

public struct Unimplemented: Error {
  let endpoint: String

  public init(_ endpoint: String) {
    self.endpoint = endpoint
  }
}
