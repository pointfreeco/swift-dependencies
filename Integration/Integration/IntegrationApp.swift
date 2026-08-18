import Dependencies
import DependenciesMacros
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

extension DependencyValues {
  @DependencyEntry(liveValue: "Live", previewValue: "Preview")
  var integrationContext = "Test"
}

struct IntegrationContextView: View {
  @Dependency(\.integrationContext) var integrationContext
  var body: some View {
    Text(self.integrationContext)
      .font(.system(size: 100))
  }
}

#Preview(
  "First",
  traits: .dependencies {
    // First dependency set takes precedence over later overrides (just like SwiftUI view modifiers)
    $0.integrationContext = "First"
  },
  .dependencies {
    $0.integrationContext = "Primera"
  },
) {
  IntegrationContextView()
}

#Preview(
  "Second",
  traits: .dependencies {
    $0.integrationContext = "Second"
  },
  .dependencies {
    // Accessing a dependency does not prevent overriding it.
    let _ = $0.integrationContext
  },
) {
  IntegrationContextView()
}

#Preview(
  "Third",
  traits: .dependencies { _ in
    struct Failure: Error {}
    throw Failure()
  }
) {
  IntegrationContextView()
}
