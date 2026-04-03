import Foundation

/// Interpolates `${/path}` expressions in template strings with values from state.
public struct TemplateInterpolator {
    /// Interpolate a template string, replacing `${/path}` with resolved state values.
    public static func interpolate(_ template: String, state: JSONValue, repeatItem: JSONValue? = nil, repeatIndex: Int? = nil) -> String {
        var result = ""
        var index = template.startIndex

        while index < template.endIndex {
            // Look for "${"
            if template[index] == "$",
               template.index(after: index) < template.endIndex,
               template[template.index(after: index)] == "{" {
                // Find closing "}"
                let startOfExpr = template.index(index, offsetBy: 2)
                if let endOfExpr = template[startOfExpr...].firstIndex(of: "}") {
                    let expr = String(template[startOfExpr..<endOfExpr])

                    // Resolve the expression
                    let resolved: String
                    if expr.hasPrefix("/") {
                        // State path reference
                        let value = JSONPointer(expr).resolve(in: state)
                        resolved = value?.displayString ?? ""
                    } else if expr == "$index" {
                        resolved = repeatIndex.map(String.init) ?? ""
                    } else if expr.hasPrefix("$item") {
                        if let item = repeatItem {
                            let field = String(expr.dropFirst(5)) // Remove "$item"
                            if field.isEmpty || field == "." {
                                resolved = item.displayString
                            } else {
                                let cleanField = field.hasPrefix(".") ? String(field.dropFirst()) : field
                                let value = JSONPointer("/\(cleanField)").resolve(in: item)
                                resolved = value?.displayString ?? ""
                            }
                        } else {
                            resolved = ""
                        }
                    } else {
                        resolved = ""
                    }

                    result += resolved
                    index = template.index(after: endOfExpr)
                    continue
                }
            }

            result.append(template[index])
            index = template.index(after: index)
        }

        return result
    }
}
