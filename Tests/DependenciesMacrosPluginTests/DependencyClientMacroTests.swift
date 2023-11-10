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

  func testSendable() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        init(
          endpoint: @Sendable @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testOptional() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var name: String?
        var endpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        var name: String?
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        init(
          name: String? = nil,
          endpoint: @Sendable @escaping () -> Void
        ) {
          self.name = name
          self.endpoint = endpoint
        }

        init(
          name: String? = nil
        ) {
          self.name = name
        }
      }
      """
    }
  }

  func testComputedProperty() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Void

        var name: String {
          "Blob"
        }
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        var name: String {
          "Blob"
        }

        init(
          endpoint: @Sendable @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testLet_WithDefault() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        let id = UUID()
        var endpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        let id = UUID()
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        init(
          endpoint: @Sendable @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testLet_WithoutDefault() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        let id: UUID
        var endpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        let id: UUID
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        init(
          id: UUID,
          endpoint: @Sendable @escaping () -> Void
        ) {
          self.id = id
          self.endpoint = endpoint
        }

        init(
          id: UUID
        ) {
          self.id = id
        }
      }
      """
    }
  }

  func testUninitializedEndpointDiagnostic() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Int
      }
      """
    } diagnostics: {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Int
            ┬────────────────────────────
            ╰─ 🛑 Missing initial value for non-throwing 'endpoint'
               ✏️ Insert '= { <#Int#> }'
      }
      """
    } fixes: {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Int = { <#Int#> }
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () -> Int = { <#Int#> }

        init(
          endpoint: @Sendable @escaping () -> Int
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
