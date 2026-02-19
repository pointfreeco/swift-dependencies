#if compiler(>=6)
  typealias SendableKeyPath<Root, Value> = KeyPath<Root, Value> & Sendable
#else
  typealias SendableKeyPath<Root, Value> = KeyPath<Root, Value>
#endif
