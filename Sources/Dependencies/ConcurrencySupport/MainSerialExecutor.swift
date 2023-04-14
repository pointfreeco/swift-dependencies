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
  var info = Dl_info()
  guard
    withUnsafePointer(to: TaskPriority.self, {
      $0.withMemoryRebound(to: UnsafeRawPointer.self, capacity: 1) {
        dladdr($0.pointee, &info)
      }
    }) != 0,
    let handle = dlopen(info.dli_fname, RTLD_LAZY),
    let symbol = dlsym(handle, "swift_task_enqueueGlobal_hook")
  else { return nil }
  return symbol.assumingMemoryBound(to: Hook.self)
}()
