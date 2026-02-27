import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DependencyEntryMacro {}

// MARK: - Mode Detection

extension DependencyEntryMacro {
  enum Mode {
    /// `@DependencyEntry(.live) var x: T = liveDefault`
    /// → public key conforming to DependencyKey, liveValue only
    case live
    /// `@DependencyEntry(.test) var x: T = testDefault`
    /// → public key conforming to TestDependencyKey, testValue only
    case test
  }

  static func detectMode(from node: AttributeSyntax) -> Mode {
    guard
      let args = node.arguments?.as(LabeledExprListSyntax.self),
      let first = args.first,
      let member = first.expression.as(MemberAccessExprSyntax.self)
    else {
      return .live
    }
    switch member.declName.baseName.text {
    case "test": return .test
    default:     return .live
    }
  }
}

// MARK: - AccessorMacro
//
// Both modes generate identical accessors:
//   get { self[__Key_<name>.self] }
//   set { self[__Key_<name>.self] = newValue }

extension DependencyEntryMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      let varDecl = declaration.as(VariableDeclSyntax.self),
      let binding = varDecl.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
    else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@DependencyEntry' can only be applied to 'var' declarations"
          )
        )
      ])
    }

    let keyName = "__Key_\(identifier)"
    return [
      "get { self[\(raw: keyName).self] }",
      "set { self[\(raw: keyName).self] = newValue }",
    ]
  }
}

// MARK: - PeerMacro
//
// .live (implementation module):
//   public enum __Key_<name>: DependencyKey {
//     public typealias Value = <Type>
//     public static let liveValue: Value = <initializer>
//   }
//   // testValue falls back to liveValue via DependencyKey's default implementation.
//   // Test-support module can extend with TestDependencyKey to override testValue.
//
// .test (interface module):
//   public enum __Key_<name>: TestDependencyKey {
//     public typealias Value = <Type>
//     public static let testValue: Value = <initializer>
//   }
//   // Implementation module extends __Key_<name> with DependencyKey to provide liveValue.

extension DependencyEntryMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let varDecl = declaration.as(VariableDeclSyntax.self),
      let binding = varDecl.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
    else {
      return []
    }

    let mode = detectMode(from: node)
    let example: String
    switch mode {
    case .live: example = "@DependencyEntry(.live) var router: MyRouter = MyRouter()"
    case .test: example = "@DependencyEntry(.test) var router: MyRouter = .unimplemented"
    }

    guard let typeAnnotation = binding.typeAnnotation?.type else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            """
            '@DependencyEntry' requires an explicit type annotation.

            Provide the type explicitly:
              \(example)
            """
          )
        )
      ])
    }

    guard let initializer = binding.initializer?.value else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            """
            '@DependencyEntry' requires a default value.

            Provide a default value:
              \(example)
            """
          )
        )
      ])
    }

    let keyName = "__Key_\(identifier)"
    let typeStr = typeAnnotation.trimmedDescription

    switch mode {
    case .live:
      return [
        """
        public enum \(raw: keyName): DependencyKey {
          public typealias Value = \(raw: typeStr)
          public static let liveValue: Value = \(initializer)
        }
        """,
      ]

    case .test:
      return [
        """
        public enum \(raw: keyName): TestDependencyKey {
          public typealias Value = \(raw: typeStr)
          public static let testValue: Value = \(initializer)
        }
        """,
      ]
    }
  }
}
