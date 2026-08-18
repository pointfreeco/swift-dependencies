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
  var integrationContext: String {
    get { self[IntegrationContextKey.self] }
    set { self[IntegrationContextKey.self] = newValue }
  }
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
    $0.integrationContext = "Uno"
  },
  .dependencies {
    // Previously prepared dependencies can be overridden
    $0.integrationContext = "First"
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
    let _ = $0.integrationContext
  }
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
