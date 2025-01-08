# Overriding dependencies

Learn how dependencies can be changed at runtime so that certain parts of your application can use
different dependencies.

## Overview

It is possible to change the dependencies for a particular feature running inside your application.
This can be handy when running a feature in a more controlled environment where it may not be
appropriate to communicate with the outside world. The most obvious examples of this is running a
feature in tests or Xcode previews, but there are other interesting examples too.

## The basics

For example, suppose you want to teach users how to use your feature through an onboarding
experience. In such an experience it may not be appropriate for the user's actions to cause data to
be written to disk, or user defaults to be written, or any number of things. It would be better to
use mock versions of those dependencies so that the user can interact with your feature in a fully
controlled environment.

To do this you need to make use of the
``withDependencies(from:operation:fileID:filePath:line:column:)`` function, which allows you to
inherit the dependencies from an existing object _and_ additionally override some of those
dependencies:

```swift
@Observable
final class AppModel {
  var onboardingTodos: TodosModel?

  func tutorialButtonTapped() {
    onboardingTodos = withDependencies(from: self) {
      $0.apiClient = .mock
      $0.fileManager = .mock
      $0.userDefaults = .mock
    } operation: {
      TodosModel()
    }
  }

  // ...
}
```

In the code above, the `TodosModel` is constructed with an environment that has all of the same
dependencies as the parent, `AppModel`, and further the `apiClient`, `fileManager` and
`userDefaults` have been overridden to be mocked in a controllable manner so that they do not
interact with the outside world. This way you can be sure that while the user is playing around in
the tutorial sandbox they are not accidentally making network requests, saving data to disk or
overwriting settings in user defaults.

> Note: The method ``withDependencies(from:operation:fileID:filePath:line:column:)`` used in the
> code snippet above is subtly different from ``withDependencies(_:operation:)``. It takes an extra
> argument, `from`, which is the object from which we propagate the dependencies before overriding 
> some. This allows you to propagate dependencies from object to object.
>
> In general you should _always_ use this method when constructing model objects from other model
> objects. See [Scoping dependencies](#Scoping-dependencies) for more information.

## Scoping dependencies

Extra care must be taken when overriding dependencies in order for the new dependencies to propagate
down to child models, and grandchild models, and on and on. All child models constructed should be
done so inside an invocation of ``withDependencies(from:operation:fileID:filePath:line:column:)`` so
that the child model picks up the exact dependencies the parent is using.

For example, taking the code sample from above, suppose that the `TodosModel` could drill down to an
edit screen for a particular todo. You could model that with an `EditTodoModel` and a piece of
optional state that when hydrated causes the drill down:

```swift
@Observable
final class TodosModel {
  var todos: [Todo] = []
  var editTodo: EditTodoModel?

  @ObservationIgnored
  @Dependency(\.apiClient) var apiClient
  @ObservationIgnored
  @Dependency(\.fileManager) var fileManager
  @ObservationIgnored
  @Dependency(\.userDefaults) var userDefaults

  func tappedTodo(_ todo: Todo) {
    editTodo = EditTodoModel(todo: todo)
  }

  // ...
}
```

However, when constructing `EditTodoModel` inside the `tappedTodo` method, its dependencies will go
back to the default ``DependencyKey/liveValue`` that the application launches with. It will not have
any of the overridden dependencies from when the `TodosModel` was created.

In order to make sure the overridden dependencies continue to propagate to the child feature, you
must wrap the creation of the child model in
``withDependencies(from:operation:fileID:filePath:line:column:)``:

```swift
func tappedTodo(_ todo: Todo) {
  editTodo = withDependencies(from: self) {
    EditTodoModel(todo: todo)
  }
}
```

Note that we are using `withDependencies(from: self)` in the above code. That is what allows the
`EditTodoModel` to be constructed with all the same dependencies as `self`, and should be used
even if you are not explicitly overriding dependencies.

## Testing

To override dependencies in tests you can use ``withDependencies(_:operation:)-4uz6m`` in the
same way you override dependencies in features. For example, if a model uses an API client to fetch
a user when the view appears, a test for this functionality could be written by overriding the
`apiClient` to return some mock data:

```swift
@Test
func onAppear() async {
  let model = withDependencies {
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
    FeatureModel()
  }

  #expect(model.user == nil)
  await model.onAppear()
  #expect(model.user == User(id: 42, name: "Blob"))
}
```

Sometimes there is a dependency that you want to override in a particular way for the entire test
case. For example, your feature may make extensive use of the ``DependencyValues/date`` dependency
and it may be cumbersome to override it in every test. Instead, it can be done a single time by
overriding `invokeTest` in your test case class:

```swift
final class FeatureTests: XCTestCase {
  override func invokeTest() {
    withDependencies {
      $0.date.now = Date(timeIntervalSince1970: 1234567890)
    } operation: {
      super.invokeTest()
    }
  }

  // All test functions will use the mock date generator.
}
```

Any dependencies overridden in `invokeTest` will be overridden for the entirety of the test case.

You can also implement a base test class for other test cases to inherit from in order to provide
a base set of dependencies for many test cases to use:

```swift
class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withDependencies {
      // Mutate $0 to override dependencies for all test
      // cases that inherit from BaseTestCase.
      // ...
    } operation: {
      super.invokeTest()
    }
  }
}
```

[swift-identified-collections]: https://github.com/pointfreeco/swift-identified-collections
[environment-values-docs]: https://developer.apple.com/documentation/swiftui/environmentvalues
