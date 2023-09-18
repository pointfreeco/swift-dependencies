# Single entry point systems

Learn about "single entry point" systems, and why they are best suited for this dependencies
library, although it is possible to use the library with non-single entry point systems.

## Overview

A system is said to have a "single entry point" if there is one place to invoke all of its logic and
behavior. Such systems make it easy to alter the execution context a system runs in, which can be
powerful.

## Examples of single entry point systems

By far the most popular example of this in the Apple ecosystem is SwiftUI views. A view is a type
conforming to the `View` protocol and exposing a single `body` property that returns the view
hierarchy:

```swift
struct FeatureView: View {
  var body: some View {
    // All of the view is constructed in here...
  }
}
```

There is only one way to create the actual views that SwiftUI will render to the screen, and that
is by invoking the `body` property, though we never need to actually do that. SwiftUI hides all of
that from us in the `@main` entry point of the application or in `UIHostingController`.

[The Composable Architecture][tca-gh] is another example of a single entry point system, but this
time for implementing logic and behavior of a view. It provides a protocol that one conforms to and
it has a single requirement, `reduce`, which is responsible for mutating the feature's state and
returning effects to execute:

```swift
import ComposableArchitecture

struct Feature: ReducerProtocol {
  struct State {
    // ...
  }
  enum Action {
    // ...
  }

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    // All of the feature's logic and behavior is implemented here...
  }
}
```

Again, there is only one way to execute this feature's logic, and that is by invoking the `reduce`
method. However, you never actually need to do that in practice. The Composable Architecture
hides all of that from you, and instead you just construct a `Store` at the root of the application.

Another example of a single entry point system is a server framework. Such frameworks usually
have a simple request-to-response lifecycle. It starts by the framework receiving a request from an
external client. Then one uses the framework's tools in order to interpret that request and build
up a response to send back to the client. This again describes just a single point for all logic to
be executed for a particular request.

So, there are a lot of examples of "single entry point" systems out there, but it's also not the
majority. There are plenty of examples that do not fall into this paradigm, such as
`ObservableObject` conformances, all of UIKit and more. If you _are_ dealing with a single entry
point system, then there are some really great superpowers that can be unlocked...

## Altered execution environments

One of the most interesting aspects of single entry point systems is that they have a well-defined
scope from beginning to end, and that makes it possible to easily alter their execution context.

For example, SwiftUI views have a powerful feature known as ["environment values"][env-values-docs].
They allow you to propagate values deep into a view hierarchy and can be overridden for just one
small subset of the view tree.

The following SwiftUI view stacks a header view on top of a footer view, and overrides the
foreground color for the header:

```swift
struct ContentView: View {
  var body: some View {
    VStack {
      HeaderView()
        .foregroundColor(.red)
      FooterView()
    }
  }
}
```

The `.red` foreground color will be applied to every view in `HeaderView`, including deeply nested
views. And most importantly, that style is applied only to the header and not to the
`FooterView`.

The `foregroundColor` view modifier is powered by [environment values][env-values-docs] under the
hood, as can be seen by printing the type of `ContentView`'s body:

```swift
print(ContentView.Body.self)
// VStack<
//   TupleView<(
//     ModifiedContent<
//       HeaderView,
//       _EnvironmentKeyWritingModifier<Optional<Color>>
//     >,
//     FooterView
//   )>
// >
```

The presence of `_EnvironmentKeyWritingModifier` shows that an environment key is being written.

This is an incredibly powerful feature of SwiftUI, and the only reason it works so well and is so
easy to understand is specifically because SwiftUI views form a single entry point system. That
makes it possible to alter the execution environment of `HeaderView` so that its foreground color
is red, and that altered state does not affect the other parts of the view tree, such as
`FooterView`.

The same is possible with the Composable Architecture and the dependencies of features. For example,
suppose some feature's logic and behavior was decomposed into the logic for the "header" and
"footer," and that we wanted to alter the dependencies used in the header. This can be done using
the `.dependency` method on reducers, which acts similarly to the
[`.environment`][env-view-modifier-docs] view modifier from SwiftUI:

```swift
struct Feature: ReducerProtocol {
  struct State {
    // ...
  }
  enum Action {
    // ...
  }

  var body: some ReducerProtocolOf<Self> {
    Header()
      .dependency(\.fileManager, .mock)
      .dependency(\.userDefaults, .mock)

    Footer()
  }
}
```

This will override the `fileManager` and `userDefaults` dependency to be mocks for the `Header`
feature (as well as all features called to from inside `Header`), but will leave the dependencies
untouched for all other features, including `Footer`.

This pattern can also be repeated for server applications. It is possible to alter the execution
environment on a per-request basis, and even for just a subset of the request-to-response lifecycle.

It is incredibly powerful to be able to do this, but it all hinges on being able to express your
system as a single point of entry. Without that it becomes a lot more difficult to alter the
execution context of the system, or a sub-system, because there is not only one place to do so.

## Non-single entry point systems

While this library thrives when applied to "single entry point" systems, it is still possible to use
with other kinds of systems. You just have to be a little more careful. In particular, you must be
careful where you add dependencies to your features and how you construct features that use
dependencies.

When adding a dependency to a feature's `ObservableObject` conformance, you should make use of
`@Dependency` only for the object's instance properties:

```swift
final class FeatureModel: ObservableObject {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.date) var date
  // ...
}
```

And similarly for `UIViewController` subclasses:

```swift
final class FeatureViewController: UIViewController {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.date) var date
  // ...
}
```

Then you are free to use those dependencies from anywhere within the model and controller.

Then, if you create a new model or controller from within an existing model or controller, you
will need to take an extra step to make sure that the parent feature's dependencies are propagated
to the child.

For example, if your SwiftUI model holds a piece of optional state that drives a sheet, then when
hydrating that state you will want to wrap it in
``withDependencies(from:operation:file:line:)-8e74m``:

```swift
final class FeatureModel: ObservableObject {
  @Published var editModel: EditModel?

  @Dependency(\.apiClient) var apiClient
  @Dependency(\.date) var date

  func editButtonTapped() {
    self.editModel = withDependencies(from: self) {
      EditModel()
    }
  }
}
```

This makes it so that if `FeatureModel` were constructed with some of its dependencies overridden
(see <doc:OverridingDependencies>), then those changes will also be visible to `EditModel`.

The same principle holds for UIKit. When constructing a child view controller to be presented,
be sure to wrap its construction in
``withDependencies(from:operation:file:line:)-8e74m``:

```swift
final class FeatureViewController: UIViewController {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.date) var date

  func editButtonTapped() {
    let controller = withDependencies(from: self) {
      EditViewController()
    }
    self.present(controller, animated: true, completion: nil)
  }
}
```

If you make sure to always use ``withDependencies(from:operation:file:line:)-8e74m``
when constructing child models and controllers you can be sure that changes to dependencies at
any layer of your application will be visible at any layer below it. See <doc:Lifetimes> for
more information on how dependency lifetimes work.

[tca-gh]: http://github.com/pointfreeco/swift-composable-architecture
[env-values-docs]: https://developer.apple.com/documentation/swiftui/environment-values
[env-view-modifier-docs]: https://developer.apple.com/documentation/swiftui/view/environment(_:_:)
