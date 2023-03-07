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
