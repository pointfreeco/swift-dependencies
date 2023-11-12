import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyEndpointMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      // isRecording: true,
      macros: [DependencyEndpointMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testBasics() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> Void = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testInitialValue() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Bool = { _ in false }
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Bool = { _ in false } {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> Bool = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          return false
        }
      }
      """
    }
  }

  func testMissingInitialValue() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Bool
      }
      """
    } diagnostics: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Bool
            ┬───────────────────
            ╰─ 🛑 Missing initial value for non-throwing 'endpoint'
               ✏️ Insert '= { <#Bool#> }'
      }
      """
    } fixes: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Bool = { <#Bool#> }
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Bool = { <#Bool#> } {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> Bool = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          return <#Bool#>
        }
      }
      """
    }
  }

  func testMissingInitialValue_Arguments() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: (Int, Bool, String) -> Bool
      }
      """
    } diagnostics: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: (Int, Bool, String) -> Bool
            ┬────────────────────────────────────
            ╰─ 🛑 Missing initial value for non-throwing 'endpoint'
               ✏️ Insert '= { _, _, _ in <#Bool#> }'
      }
      """
    } fixes: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: (Int, Bool, String) -> Bool = { _, _, _ in <#Bool#> }
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: (Int, Bool, String) -> Bool = { _, _, _ in <#Bool#> } {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: (Int, Bool, String) -> Bool = { _, _, _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          return <#Bool#>
        }
      }
      """
    }
  }

  func testMissingInitialValue_Throwing() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () throws -> Bool
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () throws -> Bool {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () throws -> Bool = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          throw DependenciesMacros.Unimplemented("endpoint")
        }
      }
      """
    }
  }

  func testTupleReturnValue() {
    assertMacro {
      """
      public struct ApiClient {
        @DependencyEndpoint
        public var apiRequest: @Sendable (ServerRoute.Api.Route) async throws -> (Data, URLResponse)
      }
      """
    } expansion: {
      """
      public struct ApiClient {
        public var apiRequest: @Sendable (ServerRoute.Api.Route) async throws -> (Data, URLResponse) {
          @storageRestrictions(initializes: _apiRequest)
          init(initialValue) {
            _apiRequest = initialValue
          }
          get {
            _apiRequest
          }
          set {
            _apiRequest = newValue
          }
        }

        private var _apiRequest: @Sendable (ServerRoute.Api.Route) async throws -> (Data, URLResponse) = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'apiRequest'")
          throw DependenciesMacros.Unimplemented("apiRequest")
        }
      }
      """
    }
  }

  func testVoidTupleReturnValue() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> ()
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> () {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> () = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testOptionalReturnValue() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Int?
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Int? {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> Int? = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          return nil
        }
      }
      """
    }
  }

  func testExplicitOptionalReturnValue() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Optional<Int>
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Optional<Int> {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: () -> Optional<Int> = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          return nil
        }
      }
      """
    }
  }

  func testSendableClosure() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: @Sendable (Int) -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: @Sendable (Int) -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        private var _endpoint: @Sendable (Int) -> Void = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testLabeledArguments() {
    assertMacro {
      """
      public struct Client {
        @DependencyEndpoint
        public var endpoint: @Sendable (String, _ id: Int, _ progress: Float) async -> Void
      }
      """
    } expansion: {
      """
      public struct Client {
        public var endpoint: @Sendable (String, _ id: Int, _ progress: Float) async -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        @Sendable
          public func endpoint(_ p0: String, id p1: Int, progress p2: Float) async -> Void {
          await self.endpoint(p0, p1, p2)
        }

        private var _endpoint: @Sendable (String, _ id: Int, _ progress: Float) async -> Void = { _, _, _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testMainActorSendableFunc() {
    assertMacro {
      """
      public struct Client {
        @DependencyEndpoint
        public var endpoint: @MainActor @Sendable (_ id: Int) async -> Void
      }
      """
    } expansion: {
      """
      public struct Client {
        public var endpoint: @MainActor @Sendable (_ id: Int) async -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        @MainActor
          public func endpoint(id p0: Int) async -> Void {
          await self.endpoint(p0)
        }

        private var _endpoint: @MainActor @Sendable (_ id: Int) async -> Void = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testMethodName() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint(method: "myEndpoint")
        var endpoint: (_ id: Int) -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: (_ id: Int) -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        func myEndpoint(id p0: Int) -> Void {
          self.endpoint(p0)
        }

        private var _endpoint: (_ id: Int) -> Void = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testMethodName_NoArguments() {
    assertMacro(record: true) {
      """
      struct Client {
        @DependencyEndpoint(method: "myEndpoint")
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: () -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        func myEndpoint() -> Void {
          self.endpoint()
        }

        private var _endpoint: () -> Void = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testInvalidName() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint(method: "~ok~")
        var endpoint: (_ id: Int) -> Void
      }
      """
    } diagnostics: {
      """
      struct Client {
        @DependencyEndpoint(method: "~ok~")
                                    ┬─────
                                    ╰─ 🛑 'method' must be a valid identifier
        var endpoint: (_ id: Int) -> Void
      }
      """
    }
  }

  func testKeywordName() {
    assertMacro {
      """
      struct Client {
        @DependencyEndpoint(method: "`class`")
        var endpoint: (_ id: Int) -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var endpoint: (_ id: Int) -> Void {
          @storageRestrictions(initializes: _endpoint)
          init(initialValue) {
            _endpoint = initialValue
          }
          get {
            _endpoint
          }
          set {
            _endpoint = newValue
          }
        }

        func `class`(id p0: Int) -> Void {
          self.endpoint(p0)
        }

        private var _endpoint: (_ id: Int) -> Void = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
        }
      }
      """
    }
  }

  func testNonStaticString() {
    assertMacro {
      #"""
      struct Client {
        @DependencyEndpoint(method: "\(Self.self)".lowercased())
        var endpoint: (_ id: Int) -> Void
      }
      """#
    } diagnostics: {
      #"""
      struct Client {
        @DependencyEndpoint(method: "\(Self.self)".lowercased())
                                    ┬──────────────────────────
                                    ╰─ 🛑 'method' must be a static string literal
        var endpoint: (_ id: Int) -> Void
      }
      """#
    }
  }
}
