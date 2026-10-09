#if Clocks && !canImport(Clocks2)
  import Clocks

  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public typealias NonsendingClock<Duration> = Clock<Duration>
#endif
