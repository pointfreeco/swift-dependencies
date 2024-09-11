# Using dependencies

Learn how to use the dependencies that are registered with the library.

## Overview

Once a dependency is registered with the library (see <doc:RegisteringDependencies> for more info),
one can access the dependency with the ``Dependency`` property wrapper. This is most commonly done
by adding `@Dependency` properties to your feature's model, such as an `ObservableObject`, or
controller, such as `UIViewController` subclass. It can be used in other scopes too, such as
functions, methods and computed properties, but there are caveats to consider, and so doing that
is not recommended until you are very comfortable with the library.

The library comes with many common dependencies that can be used in a controllable manner, such as
date generators, clocks, random number generators, UUID generators, and more.

For example, suppose you have a feature that needs access to a date initializer, a continuous
clock for time-based asynchrony, and a UUID initializer. All 3 dependencies can be added to your
feature's model:

```swift
final class TodosModel: ObservableObject {
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date
  @Dependency(\.uuid) var uuid

  // ...
}
```

Then, all 3 dependencies can easily be overridden with deterministic versions when testing the
feature:

```swift
@MainActor
@Test(
  .dependency(\.continuousClock, .immediate),
  .dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 1234567890),
  .dependency(\.uuid, .incrementing)
)
func todos() async {
  let model = TodosModel()

  // Invoke methods on `model` and make assertions...
}
```

All references to `continuousClock`, `date`, and `uuid` inside the `TodosModel` will now use the
controlled versions.
