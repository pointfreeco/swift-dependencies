import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder

struct SimpleDiagnosticMessage: DiagnosticMessage {
  var message: String
  var diagnosticID: MessageID
  var severity: DiagnosticSeverity

  init(message: String, diagnosticID: String, severity: DiagnosticSeverity) {
    self.message = message
    self.diagnosticID = MessageID(
      domain: "co.pointfree.xctest-dynamic-overlay",
      id: diagnosticID
    )
    self.severity = severity
  }
}

struct SimpleFixItMessage: FixItMessage {
  var message: String
  var fixItID: MessageID

  init(message: String, fixItID: String) {
    self.message = message
    self.fixItID = MessageID(domain: "co.pointfree.xctest-dynamic-overlay", id: fixItID)
  }
}

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
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

extension Array where Element == String {
  func qualified(_ module: String) -> Self {
    self.flatMap { [$0, "\(module).\($0)"] }
  }
}
