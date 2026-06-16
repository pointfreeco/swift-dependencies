import DependenciesMacrosPlugin
import MacroTesting
import SnapshotTesting
import XCTest

final class DependencyEntryMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      record: .failed,
      macros: [DependencyEntryMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testLiveValueAndTestValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(liveValue: Client.live)
        var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.DependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue static var liveValue = Client.live
          @DependenciesMacros._DependencyEntryDefaultValue static var testValue = Client.test
        }
      }
      """
    }
  }

  func testLiveValuePreviewValueAndTestValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(liveValue: Client.live, previewValue: Client.preview)
        var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.DependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue static var liveValue = Client.live
          @DependenciesMacros._DependencyEntryDefaultValue static var previewValue = Client.preview
          @DependenciesMacros._DependencyEntryDefaultValue static var testValue = Client.test
        }
      }
      """
    }
  }

  func testPreviewValueAndTestValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(previewValue: Client.preview)
        var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.TestDependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue static var previewValue = Client.preview
          @DependenciesMacros._DependencyEntryDefaultValue static var testValue = Client.test
        }
      }
      """
    }
  }

  func testTestValueOnly() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry
        var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.TestDependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue static var testValue = Client.test
        }
      }
      """
    }
  }

  func testWithTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(liveValue: Client.live)
        var client: Client = .test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client: Client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.DependencyKey {
          typealias Value = Client
          static var liveValue: Value {
            Client.live
          }
          static var testValue: Value {
            .test
          }
        }
      }
      """
    }
  }

  func testNotInExtension() {
    assertMacro {
      """
      struct Foo {
        @DependencyEntry
        var client = Client.test
      }
      """
    } diagnostics: {
      """
      struct Foo {
        @DependencyEntry
        ┬───────────────
        ╰─ 🛑 '@DependencyEntry' macro can only attach to 'var' declarations inside extensions of 'DependencyValues'
        var client = Client.test
      }
      """
    }
  }

  func testInWrongExtension() {
    assertMacro {
      """
      extension Foo {
        @DependencyEntry
        var client = Client.test
      }
      """
    } diagnostics: {
      """
      extension Foo {
        @DependencyEntry
        ┬───────────────
        ╰─ 🛑 '@DependencyEntry' macro can only attach to 'var' declarations inside extensions of 'DependencyValues'
        var client = Client.test
      }
      """
    }
  }

  func testMissingInitializer() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry
        var client: Client
      }
      """
    } diagnostics: {
      """
      extension DependencyValues {
        @DependencyEntry
        ╰─ 🛑 '@DependencyEntry' requires an initializer to define the property's test value, or a 'liveValue' argument to fall back on
        var client: Client
      }
      """
    }
  }

  func testMissingInitializerWithLiveValue() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(liveValue: Client.live)
        var client: Client
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        var client: Client {
          get {
            self[__Key_client.self]
          }
          set {
            self[__Key_client.self] = newValue
          }
          _modify {
            yield &self[__Key_client.self]
          }
        }

        private nonisolated enum __Key_client: Dependencies.DependencyKey {
          typealias Value = Client
          static var liveValue: Value {
            Client.live
          }
        }
      }
      """
    }
  }

  func testPublicKeyName() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry("APIClientKey", liveValue: Client.live)
        public var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var client {
          get {
            self[APIClientKey.self]
          }
          set {
            self[APIClientKey.self] = newValue
          }
          _modify {
            yield &self[APIClientKey.self]
          }
        }

        public nonisolated enum APIClientKey: Dependencies.DependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue public static var liveValue = Client.live
          @DependenciesMacros._DependencyEntryDefaultValue public static var testValue = Client.test
        }
      }
      """
    }
  }

  func testPackageKeyName() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry
        package var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        package var client {
          get {
            self[ClientKey.self]
          }
          set {
            self[ClientKey.self] = newValue
          }
          _modify {
            yield &self[ClientKey.self]
          }
        }

        package nonisolated enum ClientKey: Dependencies.TestDependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue package static var testValue = Client.test
        }
      }
      """
    }
  }

  func testPublicPropertyDerivesPublicKeyName() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry(liveValue: Client.live)
        public var client = Client.test
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var client {
          get {
            self[ClientKey.self]
          }
          set {
            self[ClientKey.self] = newValue
          }
          _modify {
            yield &self[ClientKey.self]
          }
        }

        public nonisolated enum ClientKey: Dependencies.DependencyKey {
          @DependenciesMacros._DependencyEntryDefaultValue public static var liveValue = Client.live
          @DependenciesMacros._DependencyEntryDefaultValue public static var testValue = Client.test
        }
      }
      """
    }
  }

  func testPublicPropertyWithExplicitKeyNameAndTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry("ExplicitAPIClientKey")
        public var client: any APIClient = MockAPIClient()
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var client: any APIClient {
          get {
            self[ExplicitAPIClientKey.self]
          }
          set {
            self[ExplicitAPIClientKey.self] = newValue
          }
          _modify {
            yield &self[ExplicitAPIClientKey.self]
          }
        }

        public nonisolated enum ExplicitAPIClientKey: Dependencies.TestDependencyKey {
          public typealias Value = any APIClient
          public static var testValue: Value {
            MockAPIClient()
          }
        }
      }
      """
    }
  }

  func testPublicPropertyWithImplicitKeyNameAndTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry
        public var client: MockAPIClient = MockAPIClient()
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var client: MockAPIClient {
          get {
            self[MockAPIClientKey.self]
          }
          set {
            self[MockAPIClientKey.self] = newValue
          }
          _modify {
            yield &self[MockAPIClientKey.self]
          }
        }

        public nonisolated enum MockAPIClientKey: Dependencies.TestDependencyKey {
          public typealias Value = MockAPIClient
          public static var testValue: Value {
            MockAPIClient()
          }
        }
      }
      """
    }
  }

  func testPublicPropertyWithImplicitKeyNameAndExistentialTypeAnnotation() {
    assertMacro {
      """
      extension DependencyValues {
        @DependencyEntry
        public var client: any APIClient = MockAPIClient()
      }
      """
    } expansion: {
      """
      extension DependencyValues {
        public var client: any APIClient {
          get {
            self[APIClientKey.self]
          }
          set {
            self[APIClientKey.self] = newValue
          }
          _modify {
            yield &self[APIClientKey.self]
          }
        }

        public nonisolated enum APIClientKey: Dependencies.TestDependencyKey {
          public typealias Value = any APIClient
          public static var testValue: Value {
            MockAPIClient()
          }
        }
      }
      """
    }
  }
}
