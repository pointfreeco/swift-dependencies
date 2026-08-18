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
    $0.integrationContext = "Primera"
  },
  .dependencies {
    // Dependencies can be overridden a second time.
    $0.integrationContext = "First"
  },
) {
  IntegrationContextView()
}

#Preview(
  "Second",
  traits: .dependency(\.integrationContext, "Segundo"),
  // Dependencies can be overridden a second time.
  .dependency(\.integrationContext, "Second"),
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
