# Registering dependencies

Learn how to register your own dependencies with the library so that they immediately become
available from any part of your code base.

## Overview

Although the library comes with many controllable dependencies out of the box, there are still times
when you want to register your own dependencies with the library so that you can use them with the
``Dependency`` property wrapper. There are a couple ways to achieve this, and the process is quite
similar to registering a value with [the environment][environment-values-docs] in SwiftUI.

First you create a ``DependencyKey`` protocol conformance. The minimum implementation you must
provide is a ``DependencyKey/liveValue``, which is the value used when running the app in a
simulator or on device, and so it's appropriate for it to actually make network requests to an
external server. It is usually convenient to conform the type of dependency directly to this
protocol:

```swift
extension APIClient: DependencyKey {
  static let liveValue = APIClient(/*
    Construct the "live" API client that actually makes network 
    requests and communicates with the outside world.
  */)
}
```

> Tip: There are two other values you can provide for a dependency. If you implement
> ``DependencyKey/testValue-5v726`` it will be used when running features in tests, and if you
> implement `previewValue` it  will be used while running features in an Xcode preview. You don't
> need to worry about those values when you are just getting started, and instead can add them
> later. See <Doc:LivePreviewTest> for more information.

With that done you can instantly access your API client dependency from any part of your code base:

```swift
@Observable
final class TodosModel {
  @ObservationIgnored
  @Dependency(APIClient.self) var apiClient
  // ...
}
```

This will automatically use the live dependency in previews, simulators and devices, and in tests
you can override the dependency to return mock data:

```swift
@MainActor
@Test
func fetchUser() async {
  let model = withDependencies {
    $0[APIClient.self].fetchTodos = { _ in Todo(id: 1, title: "Get milk") }
  } operation: {
    TodosModel()
  }

  await store.loadButtonTapped()
  #expect(
    model.todos == [Todo(id: 1, title: "Get milk")]
  )
}
```

## Advanced techniques

### Dependency key paths

You can take one additional step to register your dependency value at a particular key path, and
that is by extending `DependencyValues` with a property:

```swift
extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }
}
```

This allows you to access and override the dependency in way similar to SwiftUI environment values,
as a property that is discoverable from autocomplete:

```diff
-@Dependency(APIClient.self) var apiClient
+@Dependency(\.apiClient) var apiClient

 let model = withDependencies {
-  $0[APIClient.self].fetchTodos = { _ in Todo(id: 1, title: "Get milk") }
+  $0.apiClient.fetchTodos = { _ in Todo(id: 1, title: "Get milk") }
 } operation: {
   TodosModel()
 }
```

Another benefit of this style is the ability to scope a `@Dependency` to a specific sub-property:

```swift
// This feature only needs to access the API client's logged-in user
@Dependency(\.apiClient.currentUser) var currentUser
```

### Indirect dependency key conformances

It is not always appropriate to conform your dependency directly to the `DependencyKey` protocol,
for example if it is a type you do not own. In such cases you can define a separate type that
conforms to `DependencyKey`:

```swift
enum UserDefaultsKey: DependencyKey {
  static let liveValue = UserDefaults.standard
}
```

You can then access and override your dependency through this key type, instead of the value's type:

```swift
@Dependency(UserDefaultsKey.self) var userDefaults

let model = withDependencies {
  let defaults = UserDefaults(suiteName: "test-defaults")
  defaults.removePersistentDomain(forName: "test-defaults")
  $0[UserDefaultsKey.self] = defaults
} operation: {
  TodosModel()
}
```

If you extend dependency values with a dedicated key path, you can even make this key private:

```diff
-enum UserDefaultsKey: DependencyKey { /* ... */ }
+private enum UserDefaultsKey: DependencyKey { /* ... */ }
+
+extension DependencyValues {
+  var userDefaults: UserDefaults {
+    get { self[UserDefaultsKey.self] }
+    set { self[UserDefaultsKey.self] = newValue }
+  }
+}
```

[environment-values-docs]: https://developer.apple.com/documentation/swiftui/environmentvalues
