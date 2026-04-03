import Foundation

/// Binding an event to an action with parameters.
public struct ActionBinding: Sendable, Equatable, Codable {
    /// The action name to dispatch.
    public let action: String
    /// Parameters to pass to the action handler (may contain dynamic expressions).
    public let params: [String: PropValue]?

    public init(action: String, params: [String: PropValue]? = nil) {
        self.action = action
        self.params = params
    }
}

/// Wrapper to allow a single ActionBinding or an array of them on an event.
public enum ActionBindingOrArray: Sendable, Equatable, Codable {
    case single(ActionBinding)
    case multiple([ActionBinding])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([ActionBinding].self) {
            self = .multiple(arr)
        } else {
            let single = try container.decode(ActionBinding.self)
            self = .single(single)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let binding): try container.encode(binding)
        case .multiple(let bindings): try container.encode(bindings)
        }
    }

    /// Flatten to an array regardless of variant.
    public var bindings: [ActionBinding] {
        switch self {
        case .single(let b): return [b]
        case .multiple(let bs): return bs
        }
    }
}
