# Concurrency support

Learn about the concurrency tools that come with the library that make writing tests and
implementing dependencies easy.

## Overview

The library comes with a small number of concurrency tools that can be handy when constructing
dependency implementations and testing features that use dependencies.

### ActorIsolated and LockIsolated

The ``ActorIsolated`` and ``LockIsolated`` types help wrap other values in an isolated context.
``ActorIsolated`` wraps the value in an actor so that the only way to access and mutate the value is
through an async/await interface. ``LockIsolated`` wraps the value in a class with a lock, which
allows you to read and write the value with a synchronous interface. You should prefer to use
``ActorIsolated`` when you have access to an asynchronous context.

### AsyncStream and AsyncThrowingStream

The library comes with numerous helper APIs spread across the two Swift stream types:

  * There are helpers that erase any `AsyncSequence` conformance to either concrete stream type.
    This allows you to treat the stream type as a kind of "type erased" `AsyncSequence`.

    For example, suppose you have a dependency client like this:

    ```swift
    struct ScreenshotsClient {
      var screenshots: () -> AsyncStream<Void>
    }
    ```

    Then you can construct a live implementation that "erases" the
    `NotificationCenter.Notifications` async sequence to a stream:

    ```swift
    extension ScreenshotsClient {
      static let live = Self(
        screenshots: {
          NotificationCenter.default
            .notifications(named: UIApplication.userDidTakeScreenshotNotification)
            .map { _ in }
            .eraseToStream()  // ⬅️
        }
      )
    }
    ```

    Use `eraseToThrowingStream()` to propagate failures from throwing async sequences.

  * There is an API for simultaneously constructing a stream and its backing continuation. This can
    be handy in tests when overriding a dependency endpoint that returns a stream:

    ```swift
    let screenshots = AsyncStream.makeStream(of: Void.self)

    let model = withDependencies {
      $0.screenshots = { screenshots.stream }
    } operation: {
      FeatureModel()
    }

    XCTAssertEqual(model.screenshotCount, 0)
    screenshots.continuation.yield()  // Simulate a screenshot being taken.
    XCTAssertEqual(model.screenshotCount, 1)
    ```

  * Static `AsyncStream.never` and `AsyncThrowingStream.never` helpers are provided that represent
    streams that live forever and never emit. They can be handy in tests that need to override a
    dependency endpoint with a stream that should suspend and never emit for the duration test.

  * Static `AsyncStream.finished` and `AsyncThrowingStream.finished(throwing:)` helpers are provided
    that represents streams that complete immediately without emitting. They can be handy in tests
    that need to override a dependency endpoint with a stream that completes/fails immediately.

### Task

The library comes with a static function, `Task.never()`, that can asynchronously return a value of
any type, but does so by suspending forever. This can be useful for satisfying a dependency
requirement in a way that does not require you to actually return data from that endpoint.

### UncheckedSendable

A wrapper type that can make any type `Sendable`, but in an unsafe and unchecked way. This type
should only be used as an alternative to `@preconcurrency import`, which turns off concurrency
checks for everything in the library. Whereas ``UncheckedSendable`` allows you to turn off
concurrency warnings for just one single usage of a particular type.
