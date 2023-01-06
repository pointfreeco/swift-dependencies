# Dependencies

A dependency management library inspired by SwiftUI's “environment.”

[![CI](https://github.com/pointfreeco/swift-dependencies/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swift-dependencies/actions/workflows/ci.yml)
<!--
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-dependencies%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-dependencies)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-dependencies%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-dependencies)
-->

  * [Learn More](#learn-more)
  * [Overview](#overview)
  * [Documentation](#documentation)
  * [Installation](#installation)
  * [License](#license)

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

You can get really far in application development without ever thinking about dependencies, but
eventually they can cause many problems in your code base and development cycle:

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

  * How can you **propagate dependencies** throughout your entire application that is more ergonomic
    than explicitly passing them around everywhere, but safer than having a global dependency?
    
  * How can you **override dependencies** for just one portion of your application? This can be 
    handy for overriding dependencies for tests and SwiftUI previews, as well as specific user 
    flows such as onboarding experiences.
    
  * How can you be sure you **overrode _all_ dependencies** a feature uses in tests? It would be
    incorrect for a test to mock out some dependencies but leave others as interacting with the
    outside world.

This library addresses all of the points above, and much, _much_ more. Explore all of the tools this
library comes with by checking out the [documentation][docs], and reading these articles:

### Getting started

* **[Quick start][quick-start-article]**:
  Learn the basics of getting started with the library before diving deep into all of its features.

* **[What are dependencies?][what-are-dependencies-article]**:
  Learn what dependencies are, how they complicate your code, and why you want to control them.

### Essentials

* **[Using dependencies][using-dependencies-article]**:
  Learn how to use the dependencies that are registered with the library.

* **[Registering dependencies][registering-dependencies-article]**:
  Learn how to register your own dependencies with the library so that they immediately become
  available from any part of your code base.

* **[Live, preview, and test dependencies][live-preview-test-article]**:
  Learn how to provide different implementations of your dependencies for use in the live
  application, as well as in Xcode previews, and even in tests.
  
### Advanced

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

### Miscellaneous

* **[Concurrency support][concurrency-support-article]**:
  Learn about the concurrency tools that come with the library that make writing tests and 
  implementing dependencies easy.
  
## Examples

We rebuilt Apple's [Scrumdinger][scrumdinger] demo application using modern, best practices for
SwiftUI development, including using this library to control dependencies on file system access,
timers and speech recognition APIs. That [demo can be found][TODO: ] in our 
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
  .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "Dependencies", package: "swift-dependencies"),
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[docs]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/
[concurrency-support-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/concurrencysupport
[designing-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/designingdependencies
[lifetimes-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/lifetimes
[live-preview-test-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/livepreviewtest
[overriding-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/overridingdependencies
[registering-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/registeringdependencies
[single-entry-point-systems-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/singleentrypointsystems
[using-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/usingdependencies
[what-are-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/whataredependencies
[quick-start-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/quickstart
[registering-dependencies-article]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/registeringdependencies 
[scrumdinger]: https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
[swiftui-nav-gh]: http://github.com/pointfreeco/swiftui-navigation
