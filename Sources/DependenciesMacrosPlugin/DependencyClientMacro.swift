import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

#if !canImport(SwiftSyntax600)
  import SwiftSyntaxMacroExpansion
#endif

public enum DependencyClientMacro: MemberAttributeMacro, MemberMacro {
  public static func expansion<D: DeclGroupSyntax, M: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingAttributesFor member: M,
    in context: C
  ) throws -> [AttributeSyntax] {
    if member.as(VariableDeclSyntax.self)?.isIgnored == true {
      return []
    }

    guard
      let property = member.as(VariableDeclSyntax.self),
      property.bindingSpecifier.tokenKind != .keyword(.let),
      property.isClosure,
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
      let functionType = property.asClosureType?.trimmed
    else {
      return []
    }
    // NB: Ideally `@DependencyEndpoint` would handle this for us, but there are compiler crashes
    if let initializer = binding.initializer {
      guard try !initializer.diagnose(node, context: context).earlyOut
      else { return [] }
    } else if functionType.effectSpecifiers?.hasThrowsClause != true,
      !functionType.isVoid,
      !functionType.isOptional
    {
      var unimplementedDefault = functionType.unimplementedDefault
      unimplementedDefault.append(placeholder: functionType.returnClause.type.trimmed.description)
      context.diagnose(
        clientName: declaration.as(StructDeclSyntax.self)?.name.text,
        node: binding,
        identifier: identifier,
        unimplementedDefault: unimplementedDefault
      )
      return []
    }
    var attributes: [AttributeSyntax] =
      property.hasDependencyEndpointMacroAttached
      ? []
      : ["@DependencyEndpoint"]
    if try functionType.parameters.contains(where: { $0.secondName != nil })
      || node.methodArgument != nil
    {
      attributes.append(
        contentsOf: ["iOS", "macOS", "tvOS", "watchOS"].map {
          """

          @available(\
          \(raw: $0), \
          deprecated: 9999, \
          message: "This property has a method equivalent that is preferred for autocomplete via \
          this deprecation. It is perfectly fine to use for overriding and accessing via \
          '@Dependency'."\
          )
          """
        }
      )
    }

    return attributes
  }

  public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingMembersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard let declaration = declaration.as(StructDeclSyntax.self)
    else {
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@DependencyClient' can only be applied to struct types"
          )
        )
      )
      return []
    }
    var properties: [Property] = []
    var hasEndpoints = false
    var accesses: Set<Access> = Access(modifiers: declaration.modifiers).map { [$0] } ?? []
    for member in declaration.memberBlock.members {
      guard
        var property = member.decl.as(VariableDeclSyntax.self),
        !property.isStatic
      else { continue }

      let isEndpoint =
        property.hasDependencyEndpointMacroAttached
        || property.bindingSpecifier.tokenKind != .keyword(.let) && property.isClosure

      let propertyAccess = Access(modifiers: property.modifiers)
      guard
        var binding = property.bindings.first,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
        let functionType = property.asClosureType?.trimmed
      else { return [] }

      if property.bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
        continue
      }
      if let accessors = binding.accessorBlock?.accessors {
        switch accessors {
        case .getter:
          continue
        case let .accessors(accessors):
          if accessors.contains(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }) {
            continue
          }
        }
      }

      if propertyAccess == .private, binding.initializer != nil { continue }
      accesses.insert(propertyAccess ?? .internal)

      if property.isIgnored { continue }

      guard let type = binding.typeAnnotation?.type ?? binding.initializer?.value.literalType
      else {
        context.diagnose(
          Diagnostic(
            node: binding,
            message: MacroExpansionErrorMessage(
              """
              '@DependencyClient' requires '\(identifier)' to have a type annotation in order to \
              generate a memberwise initializer
              """
            ),
            fixIt: FixIt(
              message: MacroExpansionFixItMessage(
                """
                Insert ': <#Type#>'
                """
              ),
              changes: [
                .replace(
                  oldNode: Syntax(binding),
                  newNode: Syntax(
                    binding
                      .with(\.pattern.trailingTrivia, "")
                      .with(
                        \.typeAnnotation,
                        TypeAnnotationSyntax(
                          colon: .colonToken(trailingTrivia: .space),
                          type: IdentifierTypeSyntax(name: "<#Type#>"),
                          trailingTrivia: .space
                        )
                      )
                  )
                )
              ]
            )
          )
        )
        return []
      }

      if var attributedTypeSyntax = type.as(AttributedTypeSyntax.self),
        attributedTypeSyntax.baseType.is(FunctionTypeSyntax.self)
      {
        attributedTypeSyntax.attributes.append(
          .attribute("@escaping").with(\.trailingTrivia, .space)
        )
        binding.typeAnnotation?.type = TypeSyntax(attributedTypeSyntax)
      } else if let typeSyntax = type.as(FunctionTypeSyntax.self) {
        #if canImport(SwiftSyntax600)
          binding.typeAnnotation?.type = TypeSyntax(
            AttributedTypeSyntax(
              specifiers: [],
              attributes: [.attribute("@escaping").with(\.trailingTrivia, .space)],
              baseType: typeSyntax
            )
          )
        #else
          binding.typeAnnotation?.type = TypeSyntax(
            AttributedTypeSyntax(
              attributes: [.attribute("@escaping").with(\.trailingTrivia, .space)],
              baseType: typeSyntax
            )
          )
        #endif
      } else if binding.typeAnnotation == nil {
        binding.pattern.trailingTrivia = ""
        binding.typeAnnotation = TypeAnnotationSyntax(
          colon: .colonToken(trailingTrivia: .space),
          type: type.with(\.trailingTrivia, .space)
        )
      }
      if isEndpoint {
        binding.accessorBlock = nil
        binding.initializer = nil
      } else if binding.initializer == nil, type.is(OptionalTypeSyntax.self) {
        binding.typeAnnotation?.trailingTrivia = .space
        binding.initializer = InitializerClauseSyntax(
          equal: .equalToken(trailingTrivia: .space),
          value: NilLiteralExprSyntax()
        )
      }
      property.bindings[property.bindings.startIndex] = binding

      guard let unimplementedDefaultClosure = unimplementedDefault(
        binding: binding,
        functionType: functionType,
        unescapedIdentifier: identifier.trimmedDescription.trimmedBackticks,
        identifier: identifier,
        context: context
      )
      else { return [] }

      properties.append(
        Property(
          declaration: property,
          defaultClosure: unimplementedDefaultClosure,
          identifier: identifier.text,
          isEndpoint: isEndpoint
        )
      )
      hasEndpoints = hasEndpoints || isEndpoint
    }
    guard hasEndpoints else { return [] }
    let access = accesses.min().flatMap { $0.token?.with(\.trailingTrivia, .space) }
    // TODO: Don't define initializers if any single endpoint is invalid
    return [properties/*, properties.filter { !$0.isEndpoint }*/].map {
        """
        \(access)init(
        \(raw: $0.map { $0.declaration.bindings.trimmedDescription + " = " + $0.defaultClosure.description }.joined(separator: ",\n"))
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
  case `package`
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
      case .keyword(.package):
        self = .package
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
    case .package:
      return .keyword(.package)
    case .public:
      return .keyword(.public)
    }
  }
}

private struct Property {
  var declaration: VariableDeclSyntax
  var defaultClosure: ClosureExprSyntax
  var identifier: String
  var isEndpoint: Bool
}

extension VariableDeclSyntax {
  fileprivate var isStatic: Bool {
    self.modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.static)
    }
  }

  fileprivate static let dependencyEndpointName = "DependencyEndpoint"
  fileprivate static let dependencyEndpointIgnoredName = "DependencyEndpointIgnored"
  fileprivate static let dependencyName = "Dependency"

  fileprivate func hasMacroAttached(_ macro: String) -> Bool {
    self.attributes.contains {
      guard
        case let .attribute(attribute) = $0,
        let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
        [macro].qualified("DependenciesMacros").contains(attributeName)
      else { return false }
      return true
    }
  }

  fileprivate var hasDependencyEndpointMacroAttached: Bool {
    hasMacroAttached(Self.dependencyEndpointName)
  }

  fileprivate var hasDependencyEndpointIgnoredMacroAttached: Bool {
    hasMacroAttached(Self.dependencyEndpointIgnoredName)
  }

  fileprivate var hasDependencyMacroAttached: Bool {
    hasMacroAttached(Self.dependencyName)
  }

  fileprivate var isIgnored: Bool {
    hasDependencyMacroAttached || hasDependencyEndpointIgnoredMacroAttached
  }
}

extension ExprSyntax {
  fileprivate var literalType: TypeSyntax? {
    if self.is(BooleanLiteralExprSyntax.self) {
      return "Swift.Bool"
    } else if self.is(FloatLiteralExprSyntax.self) {
      return "Swift.Double"
    } else if self.is(IntegerLiteralExprSyntax.self) {
      return "Swift.Int"
    } else if self.is(StringLiteralExprSyntax.self) {
      return "Swift.String"
    } else {
      return nil
    }
  }
}
