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

    /// A comprehensive schema description of the Spec format and all built-in components.
    /// Pass this to an LLM (e.g. as `schemaDescription` in `streamObject`) so it understands the output format.
    public nonisolated static let schemaDescription = """
    A UI specification for rendering SwiftUI interfaces via JSONRenderSwift.

    Top-level fields:
    - root: The ID of the root element to render.
    - elements: A flat map of element IDs to element definitions.
    - state: Optional initial state as a nested JSON object.

    Each element has:
    - type: Component type name.
    - props: Component-specific properties (may contain literal values or dynamic expressions).
    - children: Optional array of child element IDs for layout composition.
    - on: Optional event handlers mapping event name to action binding(s). Example: {"press": {"action": "submit", "params": {}}}
    - visible: Optional visibility condition for conditional rendering.
    - repeat: Optional repeat config. Exact format: {"statePath": "/path/to/array", "key": "fieldName"}. "statePath" is REQUIRED (a JSON Pointer to the state array). "key" is optional (field name for stable identity).

    Available component types and their props:

    Text: content (string), font (string: title/headline/subheadline/body/caption/caption2/footnote/largeTitle/title2/title3), color (string), weight (string: bold/semibold/medium/regular/light/thin/ultraLight/heavy/black), alignment (string: leading/center/trailing)

    Button: label (string), style (string: bordered/borderedProminent/borderless/plain), disabled (bool). Events: "press"

    Card: title (string), subtitle (string), padding (string or number: sm/md/lg/xl), style (string: regular/clear)

    TextField: placeholder (string), value (use {"$bindState": "/path"} for two-way binding)

    Toggle: label (string), isOn (use {"$bindState": "/path"} for two-way binding)

    Slider: value ({"$bindState": "/path"}), min (number), max (number), step (number), label (string)

    ProgressView: value (number), total (number), label (string)

    Image: systemName (string - SF Symbol name), url (string), resizable (bool), aspectRatio (string: fill/fit), width (number), height (number), color (string)

    Label: title (string), systemImage (string - SF Symbol name)

    Badge: text (string), color (string)

    Link: title (string), url (string)

    VStack: alignment (string: leading/center/trailing), spacing (number)

    HStack: alignment (string: top/center/bottom), spacing (number)

    ZStack: alignment (string: topLeading/top/topTrailing/leading/center/trailing/bottomLeading/bottom/bottomTrailing)

    Form: style (string: grouped/automatic/columns)

    Section: header (string), footer (string)

    List: style (string: plain/inset/sidebar/automatic)

    Divider: (no props)

    Spacer: minLength (number)

    Dynamic value expressions for props:
    - Read state: {"$state": "/path/to/value"}
    - Two-way binding: {"$bindState": "/path/to/value"}
    - Template string: {"$template": "Hello, ${/user/name}!"}
    - Conditional: {"$cond": {"$state": "/path", "eq": value}, "$then": "Yes", "$else": "No"}
    - Repeat item field: {"$item": "fieldName"}
    - Repeat item binding: {"$bindItem": "fieldName"}
    - Repeat index: {"$index": true}

    Visibility conditions:
    - {"$state": "/path", "eq": value}
    - {"$state": "/path", "gte": 5}
    - Operators: eq, neq, gt, gte, lt, lte, not
    """
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        props = try container.decodeIfPresent([String: PropValue].self, forKey: .props) ?? [:]
        children = try container.decodeIfPresent([String].self, forKey: .children)
        visible = try container.decodeIfPresent(VisibilityCondition.self, forKey: .visible)
        on = try container.decodeIfPresent([String: ActionBindingOrArray].self, forKey: .on)
        `repeat` = try container.decodeIfPresent(RepeatConfig.self, forKey: .repeat)
    }

    private enum CodingKeys: String, CodingKey {
        case type, props, children, visible, on, `repeat`
    }
}
