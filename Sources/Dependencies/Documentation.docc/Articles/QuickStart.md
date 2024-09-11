# Quick start

Learn the basics of getting started with the library before diving deep into all of its features.

## Adding the Dependencies library as a dependency

To use this library in a SwiftPM project, add it to the dependencies of your Package.swift and
specify the `Dependencies` product in any targets that need access to the library:

```swift
let package = Package(
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "<your-target-name>",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies")
      ]
    )
  ]
)
```

## Using your first dependency

The library allows you to register your own dependencies, but it also comes with many controllable
dependencies out of the box (see ``DependencyValues`` for a full list), and there
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
inside the `addButtonTapped` method, you can use the ``withDependencies(_:operation:)-4uz6m``
function to override any dependencies for the scope of one single test. It's as easy as 1-2-3:

```swift
@Test(
    // 1️⃣ Override any dependencies that your feature uses.
  .dependency(\.clock, .immediate),
  .dependency(\.date.now, Date(timeIntervalSinceReferenceDate: 1234567890)),
  .dependency(\.uuid, .incrementing)
)
func add() async throws {
  // 2️⃣ Construct the feature's model
  let model = FeatureModel()

  // 3️⃣ The model now executes in a controlled environment of dependencies,
  //    and so we can make assertions against its behavior.
  try await model.addButtonTapped()
  #expect(
    model.items == [
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
``withDependencies(_:operation:)-4uz6m`` helper:

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
can do. You can learn more in depth about <doc:WhatAreDependencies> as well as
<doc:UsingDependencies>. Once comfortable with that you can learn about
<doc:RegisteringDependencies> as well as how to best leverage <doc:LivePreviewTest>. And finally,
there are more advanced topics to explore, such as <doc:DesigningDependencies>,
<doc:OverridingDependencies>, <doc:Lifetimes> and <doc:SingleEntryPointSystems>.

[immediate-clock-docs]: https://pointfreeco.github.io/swift-clocks/main/documentation/clocks/immediateclock
