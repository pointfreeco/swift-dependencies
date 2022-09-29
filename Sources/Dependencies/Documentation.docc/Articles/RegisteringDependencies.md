# Registering dependencies

Learn how to register your own dependencies with the library so that they immediately become
available from any part of your code base.

## Overview

Although the library comes with many controllable dependencies out of the box, there are still times
when you want to register your own dependencies with the library so that you can use the
``Dependency`` property wrapper. Doing this is a two-step process and is quite similar to
registering an [environment value][environment-values-docs] in SwiftUI.

First you create a type that conforms to the ``DependencyKey`` protocol. The minimum implementation
you must provide is a ``DependencyKey/liveValue``, which is the value used when running the app in a
simulator or on device, and so it's appropriate for it to actually make network requests to an
external server:

```swift
private enum APIClientKey: DependencyKey {
  static let liveValue = APIClient.live
}
```

> Tip: There are two other values you can provide for a dependency. If you implement
> ``DependencyKey/testValue-5v726`` it will be used when running features in tests, and if you
> implement `previewValue` it  will be used while running features in an Xcode preview. You don't
> need to worry about those values when you are just getting started, and instead can add them
> later. See <Doc:LivePreviewTest> for more information.

Finally, an extension must be made to `DependencyValues` to expose a computed property for the
dependency:

```swift
extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }
}
```

With those few steps completed you can instantly access your API client dependency from any part of
you code base:

```swift
final class TodosModel: ObservableObject {
  @Dependency(\.apiClient) var apiClient
  // ...
}
```

This will automatically use the live dependency in previews, simulators and devices, and in tests
you can override the dependency to return mock data:

```swift
@MainActor
func testFetchUser() async {
  let model = withDependencies {
    $0.apiClient.fetchTodos = { _ in Todo(id: 1, title: "Get milk") }
  } operation: {
    TodosModel()
  }

  await store.loadButtonTapped()
  XCTAssertEqual(
    model.todos,
    [Todo(id: 1, title: "Get milk")]
  )
}
```

Often times it is not necessary to create a whole new type to conform to `DependencyKey`. If the
dependency you are registering is a type that you own, then you can conform it directly to the
protocol:

```swift
extension APIClient: DependencyKey {
  static let liveValue = APIClient.live
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
```

That can save a little bit of boilerplate.

[environment-values-docs]: https://developer.apple.com/documentation/swiftui/environmentvalues
