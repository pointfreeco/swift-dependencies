import Dependencies
import DependenciesMacros
import IssueReporting

private enum PackageACL {
  @DependencyClient
  package struct Client {
    @DependencyEndpoint
    package var endpoint: (_ id: Int) -> Void
  }
}

private struct EntryValue: Sendable {
  static let live = EntryValue()
  static let test = EntryValue()
  static let preview = EntryValue()
}

extension DependencyValues {
  @DependencyEntry
  fileprivate var entryTestValueOnly = EntryValue.test

  @DependencyEntry(liveValue: EntryValue.live)
  fileprivate var entryLiveAndTestValue = EntryValue.test

  @DependencyEntry(liveValue: EntryValue.live, previewValue: EntryValue.preview)
  fileprivate var entryAllValues = EntryValue.test

  @DependencyEntry(previewValue: EntryValue.preview)
  fileprivate var entryPreviewAndTestValue = EntryValue.test

  @DependencyEntry(liveValue: EntryValue.live)
  fileprivate var entryWithTypeAnnotation: EntryValue = .test
}
