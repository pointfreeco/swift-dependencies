# Dependencies

A dependency management library inspired by SwiftUI's "environment."

[![CI](https://github.com/pointfreeco/swift-dependencies/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swift-dependencies/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](http://pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-dependencies%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-dependencies)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-dependencies%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-dependencies)

  * [Learn More](#learn-more)
  * [Overview](#overview)
  * [Quick start](#quick-start)
  * [Examples](#examples)
  * [Documentation](#documentation)
  * [Community](#community)
  * [Extensions](#extensions)

## Learn More

This library was motivated and designed over the course of many episodes on
[Point-Free](https://www.pointfree.co), a video series exploring functional programming and the
Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen
Celis](https://twitter.com/stephencelis).

<a href="https://www.pointfree.co">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0209.jpeg" width="600">
</a>

## Overview

Dependencies are the types and functions in your application that need to interact with outside
systems that you do not control. Classic examples of this are API clients that make network
requests to servers, but also seemingly innocuous things such as `UUID` and `Date` initializers,
file access, user defaults, and even clocks and timers, can all be thought of as dependencies.

You can get really far in application development without ever thinking about dependency management 
(or, as some like to call it, "dependency injection"), but eventually uncontrolled dependencies can 
cause many problems in your code base and development cycle:

  * Uncontrolled dependencies make it **difficult to write fast, deterministic tests** because you 
    are susceptible to the vagaries of the outside world, such as file systems, network 
    connectivity, internet speed, server uptime, and more.
    
  * Many dependencies **do not work well in SwiftUI previews**, such as location managers and speech
    recognizers, and some **do not work even in simulators**, such as motion managers, and more. 
    This prevents you from being able to easily iterate on the design of features if you make use of 
    those frameworks.

  * Dependencies that interact with 3rd party, non-Apple libraries (such as Firebase, web socket
    libraries, network libraries, etc.) tend to be heavyweight and take a **long time to compile**. 
    This can slow down your development cycle.

For these reasons, and a lot more, it is highly encouraged for you to take control of your
dependencies rather than letting them control you.

But, controlling a dependency is only the beginning. Once you have controlled your dependencies, 
you are faced with a whole set of new problems:

  * How can you **propagate dependencies** throughout your entire application in a way that is more
    ergonomic than explicitly passing them around everywhere, but safer than having a global
    dependency?
    
  * How can you **override dependencies** for just one portion of your application? This can be 
    handy for overriding dependencies for tests and SwiftUI previews, as well as specific user 
    flows such as onboarding experiences.
    
  * How can you be sure you **overrode _all_ dependencies** a feature uses in tests? It would be
    incorrect for a test to mock out some dependencies but leave others as interacting with the
    outside world.

This library addresses all of the points above, and much, _much_ more.

## Quick start

The library allows you to register your own dependencies, but it also comes with many controllable
dependencies out of the box (see [`DependencyValues`][dep-values-docs] for a full list), and there
is a good chance you can immediately make use of one. If you are using `Date()`, `UUID()`,
`Task.sleep`, or Combine schedulers directly in your feature's logic, you can already start to use
this library.

```swift
final class FeatureModel: ObservableObject {
  @Dependency(\.continuousClock) var clock  // Controllable way to sleep a task
  @Dependency(\.date.now) var now           // Controllable way to ask for current date
  @Dependency(\.mainQueue) var mainQueue    // Controllable scheduling on main queue
  @Dependency(\.uuid) var uuid              // Controllable UUID creation

  // ...
}
```

Once your dependencies are declared, rather than reaching out to the `Date()`, `UUID()`, etc.,
directly, you can use the dependency that is defined on your feature's model:

```swift
final class FeatureModel: ObservableObject {
  // ...

  func addButtonTapped() async throws {
    try await self.clock.sleep(for: .seconds(1))  // 👈 Don't use 'Task.sleep'
    self.items.append(
      Item(
        id: self.uuid(),  // 👈 Don't use 'UUID()'
        name: "",
        createdAt: self.now  // 👈 Don't use 'Date()'
      )
    )
  }
}
```

That is all it takes to start using controllable dependencies in your features. With that little
bit of upfront work done you can start to take advantage of the library's powers.

For example, you can easily control these dependencies in tests. If you want to test the logic
inside the `addButtonTapped` method, you can use the [`withDependencies`][withdependencies-docs]
function to override any dependencies for the scope of one single test. It's as easy as 1-2-3:

```swift
func testAdd() async throws {
  let model = withDependencies {
    // 1️⃣ Override any dependencies that your feature uses.
    $0.clock = ImmediateClock()
    $0.date.now = Date(timeIntervalSinceReferenceDate: 1234567890)
    $0.uuid = .incrementing
  } operation: {
    // 2️⃣ Construct the feature's model
    FeatureModel()
  }

  // 3️⃣ The model now executes in a controlled environment of dependencies,
  //    and so we can make assertions against its behavior.
  try await model.addButtonTapped()
  XCTAssertEqual(
    model.items,
    [
      Item(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        name: "",
        createdAt: Date(timeIntervalSinceReferenceDate: 1234567890)
      )
    ]
  )
}
```

Here we controlled the `date` dependency to always return the same date, and we controlled the
`uuid` dependency to return an auto-incrementing UUID every time it is invoked, and we even 
controlled the `clock` dependency using an [`ImmediateClock`][immediate-clock-docs] to squash all
of time into a single instant. If we did not control these dependencies this test would be very 
difficult to write since there is no way to accurately predict what will be returned by `Date()` 
and `UUID()`, and we'd have to wait for real world time to pass, making the test slow.

But, controllable dependencies aren't only useful for tests. They can also be used in Xcode
previews. Suppose the feature above makes use of a clock to sleep for an amount of time before
something happens in the view. If you don't want to literally wait for time to pass in order to see
how the view changes, you can override the clock dependency to be an "immediate" clock using the
[`withDependencies`][withdependencies-docs] helper:

```swift
struct Feature_Previews: PreviewProvider {
  static var previews: some View {
    FeatureView(
      model: withDependencies {
        $0.clock = ImmediateClock()
      } operation: {
        FeatureModel()
      }
    )
  }
}
```

This will make it so that the preview uses an immediate clock when run, but when running in a
simulator or on device it will still use a live `ContinuousClock`. This makes it possible to
override dependencies just for previews without affecting how your app will run in production.

That is the basics to getting started with using the library, but there is still a lot more you
can do. You can learn more in depth about the library by exploring the [documentation][docs]
and articles:

#### Getting started

* **[Quick start][quick-start-article] (Same as the information above)**:
  Learn the basics of getting started with the library before diving deep into all of its features.

* **[What are dependencies?][what-are-dependencies-article]**:
  Learn what dependencies are, how they complicate your code, and why you want to control them.

#### Essentials

* **[Using dependencies][using-dependencies-article]**:
  Learn how to use the dependencies that are registered with the library.

* **[Registering dependencies][registering-dependencies-article]**:
  Learn how to register your own dependencies with the library so that they immediately become
  available from any part of your code base.

* **[Live, preview, and test dependencies][live-preview-test-article]**:
  Learn how to provide different implementations of your dependencies for use in the live
  application, as well as in Xcode previews, and even in tests.

* **[Testing][testing-article]**:
  One of the main reasons to control dependencies is to allow for easier testing. Learn some tips
  and tricks for writing better tests with the library.

#### Advanced

* **[Designing dependencies][designing-dependencies-article]**:
  Learn techniques on designing your dependencies so that they are most flexible for injecting into
  features and overriding for tests.
  
* **[Overriding dependencies][overriding-dependencies-article]**:
  Learn how dependencies can be changed at runtime so that certain parts of your application can use
  different dependencies.

* **[Dependency lifetimes][lifetimes-article]**:
  Learn about the lifetimes of dependencies, how to prolong the lifetime of a dependency, and how
  dependencies are inherited.

* **[Single entry point systems][single-entry-point-systems-article]**:
  Learn about "single entry point" systems, and why they are best suited for this dependencies
  library, although it is possible to use the library with non-single entry point systems.

## Examples

We rebuilt Apple's [Scrumdinger][scrumdinger] demo application using modern, best practices for
SwiftUI development, including using this library to control dependencies on file system access,
timers and speech recognition APIs. That [demo can be found][standups-demo] in our 
[SwiftUINavigation][swiftui-nav-gh] library.

## Documentation

The latest documentation for the Dependencies APIs is available [here][docs].

## Installation

You can add Dependencies to an Xcode project by adding it to your project as a package.

> https://github.com/pointfreeco/swift-dependencies

If you want to use Dependencies in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "Dependencies", package: "swift-dependencies"),
```

## Community

If you want to discuss this library or have a question about how to use it to solve 
a particular problem, there are a number of places you can discuss with fellow 
[Point-Free](http://www.pointfree.co) enthusiasts:

* For long-form discussions, we recommend the [discussions](http://github.com/pointfreeco/swift-dependencies/discussions) tab of this repo.
* For casual chat, we recommend the [Point-Free Community Slack](http://pointfree.co/slack-invite).

## Extensions

This library controls a number of dependencies out of the box, but is also open to extension. The
following projects all build on top of Dependencies:

  * [Dependencies Additions](https://github.com/tgrapperon/swift-dependencies-additions): A
    companion library that provides higher-level dependencies.

## Alternatives

There are many other dependency injection libraries in the Swift community. Each has its own set of
priorities and trade-offs that differ from Dependencies. Here are a few well-known examples:

  * [Cleanse](https://github.com/square/Cleanse)
  * [Factory](https://github.com/hmlongco/Factory)
  * [Needle](https://github.com/uber/needle)
  * [Swinject](https://github.com/Swinject/Swinject)
  * [Weaver](https://github.com/scribd/Weaver)

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[docs]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/
[concurrency-support-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/concurrencysupport
[designing-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/designingdependencies
[lifetimes-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/lifetimes
[live-preview-test-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/livepreviewtest
[testing-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/testing
[overriding-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/overridingdependencies
[registering-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/registeringdependencies
[single-entry-point-systems-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/singleentrypointsystems
[using-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/usingdependencies
[what-are-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/whataredependencies
[quick-start-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/quickstart
[registering-dependencies-article]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/registeringdependencies 
[scrumdinger]: https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
[standups-demo]: https://github.com/pointfreeco/syncups
[swiftui-nav-gh]: http://github.com/pointfreeco/swiftui-navigation
[dep-values-docs]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/dependencyvalues
[withdependencies-docs]: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/withdependencies(_:operation:)-4uz6m
[immediate-clock-docs]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/immediateclock
