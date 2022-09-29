/// A generic wrapper for turning any non-`Sendable` type into a `Sendable` one, in an unchecked
/// manner.
///
/// Sometimes we need to use types that should be sendable but have not yet been audited for
/// sendability. If we feel confident that the type is truly sendable, and we don't want to blanket
/// disable concurrency warnings for a module via `@preconcurrency import`, then we can selectively
/// make that single type sendable by wrapping it in `UncheckedSendable`.
///
/// > Note: By wrapping something in `UncheckedSendable` you are asking the compiler to trust you
/// > that the type is safe to use from multiple threads, and the compiler cannot help you find
/// > potential race conditions in your code.
///
/// To synchronously isolate a value with a lock, see ``LockIsolated``. To asynchronously isolated a
/// value on an actor, see ``ActorIsolated``.
@dynamicMemberLookup
@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
  /// The unchecked value.
  public var value: Value

  /// Initializes unchecked sendability around a value.
  ///
  /// - Parameter value: A value to make sendable in an unchecked way.
  public init(_ value: Value) {
    self.value = value
  }

  public init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  public var wrappedValue: Value {
    _read { yield self.value }
    _modify { yield &self.value }
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.value[keyPath: keyPath]
  }

  public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Subject {
    _read { yield self.value[keyPath: keyPath] }
    _modify { yield &self.value[keyPath: keyPath] }
  }
}

extension UncheckedSendable: Equatable where Value: Equatable {}
extension UncheckedSendable: Hashable where Value: Hashable {}

extension UncheckedSendable: Decodable where Value: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      self.init(wrappedValue: try container.decode(Value.self))
    } catch {
      self.init(wrappedValue: try Value(from: decoder))
    }
  }
}

extension UncheckedSendable: Encodable where Value: Encodable {
  public func encode(to encoder: Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.wrappedValue)
    } catch {
      try self.wrappedValue.encode(to: encoder)
    }
  }
}
