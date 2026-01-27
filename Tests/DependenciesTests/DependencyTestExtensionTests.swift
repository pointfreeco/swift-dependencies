#if compiler(>=6.2) && canImport(Testing)
  import Dependencies
  import Foundation
  import Testing

  @Suite struct DependencyTestExtensionTests {
    @Suite(
      .dependencies {
        $0.client = TestClient()
      }
    )
    struct SuccessfulCast {
      @Test func key() {
        @Dependency(ClientKey.self, as: TestClient.self) var client
        #expect(!client.isLive())
      }
      
      @Test func keyPath() {
        @Dependency(\.client, as: TestClient.self) var client
        #expect(!client.isLive())
      }
    }

    @Suite struct FailedCast {
      @Test func key() async throws {
        await #expect(processExitsWith: .failure) {
          withDependencies {
            $0.client = LiveClient()
          } operation: {
            @Dependency(ClientKey.self, as: TestClient.self) var client
            _ = client.isLive()
          }
        }
      }

      @Test func keyPath() async throws {
        await #expect(processExitsWith: .failure) {
          withDependencies {
            $0.client = LiveClient()
          } operation: {
            @Dependency(\.client, as: TestClient.self) var client
            _ = client.isLive()
          }
        }
      }
    }
  }

  private protocol Client: Sendable {
    func isLive() -> Bool
  }
  private enum ClientKey: DependencyKey {
    static var liveValue: any Client { LiveClient() }
    static var testValue: any Client { TestClient() }
  }
  extension DependencyValues {
    fileprivate var client: any Client {
      get { self[ClientKey.self] }
      set { self[ClientKey.self] = newValue }
    }
  }
  private struct LiveClient: Client {
    func isLive() -> Bool {
      true
    }
  }
  private struct TestClient: Client {
    func isLive() -> Bool {
      false
    }
  }

#endif
