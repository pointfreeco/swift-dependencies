# Dependency lifetimes

Learn about the lifetimes of dependencies, how to prolong the lifetime of a dependency, and how
dependencies are inherited.

## Overview

When the ``Dependency`` property wrapper is initialized it captures the current state of the
dependency at that moment. This provides a kind of "scoping" mechanism that is similar to how
`@TaskLocal` values are inherited by new asynchronous tasks, but has some new caveats of its own.

## How task locals work

Task locals are what power this library under the hood, and so it can be important to first
understand how task locals work and how task local inheritance works.

Task locals are values that are implicitly associated with a task. They make it possible to push
values deep into every part of an application without having to explicitly pass the values around.
This makes task locals sound like a "global" variable, which you may have heard is bad, but task
locals have 3 features that make them safe to use and easy to reason about:

  * Task locals are safe to use from concurrent contexts. This means multiple tasks can access the
    same task local without fear of a race condition.
  * Task locals can be mutated only in specific, well-defined scopes. It is not allowed to forever
    mutate a task local in a way that all parts of the application observe the change.
  * Task locals are inherited by new tasks that are spun up from existing tasks.

For example, suppose you had the following task local:

```swift
enum Locals {
  @TaskLocal static var value = 1
}
```

The value can only be "mutated" by using the task locals [`withValue`][tasklocal-withvalue-docs]
method, which allows changing `value` only for the scope of a non-escaping closure:

```swift
print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
}
print(Locals.value)  // 1
```

The above shows that `Locals.value` is changed only for the duration of the `withValue` closure.

This may seem very restrictive, but it is also what makes task locals safe and easy to reason about.
You are not allowed to make task local changes to extend for any amount of time, such as mutating it
directly:

```swift
Locals.value = 42
// 🛑 Cannot assign to property: 'value' is a get-only property
```

If this were possible it would make changes to `value` instantly observable from every part of the
application. It could even cause two consecutive reads of `Locals.value` to report different values:

```swift
print(Locals.value)  // 1
print(Locals.value)  // 42
```

This would make code very difficult to reason about, and so is why task locals can be changed for
only very specific scopes.

However, there is a tool that Swift provides that allows task locals to prolong their changes
outside the scope of a non-escaping closure, and does so in a way without making it difficult to
reason about. That tool is known as "task local inheritance." Any child tasks created via
`TaskGroup` or `async let`, as well as tasks created with `Task { }`, inherit the task locals at the
moment they were created.

For example, the following example shows that a task local remains overridden even when accessed
from a `Task` a second later, and even though that closure is escaping:

```swift
enum Locals {
  @TaskLocal static var value = 1
}

print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
  Task {
    try await Task.sleep(for: .seconds(1)
    print(Locals.value)  // 42
  }
  print(Locals.value)  // 42
}
```

Even though the closure handed to `Task` is escaping, and even though the print happens long after
`withValue`'s scope has ended, somehow still "42" is printed. This happens because task locals are
inherited in tasks.

This gives us the ability to prolong the lifetime of a task local change, but in a well-defined and
easy to reason about way.

It is important to note that task locals are not inherited in _all_ escaping contexts. It does work
for [`Task.init`][task-init-docs] and [`TaskGroup.addTask`][group-add-task-docs], which make use of
escaping closures, but only because the standard library special cases those tools to inherit task
locals (see `copyTaskLocals` in [this][task-copy-locals-code] code).

But generally speaking, task local overrides are lost when crossing escaping boundaries. For
example, if instead of using `Task` we used `DispatchQueue.main.asyncAfter` in the above code, we
will observe that the task local resets back to 1 in the escaped closure:

```swift
print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    print(Locals.value)  // 1
  }
  print(Locals.value)  // 42
}
```

So, in conclusion, Swift does extra work to propagate task locals to certain escaping, unstructured
contexts, but does not do so universally, and so care must be taken.

## How @Dependency lifetimes work

Now that we understand how task locals work, we can begin to understand how `@Dependency` lifetimes
work, and how they can be extended. Under the hood, dependencies are held as a `@TaskLocal`, and so
many of the rules from task locals also apply to dependencies, _e.g._ dependencies are inherited in
tasks but not generally across escaping boundaries. But there are a few additional caveats.

Just like with task locals, a dependency's value can be changed for the scope of the trailing,
non-escaping closure of ``withDependencies(_:operation:)-4uz6m``, but the library also ships
with a few tools to prolong the change in a well-defined manner.

For example, suppose you have a feature that needs access to an API client for fetching a user:

```swift
class FeatureModel: ObservableObject {
  @Dependency(\.apiClient) var apiClient

  func onAppear() async {
    do {
      self.user = try await self.apiClient.fetchUser()
    } catch {}
  }
}
```

Sometimes we may want to construct this model in a "controlled" environment, where we use a
different implementation of `apiClient`. Tests are probably the most prototypical example of this.
In tests we do not want to make a live network request since that opens up to the vagaries of the
outside world, and instead we want to provide an implementation of the `apiClient` that
synchronously and immediately return some data so that you can test how that data flows through your
features logic.

The library comes with a helper in order to do this and it's called
``withDependencies(_:operation:)-4uz6m``. It takes two closures: the first allows you
to override any dependencies you want, and the second allows you to execute your feature's logic in
a scope where those dependency mutations are applied:

```swift
func testOnAppear() async {
  await withDependencies {
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
    let model = FeatureModel()
    XCTAssertEqual(model.user, nil)
    await model.onAppear()
    XCTAssertEqual(model.user, User(id: 42, name: "Blob"))
  }
}
```

All code executed in the `operation` trailing closure of
``withDependencies(_:operation:)-4uz6m`` will use the overridden `fetchUser`
endpoint, which makes it possible to exercise the feature's code without making a real network
request.

But, we can take this one step further. We don't need to execute the entire test in the scope of the
trailing `operation` closure. We only need to construct the model in that scope, and then as long as
all dependencies are declared in `FeatureModel` as instance variables, all interactions with the 
model will use the controlled dependencies, even outside the `operation` closure:

```swift
func testOnAppear() async {
  let model = withDependencies {
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
    FeatureModel()
  }

  XCTAssertEqual(model.user, nil)
  await model.onAppear()
  XCTAssertEqual(model.user, User(id: 42, name: "Blob"))
}
```

This is one way in which `@Dependency` can propagate changes outside of its standard scope.

Controlling dependencies isn't only useful in tests. It can also be used directly in your feature's
logic in order to run some child feature in a controlled environment, and can even be used in Xcode
previews.

Let's first see how controlling dependencies can be used directly in a feature's logic. Suppose we
wanted to show this feature in the application as a part of an "onboarding" experience. During the
onboarding experience, we want the user to be able to make use of the feature without executing real
life API requests, which may cause data to be written to a remote database.

Accomplishing this can be difficult because models are created in one scope and then dependencies
are used in another scope. However, as mentioned above, the library does extra work to make it so
that later referencing dependencies of a model uses the dependencies captured at the moment of
creating the model.

For example, if you create the features model in the following way:

```swift
let onboardingModel = withDependencies {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}
```

...then all references to the `apiClient` dependency inside `FeatureModel` will be using the mock
API client. This is true even though the `FeatureModel`'s `onAppear` method will be called outside
the scope of the `operation` closure.

However, care must be taken when creating a child model from a parent model. In order for the
child's dependencies to inherit from the parent's dependencies, you must make use of
``withDependencies(from:operation:file:line:)-8e74m`` when creating the child model:

```swift
let onboardingModel = withDependencies(from: self) {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}
```

This makes `FeatureModel`'s dependencies inherit from the parent feature, and you can further
override any additional dependencies you want.

In general, if you want dependencies to be properly inherited through every layer of feature in your
application, you should make sure to create any `ObservableObject` models inside a
``withDependencies(from:operation:file:line:)-8e74m`` scope.

If you do this, it also allows you to run previews in a very specific environment. Dependencies
already support the concept of a ``TestDependencyKey/previewValue-8u2sy``, which is an
implementation of the dependency used when run in an Xcode preview (see <doc:LivePreviewTest> for
more info). It is most appropriate to implement the ``TestDependencyKey/previewValue-8u2sy`` by
immediately returning some basic, mock data.

But sometimes you want to customize dependencies for the preview so that you can see how your
feature behaves in very specific states. For example, if you wanted to see how your feature reacts
when the `fetchUser` endpoint throws an error, you can update the preview like so:

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

[task-copy-locals-code]: https://github.com/apple/swift/blob/60952b868d46fc9a83619f747a7f92b5534fb632/stdlib/public/Concurrency/Task.swift#L500-L509
[task-init-docs]: https://developer.apple.com/documentation/swift/task/init(priority:operation:)-5k89c
[group-add-task-docs]: https://developer.apple.com/documentation/swift/taskgroup/addtask(priority:operation:)
[tasklocal-withvalue-docs]: https://developer.apple.com/documentation/swift/tasklocal/withvalue(_:operation:file:line:)-1xjor
