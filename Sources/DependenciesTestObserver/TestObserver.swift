import IssueReporting
import XCTest

#if !_runtime(_ObjC)
  final class TestObserver: NSObject, XCTestObservation {
    private let resetCache: @convention(c) () -> Void
    internal init(_ resetCache: @convention(c) () -> Void) {
      self.resetCache = resetCache
    }
    public func testCaseWillStart(_ testCase: XCTestCase) {
      self.resetCache()
    }
  }
#endif

public func registerTestObserver(_ resetCache: @convention(c) () -> Void) {
  guard isTesting else { return }
  #if !_runtime(_ObjC)
    XCTestObservationCenter.shared.addTestObserver(TestObserver(resetCache))
  #endif
}
