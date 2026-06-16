import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public enum DependencyEntryMacro {}

extension DependencyEntryMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      isInDependencyValuesExtension(context: context),
      let property = declaration.as(VariableDeclSyntax.self),
      property.bindingSpecifier.tokenKind == .keyword(.var),
      let identifier = property.bindings.first?.pattern
        .as(IdentifierPatternSyntax.self)?.identifier.trimmed
    else {
      return []
    }
    let keyName = keyTypeName(for: node, property: property, identifier: identifier)
    return [
      """
      get { self[\(keyName).self] }
      """,
      """
      set { self[\(keyName).self] = newValue }
      """,
      """
      _modify { yield &self[\(keyName).self] }
      """,
    ]
  }
}

extension DependencyEntryMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      property.bindingSpecifier.tokenKind == .keyword(.var),
      isInDependencyValuesExtension(context: context)
    else {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            """
            '@DependencyEntry' macro can only attach to 'var' declarations inside extensions of \
            'DependencyValues'
            """
          )
        )
      )
      return []
    }

    guard
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
    else {
      return []
    }

    let accessLevel = keyAccessLevel(for: node, property: property)
    let memberAccessLevel = memberAccessLevel(for: node, property: property)
    var liveValueExpr: ExprSyntax?
    var previewValueExpr: ExprSyntax?
    if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
      for argument in arguments {
        switch argument.label?.text {
        case "liveValue":
          liveValueExpr = argument.expression
        case "previewValue":
          previewValueExpr = argument.expression
        default:
          break
        }
      }
    }

    let testValueExpr: ExprSyntax? = binding.initializer?.value
    if testValueExpr == nil, liveValueExpr == nil {
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            """
            '@DependencyEntry' requires an initializer to define the property's test value, or a \
            'liveValue' argument to fall back on
            """
          )
        )
      )
      return []
    }

    let conformance = liveValueExpr != nil ? "DependencyKey" : "TestDependencyKey"
    let keyName = keyTypeName(for: node, property: property, identifier: identifier)

    var members: [String] = []
    if let typeAnnotation = binding.typeAnnotation?.type.trimmed {
      members.append("\(memberAccessLevel)typealias Value = \(typeAnnotation)")
      if let liveValueExpr {
        members.append("\(memberAccessLevel)static var liveValue: Value { \(liveValueExpr) }")
      }
      if let previewValueExpr {
        members.append("\(memberAccessLevel)static var previewValue: Value { \(previewValueExpr) }")
      }
      if let testValueExpr {
        members.append("\(memberAccessLevel)static var testValue: Value { \(testValueExpr) }")
      }
    } else {
      let attribute = "@DependenciesMacros._DependencyEntryDefaultValue"
      if let liveValueExpr {
        members.append("\(attribute) \(memberAccessLevel)static var liveValue = \(liveValueExpr)")
      }
      if let previewValueExpr {
        members.append(
          "\(attribute) \(memberAccessLevel)static var previewValue = \(previewValueExpr)"
        )
      }
      if let testValueExpr {
        members.append("\(attribute) \(memberAccessLevel)static var testValue = \(testValueExpr)")
      }
    }

    let body = members.joined(separator: "\n")
    let keyDecl: DeclSyntax = """
      \(raw: accessLevel) nonisolated enum \(keyName): Dependencies.\(raw: conformance) {
      \(raw: body)
      }
      """
    return [keyDecl]
  }
}

private func keyTypeName(
  for node: AttributeSyntax,
  property: VariableDeclSyntax,
  identifier: TokenSyntax
) -> TokenSyntax {
  guard property.isPublicOrPackage
  else {
    return "__Key_\(identifier)"
  }
  if let customKeyName = customKeyName(from: node) {
    return .identifier(customKeyName)
  }
  if let typeAnnotation = property.bindings.first?.typeAnnotation?.type,
    let typeName = keyTypeName(from: typeAnnotation)
  {
    return .identifier("\(typeName)Key")
  }
  return .identifier(
    "\(identifier.trimmedDescription.dependencyEntryTrimmedBackticks.uppercasingFirst)Key"
  )
}

private func keyTypeName(from type: TypeSyntax) -> String? {
  switch type.as(TypeSyntaxEnum.self) {
  case .identifierType(let type):
    return type.name.text.dependencyEntryTrimmedBackticks
  case .memberType(let type):
    return type.name.text.dependencyEntryTrimmedBackticks
  case .someOrAnyType(let type):
    return keyTypeName(from: type.constraint)
  case .optionalType(let type):
    return keyTypeName(from: type.wrappedType)
  case .implicitlyUnwrappedOptionalType(let type):
    return keyTypeName(from: type.wrappedType)
  case .arrayType(let type):
    return keyTypeName(from: type.element)
  case .dictionaryType(let type):
    guard
      let keyType = keyTypeName(from: type.key),
      let valueType = keyTypeName(from: type.value)
    else {
      return nil
    }
    return "\(keyType)\(valueType)"
  case .tupleType(let type):
    let elements = type.elements.compactMap { keyTypeName(from: $0.type) }
    return elements.isEmpty ? nil : elements.joined()
  case .compositionType(let type):
    let elements = type.elements.compactMap { keyTypeName(from: $0.type) }
    return elements.isEmpty ? nil : elements.joined()
  case .attributedType(let type):
    return keyTypeName(from: type.baseType)
  case .metatypeType(let type):
    return keyTypeName(from: type.baseType)
  default:
    return nil
  }
}

private func keyAccessLevel(
  for node: AttributeSyntax,
  property: VariableDeclSyntax
) -> String {
  guard customKeyName(from: node) != nil || property.isPublicOrPackage
  else {
    return "private"
  }
  return property.publicOrPackage ?? "private"
}

private func memberAccessLevel(
  for node: AttributeSyntax,
  property: VariableDeclSyntax
) -> String {
  guard let accessControl = property.publicOrPackage
  else {
    guard customKeyName(from: node) != nil
    else { return "" }
    return "public "
  }
  return "\(accessControl) "
}

private func customKeyName(from node: AttributeSyntax) -> String? {
  guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
  for argument in arguments where argument.label == nil {
    guard
      let literal = argument.expression.as(StringLiteralExprSyntax.self),
      literal.segments.count == 1,
      let segment = literal.segments.first?.as(StringSegmentSyntax.self)
    else {
      continue
    }
    return segment.content.text
  }
  return nil
}

private func isInDependencyValuesExtension(
  context: some MacroExpansionContext
) -> Bool {
  guard
    let extensionDecl = context.lexicalContext.first?.as(ExtensionDeclSyntax.self)
  else {
    return false
  }
  let extendedType = extensionDecl.extendedType
  let name: String?
  if let identifier = extendedType.as(IdentifierTypeSyntax.self) {
    name = identifier.name.text
  } else if let member = extendedType.as(MemberTypeSyntax.self) {
    name = member.name.text
  } else {
    name = nil
  }
  return name == "DependencyValues"
}

public enum DependencyEntryDefaultValueMacro {}

extension DependencyEntryDefaultValueMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      let binding = property.bindings.first,
      let initializer = binding.initializer?.value
    else {
      return []
    }
    return ["get { \(initializer) }"]
  }
}

extension VariableDeclSyntax {
  fileprivate var isPublicOrPackage: Bool {
    self.modifiers.contains {
      $0.name.tokenKind == .keyword(.public)
        || $0.name.tokenKind == .keyword(.package)
    }
  }
  fileprivate var publicOrPackage: String? {
    self.modifiers.first {
      $0.name.tokenKind == .keyword(.public)
        || $0.name.tokenKind == .keyword(.package)
    }?.name.trimmedDescription

  }
}

extension String {
  fileprivate var dependencyEntryTrimmedBackticks: String {
    var result = self[...]
    if result.first == "`" {
      result = result.dropFirst()
    }
    if result.last == "`" {
      result = result.dropLast()
    }
    return String(result)
  }

  fileprivate var uppercasingFirst: String {
    guard let first else { return self }
    return first.uppercased() + dropFirst()
  }
}
