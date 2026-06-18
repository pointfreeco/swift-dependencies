import IssueReporting

public func _reportIssue(
  _ message: @autoclosure () -> String? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  IssueReporting.reportIssue(
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// The error thrown by "unimplemented" closures produced by ``DependencyEndpoint(method:)``
public struct UnimplementedDependencyEndpoint: Error {
  let endpoint: String

  public init(_ endpoint: String) {
    self.endpoint = endpoint
  }
}
