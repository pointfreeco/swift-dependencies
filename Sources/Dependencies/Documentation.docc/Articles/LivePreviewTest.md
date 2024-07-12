# Live, preview, and test dependencies

Learn how to provide different implementations of your dependencies for use in the live application,
as well as in Xcode previews, and even in tests.

## Overview

In the previous section we showed that to conform to ``DependencyKey`` you must provide _at least_ a
``DependencyKey/liveValue``, which is the default version of the dependency that is used when
running on a device or simulator. The ``DependencyKey`` protocol inherits from a base protocol,
``TestDependencyKey``, which has two other optional properties that can be implemented 
``TestDependencyKey/testValue`` and ``TestDependencyKey/previewValue-8u2sy``, both of which will 
delegate to ``DependencyKey/liveValue`` if left unimplemented.

Leveraging these alternative dependency implementations allow to run your features in safer
environments for tests, previews, and more.

* [Live value](#Live-value)
* [Test value](#Test-value)
* [Preview value](#Preview-value)
* [Separating interface and implementation](#Separating-interface-and-implementation)
* [Cascading rules](#Cascading-rules)

## Live value

The ``DependencyKey/liveValue`` static property from the ``DependencyKey`` protocol is the only
truly _required_ requirement from the protocol. This is the value that is used when running your
feature in the simulator or on a device. It is appropriate to use an implementation of your
dependency for this value that actually interacts with the outside world. That is, it can make
network requests, perform time-based asynchrony, interact with the file system, and more.

However, if you only implement ``DependencyKey/liveValue``, then it means your feature will use the
live dependency when run in tests, which can be problematic. That will cause live API requests to be 
made, which are slow and flakey, analytics will be tracked, which will muddy your data, files will
be written to disk, which will bleed into other tests, and more.

Using live dependencies in tests are so problematic that the library will cause a test failure
if you ever interact with a live dependency while tests are running:

```swift
func testFeature() async throws {
  let model = FeatureModel()

  model.addButtonTapped()
  // 🛑  A dependency has no test implementation, but was accessed from a 
  //     test context:
  //
  //         Dependency:
  //           APIClient
  //
  //     Dependencies registered with the library are not allowed to use 
  //     their default, live implementations when run from tests.
}
```


If you truly want to use
live dependencies in tests you have to make it explicit by overriding the dependency using 
``withDependencies(_:operation:)-3vrqy`` and setting the live value:

```swift
func testFeature() async throws {
  let model = withDependencies {
    // ⚠️ Explicitly say you want to use a live dependency.
    $0.apiClient = .liveValue
  } operation: {
    FeatureModel()
  }

  // ...
}
```

## Test value

The ``TestDependencyKey/testValue`` static property from the ``TestDependencyKey`` protocol should
be implemented if you want to provide a specific implementation of your dependency for all tests. At
a bare minimum you should provide an implementation of your dependency that does not reach out to
the real world. This means it should not make network requests, should not sleep for real-world
time, should not touch the file system, etc.

This can guarantee that a whole class of bugs do not happen in your code when running tests. For
example, suppose you have a dependency for tracking user events with your analytics server. If you
allow this dependency to be used in an uncontrolled manner in tests you run the risk of accidentally
tracking events that do not actually correspond to user actions, and therefore will result in bad,
unreliable data.

Another example of a dependency you want to control during tests is access to the file system. If
your feature writes a file to disk during a test, then that file will remain there for subsequent
runs of other tests. This causes testing artifacts to bleed over into other tests, which can cause
confusing failures.

So, providing a ``TestDependencyKey/testValue`` can be very useful, but even better, we highly
encourage users of our library to provide what is known as "unimplemented" versions of their
dependencies for their ``TestDependencyKey/testValue``. These are implementations that cause a test
failure if any of its endpoints are invoked.

You can use our [Issue Reporting][issue-reporting-gh] library to aid in this, which is
immediately accessible as a transitive dependency. It comes with a function called
[`unimplemented`][unimplemented-docs] that can return a function of nearly any signature with the
property that if it is invoked it will cause a test failure. For example, the hypothetical analytics
dependency we considered a moment ago can be given such a `testValue` like so:

```swift
struct AnalyticsClient {
  var track: (String, [String: String]) async throws -> Void
}

import Dependencies

extension AnalyticsClient: TestDependencyKey {
  static let testValue = Self(
    track: unimplemented("AnalyticsClient.track")
  )
}
```

This makes it so that if your feature ever makes use of the `track` endpoint on the analytics client
without you specifically overriding it, you will get a test failure. This makes it easy to be
notified if you ever start tracking new events without writing a test for it, which can be
incredibly powerful.

## Preview value

We've now seen that ``DependencyKey/liveValue`` is an appropriate place to put dependency
implementations that reach out to the outside world, and ``TestDependencyKey/testValue`` is an
appropriate place to put dependency implementations that refrain from interacting with the outside
world. Even better if the `testValue` actually causes a test failure if any of its endpoints are
accessed.

There's a third kind of implementation that you can provide that sits somewhere between
``DependencyKey/liveValue`` and ``TestDependencyKey/testValue``: it's called
``TestDependencyKey/previewValue-8u2sy``. It will be used whenever your feature is run in an Xcode
preview.

Xcode previews are similar to tests in that you usually do not want to interact with the outside 
world, such as making network requests. In fact, many of Apple's frameworks do not work in previews, 
such as Core Location, and so it will be hard to interact with your feature in previews if it 
touches those frameworks.

However, Xcode previews are dissimilar to tests in that it's fine for dependencies to return some 
mock data. There's no need to deal with "unimplemented" clients for proving which dependencies are
actually used.

For example, suppose you have an API client with some endpoints for fetching users. You do not want
to make live, network requests in Swift previews because that will cause previews to run slowly. So,
you can provide a ``TestDependencyKey/previewValue-8u2sy`` implementation that synchronously and
immediately returns some mock data:

```swift
extension APIClient: TestDependencyKey {
  static let previewValue = Self(
    fetchUsers: {
      [
        User(id: 1, name: "Blob"),
        User(id: 2, name: "Blob Jr."),
        User(id: 3, name: "Blob Sr."),
      ]
    },
    fetchUser: { id in
      User(id: id, name: "Blob, id: \(id)")
    }
  )
}
```

> Note: The `previewValue` implementation must be defined in the same module as the 
``TestDependencyKey`` conformance. If you end up separating the interface and implementation of your
dependency, as shown in <doc:LivePreviewTest#Separating-interface-and-implementation>, then it
must be defined the interface module, not the implementation module.

Then when running a feature that uses this dependency in an Xcode preview, it will immediately get
data provided to it, making it easier for you to iterate on your feature's logic and styling.

You can also always override dependencies for the preview if you want to test out a specific 
configuration of data. For example, if you want to test the empty state of your feature when the 
API client returns an empty array, you can do so like this:

```swift
struct Feature_Previews: PreviewProvider {
  static var previews: some View {
    FeatureView(
      model: withDependencies {
        $0.apiClient.fetchUsers = { _ in [] }
      } operation: {
        FeatureModel()
      }
    )
  }
}
```

Or if you want to preview how your feature deals with errors returned from the API:

```swift
struct Feature_Previews: PreviewProvider {
  static var previews: some View {
    FeatureView(
      model: withDependencies {
        $0.apiClient.fetchUser = { _ in
          struct SomeError: Error {}
          throw SomeError()
        }
      } operation: {
        FeatureModel()
      }
    )
  }
}
```

## Separating interface and implementation

It is common for the interface of an dependency to be super lightweight and compile quickly (as
usually it consists of some simple data types), but for the "live" implementation to be heavyweight
and take a long time to compile (usually when 3rd party libraries are involved). In such cases it is
recommended to put the interface and live implementation in separate modules, and then
implementation can depend on the interface.

In order to accomplish this you can conform your dependency to the ``TestDependencyKey`` protocol in
the interface module, like this:

```swift
// Module: AnalyticsClient
struct AnalyticsClient: TestDependencyKey {
  // ...

  static let testValue = Self(/* ... */)
}
```

And then in the implementation module you can extend the dependency to further conform to the
``DependencyKey`` protocol and provide a live implementation:

```swift
// Module: LiveAnalyticsClient
extension AnalyticsClient: DependencyKey {
  static let liveValue = Self(/* ... */)
}
```

## Cascading rules

Depending on which of ``TestDependencyKey/testValue``, ``TestDependencyKey/previewValue-8u2sy`` and
``DependencyKey/liveValue`` you implement, _and_ depending on which conformance to
``TestDependencyKey`` and ``DependencyKey`` is visible to the compiler, there are rules that decide
which actual dependency will be used at runtime.

  * A default implementation of ``TestDependencyKey/testValue`` is provided, and it simply calls out
    to ``TestDependencyKey/previewValue-8u2sy``. This means that in a testing context, the preview
    version of the dependency will be used.

  * Further, if a conformance to ``DependencyKey`` is provided in addition to ``TestDependencyKey``,
    then ``TestDependencyKey/previewValue-8u2sy`` has a default implementation provided, and it
    calls out to ``DependencyKey/liveValue``. This means that in a preview context, the live version
    of the dependency will be used.

Note that a consequence of the above two rules is that if only ``DependencyKey/liveValue`` is
implemented when conforming to ``DependencyKey``, then both ``TestDependencyKey/testValue`` and
``TestDependencyKey/previewValue-8u2sy`` will call out to the `liveValue` under the hood. This means
your dependency will be interacting with the outside world during tests and in previews, which may
not be ideal.

There is one thing the library will do to help you catch using a live dependency in tests. If a live
dependency is used in a test context, the test case will fail. This is done to make sure you
understand the risks of using a live dependency in tests. To confirm that you truly want to use a
live dependency you can override the dependency with `.liveValue`:

```swift
func testFeature() {
  let model = withDependencies {
    $0.apiClient = .liveValue  // ⬅️
  } operation: {
    FeatureModel()
  }
  // ...
}
```

This will prevent the library from failing your test for using a live dependency in a testing
context.

On the flip side, the library also helps you catch when you have not provided a `liveValue`. When
running the application in the simulator or on a device, if a dependency is accessed for which a
`liveValue` has not been provided, a purple, runtime warning will appear in Xcode letting you know.

There is also a way to force a dependency context in an application target or test target. When
the environment variable `SWIFT_DEPENDENCIES_CONTEXT` is present, and is equal to either `live`,
`preview` or `test`, that context will be used. This can be useful in UI tests since the application
target runs as a separate process outside of the testing process.

In order to force the application target to run with test dependencies during a UI test, simply
perform the following in your UI test case:

```swift
func testFeature() {
  self.app.launchEnvironment["SWIFT_DEPENDENCIES_CONTEXT"] = "test"
  self.app.launch()
  …
}
```

[unimplemented-docs]: https://pointfreeco.github.io/xctest-dynamic-overlay/main/documentation/xctestdynamicoverlay/unimplemented(_:fileid:line:)-5098a
[issue-reporting-gh]: http://github.com/pointfreeco/xctest-dynamic-overlay

