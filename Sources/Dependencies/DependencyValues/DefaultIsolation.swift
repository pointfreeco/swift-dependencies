extension DependencyValues {
  public var defaultIsolation: (any Actor)? {
    get { self[DefaultIsolationKey.self] }
    set { self[DefaultIsolationKey.self] = newValue }
  }
}

private enum DefaultIsolationKey: DependencyKey {
  public static var liveValue: (any Actor)? { nil }
  public static var testValue: (any Actor)? { DefaultIsolation() }
}

private actor DefaultIsolation {}
