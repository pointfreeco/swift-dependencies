#if canImport(Combine)
  import Combine

  extension Scheduler {
    /// Propagates dependencies across the scheduler boundary.
    ///
    /// - Parameter update: Enables transforming the propagated dependencies. No-ops by default.
    /// - Returns: A version of the scheduler that propagates dependencies.
    public func dependencies(
      _ update: @escaping (inout DependencyValues) -> Void = { _ in }
    ) -> AnySchedulerOf<Self> {
      func forward(_ action: @escaping () -> Void) -> () -> Void {
        let continuation = withDependencies(update) { withEscapedDependencies { $0 } }
        return { continuation.yield(action) }
      }
      return AnyScheduler(
        minimumTolerance: { self.minimumTolerance },
        now: { self.now },
        scheduleImmediately: { self.schedule(options: $0, forward($1)) },
        delayed: { self.schedule(after: $0, tolerance: $1, options: $2, forward($3)) },
        interval: { self.schedule(after: $0, interval: $1, tolerance: $2, options: $3, forward($4)) }
      )
    }
  }
#endif
