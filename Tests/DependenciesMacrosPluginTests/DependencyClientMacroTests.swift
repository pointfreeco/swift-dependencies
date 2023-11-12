import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyClientMacroTests: BaseTestCase {
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

  func testIgnored() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Void
        @DependencyIgnored
        var nonEndpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void
        @DependencyIgnored
        var nonEndpoint: @Sendable () -> Void

        init(
          endpoint: @Sendable @escaping () -> Void,
          nonEndpoint: @Sendable @escaping () -> Void
        ) {
          self.endpoint = endpoint
          self.nonEndpoint = nonEndpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testAvailability() {
    assertMacro([DependencyClientMacro.self, DependencyEndpointMacro.self]) {
      """
      @DependencyClient
      struct Client {
        var fetch: (_ id: Int) throws -> String
      }
      """
    } expansion: {
      """
      struct Client {@available(iOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(macOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(tvOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(watchOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.")
        var fetch: (_ id: Int) throws -> String {
          @storageRestrictions(initializes: _fetch)
          init(initialValue) {
            _fetch = initialValue
          }
          get {
            _fetch
          }
          set {
            _fetch = newValue
          }
        }

        func fetch(id p0: Int) throws -> String {
          try self.fetch(p0)
        }

        private var _fetch: (_ id: Int) throws -> String = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'fetch'")
          throw DependenciesMacros.Unimplemented("fetch")
        }

        init(
          fetch: @escaping (_ id: Int) throws -> String
        ) {
          self.fetch = fetch
        }

        init() {
        }
      }
      """
    }
  }


  func testAvailability_WithDependencyEndpoint() {
    assertMacro([DependencyClientMacro.self, DependencyEndpointMacro.self]) {
      """
      @DependencyClient
      struct Client {
        @DependencyEndpoint(method: "foo")
        var fetch: (_ id: Int) throws -> String
      }
      """
    } expansion: {
      """
      struct Client {
        @available(iOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(macOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(tvOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(watchOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.")
        var fetch: (_ id: Int) throws -> String {
          @storageRestrictions(initializes: _fetch)
          init(initialValue) {
            _fetch = initialValue
          }
          get {
            _fetch
          }
          set {
            _fetch = newValue
          }
        }

        func foo(id p0: Int) throws -> String {
          try self.fetch(p0)
        }

        private var _fetch: (_ id: Int) throws -> String = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'fetch'")
          throw DependenciesMacros.Unimplemented("fetch")
        }

        init(
          fetch: @escaping (_ id: Int) throws -> String
        ) {
          self.fetch = fetch
        }

        init() {
        }
      }
      """
    }
  }

  func testAvailability_NoMethod() {
    assertMacro([DependencyClientMacro.self, DependencyEndpointMacro.self]) {
      """
      @DependencyClient
      struct Client {
        var fetch: (Int) throws -> String
      }
      """
    } expansion: {
      """
      struct Client {
        var fetch: (Int) throws -> String {
          @storageRestrictions(initializes: _fetch)
          init(initialValue) {
            _fetch = initialValue
          }
          get {
            _fetch
          }
          set {
            _fetch = newValue
          }
        }

        private var _fetch: (Int) throws -> String = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'fetch'")
          throw DependenciesMacros.Unimplemented("fetch")
        }

        init(
          fetch: @escaping (Int) throws -> String
        ) {
          self.fetch = fetch
        }

        init() {
        }
      }
      """
    }
  }
}
