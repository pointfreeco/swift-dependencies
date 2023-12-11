import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyEndpointMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      //isRecording: true,
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
    } diagnostics: {
      """

      """
    }fixes: {
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
            ╰─ 🛑 Default value required for non-throwing closure 'endpoint'
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
            ╰─ 🛑 Default value required for non-throwing closure 'endpoint'
               ✏️ Insert '= { _, _, _ in <#Bool#> }'
      }
      """
    }fixes: {
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

  func testSendableMethod() {
    assertMacro {
      """
      public struct Client {
        @DependencyEndpoint
        public var endpoint: @Sendable (_ id: Int) async -> Void
      }
      """
    } expansion: {
      """
      public struct Client {
        public var endpoint: @Sendable (_ id: Int) async -> Void {
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
          public func endpoint(id p0: Int) async -> Void {
          await self.endpoint(p0)
        }

        private var _endpoint: @Sendable (_ id: Int) async -> Void = { _ in
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
    assertMacro {
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

  func testEscapedIdentifier() {
    assertMacro {
      """
      @DependencyEndpoint
      var `return`: () throws -> Int
      """
    } expansion: {
      """
      var `return`: () throws -> Int {
          @storageRestrictions(initializes: _return)
          init(initialValue) {
              _return = initialValue
          }
          get {
              _return
          }
          set {
              _return = newValue
          }
      }

      private var _return: () throws -> Int = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'return'")
          throw DependenciesMacros.Unimplemented("return")
      }
      """
    }
  }

  func testEscapedIdentifier_ArgumentLabels() {
    assertMacro {
      """
      @DependencyEndpoint
      var `return`: (_ id: Int) throws -> Int
      """
    } expansion: {
      """
      var `return`: (_ id: Int) throws -> Int {
          @storageRestrictions(initializes: _return)
          init(initialValue) {
              _return = initialValue
          }
          get {
              _return
          }
          set {
              _return = newValue
          }
      }

      func `return`(id p0: Int) throws -> Int {
          try self.`return`(p0)
      }

      private var _return: (_ id: Int) throws -> Int = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'return'")
          throw DependenciesMacros.Unimplemented("return")
      }
      """
    }
  }

  func testNonClosureDefault() {
    assertMacro {
      """
      struct Foo {
        @DependencyEndpoint
        var bar: () -> Int = unimplemented()
      }
      """
    } diagnostics: {
      """
      struct Foo {
        @DependencyEndpoint
        var bar: () -> Int = unimplemented()
                             ┬──────────────
                             ├─ 🛑 '@DependencyEndpoint' default must be closure literal
                             ╰─ ⚠️ Do not use 'unimplemented' with '@DependencyEndpoint'; it is a replacement and implements the same runtime functionality as 'unimplemented' at compile time
      }
      """
    }
  }

  func testMultilineClosure() {
    assertMacro {
      """
      struct Blah {
        @DependencyEndpoint
        public var doAThing: (_ value: Int) -> String = { _ in
          "Hello, world"
        }
      }
      """
    } diagnostics: {
      """

      """
    }fixes: {
      """
      struct Blah {
        @DependencyEndpoint
        public var doAThing: (_ value: Int) -> String = { _ in
          "Hello, world"
        }
      }
      """
    } expansion: {
      """
      struct Blah {
        public var doAThing: (_ value: Int) -> String = { _ in
          "Hello, world"
        } {
          @storageRestrictions(initializes: _doAThing)
          init(initialValue) {
            _doAThing = initialValue
          }
          get {
            _doAThing
          }
          set {
            _doAThing = newValue
          }
        }

        public func doAThing(value p0: Int) -> String {
          self.doAThing(p0)
        }

        private var _doAThing: (_ value: Int) -> String = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'doAThing'")
          return "Hello, world"
          }
      }
      """
    }
  }

  func testInout() {
    assertMacro {
    """
    struct Blah {
      @DependencyEndpoint
      public var doAThing: (_ a: inout Int, _ b: Int, _ c: inout Bool) -> String = { _ in
        "Hello, world"
      }
    }
    """
    } diagnostics: {
      """

      """
    }fixes: {
      """
      struct Blah {
        @DependencyEndpoint
        public var doAThing: (_ a: inout Int, _ b: Int, _ c: inout Bool) -> String = { _ in
          "Hello, world"
        }
      }
      """
    } expansion: {
      """
      struct Blah {
        public var doAThing: (_ a: inout Int, _ b: Int, _ c: inout Bool) -> String = { _ in
          "Hello, world"
        } {
          @storageRestrictions(initializes: _doAThing)
          init(initialValue) {
            _doAThing = initialValue
          }
          get {
            _doAThing
          }
          set {
            _doAThing = newValue
          }
        }

        public func doAThing(a p0: inout Int, b p1: Int, c p2: inout Bool) -> String {
          self.doAThing(&p0, p1, &p2)
        }

        private var _doAThing: (_ a: inout Int, _ b: Int, _ c: inout Bool) -> String = { _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'doAThing'")
          return "Hello, world"
          }
      }
      """
    }
  }

  func testFatalError() {
    assertMacro {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { fatalError() }
        @DependencyEndpoint
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    } diagnostics: {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { fatalError() }
                            ┬            ────────────
                            ├─ ⚠️ Prefer to use a real default value rather than fatalError().

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return false, or if it returns an array, you can return [].
                            │  ✏️ Silence this warning by wrapping fatalError() in a synchronously executed closure, but we recommend against this.  │                       ╰─ ⚠️ Prefer to use a real default value rather than fatalError().

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return false, or if it returns an array, you can return [].
                               ✏️ Silence this warning by wrapping fatalError() in a synchronously executed closure, but we recommend against this.
        @DependencyEndpoint
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    }fixes: {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { fatalError() }
        @DependencyEndpoint
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    }expansion: {
      """
      struct Blah {
        public var foo: () -> String = { fatalError() }

        private var _foo: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'foo'")
          fatalError()
        }
        public var bar: () -> String = { fatalError("Goodbye") }

        private var _bar: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'bar'")
          fatalError("Goodbye")
        }
      }
      """
    }
  }

  func testFatalError_SilenceWarning() {
    assertMacro {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { { fatalError() }() }
        @DependencyEndpoint
        public var bar: () -> String = { { fatalError("Goodbye") }() }
      }
      """
    } diagnostics: {
      """

      """
    }fixes: {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { { fatalError() }() }
        @DependencyEndpoint
        public var bar: () -> String = { { fatalError("Goodbye") }() }
      }
      """
    } expansion: {
      """
      struct Blah {
        public var foo: () -> String = { { fatalError() }() } {
          @storageRestrictions(initializes: _foo)
          init(initialValue) {
            _foo = initialValue
          }
          get {
            _foo
          }
          set {
            _foo = newValue
          }
        }

        private var _foo: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'foo'")
          return {
            fatalError()
          }()
        }
        public var bar: () -> String = { { fatalError("Goodbye") }() } {
          @storageRestrictions(initializes: _bar)
          init(initialValue) {
            _bar = initialValue
          }
          get {
            _bar
          }
          set {
            _bar = newValue
          }
        }

        private var _bar: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'bar'")
          return {
            fatalError("Goodbye")
          }()
        }
      }
      """
    }
  }

  func testAutoclosure() {
    assertMacro {
      """
      struct Foo {
        @DependencyEndpoint
        var bar: (_ a: @autoclosure () -> Int, _ b: () -> Int, _ c: @autoclosure () -> Int) -> Void
      }
      """
    } expansion: {
      """
      struct Foo {
        var bar: (_ a: @autoclosure () -> Int, _ b: () -> Int, _ c: @autoclosure () -> Int) -> Void {
          @storageRestrictions(initializes: _bar)
          init(initialValue) {
            _bar = initialValue
          }
          get {
            _bar
          }
          set {
            _bar = newValue
          }
        }

        func bar(a p0: @autoclosure () -> Int, b p1: () -> Int, c p2: @autoclosure () -> Int) -> Void {
          self.bar(p0(), p1, p2())
        }

        private var _bar: (_ a: @autoclosure () -> Int, _ b: () -> Int, _ c: @autoclosure () -> Int) -> Void = { _, _, _ in
          XCTestDynamicOverlay.XCTFail("Unimplemented: 'bar'")
        }
      }
      """
    }
  }
}
