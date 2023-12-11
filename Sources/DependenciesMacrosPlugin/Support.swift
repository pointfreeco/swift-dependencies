import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}

extension ClosureExprSyntax {
  mutating func append(placeholder: String) {
    self.statements.append(
      CodeBlockItemSyntax(
        item: CodeBlockItemSyntax.Item(
          EditorPlaceholderExprSyntax(
            placeholder: TokenSyntax(
              stringLiteral: "<#\(placeholder)#>"
            ),
            trailingTrivia: .space
          )
        )
      )
    )
  }
}

extension FunctionTypeSyntax {
  var unimplementedDefault: ClosureExprSyntax {
    ClosureExprSyntax(
      leftBrace: .leftBraceToken(trailingTrivia: .space),
      signature: self.parameters.isEmpty
        ? nil
        : ClosureSignatureSyntax(
          attributes: [],
          parameterClause: .simpleInput(
            ClosureShorthandParameterListSyntax(
              (1...self.parameters.count).map { n in
                ClosureShorthandParameterSyntax(
                  name: .wildcardToken(),
                  trailingComma: n < self.parameters.count
                    ? .commaToken()
                    : nil,
                  trailingTrivia: .space
                )
              }
            )
          ),
          inKeyword: .keyword(.in, trailingTrivia: .space)
        ),
      statements: []
    )
  }

  var isVoid: Bool {
    self.returnClause.type.as(IdentifierTypeSyntax.self)
      .map { ["Void"].qualified("Swift").contains($0.name.text) }
      ?? self.returnClause.type.as(TupleTypeSyntax.self)?.elements.isEmpty == true
  }

  var isOptional: Bool {
    self.returnClause.type.is(OptionalTypeSyntax.self)
      || self.returnClause.type.as(IdentifierTypeSyntax.self)
        .map { ["Optional"].qualified("Swift").contains($0.name.text) }
        ?? false
  }
}

struct DiagnoseResult {
  let earlyOut: Bool
}

extension InitializerClauseSyntax {
  func diagnose(
    _ attribute: AttributeSyntax,
    context: some MacroExpansionContext
  ) throws -> DiagnoseResult {
    guard let closure = self.value.as(ClosureExprSyntax.self)
    else {
      var diagnostics: [Diagnostic] = [
        Diagnostic(
          node: self.value,
          message: MacroExpansionErrorMessage(
          """
          '@\(attribute.attributeName)' default must be closure literal
          """
          )
        )
      ]
      if self.value.as(FunctionCallExprSyntax.self)?
        .calledExpression.as(DeclReferenceExprSyntax.self)?
        .baseName.tokenKind == .identifier("unimplemented")
      {
        diagnostics.append(
          Diagnostic(
            node: self.value,
            message: MacroExpansionWarningMessage(
            """
            Do not use 'unimplemented' with '@\(attribute.attributeName)'; it is a replacement and \
            implements the same runtime functionality as 'unimplemented' at compile time
            """
            )
          )
        )
      }
      throw DiagnosticsError(diagnostics: diagnostics)
    }
    
    guard
      closure.statements.count == 1,
      let statement = closure.statements.first
    else {
      return DiagnoseResult(earlyOut: false)
    }
    
    context.diagnose(
      Diagnostic(
        node: statement.item,
        message: MacroExpansionWarningMessage(
                """
                Prefer to use a real default value rather than fatalError().
                
                The default value can be anything and does not need to signify a real value. For \
                example, if the endpoint returns a boolean, you can return false, or if it \
                returns an array, you can return [].
                """
        ),
        fixIt: FixIt(
          message: MacroExpansionFixItMessage(
                  """
                  Silence this warning by wrapping fatalError() in a synchronously executed \
                  closure, but we recommend against this.
                  """
          ),
          changes: [
            .replace(
              oldNode: Syntax(statement),
              newNode: Syntax(
                FunctionCallExprSyntax(
                  calledExpression: ClosureExprSyntax(
                    statements: [
                      statement.with(\.leadingTrivia, .space)
                    ]
                  ),
                  leftParen: .leftParenToken(),
                  arguments: [],
                  rightParen: .rightParenToken()
                )
                .with(\.trailingTrivia, .space)
              )
            )
          ]
        )
      )
    )
    
    return DiagnoseResult(earlyOut: true)
  }
}

extension VariableDeclSyntax {
  var asClosureType: FunctionTypeSyntax? {
    self.bindings.first?.typeAnnotation.flatMap {
      $0.type.as(FunctionTypeSyntax.self)
        ?? $0.type.as(AttributedTypeSyntax.self)?.baseType.as(FunctionTypeSyntax.self)
    }
  }

  var isClosure: Bool {
    self.asClosureType != nil
  }
}

extension MacroExpansionContext {
  func diagnose(
    node: PatternBindingSyntax,
    identifier: TokenSyntax,
    unimplementedDefault: ClosureExprSyntax
  ) {
    self.diagnose(
      Diagnostic(
        node: node,
        message: MacroExpansionErrorMessage(
          """
          Default value required for non-throwing closure '\(identifier)'
          """
        ),
        fixIt: FixIt(
          message: MacroExpansionFixItMessage(
            """
            Insert '= \(unimplementedDefault.description)'
            """
          ),
          changes: [
            .replace(
              oldNode: Syntax(node),
              newNode: Syntax(
                node.with(
                  \.initializer,
                  InitializerClauseSyntax(
                    leadingTrivia: .space,
                    equal: .equalToken(trailingTrivia: .space),
                    value: unimplementedDefault
                  )
                )
              )
            )
          ]
        )
      )
    )
  }
}

extension Array where Element == String {
  func qualified(_ module: String) -> Self {
    self.flatMap { [$0, "\(module).\($0)"] }
  }
}

extension MacroExpansionContext {
  func diagnoseFatalErrorDefault(statement: CodeBlockItemSyntax) {

  }
}
