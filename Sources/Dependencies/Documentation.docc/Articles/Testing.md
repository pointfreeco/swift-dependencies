# Testing

One of the main reasons to control dependencies is to allow for easier testing. Learn some tips and 
tricks for writing better tests with the library.

## Overview

In the article <doc:LivePreviewTest> you learned how to define a ``TestDependencyKey/testValue``
when registering your dependencies, which will be automatically used during tests. In this article
we cover more detailed information about how to actually write tests with overridden dependencies,
as well as some tips and gotchas to keep in mind.

* [Swift's native Testing framework](#Swifts-native-Testing-framework)
* [Xcode's XCTest framework](#Xcodes-XCTest-framework)
* [Changing dependencies during tests](#Changing-dependencies-during-tests)
* [Testing gotchas](#Testing-gotchas)
  * [Testing host application](#Testing-host-application)
  * [Statically linking your tests target to Dependencies](#Statically-linking-your-tests-target-to-Dependencies)
  * [Test case leakage](#Test-case-leakage)
  * [Static @Dependency](#Static-Dependency)
  * [Parameterized and repeated @Test runs](#Parameterized-and-repeated-Test-runs)

## Swift's native Testing framework

This library has full support for Swift's native Testing framework, in addition to Xcode's XCTest
framework. It even works with in process concurrent tests without tests bleeding over to other 
tests.

The most direct way to override dependencies in a test is to simply wrap the entire test function
in ``withDependencies(_:operation:)`` in order to override the dependencies for the duration of that
test:

```swift
@Test func basics() {
  withDependencies {
    $0.uuid = .incrementing
  } operation: {
    let model = FeatureModel()
    // Invoke methods on 'model' and make assertions
  }
}
```

The library also ships with test traits that can help allivate the nesting incurred by 
``withDependencies(_:operation:)``. In order to get access to the test traits you must link the
DependenciesTestSupport library to your test target, after which you can do the following:

```swift
@Test(.dependency(\.uuid, .incrementing)) 
func basics() {
  let model = FeatureModel()
  // Invoke methods on 'model' and make assertions
}
```

> Important: Make sure to link DependenciesTestSupport only to your test targets and never your 
> app targets. Linking that library to an app target will cause the project to fail to compile.

It is also possible to override dependencies for an entire `@Suite` using a suite trait:

```swift
@Suite(.dependency(\.uuid, .incrementing))
struct MySuite {
  @Test func basics() {
    let model = FeatureModel()
    // Invoke methods on 'model' and make assertions
  }
}
```

If you need to override multiple dependencies you can do so using the `.dependencies` test trait:

```swift
@Suite(.dependencies {
  $0.date.now = Date(timeIntervalSince1970:12324567890)
  $0.uuid = .incrementing
})
struct MySuite {
  @Test func basics() {
    let model = FeatureModel()
    // Invoke methods on 'model' and make assertions
  }
}
```

Because tests in Swift's native Testing framework run in parallel and in process, it is possible
for multiple tests running to access the same dependency. This can be troublesome if those 
dependencies are stateful, making it possible for one test to make changes to a dependency that
another test sees. This will cause mysterious test failures and the type of test failure you get
may even depend on the order the tests ran.

To properly handle this we recommend having a "base suite" that all of your tests and suites are
nested inside. That will allow you to provide a fresh set of dependencies to each test, and it will
not be possible for changes in one test to bleed over to another test.

To do this, simply define a `@Suite` and use the `.dependencies` trait:

```swift
@Suite(.dependencies) struct BaseSuite {}
```

This type does not need to have anything in its body, and the `.dependencies` trait is responsible
for giving each test in the suite its own scratchpad of dependencies.

Then nest all of your `@Suite`s and `@Test`s in this type:

```swift
extension BaseSuite {
  @Suite struct FeatureTests {
    @Test func basics() {
      // ...  
    }
  }
}
```

This will allow all tests to run in parallel and in process without them affecting each other.

## Xcode's XCTest framework

This library also works with Xcode's testing framework, known as XCTest. Just as with Swift's 
Testing framework, one can override dependencies for a test by wrapping the body of a test in
``withDependencies(_:operation:)``:

```swift
func testBasics() {
  withDependencies {
    $0.uuid = .incrementing
  } operation: {
    let model = FeatureModel()
    // Invoke methods on 'model' and make assertions
  }
}
```

XCTest does not support traits, and so it is not possible to override dependencies on a per-test
basis without incurring the indentation of ``withDependencies(_:operation:)``. However, you can
override all dependencies for an entire test case by implementing the `invokeTest` method:

```swift
class FeatureTests: XCTestCase {
  override func invokeTest() {
    withDependencies { 
      $0.uuid = .incrementing
    } operation: {
      super.invokeTest()
    }
  }

  func testBasics() {
    // Test has 'uuid' dependency overridden.
  }
}
```

## Changing dependencies during tests

While it is most common to set up all dependencies at the beginning of a test and then make 
assertions, sometimes it is necessary to also change the dependencies in the middle of a test.
This can be very handy for modeling test flows in which a dependency is in a failure state at
first, but then later becomes successful. To do this one can simply use 
``withDependencies(_:operation:)`` again inside the body of your test.

For example, suppose we have a login feature such that if you try logging in and an error is thrown
causing a message to appear. But then later, if login succeeds that message goes away. We can
test that entire flow, from end-to-end, but starting the API client dependency in a state where
login fails, and then later change the dependency so that it succeeds using 
``withDependencies(_:operation:)``:

```swift
@Test(.dependency(\.apiClient.login, { _, _ in throw LoginFailure() }))
func retryFlow() async {
  let model = LoginModel()
  await model.loginButtonTapped()
  #expect(model.errorMessage == "We could not log you in. Please try again")

  withDependencies {
    $0.apiClient.login = { email, password in 
      LoginResponse(user: User(id: 42, name: "Blob"))
    }
  } operation: {
    await model.loginButtonTapped()
    #expect(model.errorMessage == nil)
  }
}
```

Even though the `LoginModel` was created in the context of the API client failing it still sees 
the updated dependency when run in the new `withDependencies` context.

## Testing gotchas

### Testing host application

This is not well known, but when an application target runs tests it actually boots up a simulator
and runs your actual application entry point in the simulator. This means while tests are running,
your application's code is separately also running. This can be a huge gotcha because it means you
may be unknowingly making network requests, tracking analytics, writing data to user defaults or
to the disk, and more.

This usually flies under the radar and you just won't know it's happening, which can be problematic.
But, once you start using this library to control your dependencies the problem can surface in a 
very visible manner. Typically, when a dependency is used in a test context without being overridden,
a test failure occurs. This makes it possible for your test to pass successfully, yet for some
mysterious reason the test suite fails. This happens because the code in the _app host_ is now
running in a test context, and accessing dependencies will cause test failures.

This only happens when running tests in a _application target_, that is, a target that is 
specifically used to launch the application for a simulator or device. This does not happen when
running tests for frameworks or SwiftPM libraries, which is yet another good reason to modularize
your code base.

However, if you aren't in a position to modularize your code base right now, there is a quick
fix. Our [Issue Reporting][issue-reporting-gh] library, which is transitively included
with this library, comes with a property you can check to see if tests are currently running. If
they are, you can omit the entire entry point of your application.

For example, for a pure SwiftUI entry point you can do the following to keep your application from
running during tests:

```swift
import IssueReporting
import SwiftUI

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      if !isTesting {
        // Your real root view
      }
    }
  }
}
```

And in an `UIApplicationDelegate`-based entry point you can do the following:

```swift
func application(
_ application: UIApplication,
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  guard !isTesting else { return true }
  // ...
}
```

That will allow tests to run in the application target without your actual application code 
interfering.

### Statically linking your tests target to Dependencies

If you statically link the `Dependencies` module to your tests target, its implementation may clash
with the implementation that is statically linked to the app itself. It then may use a different
`DependencyValues` base type in the app and in tests, and you may encounter test failures where
dependency overrides performed with `withDependencies` seem ineffective.

In such cases Xcode will display multiple warnings similar to:

> Class _TtC12Dependencies[…] is implemented in both […] and […].
> One of the two will be used. Which one is undefined.

The solution is to remove the static link to `Dependencies` from your test target, as you
transitively get access to it through the app itself. In Xcode, go to "Build Phases" and remove
"Dependencies" from the "Link Binary With Libraries" section. When using SwiftPM, remove the
"Dependencies" entry from the `testTarget`'s' `dependencies` array in `Package.swift`.

### Test case leakage

Sometimes it is possible to have tests that pass successfully when run in isolation, but somehow 
fail when run together as a suite. This can happen when using escaping closures in tests, which 
creates an alternate execution flow, allowing a test's code to continue running long after the test 
has  finished.

This can happen in any kind of test, not just when using this dependencies library. For example, 
each of the following test methods passes when run in isolation, yet running the whole test suite
fails:

```swift
final class SomeTest: XCTestCase {
  func testA() {
    Task {
      try await Task.sleep(for: .seconds(0.1))
      XCTFail()
    }
  }
  func testB() async throws {
    try await Task.sleep(for: .seconds(0.15))
  }
}
```

This happens because `testA` escapes some work to be executed and then finishes immediately with
no failure. Then, while `testB` is executing, the escaped work from `testA` finally gets around
to executing and causes a failure.

You can also run into this issue while using this dependencies library. In particular, you may
see test a failure for accessing a ``TestDependencyKey/testValue`` of a dependency that your
test is not even using. If running that test in isolation passes, then you probably have some
other test accidentally leaking its code into your test. You need to check every other test in the 
suite to see if any of them use escaping closures causing the leakage.

### Static @Dependency

You should never use the `@Dependency` property wrapper as a static variable:

```swift
class Model {
  @Dependency(\.date) static var date
  // ...
}
```

You will not be able to override this dependency in the normal fashion. In general there is no need
to ever have a static dependency, and so you should avoid this pattern.

### Parameterized and repeated @Test runs

> Important: If targeting Swift 6.1+ (Xcode 16.3+), then this gotcha does not apply and can be
> ignored.

The library comes with support for Swift's new native Testing framework. However, as there are still
still features missing from the Testing framework that XCTest has, there may be some additional
steps you must take.

If you are are writing a _parameterized_ test using the `@Test` macro, you will need to surround the
entire body of your test in [`withDependencies`](<doc:withDependencies(_:operation:)>) that
resets the entire set of values to guarantee that a fresh set of dependencies is used per parameter:

```swift
@Test(arguments: [1, 2, 3])
func feature(_ number: Int) {
  withDependencies {
    $0 = DependencyValues()
  } operation: {
    // All test code in here...
  }
}
```

This will guarantee that dependency state does not bleed over to each parameter of the test.

[issue-reporting-gh]: http://github.com/pointfreeco/swift-issue-reporting
