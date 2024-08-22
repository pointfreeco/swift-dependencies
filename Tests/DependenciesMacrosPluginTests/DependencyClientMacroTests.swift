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

  func testLetBinding() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var endpoint: () -> Void
        let config: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Void
        let config: () -> Void

        init(
          endpoint: @escaping () -> Void,
          config: @escaping () -> Void
        ) {
          self.endpoint = endpoint
          self.config = config
        }

        init(
          config: @escaping () -> Void
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testBooleanLiteral() {
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

  func testFloatLiteral() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config = 1.0
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var config = 1.0
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          config: Swift.Double = 1.0,
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        init(
          config: Swift.Double = 1.0
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testIntegerLiteral() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config = 1
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var config = 1
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          config: Swift.Int = 1,
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        init(
          config: Swift.Int = 1
        ) {
          self.config = config
        }
      }
      """
    }
  }

  func testStringLiteral() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config = "Blob"
        var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      struct Client {
        var config = "Blob"
        @DependencyEndpoint
        var endpoint: () -> Void

        init(
          config: Swift.String = "Blob",
          endpoint: @escaping () -> Void
        ) {
          self.config = config
          self.endpoint = endpoint
        }

        init(
          config: Swift.String = "Blob"
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

  func testStaticVar() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var config: () -> Void
        static var value = Client()
      }
      """
    } expansion: {
      """
      struct Client {
        @DependencyEndpoint
        var config: () -> Void
        static var value = Client()

        init(
          config: @escaping () -> Void
        ) {
          self.config = config
        }

        init() {
        }
      }
      """
    }
  }

  func testDefaultValue() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var endpoint: () -> Int = { 42 }
      }
      """
    } expansion: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Int = { 42 }

        init(
          endpoint: @escaping () -> Int
        ) {
          self.endpoint = endpoint
        }

        init() {
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

  func testPackage() {
    assertMacro {
      """
      @DependencyClient
      package struct Client {
        package var endpoint: () -> Void
      }
      """
    } expansion: {
      """
      package struct Client {
        @DependencyEndpoint
        package var endpoint: () -> Void

        package init(
          endpoint: @escaping () -> Void
        ) {
          self.endpoint = endpoint
        }

        package init() {
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

  func testComputedPropertyGet() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () -> Void

        var name: String {
          get {
            "Blob"
          }
        }
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        var name: String {
          get {
            "Blob"
          }
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

  func testComputedPropertyWillSet() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        var endpoint: @Sendable () throws -> Void {
          willSet {
            print("!")
          }
        }
      }
      """
    } expansion: {
      """
      struct Client: Sendable {
        @DependencyEndpoint
        var endpoint: @Sendable () throws -> Void {
          willSet {
            print("!")
          }
        }

        init(
          endpoint: @Sendable @escaping () throws -> Void
        ) {
          self.endpoint = endpoint
        }

        init() {
        }
      }
      """
    }
  }

  func testWithDependencyEndpointIgnored() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {

        let id = UUID()
        var endpoint: @Sendable () -> Void

        @DependencyEndpointIgnored
        var ignoredVar: @Sendable () -> Void
      }
      """
    } expansion: {
      """
      struct Client: Sendable {

        let id = UUID()
        @DependencyEndpoint
        var endpoint: @Sendable () -> Void

        @DependencyEndpointIgnored
        var ignoredVar: @Sendable () -> Void

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

  func testWithDependencyMacro() {
    assertMacro {
      """
      @DependencyClient
      struct Client: Sendable {
        @Dependency(TypedDependency.self) var typedDependency
        @Dependency(TypedDependency.self) var typedDependency: TypedDependency
        @Dependency(\\.dependency1) var dependency1
        @Dependency(\\.dependency2) var dependency2: DependencyTwo

        let id = UUID()
        var endpoint: @Sendable () -> Void
      }
      """
    } expansion: {
      #"""
      struct Client: Sendable {
        @Dependency(TypedDependency.self) var typedDependency
        @Dependency(TypedDependency.self) var typedDependency: TypedDependency
        @Dependency(\.dependency1) var dependency1
        @Dependency(\.dependency2) var dependency2: DependencyTwo

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
      """#
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
            ╰─ 🛑 Default value required for non-throwing closure 'endpoint'

      Defaults are required so that the macro can generate a default, "unimplemented" version of the dependency via 'Client()'. The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.

      See the documentation for @DependencyClient for more information: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependenciesmacros/dependencyclient()#Restrictions
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

  func testDefault() {
    assertMacro(
      [
        DependencyClientMacro.self,
        DependencyEndpointMacro.self,
      ]
      , record: .all
    ) {
      """
      @DependencyClient
      struct Client {
        var fetch: (_ id: Int) -> Int = { 42 }
      }
      """
    } expansion: {
      #"""
      struct Client {
        @available(iOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(macOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(tvOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(watchOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.")
        var fetch: (_ id: Int) -> Int = { 42 }

        func fetch(id p0: Int) -> Int {
          self.fetch(p0)
        }

        init(
          fetch: @escaping (_ id: Int) -> Int = {
            IssueReporting.reportIssue("Unimplemented: '\(Self.self).fetch'")
            return 42
          }
        ) {
          self.fetch = fetch
        }
      }
      """#
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
      #"""
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

        func fetch(id p0: Int) throws -> String {
          try self.fetch(p0)
        }

        @available(iOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(macOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(tvOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(watchOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") private var _fetch: (_ id: Int) throws -> String = { _ in
          IssueReporting.reportIssue("Unimplemented: '\(Self.self).fetch'")
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
      """#
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
      #"""
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

        @available(iOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(macOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(tvOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") @available(watchOS, deprecated: 9999, message: "This property has a method equivalent that is preferred for autocomplete via this deprecation. It is perfectly fine to use for overriding and accessing via '@Dependency'.") private var _fetch: (_ id: Int) throws -> String = { _ in
          IssueReporting.reportIssue("Unimplemented: '\(Self.self).fetch'")
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
      """#
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
      #"""
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
          IssueReporting.reportIssue("Unimplemented: '\(Self.self).fetch'")
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
      """#
    }
  }

  func testMissingTypeAnnotation() {
    assertMacro {
      """
      @DependencyClient
      struct Client {
        var endpoint: () -> Void
        var value = Value()
      }
      """
    } diagnostics: {
      """
      @DependencyClient
      struct Client {
        var endpoint: () -> Void
        var value = Value()
            ┬──────────────
            ╰─ 🛑 '@DependencyClient' requires 'value' to have a type annotation in order to generate a memberwise initializer
               ✏️ Insert ': <#Type#>'
      }
      """
    } fixes: {
      """
      @DependencyClient
      struct Client {
        var endpoint: () -> Void
        var value: <#Type#> = Value()
      }
      """
    } expansion: {
      """
      struct Client {
        @DependencyEndpoint
        var endpoint: () -> Void
        var value: <#Type#> = Value()

        init(
          endpoint: @escaping () -> Void,
          value: <#Type#> = Value()
        ) {
          self.endpoint = endpoint
          self.value = value
        }

        init(
          value: <#Type#> = Value()
        ) {
          self.value = value
        }
      }
      """
    }
  }

  func testNonClosureDefault() {
    assertMacro {
      """
      @DependencyClient
      struct Foo {
        var bar: () -> Int = unimplemented()
      }
      """
    } diagnostics: {
      """
      @DependencyClient
      struct Foo {
        var bar: () -> Int = unimplemented()
                             ┬──────────────
                             ├─ 🛑 '@DependencyClient' default must be closure literal
                             ╰─ ⚠️ Do not use 'unimplemented' with '@DependencyClient'; the '@DependencyClient' macro already includes the behavior of 'unimplemented'.
      }
      """
    }
  }

  func testFatalError() {
    assertMacro {
      """
      @DependencyClient
      struct Blah {
        public var foo: () -> String = { fatalError() }
        public var bar: () -> String = { fatalError("Goodbye") }
      }
      """
    } diagnostics: {
      """
      @DependencyClient
      struct Blah {
        public var foo: () -> String = { fatalError() }
                                         ┬───────────
                                         ╰─ ⚠️ Prefer returning a default mock value over 'fatalError()' to avoid crashes in previews and tests.

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.
                                            ✏️ Wrap in a synchronously executed closure to silence this warning
        public var bar: () -> String = { fatalError("Goodbye") }
                                         ┬────────────────────
                                         ╰─ ⚠️ Prefer returning a default mock value over 'fatalError()' to avoid crashes in previews and tests.

      The default value can be anything and does not need to signify a real value. For example, if the endpoint returns a boolean, you can return 'false', or if it returns an array, you can return '[]'.
                                            ✏️ Wrap in a synchronously executed closure to silence this warning
      }
      """
    } fixes: {
      """
      @DependencyClient
      struct Blah {
        public var foo: () -> String = { { fatalError() }() }
        public var bar: () -> String = { { fatalError("Goodbye") }() }
      }
      """
    } expansion: {
      """
      struct Blah {
        @DependencyEndpoint
        public var foo: () -> String = { { fatalError() }() }
        @DependencyEndpoint
        public var bar: () -> String = { { fatalError("Goodbye") }() }

        public init(
          foo: @escaping () -> String,
          bar: @escaping () -> String
        ) {
          self.foo = foo
          self.bar = bar
        }

        public init() {
        }
      }
      """
    }
  }
}
