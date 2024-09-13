import Dependencies
import SwiftUI

@main
struct IntegrationApp: App {
  @Dependency(\.integrationContext) var integrationContext
  var body: some Scene {
    WindowGroup {
      Text(self.integrationContext)
        .font(.system(size: 100))
    }
  }
}

private enum IntegrationContextKey: DependencyKey {
  static let liveValue = "Live"
  static let previewValue = "Preview"
  static let testValue = "Test"
}
extension DependencyValues {
  var integrationContext: String { self[IntegrationContextKey.self] }
}


import DependenciesMacros

@DependencyClient
struct Client {
  var fetch: () async throws -> Int
  var get: () -> Int = { 0 }
}
struct MockClient {
  var invocations: [PartialKeyPath<Client>: any Sendable]
  init() {
    let client = Client {
      invocations[\.fetch] = …
    }
  }
}

//@DependencyClient
protocol _Client: Sendable {
  func fetch() async throws -> Int
  @Placeholder(0)
  func get() -> Int
}
// Generates
class MockClient: _Client, @unchecked Sendable {
  var invocations: [PartialKeyPath<MockClient>: any Sendable] = [:]
  var fetch: () async throws -> Int
  init(fetch: @escaping () async throws -> Int = {
    reportIssue("_Client.fetch unimplemented")
    throw Unimplemented("_Client.fetch unimplemented")
  },
  get: () -> Int = {
    reportIssue()
    return 0
  }
  ) {
    self.fetch = fetch
  }
  func fetch() async throws -> Int {
    invocations[\.fetch] = ()
    return try await fetch()
  }
  func assert(
    method: PartialKeyPath<MockClient>,
    invokedWith: any Sendable,
    returning: any Sendable
  ) {
  }
  // #expect(mock.invoked.fetch(…) == 1)
  // #expect(analytics.invoked.track("Page Visited"))
  // #expect(analytics.invoked.track)
  // #expect(analytics.invoked.track(times: 3))
  deinit {
    guard invocations.isEmpty
    else { return }
    // TODO: test failure
  }
}
import IssueReporting
import Dependencies

extension EnvironmentValues {
  @Entry var foo = 42
}

extension DependencyValues {
  @DependencyEntry var client: any _Client = MockClient()
}
// expand
extension DependencyValues {
  enum _ClientKey: TestDependencyKey {
    static let testValue: any _Client = MockClient()
  }
  var client: any _Client {
    get {
      self[_ClientKey.self]
    }
    set {
      self[_ClientKey.self] = newValue
    }
  }
  var mockClient: MockClient {
    guard let client = client as? MockClient
    else {
      reportIssue()
      return MockClient()
    }
    return client
  }
}

private enum ClientKey: TestDependencyKey {
  static let testValue: any _Client = MockClient()
}
extension DependencyValues {
  var client: any _Client {
    get {
      self[ClientKey.self]
    }
    set {
      self[ClientKey.self] = newValue
    }
  }
  var mockClient: MockClient {
    guard let client = client as? MockClient
    else {
      reportIssue()
      return MockClient()
    }
    return client
  }
}

//import Testing
//@Suite(.dependency(\.mockClient, MockClient()))
//struct MySuite {
//  @Dependency(\.mockClient) var mockClient
//
//  @Test
//  func feature() {
//    #expect(mockClient.invocations.count == 1)
//  }
//}



