import Foundation

extension DependencyValues {
  /// A dependency that yields a random number generator to a closure.
  ///
  /// Introduce controllable randomness to your features by using the ``Dependency`` property
  /// wrapper with a key path to this property. The wrapped value is an instance of
  /// ``WithRandomNumberGenerator``, which can be called with a closure to yield a random number
  /// generator. (It can be called directly because it defines
  /// ``WithRandomNumberGenerator/callAsFunction(_:)``, which is called when you invoke the instance
  /// as you would invoke a function.)
  ///
  /// For example, you could introduce controllable randomness to an observable object model that
  /// handles rolling a couple dice:
  ///
  /// ```swift
  /// final class GameModel: ObservableObject {
  ///   @Published var dice = (1, 1)
  ///
  ///   @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
  ///
  ///   func rollDice() {
  ///     self.dice = self.withRandomNumberGenerator { generator in
  ///       (
  ///         Int.random(in: 1...6, using: &generator),
  ///         Int.random(in: 1...6, using: &generator)
  ///       )
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// By default, a `SystemRandomNumberGenerator` will be provided to the closure, with the
  /// exception of when run in tests, in which an unimplemented dependency will be provided that
  /// calls `XCTFail`.
  ///
  /// To test a feature that depends on randomness, you can override its random number generator.
  /// Inject a dependency by calling ``WithRandomNumberGenerator/init(_:)`` with a random number
  /// generator that offers predictable randomness. For example, you could test the dice-rolling of
  /// a game's model by supplying a seeded random number generator as a dependency:
  ///
  /// ```swift
  /// func testRoll() {
  ///   let model = withDependencies {
  ///     $0.withRandomNumberGenerator = WithRandomNumberGenerator(LCRNG(seed: 0))
  ///   } operation: {
  ///     GameModel()
  ///   }
  ///
  ///   model.rollDice()
  ///   XCTAssert(model.dice == (1, 3))
  /// }
  /// ```
  public var withRandomNumberGenerator: WithRandomNumberGenerator {
    get { self[WithRandomNumberGeneratorKey.self] }
    set { self[WithRandomNumberGeneratorKey.self] = newValue }
  }

  private enum WithRandomNumberGeneratorKey: DependencyKey {
    static let liveValue = WithRandomNumberGenerator(SystemRandomNumberGenerator())
  }
}

/// A dependency that yields a random number generator to a closure.
///
/// See ``DependencyValues/withRandomNumberGenerator`` for more information.
public final class WithRandomNumberGenerator: @unchecked Sendable {
  private var generator: RandomNumberGenerator
  private let lock = NSLock()

  public init<T: RandomNumberGenerator & Sendable>(_ generator: T) {
    self.generator = generator
  }

  public func callAsFunction<R>(_ work: (inout RandomNumberGenerator) -> R) -> R {
    self.lock.lock()
    defer { self.lock.unlock() }
    return work(&self.generator)
  }
}
