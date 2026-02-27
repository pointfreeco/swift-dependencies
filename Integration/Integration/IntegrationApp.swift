import Dependencies
import DependenciesMacros
import SwiftUI

@main
struct IntegrationApp: App {
  @Dependency(\.integrationContext) var integrationContext
  @Dependency(\.appTitle) var appTitle
  @Dependency(\.subtitle) var subtitle

  var body: some Scene {
    WindowGroup {
      VStack(spacing: 16) {
        Text(integrationContext)
          .font(.system(size: 100))
        Text(appTitle)
          .font(.headline)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
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

// Implementation module: owns liveValue.
// Test-support module can extend DependencyValues.__Key_appTitle with TestDependencyKey to override testValue.
extension DependencyValues {
  @DependencyEntry(.live) var appTitle: String = "Hello from @DependencyEntry(.live)"
}

// MARK: - .test mode demo (cross-module inversion)

// Interface module: declares the dependency with a safe test default.
extension DependencyValues {
  @DependencyEntry(.test) var subtitle: String = "(test default)"
}

// Implementation module: extends the public key to provide liveValue.
// Note: __Key_subtitle is a nested type of DependencyValues, so use the fully qualified name.
extension DependencyValues.__Key_subtitle: DependencyKey {
  public static let liveValue: String = "Powered by @DependencyEntry(.test)"
}
