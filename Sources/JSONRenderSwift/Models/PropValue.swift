import Foundation

/// A property value that can be a literal or a dynamic expression.
/// This is the core discriminated union for all prop values in a spec.
public indirect enum PropValue: Sendable, Equatable {
    // Literals
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([PropValue])
    case object([String: PropValue])

    // Dynamic expressions
    case stateRef(path: String)                     // { "$state": "/path" }
    case bindStateRef(path: String)                  // { "$bindState": "/path" }
    case itemRef(field: String)                      // { "$item": "fieldName" or "" }
    case bindItemRef(field: String)                  // { "$bindItem": "fieldName" or "" }
    case indexRef                                     // { "$index": true }
    case template(String)                            // { "$template": "Hello ${/user/name}" }
    case cond(
        condition: VisibilityCondition,
        then: PropValue,
        else: PropValue
    )                                                 // { "$cond": ..., "$then": ..., "$else": ... }
}

// MARK: - Codable

extension PropValue: Codable {
    private enum CodingKeys: String, CodingKey {
        case state = "$state"
        case bindState = "$bindState"
        case item = "$item"
        case bindItem = "$bindItem"
        case index = "$index"
        case template = "$template"
        case cond = "$cond"
        case then = "$then"
        case `else` = "$else"
    }

    public init(from decoder: Decoder) throws {
        // Try as keyed container first (object with potential expression keys)
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // Check expression discriminators in priority order
            if let path = try container.decodeIfPresent(String.self, forKey: .state) {
                self = .stateRef(path: path)
                return
            }
            if let path = try container.decodeIfPresent(String.self, forKey: .bindState) {
                self = .bindStateRef(path: path)
                return
            }
            if let field = try container.decodeIfPresent(String.self, forKey: .item) {
                self = .itemRef(field: field)
                return
            }
            if let field = try container.decodeIfPresent(String.self, forKey: .bindItem) {
                self = .bindItemRef(field: field)
                return
            }
            if (try container.decodeIfPresent(Bool.self, forKey: .index)) != nil {
                self = .indexRef
                return
            }
            if let tmpl = try container.decodeIfPresent(String.self, forKey: .template) {
                self = .template(tmpl)
                return
            }
            if let condValue = try container.decodeIfPresent(VisibilityCondition.self, forKey: .cond) {
                let thenValue = try container.decode(PropValue.self, forKey: .then)
                let elseValue = try container.decode(PropValue.self, forKey: .else)
                self = .cond(condition: condValue, then: thenValue, else: elseValue)
                return
            }

            // No expression key found — decode as a plain object
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
            var dict: [String: PropValue] = [:]
            for key in dynamicContainer.allKeys {
                dict[key.stringValue] = try dynamicContainer.decode(PropValue.self, forKey: key)
            }
            if dict.isEmpty {
                // Could be an empty object or something else
                self = .object(dict)
            } else {
                self = .object(dict)
            }
            return
        }

        // Try single value container for primitives and arrays
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
            return
        }
        if let v = try? container.decode(Int.self) {
            self = .int(v)
            return
        }
        if let v = try? container.decode(Double.self) {
            self = .double(v)
            return
        }
        if let v = try? container.decode(String.self) {
            self = .string(v)
            return
        }
        if let v = try? container.decode([PropValue].self) {
            self = .array(v)
            return
        }

        throw DecodingError.typeMismatch(
            PropValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode PropValue")
        )
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .bool(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .int(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .double(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .string(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .array(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .object(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .stateRef(let path):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(path, forKey: .state)
        case .bindStateRef(let path):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(path, forKey: .bindState)
        case .itemRef(let field):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(field, forKey: .item)
        case .bindItemRef(let field):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(field, forKey: .bindItem)
        case .indexRef:
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(true, forKey: .index)
        case .template(let tmpl):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(tmpl, forKey: .template)
        case .cond(let condition, let thenVal, let elseVal):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(condition, forKey: .cond)
            try container.encode(thenVal, forKey: .then)
            try container.encode(elseVal, forKey: .else)
        }
    }
}

// MARK: - Dynamic coding key for arbitrary object keys

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
