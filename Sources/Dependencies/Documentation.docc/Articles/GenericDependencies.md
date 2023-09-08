# Generic Dependencies

Learn what a generic dependency is, why they are more complicated than regular dependencies, and
how you can handle them in this library.

## Overview

A generic dependency is one that requires a generic in its interface in some way. This can occur
if you want to model the interface as a struct with a generic, or a protocol with an associated
type, or even just if a method needs a generic. Such dependencies are significantly more complicated
than a non-generic interface, both in terms of how they are provided to features and how one 
provides alternative conconformances for tests, previews, etc.

### What is a generic dependency?

A generic dependency is one that needs a generic somewhere in its interface. For example, you may
have a file client that deals with JSON files on the disk, and could model that with the following
protocol:

```swift
protocol JSONFileClient {
  func save<Model: Encodable>(_ model: Model, to url: URL) throws
  func load<Model: Decodable>(from url: URL) throws -> Model
}
```

A "live" implementation of this that actually reaches out to the file system might look like this:

```swift
struct LiveJSONFileClient: JSONFileClient {
  func save<Model: Encodable>(_ model: Model, to url: URL) throws {
    try JSONEncoder().encode(model).write(to: url)
  }
  func load<Model: Decodable>(from url: URL) throws -> Model {
    try JSONDecoder().decode(Model.self, from: Data(contentsOf: url))
  }
} 
```

Another example 


```swift
protocol MediaPlayer {
  associatedType Media
  func load()
  func stop()
  func play()
  var media: Media
}
```


# What can go wrong with generic dependencies?
