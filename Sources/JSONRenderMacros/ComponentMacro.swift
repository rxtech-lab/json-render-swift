import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ComponentMacro {}

// MARK: - MemberMacro: generates static properties

extension ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract macro arguments
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw MacroError.missingArguments
        }

        // First argument: component name (required)
        guard let nameExpr = arguments.first?.expression.as(StringLiteralExprSyntax.self),
              let name = nameExpr.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
            throw MacroError.invalidName
        }

        // Named arguments: description, events
        var description = ""
        var events: [String] = []

        for arg in arguments.dropFirst() {
            guard let label = arg.label?.text else { continue }
            switch label {
            case "description":
                if let str = arg.expression.as(StringLiteralExprSyntax.self),
                   let seg = str.segments.first?.as(StringSegmentSyntax.self) {
                    description = seg.content.text
                }
            case "events":
                if let arrayExpr = arg.expression.as(ArrayExprSyntax.self) {
                    events = arrayExpr.elements.compactMap { element in
                        element.expression.as(StringLiteralExprSyntax.self)?
                            .segments.first?.as(StringSegmentSyntax.self)?.content.text
                    }
                }
            default:
                break
            }
        }

        // Find all @Prop properties in the struct
        let propInfos = extractProps(from: declaration)

        // Build propDefinitions array literal
        let propEntries = propInfos.map { prop in
            let defaultLiteral: String
            if let dv = prop.defaultValue {
                // Escape any inner quotes for use inside a string literal
                let escaped = dv.replacingOccurrences(of: "\\", with: "\\\\")
                                .replacingOccurrences(of: "\"", with: "\\\"")
                defaultLiteral = "\"\(escaped)\""
            } else {
                defaultLiteral = "nil"
            }
            return "PropDefinition(name: \"\(prop.name)\", type: .\(prop.type), defaultValue: \(defaultLiteral), description: nil, binding: \(prop.binding))"
        }.joined(separator: ",\n            ")

        let eventsLiteral = events.map { "\"\($0)\"" }.joined(separator: ", ")

        return [
            """
            static var componentName: String { "\(raw: name)" }
            """,
            """
            static var propDefinitions: [PropDefinition] {
                [\(raw: propEntries)]
            }
            """,
            """
            static var eventNames: [String] { [\(raw: eventsLiteral)] }
            """,
            """
            static var componentDescription: String { "\(raw: description)" }
            """,
        ]
    }
}

// MARK: - ExtensionMacro: adds ComponentDefinition conformance

extension ComponentMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let ext = try ExtensionDeclSyntax("extension \(type): ComponentDefinition") {}
        return [ext]
    }
}

// MARK: - Prop extraction

private struct PropInfo {
    let name: String
    let type: String  // PropType raw value
    let defaultValue: String?
    let binding: Bool
}

private func extractProps(from declaration: some DeclGroupSyntax) -> [PropInfo] {
    var props: [PropInfo] = []

    for member in declaration.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

        // Check if it has @Prop attribute
        let hasProp = varDecl.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Prop"
        }
        guard hasProp else { continue }

        for binding in varDecl.bindings {
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }

            // Extract type
            let swiftType: String
            if let typeAnnotation = binding.typeAnnotation?.type {
                swiftType = typeAnnotation.trimmedDescription
            } else {
                swiftType = "String" // fallback
            }

            // Extract default value
            let defaultValue = binding.initializer?.value.trimmedDescription

            // Map Swift type to PropType
            let propType = mapToPropType(swiftType)

            // Check if the name suggests binding (convention: starts with "is" or type annotation)
            let isBinding = false // Could be enhanced later

            props.append(PropInfo(name: name, type: propType, defaultValue: defaultValue, binding: isBinding))
        }
    }

    return props
}

private func mapToPropType(_ swiftType: String) -> String {
    switch swiftType {
    case "String": return "string"
    case "Int": return "int"
    case "Double", "Float", "CGFloat": return "double"
    case "Bool": return "bool"
    default:
        if swiftType.hasPrefix("[") && !swiftType.contains(":") {
            return "array"
        }
        if swiftType.hasPrefix("[") && swiftType.contains(":") {
            return "object"
        }
        return "string"
    }
}

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case missingArguments
    case invalidName

    var description: String {
        switch self {
        case .missingArguments: return "@Component requires at least a name argument"
        case .invalidName: return "@Component name must be a string literal"
        }
    }
}
