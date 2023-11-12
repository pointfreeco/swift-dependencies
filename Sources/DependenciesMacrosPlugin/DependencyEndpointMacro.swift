import SwiftDiagnostics
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum DependencyEndpointMacro: AccessorMacro, PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: D,
    in context: C
  ) throws -> [AccessorDeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
      property.isClosure
    else {
      return []
    }

    return [
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = initialValue
      }
      """,
      """
      get {
      _\(identifier)
      }
      """,
      """
      set {
      _\(identifier) = newValue
      }
      """,
    ]
  }

  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
      let type = binding.typeAnnotation?.type.trimmed,
      let functionType = property.asClosureType?.trimmed
    else {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            """
            '@DependencyEndpoint' must be attached to closure property
            """
          )
        )
      )
      return []
    }

    var unimplementedDefault: ClosureExprSyntax
    if let initializer = binding.initializer {
      guard var closure = initializer.value.as(ClosureExprSyntax.self)
      else {
        // TODO: Diagnose?
        return []
      }
      if !functionType.isVoid,
        closure.statements.count == 1,
        var statement = closure.statements.first,
        let expression = statement.item.as(ExprSyntax.self)
      {
        statement.item = CodeBlockItemSyntax.Item(
          ReturnStmtSyntax(
            returnKeyword: .keyword(.return, trailingTrivia: .space),
            expression: expression
          )
        )
        closure.statements = closure.statements.with(\.[closure.statements.startIndex], statement)
      }
      unimplementedDefault = closure
    } else {
      unimplementedDefault = functionType.unimplementedDefault
      if functionType.effectSpecifiers?.throwsSpecifier != nil {
        unimplementedDefault.statements.append(
          """
          throw DependenciesMacros.Unimplemented("\(identifier)")
          """
        )
      } else if functionType.isVoid {
        // Do nothing...
      } else if functionType.isOptional {
        unimplementedDefault.statements.append(
          """
          return nil
          """
        )
      } else {
        unimplementedDefault.append(placeholder: functionType.returnClause.type.trimmed.description)
        context.diagnose(
          node: binding,
          identifier: identifier,
          unimplementedDefault: unimplementedDefault
        )
        return []
      }
    }
    unimplementedDefault.statements.insert(
      """
      XCTestDynamicOverlay.XCTFail("Unimplemented: '\(identifier)'")
      """,
      at: unimplementedDefault.statements.startIndex
    )

    var effectSpecifiers = ""
    if functionType.effectSpecifiers?.throwsSpecifier != nil {
      effectSpecifiers.append("try ")
    }
    if functionType.effectSpecifiers?.asyncSpecifier != nil {
      effectSpecifiers.append("await ")
    }
    let access = property.modifiers.first { $0.name.tokenKind == .keyword(.public) }

    var decls: [DeclSyntax] = []

    if try functionType.parameters.contains(where: { $0.secondName != nil })
      || node.methodArgument != nil
    {
      var attributes: [String] =
        binding.typeAnnotation.flatMap {
          $0.type.as(AttributedTypeSyntax.self)?.attributes.compactMap {
            guard case let .attribute(attribute) = $0 else { return nil }
            return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          }
        }
        ?? []
      if attributes.count > 1 {
        attributes.removeAll(where: { $0 == "Sendable" })
      }

      var parameters = functionType.parameters
      for (offset, i) in parameters.indices.enumerated() {
        parameters[i].firstName = (parameters[i].secondName ?? .wildcardToken())
          .with(\.trailingTrivia, .space)
        parameters[i].secondName = TokenSyntax(stringLiteral: "p\(offset)")
        parameters[i].colon = parameters[i].colon ?? .colonToken(trailingTrivia: .space)
      }
      let appliedParameters = (0..<parameters.count).map { "p\($0)" }.joined(separator: ", ")
      decls.append(
        """
        \(raw: attributes.map { "@\($0) " }.joined())\
        \(access)func \(try node.methodArgument ?? identifier)(\(parameters))\
        \(functionType.effectSpecifiers)\(functionType.returnClause) {
        \(raw: effectSpecifiers)self.\(identifier)(\(raw: appliedParameters))
        }
        """
      )
    }

    return decls + [
      """
      private var _\(identifier): \(raw: type) = \(unimplementedDefault)
      """
    ]
  }
}

extension AttributeSyntax {
  var methodArgument: TokenSyntax? {
    get throws {
      guard
        let arguments = self.arguments?.as(LabeledExprListSyntax.self),
        arguments.count == 1,
        let argument = arguments.first,
        argument.label?.text == "method"
      else { return nil }

      guard
        let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
        stringLiteral.segments.count == 1,
        let name = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
      else {
        throw DiagnosticsError(
          diagnostics: [
            Diagnostic(
              node: argument.expression,
              message: MacroExpansionErrorMessage(
                """
                'method' must be a static string literal
                """
              )
            )
          ]
        )
      }

      let parsed = Parser.parse(source: name)
      guard
        parsed.statements.count == 1,
        let item = parsed.statements.first?.item,
        item.is(DeclReferenceExprSyntax.self)
      else {
        throw DiagnosticsError(
          diagnostics: [
            Diagnostic(
              node: argument.expression,
              message: MacroExpansionErrorMessage(
                """
                'method' must be a valid identifier
                """
              )
            )
          ]
        )
      }

      return .identifier(name)
    }
  }
}
