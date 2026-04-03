import Foundation

/// The top-level UI specification decoded from AI-generated JSON.
public struct Spec: Sendable, Equatable, Codable {
    /// The ID of the root element to render.
    public var root: String
    /// A flat map of element IDs to their definitions.
    public var elements: [String: UIElement]
    /// Initial state for the UI (optional).
    public var state: JSONValue?

    public init(root: String, elements: [String: UIElement], state: JSONValue? = nil) {
        self.root = root
        self.elements = elements
        self.state = state
    }
}

/// A single element in the flat element tree.
public struct UIElement: Sendable, Equatable, Codable {
    /// Component type name from the registry (e.g. "Text", "Button", "Card").
    public var type: String
    /// Component properties — may contain literal values or dynamic expressions.
    public var props: [String: PropValue]
    /// IDs of child elements.
    public var children: [String]?
    /// Visibility condition for conditional rendering.
    public var visible: VisibilityCondition?
    /// Event bindings: event name -> action binding(s).
    public var on: [String: ActionBindingOrArray]?
    /// Repeat configuration for rendering items from a state array.
    public var `repeat`: RepeatConfig?

    public init(
        type: String,
        props: [String: PropValue] = [:],
        children: [String]? = nil,
        visible: VisibilityCondition? = nil,
        on: [String: ActionBindingOrArray]? = nil,
        repeat: RepeatConfig? = nil
    ) {
        self.type = type
        self.props = props
        self.children = children
        self.visible = visible
        self.on = on
        self.repeat = `repeat`
    }
}
