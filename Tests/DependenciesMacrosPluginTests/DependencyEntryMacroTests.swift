import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyEntryMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      record: .failed,
      macros: [DependencyEntryMacro.self]
    ) {
      super.invokeTest()
    }
  }

  // MARK: - .live mode (implementation module)

  func testLiveBasicExpansion() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var router: MyRouter = MyRouter()
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var router: MyRouter {
          get { self[__Key_router.self] }
          set { self[__Key_router.self] = newValue }
        }

        public enum __Key_router: DependencyKey {
          public typealias Value = MyRouter
          public static let liveValue: Value = MyRouter()
        }
      }
      """
    }
  }

  func testLiveWithAccessLevel() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.live) public var analytics: AnalyticsClient = AnalyticsClient()
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var analytics: AnalyticsClient {
          get { self[__Key_analytics.self] }
          set { self[__Key_analytics.self] = newValue }
        }

        public enum __Key_analytics: DependencyKey {
          public typealias Value = AnalyticsClient
          public static let liveValue: Value = AnalyticsClient()
        }
      }
      """
    }
  }

  func testLiveSimpleValueType() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var itemCount: Int = 0
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var itemCount: Int {
          get { self[__Key_itemCount.self] }
          set { self[__Key_itemCount.self] = newValue }
        }

        public enum __Key_itemCount: DependencyKey {
          public typealias Value = Int
          public static let liveValue: Value = 0
        }
      }
      """
    }
  }

  // MARK: - .test mode (interface module)

  func testTestModeExpansion() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var router: MyRouter = .unimplemented
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var router: MyRouter {
          get { self[__Key_router.self] }
          set { self[__Key_router.self] = newValue }
        }

        public enum __Key_router: TestDependencyKey {
          public typealias Value = MyRouter
          public static let testValue: Value = .unimplemented
        }
      }
      """
    }
  }

  func testTestModeWithAccessLevel() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.test) public var analytics: AnalyticsClient = .unimplemented
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var analytics: AnalyticsClient {
          get { self[__Key_analytics.self] }
          set { self[__Key_analytics.self] = newValue }
        }

        public enum __Key_analytics: TestDependencyKey {
          public typealias Value = AnalyticsClient
          public static let testValue: Value = .unimplemented
        }
      }
      """
    }
  }

  func testTestModeSimpleValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var title: String = ""
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var title: String {
          get { self[__Key_title.self] }
          set { self[__Key_title.self] = newValue }
        }

        public enum __Key_title: TestDependencyKey {
          public typealias Value = String
          public static let testValue: Value = ""
        }
      }
      """
    }
  }

  // MARK: - Error cases

  func testMissingTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var router = MyRouter()
      }
      """
    } diagnostics: {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var router = MyRouter()
        ┬──────────────────────
        ╰─ 🛑 '@DependencyEntry' requires an explicit type annotation.

           Provide the type explicitly:
             @DependencyEntry(.live) var router: MyRouter = MyRouter()
      }
      """
    }
  }

  func testTestModeMissingTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var router = MyRouter.unimplemented
      }
      """
    } diagnostics: {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var router = MyRouter.unimplemented
        ┬──────────────────────
        ╰─ 🛑 '@DependencyEntry' requires an explicit type annotation.

           Provide the type explicitly:
             @DependencyEntry(.test) var router: MyRouter = .unimplemented
      }
      """
    }
  }

  func testLiveMissingDefaultValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var router: MyRouter
      }
      """
    } diagnostics: {
      """
      extension DependencyValues {
        @DependencyEntry(.live) var router: MyRouter
        ┬──────────────────────
        ╰─ 🛑 '@DependencyEntry' requires a default value.

           Provide a default value:
             @DependencyEntry(.live) var router: MyRouter = MyRouter()
      }
      """
    }
  }

  func testTestModeMissingDefaultValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var router: MyRouter
      }
      """
    } diagnostics: {
      """
      extension DependencyValues {
        @DependencyEntry(.test) var router: MyRouter
        ┬──────────────────────
        ╰─ 🛑 '@DependencyEntry' requires a default value.

           Provide a default value:
             @DependencyEntry(.test) var router: MyRouter = .unimplemented
      }
      """
    }
  }
}
