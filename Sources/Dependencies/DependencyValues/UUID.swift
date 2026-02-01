import Foundation

extension DependencyValues {
  /// A dependency that generates UUIDs.
  ///
  /// Introduce controllable UUID generation to your features by using the ``Dependency`` property
  /// wrapper with a key path to this property. The wrapped value is an instance of
  /// ``UUIDGenerator``, which can be called with a closure to create UUIDs. (It can be called
  /// directly because it defines ``UUIDGenerator/callAsFunction()``, which is called when you
  /// invoke the instance as you would invoke a function.)
  ///
  /// For example, you could introduce controllable UUID generation to an observable object model
  /// that creates to-dos with unique identifiers:
  ///
  /// ```swift
  /// @Observable
  /// final class TodosModel {
  ///   var todos: [Todo] = []
  ///
  ///   @ObservationIgnored
  ///   @Dependency(\.uuid) var uuid
  ///
  ///   func addButtonTapped() {
  ///     todos.append(Todo(id: uuid()))
  ///   }
  /// }
  /// ```
  ///
  /// By default, a "live" generator is supplied, which returns a random UUID when called by
  /// invoking `UUID.init` under the hood.  When used in tests, an "unimplemented" generator that
  /// additionally reports test failures if invoked, unless explicitly overridden.
  ///
  /// To test a feature that depends on UUID generation, you can override its generator using
  /// ``withDependencies(_:operation:)-4uz6m`` to override the underlying ``UUIDGenerator``:
  ///
  ///   * ``UUIDGenerator/incrementing`` for reproducible UUIDs that count up from
  ///     `00000000-0000-0000-0000-000000000000`.
  ///
  ///   * ``UUIDGenerator/constant(_:)`` for a generator that always returns the given UUID.
  ///
  /// For example, you could test the to-do-creating model by supplying an
  /// ``UUIDGenerator/incrementing`` generator as a dependency:
  ///
  /// ```swift
  /// @Test
  /// func feature() {
  ///   let model = withDependencies {
  ///     $0.uuid = .incrementing
  ///   } operation: {
  ///     TodosModel()
  ///   }
  ///
  ///   model.addButtonTapped()
  ///   #expect(
  ///     model.todos == [
  ///       Todo(id: UUID(0))
  ///     ]
  ///   )
  /// }
  /// ```
  ///
  /// > Note: This test uses the special ``Foundation/UUID/init(_:)`` UUID initializer that comes
  /// with this library.
  public var uuid: UUIDGenerator {
    get { self[UUIDGeneratorKey.self] }
    set { self[UUIDGeneratorKey.self] = newValue }
  }

  private enum UUIDGeneratorKey: DependencyKey {
    static let liveValue = UUIDGenerator { UUID() }
  }
}

/// A dependency that generates a UUID.
///
/// See ``DependencyValues/uuid`` for more information.
public struct UUIDGenerator: Sendable {
  private let generate: @Sendable () -> UUID

  /// A generator that returns a constant UUID.
  ///
  /// - Parameter uuid: A UUID to return.
  /// - Returns: A generator that always returns the given UUID.
  public static func constant(_ uuid: UUID) -> Self {
    Self { uuid }
  }

  /// A generator that generates UUIDs in incrementing order.
  ///
  /// For example:
  ///
  /// ```swift
  /// let generate = UUIDGenerator.incrementing
  /// generate()  // UUID(00000000-0000-0000-0000-000000000000)
  /// generate()  // UUID(00000000-0000-0000-0000-000000000001)
  /// generate()  // UUID(00000000-0000-0000-0000-000000000002)
  /// ```
  public static var incrementing: Self {
    let generator = IncrementingUUIDGenerator()
    return Self { generator() }
  }

  /// Initializes a UUID generator that generates a UUID from a closure.
  ///
  /// - Parameter generate: A closure that returns the current date when called.
  public init(_ generate: @escaping @Sendable () -> UUID) {
    self.generate = generate
  }

  public func callAsFunction() -> UUID {
    self.generate()
  }
}

extension UUID {
  /// Initializes a UUID from an integer by converting it to hex and padding it with 0's.
  ///
  /// For example:
  ///
  /// ```swift
  /// UUID(16) == UUID(uuidString: "00000000-0000-0000-0000-000000000010")
  /// ```
  ///
  /// If a negative number is passed to this function then it is inverted and the negative sign
  /// is encoded into the 16th bit of the UUID:
  ///
  /// ```swift
  /// UUID(-16) == UUID(uuidString: "00000000-0000-0001-0000-000000000010")
  ///                                            👆
  /// ```
  public init(_ intValue: Int) {
    let isNegative = intValue < 0
    let intValue = isNegative ? -intValue : intValue
    var hexString = String(format: "%016llx", intValue)
    hexString.insert("-", at: hexString.index(hexString.startIndex, offsetBy: 4))
    self.init(uuidString: "00000000-0000-000\(isNegative ? "1" : "0")-\(hexString)")!
  }
}

private struct IncrementingUUIDGenerator: Sendable {
  private let sequence = LockIsolated(0)

  func callAsFunction() -> UUID {
    sequence.withValue { sequence in
      defer { sequence += 1 }
      return UUID(sequence)
    }
  }
}
