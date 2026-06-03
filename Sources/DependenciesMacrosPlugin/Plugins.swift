import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    DependencyClientMacro.self,
    DependencyEndpointMacro.self,
    DependencyEndpointIgnoredMacro.self,
    DependencyEntryMacro.self,
    DependencyEntryDefaultValueMacro.self,
  ]
}
