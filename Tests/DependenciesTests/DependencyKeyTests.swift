import Dependencies
import XCTest

final class DependencyKeyTests: XCTestCase {
  func testTestDependencyKey_ImplementOnlyTestValue() {
    enum Key: TestDependencyKey {
      static let testValue = 42
    }

    XCTAssertEqual(42, Key.previewValue)
    XCTAssertEqual(42, Key.testValue)
  }

  func testDependencyKeyCascading_ValueIsSelf_ImplementOnlyLiveValue() {
    struct Dependency: DependencyKey {
      let value: Int
      static let liveValue = Self(value: 42)
    }

    XCTAssertEqual(42, Dependency.liveValue.value)
    XCTAssertEqual(42, Dependency.previewValue.value)

    #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
      XCTExpectFailure {
        XCTAssertEqual(42, Dependency.testValue.value)
      } issueMatcher: { issue in
        issue.compactDescription == """
          failed - A dependency has no test implementation, but was accessed from a test context:

            Dependency:
              DependencyKeyTests.Dependency

          Dependencies registered with the library are not allowed to use their default, live \
          implementations when run from tests.

          To fix, override the dependency with a test value. If you are using the Composable \
          Architecture, mutate the 'dependencies' property on your 'TestStore'. Otherwise, use \
          'withDependencies' to define a scope for the override. If you'd like to provide a \
          default value for all tests, implement the 'testValue' requirement of the \
          'DependencyKey' protocol.
          """
      }
    #endif
  }

  func testDependencyKeyCascading_ImplementOnlyLiveValue() {
    enum Key: DependencyKey {
      static let liveValue = 42
    }

    XCTAssertEqual(42, Key.liveValue)
    XCTAssertEqual(42, Key.previewValue)

    #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
      XCTExpectFailure {
        XCTAssertEqual(42, Key.testValue)
      } issueMatcher: { issue in
        issue.compactDescription == """
          failed - A dependency has no test implementation, but was accessed from a test context:

            Key:
              DependencyKeyTests.Key
            Value:
              Int

          Dependencies registered with the library are not allowed to use their default, live \
          implementations when run from tests.

          To fix, override the dependency with a test value. If you are using the Composable \
          Architecture, mutate the 'dependencies' property on your 'TestStore'. Otherwise, use \
          'withDependencies' to define a scope for the override. If you'd like to provide a \
          default value for all tests, implement the 'testValue' requirement of the \
          'DependencyKey' protocol.
          """
      }
    #endif
  }

  func testDependencyKeyCascading_ImplementOnlyLiveAndPreviewValue() {
    enum Key: DependencyKey {
      static let liveValue = 42
      static let previewValue = 1729
    }

    XCTAssertEqual(42, Key.liveValue)
    XCTAssertEqual(1729, Key.previewValue)

    #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
      XCTExpectFailure {
        XCTAssertEqual(1729, Key.testValue)
      } issueMatcher: { issue in
        issue.compactDescription == """
          failed - A dependency has no test implementation, but was accessed from a test context:

            Key:
              DependencyKeyTests.Key
            Value:
              Int

          Dependencies registered with the library are not allowed to use their default, live \
          implementations when run from tests.

          To fix, override the dependency with a test value. If you are using the Composable \
          Architecture, mutate the 'dependencies' property on your 'TestStore'. Otherwise, use \
          'withDependencies' to define a scope for the override. If you'd like to provide a \
          default value for all tests, implement the 'testValue' requirement of the \
          'DependencyKey' protocol.
          """
      }
    #endif
  }

  func testDependencyOverridingProperty() {
    withDependencies {
      $0.numberClient.fetch = { 1729 }
    } operation: {
      @Dependency(\.numberClient) var numberClient: NumberClient
      XCTAssertEqual(numberClient.fetch(), 1729)
    }
  }

  func testDependencyKeyCascading_ImplementOnlyLive_Named() {
    #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
      withDependencies {
        $0.context = .test
      } operation: {
        @Dependency(\.missingTestDependency) var missingTestDependency: Int
        let line = #line - 1
        XCTExpectFailure {
          XCTAssertEqual(42, missingTestDependency)
        } issueMatcher: { issue in
          issue.compactDescription == """
            failed - @Dependency(\\.missingTestDependency) has no test implementation, but was \
            accessed from a test context:

              Location:
                DependenciesTests/DependencyKeyTests.swift:\(line)
              Key:
                LiveKey
              Value:
                Int

            Dependencies registered with the library are not allowed to use their default, live \
            implementations when run from tests.

            To fix, override 'missingTestDependency' with a test value. If you are using the \
            Composable Architecture, mutate the 'dependencies' property on your 'TestStore'. \
            Otherwise, use 'withDependencies' to define a scope for the override. If you'd \
            like to provide a default value for all tests, implement the 'testValue' requirement \
            of the 'DependencyKey' protocol.
            """
        }
      }
    #endif
  }

  func testDependencyKeyCascading_ImplementOnlyLive_NamedType() {
    #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
      withDependencies {
        $0.context = .test
      } operation: {
        @Dependency(LiveKey.self) var missingTestDependency: Int
        let line = #line - 1
        XCTExpectFailure {
          XCTAssertEqual(42, missingTestDependency)
        } issueMatcher: { issue in
          issue.compactDescription == """
            failed - @Dependency(LiveKey.self) has no test implementation, but was accessed from a \
            test context:

              Location:
                DependenciesTests/DependencyKeyTests.swift:\(line)
              Key:
                LiveKey
              Value:
                Int

            Dependencies registered with the library are not allowed to use their default, live \
            implementations when run from tests.

            To fix, override 'LiveKey.self' with a test value. If you are using the \
            Composable Architecture, mutate the 'dependencies' property on your 'TestStore'. \
            Otherwise, use 'withDependencies' to define a scope for the override. If you'd \
            like to provide a default value for all tests, implement the 'testValue' requirement \
            of the 'DependencyKey' protocol.
            """
        }
      }
    #endif
  }

  #if DEBUG && !os(Linux) && !os(WASI) && !os(Windows)
    func testShouldReportUnimplemented() {
      XCTExpectFailure {
        @Dependency(ReportIssueTestValueClient.self) var client
        _ = client
      } issueMatcher: { issue in
        issue.compactDescription == """
          failed - Override this dependency.
          """
      }
    }
  #endif

  func testShouldReportUnimplemented_OverrideDependency() {
    withDependencies {
      $0[ReportIssueTestValueClient.self] = ReportIssueTestValueClient()
    } operation: {
      @Dependency(ReportIssueTestValueClient.self) var client
      _ = client
    }
  }
}

private enum LiveKey: DependencyKey {
  static let liveValue = 42
}

extension DependencyValues {
  fileprivate var missingTestDependency: Int {
    get { self[LiveKey.self] }
    set { self[LiveKey.self] = newValue }
  }
}

private struct NumberClient: DependencyKey, Sendable {
  var fetch: @Sendable () -> Int
  static let liveValue = NumberClient { 42 }
}
extension DependencyValues {
  fileprivate var numberClient: NumberClient {
    get { self[NumberClient.self] }
    set { self[NumberClient.self] = newValue }
  }
}

struct ReportIssueTestValueClient: TestDependencyKey {
  static var testValue: ReportIssueTestValueClient {
    if shouldReportUnimplemented {
      reportIssue("Override this dependency.")
    }
    return ReportIssueTestValueClient()
  }
}
