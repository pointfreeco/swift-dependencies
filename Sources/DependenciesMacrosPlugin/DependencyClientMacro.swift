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

  #if canImport(SwiftSyntax602)
  #else
    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
      of node: AttributeSyntax,
      providingMembersOf declaration: D,
      in context: C
    ) throws -> [DeclSyntax] {
      try expansion(of: node, providingMembersOf: declaration, conformingTo: [], in: context)
    }
  #endif

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo _: [TypeSyntax],
    in context: some MacroExpansionContext
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
    var conditionalGroups: [ConditionalGroup] = []
    var hasEndpoints = false
    var accesses: Set<Access> = Access(modifiers: declaration.modifiers).map { [$0] } ?? []
    for member in declaration.memberBlock.members {
      if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
        for clause in ifConfig.clauses {
          guard
            let condition = clause.condition,
            let elements = clause.elements?.as(MemberBlockItemListSyntax.self)
          else { continue }
          let conditionKey = condition.trimmedDescription
          let groupIdx: Int
          if let idx = conditionalGroups.firstIndex(where: { $0.conditionKey == conditionKey }) {
            groupIdx = idx
          } else {
            conditionalGroups.append(ConditionalGroup(conditionKey: conditionKey, properties: []))
            groupIdx = conditionalGroups.count - 1
          }
          for item in elements {
            guard
              var property = item.decl.as(VariableDeclSyntax.self),
              !property.isStatic
            else { continue }
            let isEndpoint =
              property.hasDependencyEndpointMacroAttached
              || property.bindingSpecifier.tokenKind != .keyword(.let) && property.isClosure
            let propertyAccess = Access(modifiers: property.modifiers)
            guard
              var binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }
            if property.bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
              continue
            }
            if let accessors = binding.accessorBlock?.accessors {
              switch accessors {
              case .getter:
                continue
              case .accessors(let accessors):
                if accessors.contains(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }) {
                  continue
                }
              @unknown default: continue
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
                    '@DependencyClient' requires '\(identifier)' to have a type annotation in order \
                    to generate a memberwise initializer
                    """
                  ),
                  fixIt: FixIt(
                    message: MacroExpansionFixItMessage("Insert ': <#Type#>'"),
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
              continue
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
            conditionalGroups[groupIdx].properties.append(
              Property(declaration: property, identifier: identifier, isEndpoint: isEndpoint)
            )
            hasEndpoints = hasEndpoints || isEndpoint
          }
        }
        continue
      }
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
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else { return [] }

      if property.bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
        continue
      }
      if let accessors = binding.accessorBlock?.accessors {
        switch accessors {
        case .getter:
          continue
        case .accessors(let accessors):
          if accessors.contains(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }) {
            continue
          }
        @unknown default: return []
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
      properties.append(
        Property(declaration: property, identifier: identifier, isEndpoint: isEndpoint)
      )
      hasEndpoints = hasEndpoints || isEndpoint
    }
    guard hasEndpoints else { return [] }
    let access = accesses.min().flatMap { $0.token?.with(\.trailingTrivia, .space) }

    // Generate an unimplemented default closure string for a conditional endpoint property,
    // for use in init bodies to satisfy Swift's initialization requirements.
    func unimplementedAssignment(for property: Property) -> String? {
      // Synthesize a @DependencyEndpoint attribute and delegate to its peer expansion
      // so the unimplemented closure stays in sync with @DependencyEndpoint's behavior.
      let attribute: AttributeSyntax = "@DependencyEndpoint"
      guard let peers = try? DependencyEndpointMacro.expansion(
        of: attribute,
        providingPeersOf: DeclSyntax(property.declaration),
        in: context
      ),
        !peers.isEmpty,
        let privateVar = peers.last?.as(VariableDeclSyntax.self),
        let closureExpr = privateVar.bindings.first?.initializer?.value
      else { return nil }
      return "self.\(property.identifier) = \(closureExpr.trimmedDescription)"
    }

    // Extra body lines that conditionally initialize endpoints from groups not in current init params.
    func conditionalDefaultLines(excludingGroupKey: String? = nil) -> [String] {
      conditionalGroups.flatMap { group -> [String] in
        guard group.conditionKey != excludingGroupKey else { return [] }
        let assignments = group.properties.filter(\.isEndpoint).compactMap {
          unimplementedAssignment(for: $0)
        }
        guard !assignments.isEmpty else { return [] }
        return ["#if \(group.conditionKey)"] + assignments + ["#endif"]
      }
    }

    // TODO: Don't define initializers if any single endpoint is invalid
    func makeInit(_ props: [Property], excludingGroupKey: String? = nil) -> DeclSyntax {
      let extraLines = conditionalDefaultLines(excludingGroupKey: excludingGroupKey)
      let allBodyLines =
        props.map { "self.\($0.identifier) = \($0.identifier)" } + extraLines
      if props.isEmpty && extraLines.isEmpty {
        return "\(access)init() {}"
      } else if props.isEmpty {
        return """
          \(access)init() {
          \(raw: allBodyLines.joined(separator: "\n"))
          }
          """
      } else {
        return """
          \(access)init(
          \(raw: props.map { $0.declaration.bindings.trimmedDescription }.joined(separator: ",\n"))
          ) {
          \(raw: allBodyLines.joined(separator: "\n"))
          }
          """
      }
    }

    var result: [DeclSyntax] = []
    // Unconditional full init (only if there are unconditional endpoints)
    if properties.contains(where: \.isEndpoint) {
      result.append(makeInit(properties))
    }
    // #if-wrapped init per conditional group
    for group in conditionalGroups where group.properties.contains(where: \.isEndpoint) {
      let allProps = properties + group.properties
      let initDecl = makeInit(allProps, excludingGroupKey: group.conditionKey)
      result.append(
        """
        #if \(raw: group.conditionKey)
        \(initDecl)
        #endif
        """
      )
    }
    // No-endpoint init (always generated)
    result.append(makeInit(properties.filter { !$0.isEndpoint }))
    return result
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
  var identifier: String
  var isEndpoint: Bool
}

private struct ConditionalGroup {
  var conditionKey: String
  var properties: [Property]
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
        case .attribute(let attribute) = $0,
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
