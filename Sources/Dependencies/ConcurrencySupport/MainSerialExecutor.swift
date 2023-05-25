#if !os(WASI) && !os(Windows)
  import Foundation

  @_spi(Concurrency)
  @MainActor
  public func withMainSerialExecutor<T>(
    @_implicitSelfCapture operation: @MainActor @Sendable () async throws -> T
  ) async rethrows -> T {
    let hook = swift_task_enqueueGlobal_hook
    defer { swift_task_enqueueGlobal_hook = hook }
    swift_task_enqueueGlobal_hook = { job, original in
      MainActor.shared.enqueue(job)
    }
    return try await operation()
  }

  typealias Original = @convention(thin) (UnownedJob) -> Void
  typealias Hook = @convention(thin) (UnownedJob, Original) -> Void
  private let _swift_task_enqueueGlobal_hook: UnsafeMutablePointer<Hook?> = {
    dlsym(dlopen(nil, 0), "swift_task_enqueueGlobal_hook").assumingMemoryBound(to: Hook?.self)
  }()

  var swift_task_enqueueGlobal_hook: Hook? {
    get { _swift_task_enqueueGlobal_hook.pointee }
    set { _swift_task_enqueueGlobal_hook.pointee = newValue }
  }
#endif
