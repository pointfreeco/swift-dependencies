#if !os(Windows)
  import Foundation

  @_spi(Concurrency) public func withMainSerialExecutor<T>(
    @_implicitSelfCapture operation: () async throws -> T
  ) async rethrows -> T {
    guard let pointer = swift_task_enqueueGlobal_hook else { return try await operation() }
    let hook = pointer.pointee
    defer { pointer.pointee = hook }
    pointer.pointee = { job, original in
      MainActor.shared.enqueue(job)
    }
    return try await operation()
  }

  // here be dragons
  private typealias Orig = @convention(thin) (UnownedJob) -> Void
  private typealias Hook = @convention(thin) (UnownedJob, Orig) -> Void
  private var swift_task_enqueueGlobal_hook: UnsafeMutablePointer<Hook>? = {
    dlsym(dlopen(nil, 0), "swift_task_enqueueGlobal_hook")?
      .assumingMemoryBound(to: Hook.self)
  }()
#endif
