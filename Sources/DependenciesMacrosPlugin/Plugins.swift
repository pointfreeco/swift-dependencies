import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DependencyClientMacro.self,
    DependencyEndpointMacro.self,
    DependencyEndpointIgnoredMacro.self
  ]
}
