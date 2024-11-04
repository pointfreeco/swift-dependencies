# What are dependencies?

Learn what dependencies are, how they complicate your code, and why you want to control them.

## Overview

Dependencies in an application are the types and functions that need to interact with outside
systems that you do not control. Classic examples of this are API clients that make network requests
to servers, but also seemingly innocuous things such as the `UUID` and `Date` initializers, and even
clocks and timers, can be thought of as dependencies.

By controlling the dependencies our features need to do their jobs we gain the ability to completely
alter the execution context a feature runs in. This means in tests and Xcode previews you can
provide a mock version of an API client that immediately returns some stubbed data rather than
making a live network request to a server.

## The need for controlled dependencies

Suppose that you are building a feature that displays a message to the user after 10 seconds. This
logic can be packaged up into an observable object:

```swift
@Observable
final class FeatureModel {
  var message: String?

  func onAppear() async {
    do {
      try await Task.sleep(for: .seconds(10))
      message = "Welcome!"
    } catch {}
  }
}
```

And a view can make use of that model:

```swift
struct FeatureView: View {
  let model: FeatureModel

  var body: some View {
    Form {
      if let message = model.message {
        Text(message)
      }

      // ...
    }
    .task { await model.onAppear() }
  }
}
```

This code works just fine at first, but it has some problems:

First, if you want to iterate on the styling of the message in an Xcode preview you will have to
wait for 10 whole seconds of real world time to pass before the message appears. This completely
destroys the fast, iterative nature of previews.

Second, if you want to write a test for this feature, you will again have to wait for 10 whole
seconds of real world time to pass. This slows down your test suite, making it less likely you will
add new tests in the future if the whole suite takes a long time to run.

The reason this code does not play nicely with Xcode previews or tests is because it has an
uncontrolled dependency on an outside system: `Task.sleep`. That API can only sleep for a real world
amount of time.

## Controlling the dependency

It would be far better if we could swap out different notions of "sleeping" in our feature so that
when run in the simulator or device, `Task.sleep` could be used, but in previews or tests other
forms of sleeping could be used.

The tool to do this is known as the `Clock` protocol, which is a tool from the Swift standard
library. Instead of reaching out to `Task.sleep` directly, we can "inject" our dependency on
time-based asynchrony by holding onto a clock in the feature's model by using the ``Dependency``
property  wrapper and ``DependencyValues/continuousClock`` dependency value:

```swift
@Observable
final class FeatureModel {
  var message: String?

  @ObservationIgnored
  @Dependency(\.continuousClock) var clock

  func onAppear() async {
    do {
      try await clock.sleep(for: .seconds(10))
      message = "Welcome!"
    } catch {}
  }
}
```

> Note: Using the `@ObservationIgnored` macro is necessary when using `@Observable` because 
> `@Dependency` is a property wrapper. 

That small change makes this feature much friendlier to Xcode previews and testing.

For previews, you can use the `.dependencies` preview trait to override the
``DependencyValues/continuousClock`` dependency to be an "immediate" clock, which is a clock that
does not actually sleep for any amount of time:

```swift
#Preview(
  .dependencies { $0.continuousClock = .immediate }
) {
  FeatureView(
    model: withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      FeatureModel()
    }
  )
}
```

This will cause the message to appear immediately. No need to wait 10 seconds.

> Tip: We have a [series of episodes][clocks-collection] discussing the `Clock` protocol in depth
and showing how it can be used to control time-based asynchrony.

Further, in tests you can also override the clock dependency to use an immediate clock, also using
the ``withDependencies(_:operation:)-4uz6m`` helper:

```swift
@Test
func message() async {
  let model = withDependencies {
    $0.continuousClock = .immediate
  } operation: {
    FeatureModel()
  }

  #expect(model.message == nil)
  await model.onAppear()
  #expect(model.message == "Welcome!")
}
```

This test will pass quickly, and deterministically, 100% of the time. This is why it is so
important to control dependencies that interact with outside systems.

[clocks-collection]: https://www.pointfree.co/collections/concurrency/clocks
