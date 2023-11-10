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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> Void>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> Bool>(
          initialValue: { _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            return false
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> Bool>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            return <#Bool#>
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<(Int, Bool, String) -> Bool>(
          initialValue: { _, _, _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            return <#Bool#>
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return newValue($0, $1, $2)
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() throws -> Bool>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            throw DependenciesMacros.Unimplemented("endpoint")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return try newValue()
          }
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
          @storageRestrictions(initializes: $apiRequest)
          init(initialValue) {
            $apiRequest = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $apiRequest.rawValue
          }
          set {
            $apiRequest.rawValue = newValue
          }
        }

        public var $apiRequest = DependenciesMacros.Endpoint<@Sendable (ServerRoute.Api.Route) async throws -> (Data, URLResponse)>(
          initialValue: { _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'apiRequest'")
            throw DependenciesMacros.Unimplemented("apiRequest")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "apiRequest",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return try await newValue($0)
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> ()>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> Int?>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            return nil
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<() -> Optional<Int>>(
          initialValue: {
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
            return nil
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            return newValue()
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        var $endpoint = DependenciesMacros.Endpoint<@Sendable (Int) -> Void>(
          initialValue: { _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            newValue($0)
          }
o        }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        @Sendable
          public func endpoint(_ p0: String, id p1: Int, progress p2: Float) async -> Void {
          await self.endpoint(p0, p1, p2)
        }

        public var $endpoint = DependenciesMacros.Endpoint<@Sendable (String, _ id: Int, _ progress: Float) async -> Void>(
          initialValue: { _, _, _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            await newValue($0, $1, $2)
          }
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
          @storageRestrictions(initializes: $endpoint)
          init(initialValue) {
            $endpoint = DependenciesMacros.Endpoint(initialValue: initialValue)
          }
          get {
            $endpoint.rawValue
          }
          set {
            $endpoint.rawValue = newValue
          }
        }

        @MainActor
          public func endpoint(id p0: Int) async -> Void {
          await self.endpoint(p0)
        }

        public var $endpoint = DependenciesMacros.Endpoint<@MainActor @Sendable (_ id: Int) async -> Void>(
          initialValue: { _ in
            XCTestDynamicOverlay.XCTFail("Unimplemented: 'endpoint'")
          }
        ) { configuration, newValue in
          let expectation = DependenciesMacros._$Expectation(
            "endpoint",
            configuration: configuration
          )
          return {
            expectation.fulfill()
            await newValue($0)
          }
        }
      }
      """
    }
  }
}
