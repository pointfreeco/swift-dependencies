#if canImport(Combine)
  import Combine

  extension Scheduler {
    /// Propagates dependencies across `schedule` calls.
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
