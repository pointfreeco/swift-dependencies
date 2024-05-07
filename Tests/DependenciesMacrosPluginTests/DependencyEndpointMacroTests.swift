import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class DependencyEndpointMacroTests: BaseTestCase {
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
      struct Client {
        var endpoint: () -> Bool {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          return false
        }
      }
      """#
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

      Defaults are required so that the macro can generate a default, "unimplemented" version of the dependency. The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.

      See the documentation for @DependencyClient for more information: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependenciesmacros/dependencyclient()#Restrictions
               ✏️ Insert '= { <#Bool#> }'
      }
      """
    }fixes: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Bool = { <#Bool#> }
      }
      """
    } expansion: {
      #"""
      struct Client {
        var endpoint: () -> Bool {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          return <#Bool#>
        }
      }
      """#
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

      Defaults are required so that the macro can generate a default, "unimplemented" version of the dependency. The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.

      See the documentation for @DependencyClient for more information: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependenciesmacros/dependencyclient()#Restrictions
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
      #"""
      struct Client {
        var endpoint: (Int, Bool, String) -> Bool {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          return <#Bool#>
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          throw DependenciesMacros.Unimplemented("endpoint")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).apiRequest'")
          throw DependenciesMacros.Unimplemented("apiRequest")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          return nil
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
          return nil
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).return'")
          throw DependenciesMacros.Unimplemented("return")
      }
      """#
    }
  }

  func testEscapedIdentifier_ArgumentLabels() {
    assertMacro {
      """
      @DependencyEndpoint
      var `return`: (_ id: Int) throws -> Int
      """
    } expansion: {
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).return'")
          throw DependenciesMacros.Unimplemented("return")
      }
      """#
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
                             ╰─ ⚠️ Do not use 'unimplemented' with '@DependencyEndpoint'; the '@DependencyEndpoint' macro already includes the behavior of 'unimplemented'.
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
    } expansion: {
      #"""
      struct Blah {
        public var doAThing: (_ value: Int) -> String {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).doAThing'")
          return "Hello, world"
          }
      }
      """#
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
    } expansion: {
      #"""
      struct Blah {
        public var doAThing: (_ a: inout Int, _ b: Int, _ c: inout Bool) -> String {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).doAThing'")
          return "Hello, world"
          }
      }
      """#
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
      #"""
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).bar'")
        }
      }
      """#
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
                            ├─ ⚠️ Prefer returning a default mock value over 'fatalError()' to avoid crashes in previews and tests.

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.
                            │  ✏️ Wrap in a synchronously executed closure to silence this warning
                            ╰─ ⚠️ Prefer returning a default mock value over 'fatalError()' to avoid crashes in previews and tests.

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.
                               ✏️ Wrap in a synchronously executed closure to silence this warning
        @DependencyEndpoint
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    } fixes: {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -{ fatalError() }() fatalError() }
        @DependencyEndpoint
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    } expansion: {
      #"""
      struct Blah {
        public var foo: () -> String = { fatalError() }

        private var _foo: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).foo'")
          fatalError()
        }
        public var bar: () -> String = { fatalError("Goodbye") }

        private var _bar: () -> String = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).bar'")
          fatalError("Goodbye")
        }
      }
      """#
    }
  }

  func testFatalError_SilenceWarning() {
    assertMacro {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> Void = { { fatalError() }() }
        @DependencyEndpoint
        public var bar: () -> String = { { fatalError("Goodbye") }() }
      }
      """
    } expansion: {
      #"""
      struct Blah {
        public var foo: () -> Void {
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

        private var _foo: () -> Void = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).foo'")
          return {
            fatalError()
          }()
        }
        public var bar: () -> String {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).bar'")
          return {
            fatalError("Goodbye")
          }()
        }
      }
      """#
    }
  }

  func testWillSet() {
    assertMacro {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () throws -> Void {
          willSet {
            print("!")
          }
        }
      }
      """
    } expansion: {
      #"""
      struct Blah {
        public var foo: () throws -> Void {
          willSet {
            print("!")
          }
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

        private var _foo: () throws -> Void = {
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).foo'")
          throw DependenciesMacros.Unimplemented("foo")
        } {
                willSet {
                    print("!")
                }
          }
      }
      """#
    }
  }
    
  func testAccessPackage() {
    assertMacro {
      """
      package struct Client {
        @DependencyEndpoint
        package var endpoint: () -> Void
      }
      """
    } expansion: {
      #"""
      package struct Client {
        package var endpoint: () -> Void {
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
          XCTestDynamicOverlay.XCTFail("Unimplemented: '\(Self.self).endpoint'")
        }
      }
      """#
    }
  }
}
