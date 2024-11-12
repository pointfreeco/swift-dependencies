#if canImport(Testing) && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
  import Dependencies
  import Testing
  import SwiftUI

  @Suite
  @MainActor
  struct PreviewTraitsTests {
    @Test
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    func dependency() {
      _ = PreviewTrait.dependency(\.date.now, Date(timeIntervalSince1970: 1_234_567_890))
      withDependencies {
        $0.context = .preview
      } operation: {
        @Dependency(\.date.now) var now
        #expect(now == Date(timeIntervalSince1970: 1_234_567_890))
      }
    }
  }
#endif
