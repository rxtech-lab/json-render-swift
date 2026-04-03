import Foundation
import SwiftParser
import SwiftSyntax

/// CLI tool that scans Swift source files for @Component declarations
/// and generates a components.json schema file.
///
/// Usage: SchemaGeneratorTool <source-directory> <output-path>

@main
struct SchemaGenerator {
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            print("Usage: SchemaGeneratorTool <source-directory> <output-path>")
            return
        }

        let sourceDir = args[1]
        let outputPath = args[2]

        let components = try scanDirectory(sourceDir)

        let schema: [String: Any] = ["components": components]
        let data = try JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted, .sortedKeys])

        try data.write(to: URL(fileURLWithPath: outputPath))
        print("Generated schema with \(components.count) components at \(outputPath)")
    }

    static func scanDirectory(_ path: String) throws -> [String: Any] {
        let fm = FileManager.default
        var components: [String: Any] = [:]

        guard let enumerator = fm.enumerator(atPath: path) else { return components }

        while let file = enumerator.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let fullPath = (path as NSString).appendingPathComponent(file)
            let source = try String(contentsOfFile: fullPath, encoding: .utf8)
            let sourceFile = Parser.parse(source: source)
            let visitor = ComponentVisitor(viewMode: .sourceAccurate)
            visitor.walk(sourceFile)

            for component in visitor.components {
                components[component.name] = component.toDict()
            }
        }

        return components
    }
}

// MARK: - Syntax Visitor

private class ComponentVisitor: SyntaxVisitor {
    var components: [ComponentInfo] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for @Component attribute
        for attribute in node.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                  name == "Component" else { continue }

            // Extract component name from first argument
            guard let args = attr.arguments?.as(LabeledExprListSyntax.self),
                  let firstArg = args.first,
                  let nameExpr = firstArg.expression.as(StringLiteralExprSyntax.self),
                  let componentName = nameExpr.segments.first?.as(StringSegmentSyntax.self)?.content.text else { continue }

            // Extract description and events from named args
            var description = ""
            var events: [String] = []
            for arg in args.dropFirst() {
                guard let label = arg.label?.text else { continue }
                if label == "description",
                   let str = arg.expression.as(StringLiteralExprSyntax.self),
                   let seg = str.segments.first?.as(StringSegmentSyntax.self) {
                    description = seg.content.text
                }
                if label == "events",
                   let arr = arg.expression.as(ArrayExprSyntax.self) {
                    events = arr.elements.compactMap {
                        $0.expression.as(StringLiteralExprSyntax.self)?
                            .segments.first?.as(StringSegmentSyntax.self)?.content.text
                    }
                }
            }

            // Extract @Prop properties
            let props = extractProps(from: node.memberBlock)

            components.append(ComponentInfo(
                name: componentName,
                description: description,
                props: props,
                events: events
            ))
        }

        return .visitChildren
    }

    private func extractProps(from memberBlock: MemberBlockSyntax) -> [PropInfo] {
        var props: [PropInfo] = []

        for member in memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            let hasProp = varDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Prop"
            }
            guard hasProp else { continue }

            for binding in varDecl.bindings {
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }

                let swiftType = binding.typeAnnotation?.type.trimmedDescription ?? "String"
                let defaultValue = binding.initializer?.value.trimmedDescription

                props.append(PropInfo(
                    name: name,
                    type: mapType(swiftType),
                    defaultValue: defaultValue
                ))
            }
        }

        return props
    }

    private func mapType(_ swiftType: String) -> String {
        switch swiftType {
        case "String": return "string"
        case "Int": return "int"
        case "Double", "Float", "CGFloat": return "double"
        case "Bool": return "bool"
        default:
            if swiftType.hasPrefix("[") && !swiftType.contains(":") { return "array" }
            if swiftType.hasPrefix("[") && swiftType.contains(":") { return "object" }
            return "string"
        }
    }
}

// MARK: - Data types

private struct ComponentInfo {
    let name: String
    let description: String
    let props: [PropInfo]
    let events: [String]

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]

        var propsDict: [String: Any] = [:]
        for prop in props {
            var propInfo: [String: Any] = ["type": prop.type]
            if let d = prop.defaultValue { propInfo["default"] = d }
            propsDict[prop.name] = propInfo
        }
        dict["props"] = propsDict

        if !events.isEmpty { dict["events"] = events }
        if !description.isEmpty { dict["description"] = description }

        return dict
    }
}

private struct PropInfo {
    let name: String
    let type: String
    let defaultValue: String?
}
