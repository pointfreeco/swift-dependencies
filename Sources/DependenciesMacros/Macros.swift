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

@DependencyClient
struct FileClient {
  var load: (_ path: String) throws -> String
  var save: (_ path: String, String) throws -> Void
}
