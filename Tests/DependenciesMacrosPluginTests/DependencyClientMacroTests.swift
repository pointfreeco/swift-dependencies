import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyClientMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      // isRecording: true,
      macros: [DependencyClientMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testBasics() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config: Bool = false
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var config: Bool = false
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          config: Bool = false,
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        init(
          config: Bool = false
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testEndpointMacroAlreadyApplied() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        @DependencyEndpoint var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        @DependencyEndpoint var endpoint: () -> Void

        init(
          endpoint: @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testLiteral() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config = false
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var config = false
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          config: Swift.Bool = false,
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        init(
          config: Swift.Bool = false
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testPrivate_WithoutDefault() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        private var config: Bool
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        private var config: Bool
        @DependencyEndpoint
        var endpoint: () -> Void

        private init(
          config: Bool,
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        private init(
          config: Bool
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testPrivate_WithDefault() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        private var config: Bool = false
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        private var config: Bool = false
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          endpoint: @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testPublic_PublicProperties() {
    assertMacro {
      """
      @DependencyClient
      public struct Client {
        private var config: Bool = false
        public var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      public struct Client {
        private var config: Bool = false
        @DependencyEndpoint
        public var endpoint: () -> Void

        public init(
          endpoint: @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        public init() {
        }
      }
      """
    }
  }

  func testPublic_InternalProperties() {
    assertMacro {
      """
      @DependencyClient
      public struct Client {
        private var config: Bool = false
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      public struct Client {
        private var config: Bool = false
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          endpoint: @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }
}
