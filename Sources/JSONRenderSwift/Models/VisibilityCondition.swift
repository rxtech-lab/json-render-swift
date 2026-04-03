import Foundation

/// Visibility condition for conditional rendering of elements.
public indirect enum VisibilityCondition: Sendable, Equatable, Codable {
    /// Always visible or hidden.
    case literal(Bool)
    /// A single condition check.
    case single(SingleCondition)
    /// Implicit AND — all conditions must be true (decoded from JSON array).
    case allOf([VisibilityCondition])
    /// Explicit AND via "$and" key.
    case and([VisibilityCondition])
    /// Explicit OR via "$or" key.
    case or([VisibilityCondition])

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case and = "$and"
        case or = "$or"
        case state = "$state"
        case item = "$item"
        case index = "$index"
    }

    public init(from decoder: Decoder) throws {
        // Try as a boolean literal
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(Bool.self) {
            self = .literal(value)
            return
        }

        // Try as an array (implicit AND)
        if let container = try? decoder.singleValueContainer(),
           let array = try? container.decode([VisibilityCondition].self) {
            self = .allOf(array)
            return
        }

        // Try as a keyed container (object)
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Check for $and
        if let conditions = try container.decodeIfPresent([VisibilityCondition].self, forKey: .and) {
            self = .and(conditions)
            return
        }

        // Check for $or
        if let conditions = try container.decodeIfPresent([VisibilityCondition].self, forKey: .or) {
            self = .or(conditions)
            return
        }

        // Must be a single condition — decode it
        let singleCondition = try SingleCondition(from: decoder)
        self = .single(singleCondition)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .literal(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case .single(let cond):
            try cond.encode(to: encoder)
        case .allOf(let conditions):
            var container = encoder.singleValueContainer()
            try container.encode(conditions)
        case .and(let conditions):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(conditions, forKey: .and)
        case .or(let conditions):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(conditions, forKey: .or)
        }
    }
}

/// A single condition that checks a state path, item field, or index against operators.
public struct SingleCondition: Sendable, Equatable, Codable {
    public let source: ConditionSource
    public let operators: ConditionOperators

    public enum ConditionSource: Sendable, Equatable {
        case state(path: String)
        case item(field: String)
        case index
    }

    private enum CodingKeys: String, CodingKey {
        case state = "$state"
        case item = "$item"
        case index = "$index"
        case eq, neq, gt, gte, lt, lte, not
    }

    public init(source: ConditionSource, operators: ConditionOperators) {
        self.source = source
        self.operators = operators
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let path = try container.decodeIfPresent(String.self, forKey: .state) {
            self.source = .state(path: path)
        } else if let field = try container.decodeIfPresent(String.self, forKey: .item) {
            self.source = .item(field: field)
        } else if (try container.decodeIfPresent(Bool.self, forKey: .index)) != nil {
            self.source = .index
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "SingleCondition must have $state, $item, or $index")
            )
        }

        self.operators = ConditionOperators(
            eq: try container.decodeIfPresent(ConditionComparand.self, forKey: .eq),
            neq: try container.decodeIfPresent(ConditionComparand.self, forKey: .neq),
            gt: try container.decodeIfPresent(ConditionComparand.self, forKey: .gt),
            gte: try container.decodeIfPresent(ConditionComparand.self, forKey: .gte),
            lt: try container.decodeIfPresent(ConditionComparand.self, forKey: .lt),
            lte: try container.decodeIfPresent(ConditionComparand.self, forKey: .lte),
            not: try container.decodeIfPresent(Bool.self, forKey: .not)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch source {
        case .state(let path): try container.encode(path, forKey: .state)
        case .item(let field): try container.encode(field, forKey: .item)
        case .index: try container.encode(true, forKey: .index)
        }
        try container.encodeIfPresent(operators.eq, forKey: .eq)
        try container.encodeIfPresent(operators.neq, forKey: .neq)
        try container.encodeIfPresent(operators.gt, forKey: .gt)
        try container.encodeIfPresent(operators.gte, forKey: .gte)
        try container.encodeIfPresent(operators.lt, forKey: .lt)
        try container.encodeIfPresent(operators.lte, forKey: .lte)
        try container.encodeIfPresent(operators.not, forKey: .not)
    }
}

/// Comparison operators for a condition.
public struct ConditionOperators: Sendable, Equatable {
    public let eq: ConditionComparand?
    public let neq: ConditionComparand?
    public let gt: ConditionComparand?
    public let gte: ConditionComparand?
    public let lt: ConditionComparand?
    public let lte: ConditionComparand?
    public let not: Bool?

    public var hasOperators: Bool {
        eq != nil || neq != nil || gt != nil || gte != nil || lt != nil || lte != nil
    }
}

/// A comparand can be a literal value or a reference to another state path.
public enum ConditionComparand: Sendable, Equatable, Codable {
    case value(JSONValue)
    case stateRef(path: String)

    private enum CodingKeys: String, CodingKey {
        case state = "$state"
    }

    public init(from decoder: Decoder) throws {
        // Check if it's a { "$state": "/path" } object
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let path = try container.decodeIfPresent(String.self, forKey: .state) {
            self = .stateRef(path: path)
            return
        }
        // Otherwise it's a literal value
        let value = try JSONValue(from: decoder)
        self = .value(value)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .value(let v):
            try v.encode(to: encoder)
        case .stateRef(let path):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(path, forKey: .state)
        }
    }
}
