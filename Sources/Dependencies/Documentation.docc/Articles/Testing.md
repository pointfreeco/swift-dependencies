# Testing

One of the main reasons to control dependencies is to allow for easier testing. Learn some tips and 
tricks for writing better tests with the library.

## Overview

In the article <doc:LivePreviewTest> you learned how to define a ``TestDependencyKey/testValue``
when registering your dependencies, which will be automatically used during tests. In this article
we cover more detailed information about how to actually write tests with overridden dependencies,
as well as some tips and gotchas to keep in mind.

* [Altered execution contexts](#Altered-execution-contexts)
* [Changing dependencies during tests](#Changing-dependencies-during-tests)
* [Testing gotchas](#Testing-gotchas)

## Altered execution contexts

It is possible to completely alter the execution context in which a feature's logic runs, which is
great for tests. It means your feature doesn't need to actually make network requests just to test
how your feature deals with data returned from an API, and your feature doesn't need to interact
with the file system just to test how data gets loaded or persisted.

The tool for doing this is ``withDependencies(_:operation:)-3vrqy``, which allows you to specify
which dependencies should be overriden for the test, and then construct your feature's model
in that context:

```swift
func testFeature() async {
  let model = withDependencies { 
    $0.continuousClock = ImmediateClock()
    $0.date.now = Date(timeIntervalSince1970: 1234567890)
  } operation: {
    FeatureModel()
  }

  // Call methods on `model` and make assertions
}
```

As long as all of your dependencies are declared with `@Dependency` as instance properties on 
`FeatureModel`, its entire execution will happen in a context in which any reference to 
`continuousClock` is an `ImmediateClock` and any reference to `date.now` will always report that
the date is "Feb 13, 2009 at 3:31 PM".

It is important to note that if `FeatureModel` creates _other_ models inside its methods, then it
has to be careful about how it does so. In order for `FeatureModel`'s dependencies to propagate
to the new child model, it must construct the child model in an altered execution context that
passes along the dependencies. The tool for this is 
``withDependencies(from:operation:file:line:)-2qx0c`` and can be used simply like this:

```swift
class FeatureModel: ObservableObject {
  // ...

  func buttonTapped() {
    self.child = withDependencies(from: self) {
      ChildModel()
    }
  }
}
```

This guarantees that when `FeatureModel`'s dependencies are overridden in tests that it will also
trickle down to `ChildModel`.

## Changing dependencies during tests

While it is most common to set up all dependencies at the beginning of a test and then make 
assertions, sometimes it is necessary to also change the dependencies in the middle of a test.
This can be very handy for modeling test flows in which a dependency is in a failure state at
first, but then later becomes successful.

For example, suppose we have a login feature such that if you try logging in and an error is thrown
causing a message to appear. But then later, if login succeeds that message goes away. We can
test that entire flow, from end-to-end, but starting the API client dependency in a state where
login fails, and then later change the dependency so that it succeeds using 
``withDependencies(_:operation:)-3vrqy``:

```swift
func testRetryFlow() async {
  let model = withDependencies { 
    $0.apiClient.login = { email, password in 
      struct LoginFailure: Error {}
      throw LoginFailure()
    }
  } operation: {
    LoginModel()
  }

  await model.loginButtonTapped()
  XCTAssertEqual(model.errorMessage, "We could not log you in. Please try again")

  withDependencies {
    $0.apiClient.login = { email, password in 
      LoginResponse(user: User(id: 42, name: "Blob"))
    }
  } operation: {
    await model.loginButtonTapped()
    XCTAssertEqual(model.errorMessage, nil)
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
fix. Our [XCTest Dynamic Overlay][xctest-dynamic-overlay-gh] library, which is transitively included
with this library, comes with a property you can check to see if tests are currently running. If
they are, you can omit the entire entry point of your application:

```swift
import SwiftUI
import XCTestDynamicOverlay

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      if !_XCTIsTesting {
        // Your real root view
      }
    }
  }
}
```

That will allow tests to run in the application target without your actual application code 
interfering.

### Statically linking your tests target to `Dependencies`

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

[xctest-dynamic-overlay-gh]: http://github.com/pointfreeco/xctest-dynamic-overlay
