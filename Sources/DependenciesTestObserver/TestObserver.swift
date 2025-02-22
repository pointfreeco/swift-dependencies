import Foundation
import IssueReporting

#if canImport(XCTest)
  import XCTest
#endif

#if !_runtime(_ObjC)
  final class TestObserver: NSObject {
    private let resetCache: @convention(c) () -> Void
    internal init(_ resetCache: @convention(c) () -> Void) {
      self.resetCache = resetCache
    }
  }
  #if canImport(XCTest)
    extension TestObserver: XCTestObservation {
      public func testCaseWillStart(_ testCase: XCTestCase) {
        self.resetCache()
      }
    }
  #endif
#endif

public func registerTestObserver(_ resetCache: @convention(c) () -> Void) {
  guard isTesting else { return }
  #if !_runtime(_ObjC)
    XCTestObservationCenter.shared.addTestObserver(TestObserver(resetCache))
  #endif
}
