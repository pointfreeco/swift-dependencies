import Dependencies
import XCTest
import XCTestDynamicOverlay

final class UUIDDependencyTests: XCTestCase {
  @Dependency(\.uuid) var uuid

  func testIncrementing() {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      XCTAssertEqual(self.uuid(), UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
      XCTAssertEqual(self.uuid(), UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    }
  }

  func testInitIntValue() {
    XCTAssertEqual(UUID(0), UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    XCTAssertEqual(UUID(1), UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    XCTAssertEqual(UUID(15), UUID(uuidString: "00000000-0000-0000-0000-00000000000F"))
    XCTAssertEqual(UUID(256), UUID(uuidString: "00000000-0000-0000-0000-000000000100"))
  }

  func testDebouncing() throws {

    // Given - an arbitrator

    let arbitrator = Arbitrator<String>(debounceInterval: 1)

    var outcome: String?
    var count: Int = 0

    arbitrator.ruling = { coalesced in
      count += 1
      outcome = coalesced
    }

    // When - we discolse several input values
    // in quick succession

    withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      arbitrator.disclose("H")
      arbitrator.disclose("He")
      arbitrator.disclose("Hel")
      arbitrator.disclose("Hell")
      arbitrator.disclose("Hello")
    }

    // Then - only one ruling is provided

    XCTAssertTrue(count == 1)

    // And - the ruling is the last value disclosed

    XCTAssertEqual(outcome, "Hello")
  }
}


public final class Arbitrator<Value: Equatable> {

  @Dependency(\.continuousClock) var continuousClock

  private var currentTask: Task<Void, Never>?
  private var previousValue: Value?
  private let debounceInterval: TimeInterval

  public var ruling: @MainActor (Value) -> Void = { _ in }

  public init(debounceInterval: TimeInterval) {
    self.debounceInterval = debounceInterval
  }

  public func disclose(_ newValue: Value) {
    currentTask?.cancel()
    currentTask = Task { [weak self] in
      guard let self else { return }
      try? await continuousClock.sleep(for: .seconds(debounceInterval))
      if newValue != self.previousValue {
        await self.ruling(newValue)
        self.previousValue = newValue
      }
    }
  }
}
