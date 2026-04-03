import Foundation

/// Resolves PropValue expressions into concrete JSONValue results.
public struct PropResolver {
    /// Resolve a single PropValue to a concrete JSONValue.
    public static func resolve(_ value: PropValue, context: ResolutionContext) -> JSONValue {
        switch value {
        case .null:
            return .null
        case .bool(let v):
            return .bool(v)
        case .int(let v):
            return .int(v)
        case .double(let v):
            return .double(v)
        case .string(let v):
            return .string(v)
        case .array(let arr):
            return .array(arr.map { resolve($0, context: context) })
        case .object(let dict):
            return .object(dict.mapValues { resolve($0, context: context) })

        case .stateRef(let path):
            return JSONPointer(path).resolve(in: context.state) ?? .null

        case .bindStateRef(let path):
            // Read side is same as $state; write side handled by resolveBindings
            return JSONPointer(path).resolve(in: context.state) ?? .null

        case .itemRef(let field):
            guard let item = context.repeatItem else { return .null }
            if field.isEmpty {
                return item
            }
            return JSONPointer("/\(field)").resolve(in: item) ?? .null

        case .bindItemRef(let field):
            guard let item = context.repeatItem else { return .null }
            if field.isEmpty {
                return item
            }
            return JSONPointer("/\(field)").resolve(in: item) ?? .null

        case .indexRef:
            if let idx = context.repeatIndex {
                return .int(idx)
            }
            return .null

        case .template(let tmpl):
            let result = TemplateInterpolator.interpolate(
                tmpl,
                state: context.state,
                repeatItem: context.repeatItem,
                repeatIndex: context.repeatIndex
            )
            return .string(result)

        case .cond(let condition, let thenVal, let elseVal):
            let visible = VisibilityEvaluator.evaluate(condition, context: context)
            return resolve(visible ? thenVal : elseVal, context: context)
        }
    }

    /// Resolve all props of an element to concrete values.
    public static func resolveAll(_ props: [String: PropValue], context: ResolutionContext) -> [String: JSONValue] {
        props.mapValues { resolve($0, context: context) }
    }

    /// Extract two-way binding paths from props.
    /// Returns a dictionary of prop name -> state path for $bindState/$bindItem props.
    public static func resolveBindings(_ props: [String: PropValue], context: ResolutionContext) -> [String: String] {
        var bindings: [String: String] = [:]
        for (key, value) in props {
            switch value {
            case .bindStateRef(let path):
                bindings[key] = path
            case .bindItemRef(let field):
                if let basePath = context.repeatItem != nil ? "" : nil {
                    // For $bindItem, construct the full state path from repeat context
                    // This requires the basePath from the repeat scope
                    if field.isEmpty {
                        bindings[key] = basePath
                    } else {
                        bindings[key] = "\(basePath)/\(field)"
                    }
                }
            default:
                break
            }
        }
        return bindings
    }

    /// Extract binding paths with full repeat base path support.
    public static func resolveBindings(_ props: [String: PropValue], repeatBasePath: String?) -> [String: String] {
        var bindings: [String: String] = [:]
        for (key, value) in props {
            switch value {
            case .bindStateRef(let path):
                bindings[key] = path
            case .bindItemRef(let field):
                if let basePath = repeatBasePath {
                    if field.isEmpty {
                        bindings[key] = basePath
                    } else {
                        bindings[key] = "\(basePath)/\(field)"
                    }
                }
            default:
                break
            }
        }
        return bindings
    }
}
