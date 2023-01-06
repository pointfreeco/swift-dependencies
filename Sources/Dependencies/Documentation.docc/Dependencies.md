# ``Dependencies``

A dependency management library inspired by SwiftUI's "environment."

## Overview

Dependencies are the types and functions in your application that need to interact with outside
systems that you do not control. Classic examples of this are API clients that make network
requests to servers, but also seemingly innocuous things such as `UUID` and `Date` initializers,
file access, user defaults, and even clocks and timers, can all be thought of as dependencies.

You can get really far in application development without ever thinking about dependency management 
(or, as some like to call it, "dependency injection”), but eventually uncontrolled dependencies can 
cause many problems in your code base and development cycle

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

But, controlling a dependency (some people like to call this "dependency injection") is only the
beginning. Once you have controlled your dependencies, you are faced with a whole set of new
problems:

  * How can you **propagate dependencies** throughout your entire application that is more ergonomic
    than explicitly passing them around everywhere, but safer than having a global dependency?
    
  * How can you **override dependencies** for just one portion of your application? This can be 
    handy for overriding dependencies for tests and SwiftUI previews, as well as specific user 
    flows such as onboarding experiences.
    
  * How can you be sure you **overrode _all_ dependencies** a feature uses in tests? It would be
    incorrect for a test to mock out some dependencies but leave others as interacting with the
    outside world.

This library addresses all of the points above, and much, _much_ more.

## Topics

### Getting started

- <doc:QuickStart>
- <doc:WhatAreDependencies>

### Essentials

- <doc:UsingDependencies>
- <doc:RegisteringDependencies>
- <doc:LivePreviewTest>

### Advanced

- <doc:DesigningDependencies>
- <doc:OverridingDependencies>
- <doc:Lifetimes>
- <doc:SingleEntryPointSystems>

### Miscellaneous

- <doc:ConcurrencySupport>

### Dependency management

- ``Dependency``
- ``DependencyValues``
- ``DependencyKey``
- ``DependencyContext``

### Concurrency support

- ``ActorIsolated``
- ``LockIsolated``
- ``UncheckedSendable``
