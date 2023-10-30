import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DependencyClientMacro: MemberAttributeMacro, MemberMacro {
  public static func expansion<D: DeclGroupSyntax, M: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingAttributesFor member: M,
    in context: C
  ) throws -> [AttributeSyntax] {
    guard
      let property = member.as(VariableDeclSyntax.self),
      !property.hasDependencyEndpointMacroAttached,
      property.isClosure
    else {
      return []
    }
    return [
      "@DependencyEndpoint"
    ]
  }

  public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingMembersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard let declaration = declaration.as(StructDeclSyntax.self)
    else {
      // TODO: Diagnostic?
      return []
    }
    var properties: [Property] = []
    var hasEndpoints = false
    var accesses: Set<Access> = Access(modifiers: declaration.modifiers).map { [$0] } ?? []
    for member in declaration.memberBlock.members {
      guard var property = member.decl.as(VariableDeclSyntax.self) else { continue }
      let isEndpoint = property.hasDependencyEndpointMacroAttached || property.isClosure
      let propertyAccess = Access(modifiers: property.modifiers)
      guard
        var binding = property.bindings.first,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else { return [] }

      if propertyAccess == .private, binding.initializer != nil { continue }
      accesses.insert(propertyAccess ?? .internal)

      guard let type = binding.typeAnnotation?.type ?? binding.initializer?.value.literalType
      // TODO: Get type from literals
      else {
        // TODO: Diagnostic?
        return []
      }
      if var attributedTypeSyntax = type.as(AttributedTypeSyntax.self),
        attributedTypeSyntax.baseType.is(FunctionTypeSyntax.self)
      {
        attributedTypeSyntax.attributes.append(
          .attribute("@escaping").with(\.trailingTrivia, .space)
        )
        binding.typeAnnotation?.type = attributedTypeSyntax.cast(TypeSyntax.self)
      } else if let typeSyntax = type.as(FunctionTypeSyntax.self) {
        binding.typeAnnotation?.type = AttributedTypeSyntax(
          attributes: [.attribute("@escaping").with(\.trailingTrivia, .space)],
          baseType: typeSyntax
        )
        .cast(TypeSyntax.self)
      } else if binding.typeAnnotation == nil {
        binding.pattern.trailingTrivia = ""
        binding.typeAnnotation = TypeAnnotationSyntax(
          colon: .colonToken(trailingTrivia: .space),
          type: type
        )
      }
      if isEndpoint {
        binding.initializer = nil
      } else if binding.initializer == nil, type.is(OptionalTypeSyntax.self) {
        binding.initializer = InitializerClauseSyntax(
          equal: .equalToken(trailingTrivia: .space),
          value: NilLiteralExprSyntax()
        )
      }
      property.bindings[property.bindings.startIndex] = binding
      properties.append(
        Property(declaration: property, identifier: identifier, isEndpoint: isEndpoint)
      )
      hasEndpoints = hasEndpoints || isEndpoint
    }
    guard hasEndpoints else { return [] }
    let access = accesses.min().flatMap { $0.token?.with(\.trailingTrivia, .space) }
    return [properties, properties.filter { !$0.isEndpoint }].map {
      $0.isEmpty
        ? "\(access)init() {}"
        : """
        \(access)init(
        \(raw: $0.map { $0.declaration.bindings.trimmedDescription }.joined(separator: ",\n"))
        ) {
        \(raw: $0.map { "self.\($0.identifier) = \($0.identifier)" }.joined(separator: "\n"))
        }
        """
    }
  }
}

private enum Access: Comparable {
  case `private`
  case `internal`
  case `public`

  init?(modifiers: DeclModifierListSyntax) {
    for modifier in modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.private):
        self = .private
        return
      case .keyword(.internal):
        self = .internal
        return
      case .keyword(.public):
        self = .public
        return
      default:
        continue
      }
    }
    return nil
  }

  var token: TokenSyntax? {
    switch self {
    case .private:
      return .keyword(.private)
    case .internal:
      return nil
    case .public:
      return .keyword(.public)
    }
  }
}

private struct Property {
  var declaration: VariableDeclSyntax
  var identifier: String
  var isEndpoint: Bool
}

extension VariableDeclSyntax {
  fileprivate var hasDependencyEndpointMacroAttached: Bool {
    self.attributes.contains {
      guard
        case let .attribute(attribute) = $0,
        let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
        ["DependencyEndpoint"].qualified("DependenciesMacros").contains(attributeName)
      else { return false }
      return true
    }
  }
}

private extension ExprSyntax {
  var literalType: TypeSyntax? {
    if self.is(BooleanLiteralExprSyntax.self) {
      return TypeSyntax(stringLiteral: "Swift.Bool")
    } else if self.is(FloatLiteralExprSyntax.self) {
      return TypeSyntax(stringLiteral: "Swift.Double")
    } else if self.is(IntegerLiteralExprSyntax.self) {
      return TypeSyntax(stringLiteral: "Swift.Int")
    } else {
      return nil
    }
  }
}
