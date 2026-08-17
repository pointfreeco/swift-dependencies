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
    $0.integrationContext = "First"
    print(#line, $0.integrationContext)
  }
) {
  IntegrationContextView()
}

#Preview(
  "Second",
  traits: .dependencies {
    $0.integrationContext = "Second"
    print(#line, $0.integrationContext)
  }
) {
  IntegrationContextView()
}

#Preview(
  "Third",
  traits: .dependencies { _ in
    struct Failure: Error {}
    print(#line, "Third")
    throw Failure()
  }
) {
  IntegrationContextView()
}
