import Benchmark
import Dependencies
import Foundation

let withValueSuite = BenchmarkSuite(name: "Dependencies") { suite in
  _ = DependencyValues._current.date.now
  _ = DependencyValues._current.calendar
  _ = DependencyValues._current.context
  _ = DependencyValues._current.locale
  _ = DependencyValues._current.timeZone
  _ = DependencyValues._current.urlSession
  _ = DependencyValues._current.uuid
  _ = DependencyValues._current.withRandomNumberGenerator
  @Dependency(\.someValue) var someValue: Int

  suite.benchmark("Dependency key writing") {
    let value = withDependencies {
      $0.someValue = 1
    } operation: {
      withDependencies {
        $0.someValue = 2
      } operation: {
        withDependencies {
          $0.someValue = 3
        } operation: {
          withDependencies {
            $0.someValue = 4
          } operation: {
            withDependencies {
              $0.someValue = 5
            } operation: {
              withDependencies {
                $0.someValue = 6
              } operation: {
                withDependencies {
                  $0.someValue = 7
                } operation: {
                  withDependencies {
                    $0.someValue = 8
                  } operation: {
                    withDependencies {
                      $0.someValue = 9
                    } operation: {
                      withDependencies {
                        $0.someValue = 10
                      } operation: {
                        withDependencies {
                          $0.date = .constant(Date())
                          $0.calendar = Calendar(identifier: .gregorian)
                          $0.context = .live
                          $0.locale = Locale(identifier: "en_US")
                          $0.uuid = .incrementing
                        } operation: {
                          someValue
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    precondition(value == 10)
  }
}

private enum SomeValueKey: DependencyKey {
  static let liveValue = 1
}
extension DependencyValues {
  var someValue: Int {
    get { self[SomeValueKey.self] }
    set { self[SomeValueKey.self] = newValue }
  }
}
