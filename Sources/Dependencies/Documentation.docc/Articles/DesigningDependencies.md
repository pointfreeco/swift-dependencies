# Designing dependencies

Learn techniques on designing your dependencies so that they are most flexible for injecting into
features and overriding for tests.

* [Protocol-based dependencies](#Protocol-based-dependencies)
* [Struct-based dependencies](#Struct-based-dependencies)
* [@DependencyClient macro](#DependencyClient-macro)

## Overview

Making it possible to control your dependencies is the most important step you can take towards
making your features isolatable and testable. The second most important step after that is to design
your dependencies in a way that maximizes their flexibility in tests and other situations.

> Tip: We have an [entire series of episodes][designing-deps] dedicated to the topic of dependencies
> and how to best design and construct them.

## Protocol-based dependencies

The most popular way to design dependencies in Swift is to use protocols. For example, if your
feature needs to interact with an audio player, you might design a protocol with methods for
playing, stopping, and more:

```swift
protocol AudioPlayer {
  func loop(url: URL) async throws
  func play(url: URL) async throws
  func setVolume(_ volume: Float) async
  func stop() async
}
```

Then you are free to make as many conformances of this protocol as you want, such as a
`LiveAudioPlayer` that actually interacts with AVFoundation, or a `MockAudioPlayer` that doesn't
play any sounds, but does suspend in order to simulate that something is playing. You could even
have an `UnimplementedAudioPlayer` conformance that invokes `reportIssue` when any method is 
invoked:

```swift
struct LiveAudioPlayer: AudioPlayer {
  let audioEngine: AVAudioEngine
  // ...
}
struct MockAudioPlayer: AudioPlayer {
  // ...
}
struct UnimplementedAudioPlayer: AudioPlayer {
  func loop(url: URL) async throws {
    reportIssue("AudioPlayer.loop is unimplemented")
  }
  // ...
}
```

And all of those conformances can be used to specify the live, preview and test values for the
dependency:

```swift
private enum AudioPlayerKey: DependencyKey {
  static let liveValue: any AudioPlayer = LiveAudioPlayer()
  static let previewValue: any AudioPlayer = MockAudioPlayer()
  static let testValue: any AudioPlayer = UnimplementedAudioPlayer()
}
```

> Tip: See <doc:LivePreviewTest> for more information on how to best leverage live, preview and test
> implementations of your dependencies.

This style of dependencies works just fine, and if it is what you are most comfortable with then
there is no need to change.

## Struct-based dependencies

However, there is a small change one can make to this dependency to unlock even more power. Rather
than designing the audio player as a protocol, we can use a struct with closure properties to
represent the interface:

```swift
struct AudioPlayerClient {
  var loop: (_ url: URL) async throws -> Void
  var play: (_ url: URL) async throws -> Void
  var setVolume: (_ volume: Float) async -> Void
  var stop: () async -> Void
}
```

Then, rather than defining types that conform to the protocol you construct values:

```swift
extension AudioPlayerClient {
  static var live: Self {
    let audioEngine: AVAudioEngine
    return Self(/*...*/)
  }

  static let mock = Self(/* ... */)

  static let unimplemented = Self(
    loop: { _ in reportIssue("AudioPlayerClient.loop is unimplemented") },
    // ...
  )
}
```

Then, to register this dependency you can leverage the `AudioPlayerClient` struct to conform
to the ``DependencyKey`` protocol. There's no need to define a new type. In fact, you can even 
define the live, preview and test values directly in the conformance, all at once:

```swift
extension AudioPlayerClient: DependencyKey {
  static var liveValue: Self {
    let audioEngine: AVAudioEngine
    return Self(/* ... */)
  }

  static let previewValue = Self(/* ... */)

  static let testValue = Self(
    loop: unimplemented("AudioPlayerClient.loop"),
    play: unimplemented("AudioPlayerClient.play"),
    setVolume: unimplemented("AudioPlayerClient.setVolume"),
    stop: unimplemented("AudioPlayerClient.stop")
  )
}

extension DependencyValues {
  var audioPlayer: AudioPlayerClient {
    get { self[AudioPlayerClient.self] }
    set { self[AudioPlayerClient.self] = newValue }
  }
}
```

> Tip: We are using the `unimplemented` method from our 
> [Issue Reporting][issue-reporting-gh] library to provide closures that cause an
> XCTest failure if they are ever invoked. See <doc:LivePreviewTest> for more information on this
> pattern.

If you design your dependencies in this way you can pick which dependency endpoints you need in your
feature. For example, if you have a feature that needs an audio player to do its job, but it only
needs the `play` endpoint, and doesn't need to loop, set volume or stop audio, then you can specify
a dependency on just that one function:

```swift
@Observable
final class FeatureModel {
  @ObservationIgnored
  @Dependency(\.audioPlayer.play) var play
  // ...
}
```

This can allow your features to better describe the minimal interface they need from dependencies,
which can help a feature seem less intimidating.

You can also override the bare minimum of the dependency in tests. For example, suppose that one
user flow of your feature you are testing invokes the `play` endpoint, but you don't think any other
endpoint will be called. Then you can write a test that overrides only that one single endpoint:

```swift
func testFeature() {
  let isPlaying = ActorIsolated(false)

  let model = withDependencies {
    $0.audioPlayer.play = { _ in await isPlaying.setValue(true) }
  } operation: {
    FeatureModel()
  }

  await model.play()
  XCTAssertEqual(isPlaying.value, true)
}
```

If this test passes you can be guaranteed that no other endpoints of the dependency are used in the
user flow you are testing. If someday in the future more of the dependency is used, you will
instantly get a test failure, letting you know that there is more behavior that you must assert on.

## @DependencyClient macro

The library ships with a macro that can help improve the ergonomics of struct-based dependency
interfaces. The macro ships as a separate library within this package because it depends on 
SwiftSyntax, and that increases the build times by about 20 seconds. We did not want to force
everyone using this library to incur that cost, so if you want to use the macro you will need to
explicitly add the `DependenciesMacros` product to your targets.

Once that is done you can apply the `@DependencyClient` macro directly to your dependency struct:

```swift
import DependenciesMacros

@DependencyClient
struct AudioPlayerClient {
  var loop: (_ url: URL) async throws -> Void
  var play: (_ url: URL) async throws -> Void
  var setVolume: (_ volume: Float) async -> Void
  var stop: () async -> Void
}
```

This does a few things for you. First, it automatically provides a default for each endpoint that
simply throws an error and triggers an XCTest failure. This means you get an "unimplemented" client
for free with no additional work. This allows you to simplify the `testValue` of your 
``TestDependencyKey`` conformance like so:

```diff
 extension AudioPlayerClient: TestDependencyKey {
-  static let testValue = Self(
-    loop: unimplemented("AudioPlayerClient.loop"),
-    play: unimplemented("AudioPlayerClient.play"),
-    setVolume: unimplemented("AudioPlayerClient.setVolume"),
-    stop: unimplemented("AudioPlayerClient.stop")
-  )
+  static let testValue = Self()
 }
```

This behaves the exact same as before, but now all of the code is generated for you.

Further, when you provide argument labels to the client's closure endpoints, the macro turns that 
information into methods with argument labels. This means you can invoke the `play` endpoint
like so:

```swift
try await player.play(url: URL(filePath: "..."))
```

And finally, the macro also generates a public initializer for you with all of the client's 
endpoints. One typically needs to maintain this initializer when separate the interface of the 
dependency from the implementation (see 
<doc:LivePreviewTest#Separating-interface-and-implementation> for more information). But now there
is no need to maintain that code as it is automatically provided for you by the macro.

[designing-deps]: https://www.pointfree.co/collections/dependencies
[issue-reporting-gh]: http://github.com/pointfreeco/swift-issue-reporting
