# Comparison: Full Library vs. Minimal Implementation

## File Count Comparison

**Full Library:**
- ~25+ source files
- Multiple targets (Dependencies, DependenciesMacros, DependenciesTestSupport, etc.)
- 4 external dependencies (xctest-dynamic-overlay, swift-clocks, combine-schedulers, swift-concurrency-extras)
- Swift syntax for macro support

**Minimal Implementation:**
- 5 source files (DependencyContext.swift, DependencyKey.swift, DependencyValues.swift, Dependency.swift, WithDependencies.swift)
- Single target
- Zero external dependencies

## Line Count Comparison

**Full Library:**
- DependencyValues.swift: ~635 lines
- Dependency.swift: ~267 lines
- DependencyKey.swift: ~282 lines
- WithDependencies.swift: ~620 lines
- Plus 20+ additional files

**Minimal Implementation:**
- DependencyContext.swift: ~17 lines
- DependencyKey.swift: ~54 lines
- DependencyValues.swift: ~181 lines
- Dependency.swift: ~86 lines
- WithDependencies.swift: ~56 lines
- **Total: ~394 lines** (vs. thousands in full library)

## Feature Comparison

| Feature | Full Library | Minimal |
|---------|--------------|---------|
| **Core DI Mechanism** | ✅ | ✅ |
| @Dependency property wrapper | ✅ | ✅ |
| DependencyKey protocol | ✅ | ✅ |
| TestDependencyKey protocol | ✅ | ✅ |
| DependencyValues registry | ✅ | ✅ |
| @TaskLocal storage | ✅ | ✅ |
| withDependencies (sync) | ✅ | ✅ |
| withDependencies (async) | ✅ | ✅ |
| Three contexts (live/preview/test) | ✅ | ✅ |
| Automatic context detection | ✅ | ✅ |
| Caching per context | ✅ | ✅ (simplified) |
| **Additional Features** |  |  |
| @DependencyClient macro | ✅ | ❌ |
| @DependencyEndpoint macro | ✅ | ❌ |
| prepareDependencies | ✅ | ❌ |
| withEscapedDependencies | ✅ | ❌ |
| withDependencies(from:) | ✅ | ❌ |
| DependencyValues.Continuation | ✅ | ❌ |
| Dependency object tracking | ✅ | ❌ |
| **Pre-built Dependencies** |  |  |
| Date dependency | ✅ | ❌ |
| UUID dependency | ✅ | ❌ |
| Clock dependencies | ✅ | ❌ |
| MainQueue dependency | ✅ | ❌ |
| URLSession dependency | ✅ | ❌ |
| Calendar, Locale, TimeZone | ✅ | ❌ |
| FireAndForget | ✅ | ❌ |
| Assert dependency | ✅ | ❌ |
| OpenURL dependency | ✅ | ❌ |
| **Testing Support** |  |  |
| Swift Testing trait | ✅ | ❌ |
| Automatic cache reset | ✅ | ❌ |
| TestContext detection | ✅ | ✅ (simplified) |
| Test observer registration | ✅ | ❌ |
| Per-test isolation | ✅ | ❌ |
| **Developer Experience** |  |  |
| Source location tracking | ✅ | ❌ |
| Rich error messages | ✅ | ❌ |
| IssueReporting integration | ✅ | ❌ |
| Preview app entry detection | ✅ | ❌ |
| Deprecation warnings | ✅ | ❌ |
| **Compatibility** |  |  |
| Swift 5.x support | ✅ | ❌ |
| Swift 6.0+ support | ✅ | ✅ |
| iOS 13+ | ✅ | ✅ |
| macOS 10.15+ | ✅ | ✅ |
| Linux support | ✅ | ✅ |
| Windows support | ✅ | ✅ |
| WASI support | ✅ | ❌ |

## Code Examples

### Defining a Dependency

**Both implementations (identical):**
```swift
extension APIClient: DependencyKey {
  static let liveValue = APIClient.live
  static let testValue = APIClient.mock
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
```

### Using a Dependency

**Both implementations (identical):**
```swift
@Dependency(\.apiClient) var apiClient
```

### Overriding in Tests

**Both implementations (identical):**
```swift
withDependencies {
  $0.apiClient = .mock
} operation: {
  // Test code
}
```

### Using @DependencyClient Macro

**Full Library:**
```swift
@DependencyClient
struct APIClient {
  var fetchUser: (Int) async throws -> User
}
// Automatically generates unimplemented defaults
```

**Minimal Implementation:**
```swift
// No macro support - define struct manually
struct APIClient: Sendable {
  var fetchUser: @Sendable (Int) async throws -> User
}
```

### Escaping Closures

**Full Library:**
```swift
withEscapedDependencies { dependencies in
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    dependencies.yield {
      // Use dependencies here
    }
  }
}
```

**Minimal Implementation:**
```swift
// Not supported - use structured concurrency instead
Task {
  try await Task.sleep(for: .seconds(1))
  // Dependencies automatically propagate
}
```

## Performance Comparison

| Metric | Full Library | Minimal |
|--------|--------------|---------|
| Compile time | Slower (macros + more files) | Faster |
| Binary size | Larger | Smaller |
| Runtime overhead | Low | Lower |
| Memory usage | More (complex caching) | Less (simple caching) |

## When to Choose Each

### Choose Full Library When:
- You want rich developer experience with detailed error messages
- You need `@DependencyClient` macro for automatic mock generation
- You want pre-built dependencies (date, uuid, clocks, etc.)
- You need escaping closure support (`withEscapedDependencies`)
- You want automatic test cache management
- You need dependency propagation from parent to child models
- You want Swift Testing trait support

### Choose Minimal Implementation When:
- You want zero external dependencies
- You prefer minimal code footprint
- You only need core DI functionality
- You're comfortable with structured concurrency
- You want faster compile times
- You want to understand exactly how the DI system works
- You're building a library that shouldn't pull in heavy dependencies

## Migration Path

If you start with the minimal implementation and later need full library features:

1. The APIs are identical for core functionality
2. Simply swap `import MinimalDependencies` with `import Dependencies`
3. No code changes needed for basic usage
4. Gradually adopt additional features as needed (macros, pre-built dependencies, etc.)

## Summary

The minimal implementation provides **80% of the value with 10% of the code**. It contains only the essential mechanism that makes the dependency injection work:

- `@TaskLocal` for automatic propagation
- Property wrapper for ergonomic access
- Protocol-based registration
- Context-aware resolution

Everything else in the full library (macros, pre-built dependencies, advanced features) is **convenience**, not **necessity**. If you understand how the minimal version works, you understand the core principle behind the full library.
