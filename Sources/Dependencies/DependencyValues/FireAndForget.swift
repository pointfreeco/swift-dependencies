extension DependencyValues {
  /// A dependency for firing off an unstructured task.
  ///
  /// Useful as a controllable and testable substitute for a `Task { }` that performs some work off
  /// into the void. In tests, the operation becomes structured, and the async context that kicks
  /// off the work will wait for it to complete before resuming.
  ///
  /// For example, suppose you are building a server application that has an endpoint for updating
  /// a user's email address. To accomplish that you will first make a database request to update
  /// the user's email, and then if that succeeds you will send an email to the new address to let
  /// the user know their email has been updated.
  ///
  /// However, there is no need to tie up the server in order to send the email. That request
  /// doesn't return any data of interest, and we just want to fire it off and then forget about it.
  /// One way to do this is to use an unstructured `Task` like so:
  ///
  /// ```swift
  /// try await self.database.updateUser(id: userID, email: newEmailAddress)
  /// Task {
  ///   try await self.sendEmail(
  ///     email: newEmailAddress,
  ///     subject: "Your email has been updated"
  ///   )
  /// }
  /// ```
  ///
  /// However, this kind of code can be problematic for testing. In a test we would like to verify
  /// that an email is sent, but the code inside the `Task` is executed at some later time. We
  /// would need to add `Task.sleep` or `Task.yield` to the test to give the task enough time to
  /// start and finish, which can be flakey and error prone.
  ///
  /// So, instead, you can use the ``fireAndForget`` dependency, which creates an unstructured task
  /// when run in production, but creates a _structured_ task in tests:
  ///
  /// ```swift
  /// try await self.database.updateUser(id: userID, email: newEmailAddress)
  /// self.fireAndForget {
  ///   self.sendEmail(
  ///     email: newEmailAddress,
  ///     subject: "You email has been updated"
  ///   )
  /// }
  /// ```
  ///
  /// Now this is easy to test. We just have to `await` for the code to finish, and once it does
  /// we can verify that the email was sent.
  public var fireAndForget: FireAndForget {
    get { self[FireAndForgetKey.self] }
    set { self[FireAndForgetKey.self] = newValue }
  }
}

/// A type for creating unstructured tasks in production and structured tasks in tests.
///
/// See ``DependencyValues/fireAndForget`` for more information.
public struct FireAndForget: Sendable {
  public let operation:
    @Sendable (TaskPriority?, @Sendable @escaping () async throws -> Void) async -> Void

  public func callAsFunction(
    priority: TaskPriority? = nil,
    @_inheritActorContext _ operation: @Sendable @escaping () async throws -> Void
  ) async {
    await self.operation(priority) { try await operation() }
  }
}

private enum FireAndForgetKey: DependencyKey {
  public static let liveValue = FireAndForget { priority, operation in
    Task(priority: priority) { try await operation() }
  }
  public static let testValue = FireAndForget { _, operation in
    try? await operation()
  }
}
