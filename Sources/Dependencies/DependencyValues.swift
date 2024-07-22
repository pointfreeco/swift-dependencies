import Foundation
import XCTestDynamicOverlay

#if os(Windows)
  import WinSDK
#elseif os(Linux)
  import Glibc
#endif
// WASI does not support dynamic linking
#if os(WASI)
  import XCTest
#endif

#if _runtime(_ObjC)
  extension DispatchQueue {
    fileprivate static func mainASAP(execute block: @escaping @Sendable () -> Void) {
      if Thread.isMainThread {
        return block()
      } else {
        return Self.main.async(execute: block)
      }
    }
  }

  final class TestObserver: NSObject {}
#elseif os(WASI)
  final class TestObserver: NSObject, XCTestObservation {
    private let resetCache: @convention(c) () -> Void
    internal init(_ resetCache: @convention(c) () -> Void) {
      self.resetCache = resetCache
    }
    public func testCaseWillStart(_ testCase: XCTestCase) {
      self.resetCache()
    }
  }
#endif

/// A collection of dependencies that is globally available.
///
/// To access a particular dependency from the collection you use the ``Dependency`` property
/// wrapper:
///
/// ```swift
/// @Dependency(\.date) var date
/// // ...
/// let now = date.now
/// ```
///
/// To change a dependency for a well-defined scope you can use the
/// ``withDependencies(_:operation:)-4uz6m`` method:
///
/// ```swift
/// @Dependency(\.date) var date
/// let now = date.now
///
/// withDependencies {
///   $0.date.now = Date(timeIntervalSinceReferenceDate: 1234567890)
/// } operation: {
///   @Dependency(\.date.now) var now: Date
///   now.timeIntervalSinceReferenceDate  // 1234567890
/// }
/// ```
///
/// The dependencies will be changed for the lifetime of the `operation` scope, which can be
/// synchronous or asynchronous.
///
/// > Note: In general, the dependency remains changed only for the duration of the `operation`
/// > scope, and in particular if you capture the dependency in an escaping closure its changed
/// > value will not propagate. There are exceptions though, because the collection of dependencies
/// > held inside ``DependencyValues`` is a `@TaskLocal`. This means if you escape the `operation`
/// > closure with a `Task`, the dependency change will propagate:
/// >
/// > ```
/// > withDependencies {
/// >   $0.date.now = Date(timeIntervalSinceReferenceDate: 1234567890)
/// > } operation: {
/// >   @Dependency(\.date.now) var now: Date
/// >   now.timeIntervalSinceReferenceDate  // 1234567890
/// >   Task {
/// >     now.timeIntervalSinceReferenceDate  // 1234567890
/// >   }
/// > }
/// > ```
/// >
/// > Read the article <doc:Lifetimes> for more information.
///
/// To register a dependency inside ``DependencyValues``, you first create a type to conform to the
/// ``DependencyKey`` protocol in order to specify the ``DependencyKey/liveValue`` to use for the
/// dependency when run in simulators and on devices. It can even be private:
///
/// ```swift
/// private enum MyValueKey: DependencyKey {
///   static let liveValue = 42
/// }
/// ```
///
/// And then extend ``DependencyValues`` with a computed property that uses the key to read and
/// write to ``DependencyValues``:
///
/// ```swift
/// extension DependencyValues {
///   var myValue: Int {
///     get { self[MyValueKey.self] }
///     set { self[MyValueKey.self] = newValue }
///   }
/// }
/// ```
///
/// With those steps done you can access the dependency using the ``Dependency`` property wrapper:
///
/// ```swift
/// @Dependency(\.myValue) var myValue
/// myValue  // 42
/// ```
///
/// Read the article <doc:RegisteringDependencies> for more information.
public struct DependencyValues: Sendable {
  @TaskLocal public static var _current = Self()
  @TaskLocal static var isSetting = false
  @TaskLocal static var currentDependency = CurrentDependency()

  @_spi(Internals)
  public var cachedValues = CachedValues()
  private var storage: [ObjectIdentifier: any Sendable] = [:]

  /// Creates a dependency values instance.
  ///
  /// You don't typically create an instance of ``DependencyValues`` directly. Doing so would
  /// provide access only to default values. Instead, you rely on the dependency values' instance
  /// that the library manages for you when you use the ``Dependency`` property wrapper.
  public init() {
    #if _runtime(_ObjC)
      DispatchQueue.mainASAP {
        guard
          let XCTestObservation = objc_getProtocol("XCTestObservation"),
          let XCTestObservationCenter = NSClassFromString("XCTestObservationCenter"),
          let XCTestObservationCenter = XCTestObservationCenter as Any as? NSObjectProtocol,
          let XCTestObservationCenterShared =
            XCTestObservationCenter
            .perform(Selector(("sharedTestObservationCenter")))?
            .takeUnretainedValue()
        else { return }
        let testCaseWillStartBlock: @convention(block) (AnyObject) -> Void = { _ in
          DependencyValues._current.cachedValues.cached = [:]
        }
        let testCaseWillStartImp = imp_implementationWithBlock(testCaseWillStartBlock)
        class_addMethod(
          TestObserver.self, Selector(("testCaseWillStart:")), testCaseWillStartImp, nil)
        class_addProtocol(TestObserver.self, XCTestObservation)
        _ =
          XCTestObservationCenterShared
          .perform(Selector(("addTestObserver:")), with: TestObserver())
      }
    #elseif os(WASI)
      if _XCTIsTesting {
        XCTestObservationCenter.shared.addTestObserver(
          TestObserver({
            DependencyValues._current.cachedValues.cached = [:]
          }))
      }
    #else
      typealias RegisterTestObserver = @convention(thin) (@convention(c) () -> Void) -> Void
      var pRegisterTestObserver: RegisterTestObserver? = nil

      #if os(Windows)
        let hModule = LoadLibraryA("DependenciesTestObserver.dll")
        if let hModule,
          let pAddress = GetProcAddress(hModule, "$s24DependenciesTestObserver08registerbC0yyyyXCF")
        {
          pRegisterTestObserver = unsafeBitCast(pAddress, to: RegisterTestObserver.self)
        }
      #else
        let hModule: UnsafeMutableRawPointer? = dlopen("libDependenciesTestObserver.so", RTLD_NOW)
        if let hModule,
          let pAddress = dlsym(hModule, "$s24DependenciesTestObserver08registerbC0yyyyXCF")
        {
          pRegisterTestObserver = unsafeBitCast(pAddress, to: RegisterTestObserver.self)
        }
      #endif
      pRegisterTestObserver?({
        DependencyValues._current.cachedValues.cached = [:]
      })
    #endif
  }

  @_disfavoredOverload
  public subscript<Key: TestDependencyKey>(type: Key.Type) -> Key.Value {
    get { self[type] }
    set { self[type] = newValue }
  }

  /// Accesses the dependency value associated with a custom key.
  ///
  /// This subscript is typically only used when adding a computed property to ``DependencyValues``
  /// for registering custom dependencies:
  ///
  /// ```swift
  /// private struct MyDependencyKey: DependencyKey {
  ///   static let testValue = "Default value"
  /// }
  ///
  /// extension DependencyValues {
  ///   var myCustomValue: String {
  ///     get { self[MyDependencyKey.self] }
  ///     set { self[MyDependencyKey.self] = newValue }
  ///   }
  /// }
  /// ```
  ///
  /// You use custom dependency values the same way you use system-provided values, setting a value
  /// with ``withDependencies(_:operation:)-4uz6m``, and reading values with the ``Dependency``
  /// property wrapper.
  public subscript<Key: TestDependencyKey>(
    key: Key.Type,
    file file: StaticString = #file,
    function function: StaticString = #function,
    line line: UInt = #line
  ) -> Key.Value {
    get {
      guard let base = self.storage[ObjectIdentifier(key)], let dependency = base as? Key.Value
      else {
        let context =
          self.storage[ObjectIdentifier(DependencyContextKey.self)] as? DependencyContext
          ?? defaultContext

        switch context {
        case .live, .preview:
          return self.cachedValues.value(
            for: Key.self,
            context: context,
            file: file,
            function: function,
            line: line
          )
        case .test:
          var currentDependency = Self.currentDependency
          currentDependency.name = function
          return Self.$currentDependency.withValue(currentDependency) {
            self.cachedValues.value(
              for: Key.self,
              context: context,
              file: file,
              function: function,
              line: line
            )
          }
        }
      }
      return dependency
    }
    set {
      self.storage[ObjectIdentifier(key)] = newValue
    }
  }

  /// A collection of "live" dependencies.
  ///
  /// A useful starting point for working with live dependencies.
  ///
  /// For example, if you want to write a test that exercises your application's live dependencies
  /// (rather than its test dependencies, which is the default), you can override the test's
  /// dependencies with a live value:
  ///
  /// ```swift
  /// func testLiveDependencies() {
  ///   withDependencies { $0 = .live } operation: {
  ///     // Make assertions using live dependencies...
  ///   }
  /// }
  /// ```
  public static var live: Self {
    var values = Self()
    values.context = .live
    return values
  }

  /// A collection of "preview" dependencies.
  public static var preview: Self {
    var values = Self()
    values.context = .preview
    return values
  }

  /// A collection of "test" dependencies.
  public static var test: Self {
    var values = Self()
    values.context = .test
    return values
  }

  func merging(_ other: Self) -> Self {
    var values = self
    values.storage.merge(other.storage, uniquingKeysWith: { $1 })
    return values
  }
}

struct CurrentDependency {
  var name: StaticString?
  var file: StaticString?
  var fileID: StaticString?
  var line: UInt?
}

private let defaultContext: DependencyContext = {
  let environment = ProcessInfo.processInfo.environment
  var inferredContext: DependencyContext {
    if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      return .preview
    } else if _XCTIsTesting {
      return .test
    } else {
      return .live
    }
  }

  guard let value = environment["SWIFT_DEPENDENCIES_CONTEXT"]
  else { return inferredContext }

  switch value {
  case "live":
    return .live
  case "preview":
    return .preview
  case "test":
    return .test
  default:
    runtimeWarn(
      """
      An environment value for SWIFT_DEPENDENCIES_CONTEXT was provided but did not match "live",
      "preview", or "test".

          SWIFT_DEPENDENCIES_CONTEXT = \(value.debugDescription)
      """
    )
    return inferredContext
  }
}()

@_spi(Internals)
public final class CachedValues: @unchecked Sendable {
  public struct CacheKey: Hashable, Sendable {
    let id: ObjectIdentifier
    let context: DependencyContext
  }

  private let lock = NSRecursiveLock()
  public var cached = [CacheKey: any Sendable]()

  func value<Key: TestDependencyKey>(
    for key: Key.Type,
    context: DependencyContext,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) -> Key.Value {
    lock.lock()
    defer { lock.unlock() }

    return XCTFailContext.$current.withValue(XCTFailContext(file: file, line: line)) {
      let cacheKey = CacheKey(id: ObjectIdentifier(key), context: context)
      guard let base = cached[cacheKey], let value = base as? Key.Value
      else {
        let value: Key.Value?
        switch context {
        case .live:
          value = (key as? any DependencyKey.Type)?.liveValue as? Key.Value
        case .preview:
          value = Key.previewValue
        case .test:
          value = Key.testValue
        }

        guard let value
        else {
          #if DEBUG
          if !DependencyValues.isSetting {
            var dependencyDescription = ""
            if let fileID = DependencyValues.currentDependency.fileID,
               let line = DependencyValues.currentDependency.line
            {
              dependencyDescription.append(
                    """
                      Location:
                        \(fileID):\(line)

                    """
              )
            }
            dependencyDescription.append(
              Key.self == Key.Value.self
              ? """
                      Dependency:
                        \(typeName(Key.Value.self))
                    """
              : """
                      Key:
                        \(typeName(Key.self))
                      Value:
                        \(typeName(Key.Value.self))
                    """
            )

            var argument: String {
              "\(function)" == "subscript(_:)" ? "\(typeName(Key.self)).self" : "\\.\(function)"
            }

            runtimeWarn(
              """
              @Dependency(\(argument)) has no live implementation, but was accessed from a live \
              context.

              \(dependencyDescription)

              To fix you can do one of two things:

              * Conform '\(typeName(Key.self))' to the 'DependencyKey' protocol by providing \
              a live implementation of your dependency, and make sure that the conformance is \
              linked with this current application.

              * Override the implementation of '\(typeName(Key.self))' using 'withDependencies'. \
              This is typically done at the entry point of your application, but can be done \
              later too.
              """,
              file: DependencyValues.currentDependency.file ?? file,
              line: DependencyValues.currentDependency.line ?? line
            )
          }
          #endif
          let value = Key.testValue
          if !DependencyValues.isSetting {
            cached[cacheKey] = value
          }
          return value
        }

        cached[cacheKey] = value
        return value
      }

      return value
    }
  }
}
