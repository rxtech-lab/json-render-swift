import Foundation

/// The type of a component prop, used for schema generation.
public enum PropType: String, Sendable, Codable, CaseIterable {
    case string
    case int
    case double
    case bool
    case array
    case object
}

/// Metadata about a single prop on a component.
public struct PropDefinition: Sendable, Codable, Equatable {
    public let name: String
    public let type: PropType
    public let defaultValue: String?
    public let description: String?
    public let binding: Bool

    public init(name: String, type: PropType, defaultValue: String? = nil, description: String? = nil, binding: Bool = false) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
        self.binding = binding
    }
}

/// Protocol that describes a component's metadata.
/// The `@Component` macro auto-generates conformance.
public protocol ComponentDefinition {
    /// The component type name used in JSON specs (e.g. "StarRating").
    static var componentName: String { get }
    /// Metadata for each prop the component accepts.
    static var propDefinitions: [PropDefinition] { get }
    /// Event names this component can emit (e.g. ["press", "longPress"]).
    static var eventNames: [String] { get }
    /// A description for AI prompt generation.
    static var componentDescription: String { get }
}
