// Example usage of Dependencies
//
// This file demonstrates how to use the dependency injection system.
// It is not part of the library itself.

import Foundation
import Dependencies

// MARK: - Example Dependency: APIClient

struct APIClient: Sendable {
  var fetchUser: @Sendable (Int) async throws -> User
  var saveUser: @Sendable (User) async throws -> Void
}

struct User: Sendable, Codable {
  let id: Int
  let name: String
  let email: String

  static let mock = User(id: 1, name: "Mock User", email: "mock@example.com")
}

// MARK: - Register APIClient as a Dependency

extension APIClient: DependencyKey {
  static let liveValue = APIClient(
    fetchUser: { id in
      let url = URL(string: "https://api.example.com/users/\(id)")!
      let (data, _) = try await URLSession.shared.data(from: url)
      return try JSONDecoder().decode(User.self, from: data)
    },
    saveUser: { user in
      let url = URL(string: "https://api.example.com/users/\(user.id)")!
      var request = URLRequest(url: url)
      request.httpMethod = "PUT"
      request.httpBody = try JSONEncoder().encode(user)
      _ = try await URLSession.shared.data(for: request)
    }
  )

  static let testValue = APIClient(
    fetchUser: { _ in User.mock },
    saveUser: { _ in }
  )
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

// MARK: - Example Usage in a ViewModel

@Observable
final class UserViewModel {
  @ObservationIgnored
  @Dependency(\.apiClient) var apiClient

  private(set) var user: User?
  private(set) var isLoading = false
  private(set) var error: Error?

  func loadUser(id: Int) async {
    isLoading = true
    error = nil

    do {
      user = try await apiClient.fetchUser(id)
    } catch {
      self.error = error
    }

    isLoading = false
  }

  func saveUser(_ user: User) async throws {
    try await apiClient.saveUser(user)
    self.user = user
  }
}

// MARK: - Example Tests

#if DEBUG
  func exampleTests() async throws {
    // Test 1: Default test value is used
    await withDependencies {
      $0.context = .test
    } operation: {
      let viewModel = UserViewModel()
      await viewModel.loadUser(id: 42)

      assert(viewModel.user?.name == "Mock User")
      print("✅ Test 1 passed: Default test value used")
    }

    // Test 2: Override with custom mock
    let customUser = User(id: 99, name: "Custom Mock", email: "custom@example.com")

    await withDependencies {
      $0.apiClient.fetchUser = { _ in customUser }
    } operation: {
      let viewModel = UserViewModel()
      await viewModel.loadUser(id: 99)

      assert(viewModel.user?.id == 99)
      assert(viewModel.user?.name == "Custom Mock")
      print("✅ Test 2 passed: Custom mock override worked")
    }

    // Test 3: Test save functionality
    var savedUser: User?
    await withDependencies {
      $0.apiClient.saveUser = { user in
        savedUser = user
      }
    } operation: {
      let viewModel = UserViewModel()
      let userToSave = User(id: 123, name: "Test Save", email: "save@test.com")
      try await viewModel.saveUser(userToSave)

      assert(savedUser?.id == 123)
      assert(savedUser?.name == "Test Save")
      print("✅ Test 3 passed: Save mock captured data")
    }

    print("\n🎉 All tests passed!")
  }
#endif

// MARK: - Example: Multiple Dependencies

struct Analytics: Sendable {
  var track: @Sendable (String, [String: String]) -> Void
}

extension Analytics: DependencyKey {
  static let liveValue = Analytics(
    track: { event, properties in
      print("📊 Analytics: \(event) - \(properties)")
      // Real analytics implementation
    }
  )

  static let testValue = Analytics(
    track: { _, _ in }
  )
}

extension DependencyValues {
  var analytics: Analytics {
    get { self[Analytics.self] }
    set { self[Analytics.self] = newValue }
  }
}

// Using multiple dependencies
@Observable
final class CheckoutViewModel {
  @ObservationIgnored
  @Dependency(\.apiClient) var apiClient

  @ObservationIgnored
  @Dependency(\.analytics) var analytics

  func checkout(userId: Int) async throws {
    analytics.track("checkout_started", ["user_id": "\(userId)"])

    let user = try await apiClient.fetchUser(userId)

    analytics.track("checkout_completed", [
      "user_id": "\(userId)",
      "user_name": user.name,
    ])
  }
}
