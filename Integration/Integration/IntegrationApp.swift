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

@available(iOS 17.0, *)
extension DeveloperToolsSupport.PreviewRegistry {
  static func prepareDependencies(_ operation: () -> Void) {}
}

protocol Fooable {
}
extension Fooable {
  static var x: Text { Text("") }
}
struct Foo: Fooable {
  @ViewBuilder
  static func foo() -> some View {
    x
  }
}

//@Testing()

@available(iOS 18.0, *)
#Preview(
  traits: .dependencies {
    $0.date.now = Date(timeIntervalSince1970: 111111111213)
  }
) {
  DateView()
}

struct DateView: View {
  @Dependency(\.date) var date
  var body: some View {
    withDependencies {
      $0//.date.now = Date()
    } operation: {
      Text(date.now.description)
    }
  }
}
