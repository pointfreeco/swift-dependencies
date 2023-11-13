/// Improves the ergonomics of dependency clients modeled on structs and closures, as detailed in
/// our ["Designing Dependencies"][designing-dependencies] article.
///
/// To use the macro, simply apply it to the struct interface of your dependency:
///
/// ```swift
/// @DependencyClient
/// struct APIClient {
///   var fetchUser: (Int) async throws -> User
///   var saveUser: (User) async throws -> Void
/// }
/// ```
///
/// This adds a number of things to your dependency client types.
///
/// First of all, it provides a default, "unimplemented" value for all of the closure endpoints that
/// do not have one by applying the ``DependencyEndpoint(method:)`` macro. This means you get a very
/// lightweight way to create an instance of this interface:
///
/// ```swift
/// let unimplementedClient = APIClient()
/// ```
///
/// This is a very special implementation of the client. If you invoke any endpoint on this instance
/// it will also cause a test failure when run in tests, and if the endpoint is throwing, it will
/// throw an error. This serves as the perfect client to use as the `testValue` of your
/// dependencies:
///
/// ```swift
/// extension APIClient: TestDependencyKey {
///   static let testValue = APIClient()
/// }
/// ```
///
/// This makes it so that while testing your feature, if an execution flow ever uses an endpoint
/// that you did not explicitly override in the test, a failure will be triggered. Manually
/// maintaining an unimplemented client can be laborious, but now the macro provides one to you for
/// free.
///
/// Second, the macro will generate methods with named arguments for any of your closure endpoints
/// that have tuple argument labels. This is done by applying the ``DependencyEndpoint(method:)``
/// macro to each closure property, so read the documentation for that macro for more
/// detailed information.
///
/// As an example, if you change the above `APIClient` like so:
///
/// ```diff
///  @DependencyClient
///  struct APIClient {
/// -  var fetchUser: (Int) async throws -> User
/// +  var fetchUser: (_ id: Int) async throws -> User
///    var saveUser: (User) async throws -> Void
///  }
/// ```
///
/// …then a method `fetchUser(id:)` is automatically added to the client:
///
/// ```swift
/// let client = APIClient()
///
/// let user = try await client.fetchUser(id: 42)
/// ```
///
/// This fixes one of the biggest problems of dealing with struct interfaces for dependencies, and
/// that is the loss of argument labels.
///
/// And finally, it generates a public initializer for all of the endpoints automatically:
///
/// ```swift
/// let liveClient = APIClient(
///   fetchUser: { id in … },
///   saveUser: { user in … }
/// )
/// ```
///
/// This is particularly useful when modularizing your dependencies (as explained
/// [here][separating-interface-implementation]) as you will need a public initializer to create
/// instances of the client. Creating that initializer manually is quite laborious, and you have to
/// update it each time a new endpoint is added to the client.
///
/// [designing-dependencies]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/designingdependencies
/// [separating-interface-implementation]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/livepreviewtest#Separating-interface-and-implementation
@attached(member, names: named(init))
@attached(memberAttribute)
public macro DependencyClient() = #externalMacro(
  module: "DependenciesMacrosPlugin", type: "DependencyClientMacro"
)

/// Provides a default, "unimplemented" value to a closure property.
///
/// This macro is automatically applied to all closure properties of a struct annotated with
/// ``DependencyClient``.
///
/// If an "unimplemented" closure is invoked and not overridden, a test failure will be emitted, and
/// the endpoint will throw an error if it is a throwing closure.
///
/// If the closure this macro is applied to provides argument labels for the input tuple, then a
/// corresponding method will also be generated with named labels. For example, this:
///
/// ```swift
/// @DependencyEndpoint
/// var fetchUser: (_ id: User.ID) async throws -> User
/// ```
///
/// …expands to this:
///
/// ```swift
/// var fetchUser: (_ id: User.ID) async throws -> User
/// func fetchUser(id: User.ID) async throws -> User {
///   try await self.fetchUser(id)
/// }
/// ```
///
/// Now you can use a clearer syntax at the call site of invoking this endpoint:
///
/// ```swift
/// let client = APIClient()
/// let user = try await client.fetchUser(id: 42)
/// ```
///
/// You can also modify the name of the generated method, which can be handy for creating overloaded
/// method names:
///
/// ```swift
/// @DependencyEndpoint(method: "fetchUser")
/// var fetchUserByID: (_ id: User.ID) async throws -> User
/// @DependencyEndpoint(method: "fetchUser")
/// var fetchUserBySubscriptionID: (_ subscriptionID: Subscription.ID) async throws -> User
/// ```
///
/// This expands to:
///
/// ```swift
/// var fetchUserByID: (_ id: User.ID) async throws -> User
/// func fetchUser(id: User.ID) async throws -> User {
///   self.fetchUserByID(id)
/// }
/// var fetchUserBySubscriptionID: (_ subscriptionID: Subscription.ID) async throws -> User
/// func fetchUser(subscriptionID: Subscription.ID) async throws -> User {
///   self.fetchUserBySubscriptionID(subscriptionID)
/// }
/// ```
///
/// Now you can have an overloaded version of `fetchUser` that takes different arguments:
///
/// ```swift
/// let client = APIClient()
/// let user1 = try await client.fetchUser(id: 42)
/// let user2 = try await client.fetchUser(subscriptionID: "sub_deadbeef")
/// ```
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: arbitrary)
public macro DependencyEndpoint(method: String = "") = #externalMacro(
  module: "DependenciesMacrosPlugin", type: "DependencyEndpointMacro"
)

/// The error thrown by "unimplemented" closures produced by ``DependencyEndpoint(method:)``
public struct Unimplemented: Error {
  let endpoint: String

  public init(_ endpoint: String) {
    self.endpoint = endpoint
  }
}
