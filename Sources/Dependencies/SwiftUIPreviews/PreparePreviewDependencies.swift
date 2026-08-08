//
//  PreviewHelper.swift
//  swift-dependencies
//
//  Created by Pete Schuette on 8/8/26.
//

#if canImport(SwiftUI)
public import SwiftUI

@ViewBuilder
public func preparePreviewDependencies<R, V: View>(
  _ updateValues: (inout DependencyValues) throws -> R,
  errorViewBuilder: ((any Error) -> V)? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) -> some View {
  let error: (any Error)? = {
    guard Thread.isPreviewAppEntryPoint else {
      reportIssue(
        """
        You are using the preview support helper outside of a preview context.
        This will have no effect.
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return nil
    }

    do {
      _ = try prepareDependencies(updateValues)
    } catch {
      return error
    }
    return nil
  }()
  
  if let error {
    if let errorViewBuilder {
      errorViewBuilder(error)
    } else {
      PreviewErrorView(error)
    }
  }
}

public struct PreviewErrorView: View {
  let error: any Error
  
  nonisolated
  public init(_ error: any Error) {
    self.error = error
  }

  public var body: some View {
    ScrollView {
      Text(error.localizedDescription)
        .foregroundColor(.red)
        .padding(.horizontal, 12)
    }
    .foregroundColor(.white)
  }
}
#endif
