#if canImport(Combine)
  import Combine
  import Dependencies
  import Foundation
  import Testing

  func post() {
    @Dependency(\.notificationCenter) var notificationCenter
    notificationCenter.post(Notification(name: notificationName))
  }

  private let notificationName = Notification.Name("Hello")

  struct NotificationCenterTests {
    @Dependency(\.notificationCenter) var notificationCenter
    var cancellables: Set<AnyCancellable> = []

    @Test mutating func basics() {
      var defaultReceived = 0
      var dependencyReceived = 0
      NotificationCenter.default
        .publisher(for: notificationName).sink { _ in defaultReceived += 1 }
        .store(in: &cancellables)
      notificationCenter
        .publisher(for: notificationName).sink { _ in dependencyReceived += 1 }
        .store(in: &cancellables)
      post()
      #expect(defaultReceived == 0)
      #expect(dependencyReceived == 1)
    }

    @Test mutating func concurrent1() async throws {
      nonisolated(unsafe) var count = 0
      notificationCenter
        .publisher(for: notificationName)
        .sink { _ in count += 1 }
        .store(in: &cancellables)

      for _ in 1...100 {
        notificationCenter.post(name: notificationName, object: nil)
        try await Task.sleep(for: .milliseconds(1))
      }
      #expect(count == 100)
    }

    @Test mutating func concurrent2() async throws {
      nonisolated(unsafe) var count = 0
      notificationCenter
        .publisher(for: notificationName)
        .sink { _ in count += 1 }
        .store(in: &cancellables)

      for _ in 1...100 {
        notificationCenter.post(name: notificationName, object: nil)
        try await Task.sleep(for: .milliseconds(1))
      }
      #expect(count == 100)
    }

    @Test
    mutating func concurrent3() async throws {
      nonisolated(unsafe) var count = 0
      notificationCenter
        .publisher(for: notificationName)
        .sink { _ in count += 1 }
        .store(in: &cancellables)

      for _ in 1...100 {
        notificationCenter.post(name: notificationName, object: nil)
        try await Task.sleep(for: .milliseconds(1))
      }
      #expect(count == 100)
    }
  }
#endif
