/// Improves the ergnomics of dependency clients modeled on structs and closures, as detailed in
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
/// This adds a number of things to your dependency client types. First of all, it generates an
/// initializer for all of the endpoints automatically:
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
/// Second, the macro provides a default value for all of the closure endpoints that do not hvae
/// one, and that default just throws an error. This means you get a very lightweight way to create
/// an instance of this interface:
///
/// ```swift
/// let unimplementedClient = APIClient()
/// ```
///
/// And this is a very special implementation of the client. If you invoke any endpoint on this
/// client it will throw an error, _and_ it will also cause a test failure when run in tests. This
/// serves as the perfect client to use as the `testValue` of your dependencies:
///
/// ```swift
/// extension APIClient: TestDependencyKey {
///   static let testValue = APIClient()
/// }
/// ```
///
/// This makes it so that while testing your feature, if an execution flow ever uses an endpoint 
/// that you did not explicitly override in the test, a failure will be triggered. Manually
/// maintaining an unimplemented client can be laborious, but now the macro provides one to you
/// for free.
///
/// And finally, the macro will generate methods with named arguments for any of your closure
/// endpoints that have tuple argument labels. For example, if you change the above `APIClient`
/// like so:
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
/// [designing-dependencies]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/designingdependencies
/// [separating-interface-implementation]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/livepreviewtest#Separating-interface-and-implementation
@attached(member, names: named(init))
@attached(memberAttribute)
public macro DependencyClient() = #externalMacro(
  module: "DependenciesMacrosPlugin", type: "DependencyClientMacro"
)

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: overloaded, prefixed(`$`))
public macro DependencyEndpoint() = #externalMacro(
  module: "DependenciesMacrosPlugin", type: "DependencyEndpointMacro"
)
