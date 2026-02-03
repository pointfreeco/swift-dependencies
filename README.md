# Dependencies

A lightweight dependency injection library for Swift, containing only the core mechanism without additional features.

## What's Included

This library contains only the essential components:

### Core Components

- **`DependencyValues`** - Global registry using `@TaskLocal` storage for automatic propagation through async/await
- **`@Dependency`** - Property wrapper for ergonomic access via KeyPath or Type
- **`DependencyKey`** protocol - Defines live/preview/test values
- **`TestDependencyKey`** protocol - Base protocol for interface/implementation separation
- **`withDependencies`** - Scoping function to temporarily override dependencies (sync & async)
- **`DependencyContext`** enum - Three contexts: live, preview, test
- Automatic context detection (Xcode previews, XCTest, live)
- Basic caching per context

## What's Been Removed

All extra features have been stripped out:

- ❌ `@DependencyClient` and `@DependencyEndpoint` macros
- ❌ Pre-built dependencies (date, uuid, mainQueue, continuousClock, etc.)
- ❌ `prepareDependencies` - app-level setup
- ❌ `withEscapedDependencies` - escaping closure support
- ❌ Swift Testing `.dependencies` trait
- ❌ Dependency object tracking and propagation from parent models
- ❌ Complex test observer setup and automatic cache reset
- ❌ Source location tracking for debugging
- ❌ IssueReporting integration (uses simple fatalError)
- ❌ All deprecations and backwards compatibility code
- ❌ Support for older Swift versions (Swift 6.0+ only)

## Usage

### 1. Define Your Dependency

```swift
struct APIClient: Sendable {
  var fetchUser: @Sendable (Int) async throws -> User
  var saveUser: @Sendable (User) async throws -> Void
}

// Conform to DependencyKey
extension APIClient: DependencyKey {
  static let liveValue = APIClient(
    fetchUser: { id in
      // Real network implementation
      try await URLSession.shared.data(from: URL(string: "https://api.example.com/users/\(id)")!)
      // ... decode and return User
    },
    saveUser: { user in
      // Real save implementation
    }
  )

  static let testValue = APIClient(
    fetchUser: { _ in User.mock },
    saveUser: { _ in }
  )
}
```

### 2. Register in DependencyValues

```swift
extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
```

### 3. Use via Property Wrapper

```swift
@Observable
final class UserListViewModel {
  @ObservationIgnored
  @Dependency(\.apiClient) var apiClient

  func loadUser(id: Int) async throws {
    let user = try await apiClient.fetchUser(id)
    // ...
  }
}
```

### 4. Override in Tests

```swift
func testLoadUser() async throws {
  let mockUser = User(id: 42, name: "Test User")

  let model = withDependencies {
    $0.apiClient.fetchUser = { _ in mockUser }
  } operation: {
    UserListViewModel()
  }

  try await model.loadUser(id: 42)
  // Assertions...
}
```

## How It Works

The core mechanism relies on three key features:

1. **`@TaskLocal` Storage** - Dependencies are stored in task-local storage, so they automatically propagate through Swift's structured concurrency without manual threading

2. **Lazy Initialization with Caching** - Each dependency is computed once per context (live/preview/test) and then cached

3. **Context-Aware Resolution** - Automatically detects whether code is running in a live app, Xcode preview, or test environment and returns the appropriate value

## Benefits

- ✅ Zero external dependencies
- ✅ Minimal code footprint (~300 lines)
- ✅ Automatic propagation through async/await
- ✅ Type-safe dependency injection
- ✅ Prevents accidental use of live dependencies in tests
- ✅ Works seamlessly with SwiftUI previews

## Limitations

- No macro support (you must manually define your dependency structs)
- No pre-built dependencies (you define only what you need)
- No escaping closure support (use structured concurrency instead)
- Test failures use simple `fatalError` instead of rich issue reporting
- No automatic test cache reset between tests (call `resetCache()` manually if needed)

## Design Philosophy

This library focuses on:
- **Simplicity** - Zero external dependencies, minimal code
- **Core functionality** - Only the essential DI mechanism
- **Modern Swift** - Leverages Swift 6.0+ and structured concurrency
- **Type safety** - Compile-time safety with property wrappers
