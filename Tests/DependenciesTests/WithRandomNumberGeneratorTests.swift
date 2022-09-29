import Dependencies
import XCTest
import XCTestDynamicOverlay

final class WithRandomNumberGeneratorDependencyTests: XCTestCase {
  @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

  func testWithRandomNumberGenerator() {
    withDependencies { $0.withRandomNumberGenerator = .init(LCRNG(seed: 0)) } operation: {
      self.withRandomNumberGenerator {
        XCTAssertEqual(.random(in: 1...6, using: &$0), 1)
        XCTAssertEqual(.random(in: 1...6, using: &$0), 3)
        XCTAssertEqual(.random(in: 1...6, using: &$0), 6)
        XCTAssertEqual(.random(in: 1...6, using: &$0), 3)
        XCTAssertEqual(.random(in: 1...6, using: &$0), 2)
      }
    }
  }
}

private struct LCRNG: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}
