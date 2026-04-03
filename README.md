# JSONRenderSwift

A SwiftUI **Generative UI** framework. AI generates JSON specs, your app renders them as native SwiftUI views.

Inspired by [json-render](https://github.com/vercel-labs/json-render) from Vercel Labs.

## Why

When AI generates UI, you need guardrails. JSONRenderSwift constrains the AI to a catalog of known components with typed props, then renders the spec as native SwiftUI — safe, predictable, and fast.

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.0+

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/anthropics/json-render-swift.git", from: "0.1.0"),
],
targets: [
    .target(dependencies: ["JSONRenderSwift"]),
]
```

## Quick Start

### 1. Define a JSON spec

The spec is a flat element tree. AI generates this.

```json
{
    "root": "card",
    "elements": {
        "card": {
            "type": "Card",
            "props": { "title": "Hello" },
            "children": ["greeting", "input"]
        },
        "greeting": {
            "type": "Text",
            "props": { "content": { "$template": "Hello, ${/user/name}!" } }
        },
        "input": {
            "type": "TextField",
            "props": {
                "placeholder": "Your name",
                "value": { "$bindState": "/user/name" }
            }
        }
    },
    "state": {
        "user": { "name": "World" }
    }
}
```

### 2. Render it

```swift
import JSONRenderSwift

struct ContentView: View {
    let spec: Spec  // decoded from JSON

    var body: some View {
        JSONRenderer(spec: spec)
    }
}
```

That's it. The renderer handles decoding, state, binding, and component lookup.

### 3. Customize (optional)

```swift
let registry = ComponentRegistry.withBuiltIns()
let store = StateStore()
let executor = ActionExecutor()

// Add a custom component
registry.register("Avatar") { ctx in
    let url = ctx.resolvedProps["url"]?.stringValue ?? ""
    return AnyView(AsyncImage(url: URL(string: url)) { image in
        image.resizable().clipShape(Circle())
    } placeholder: {
        ProgressView()
    }.frame(width: 40, height: 40))
}

// Add a custom action
executor.register("submitForm") { params, store in
    let name = store.get("/user/name")?.stringValue ?? ""
    // call your API...
}

JSONRenderer(spec: spec, registry: registry, store: store, actionExecutor: executor)
```

---

## Spec Format

A spec has three fields:

| Field | Type | Description |
|-------|------|-------------|
| `root` | `String` | ID of the root element |
| `elements` | `{id: Element}` | Flat map of all elements |
| `state` | `JSON` | Initial state tree (optional) |

### Element

```json
{
    "type": "Button",
    "props": { "label": "Submit" },
    "children": ["child-1"],
    "visible": { "$state": "/form/isValid" },
    "on": { "press": { "action": "submitForm" } },
    "repeat": { "statePath": "/items", "key": "id" }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Component type name from registry |
| `props` | yes | Properties — literals or [expressions](#data-binding) |
| `children` | no | Array of child element IDs |
| `visible` | no | [Visibility condition](#visibility) |
| `on` | no | Event name → [action binding](#actions) |
| `repeat` | no | [Repeat config](#repeat) for array iteration |

---

## Data Binding

Props can be literals or dynamic expressions:

| Expression | JSON | Description |
|------------|------|-------------|
| Literal | `"hello"`, `42`, `true` | Static value |
| `$state` | `{"$state": "/user/name"}` | Read from state (one-way) |
| `$bindState` | `{"$bindState": "/user/name"}` | Read + write (two-way binding) |
| `$template` | `{"$template": "Hello ${/user/name}!"}` | String interpolation |
| `$cond` | `{"$cond": ..., "$then": "A", "$else": "B"}` | Conditional value |
| `$item` | `{"$item": "title"}` | Current repeat item field |
| `$bindItem` | `{"$bindItem": "value"}` | Two-way bind to repeat item field |
| `$index` | `{"$index": true}` | Current repeat index |

All paths follow [RFC 6901 JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901) format: `/user/name`, `/items/0/title`.

### Examples

```json
{
    "content": { "$state": "/user/name" },
    "value": { "$bindState": "/form/email" },
    "greeting": { "$template": "Welcome, ${/user/name}! You have ${/count} items." },
    "label": {
        "$cond": { "$state": "/user/isAdmin" },
        "$then": "Admin Panel",
        "$else": "Dashboard"
    }
}
```

---

## Visibility

Control conditional rendering with the `visible` field:

```json
{ "visible": { "$state": "/form/isDirty" } }
```

### Operators

| Operator | Example |
|----------|---------|
| `eq` | `{"$state": "/role", "eq": "admin"}` |
| `neq` | `{"$state": "/tab", "neq": "home"}` |
| `gt` | `{"$state": "/total", "gt": 100}` |
| `gte` | `{"$state": "/count", "gte": 1}` |
| `lt` | `{"$state": "/total", "lt": 1000}` |
| `lte` | `{"$state": "/count", "lte": 10}` |
| `not` | `{"$state": "/hasErrors", "not": true}` |

### Combining conditions

```json
// AND (array)
"visible": [
    { "$state": "/form/isValid" },
    { "$state": "/form/hasChanges" }
]

// OR
"visible": { "$or": [
    { "$state": "/user/isVIP" },
    { "$state": "/cart/total", "gt": 200 }
]}

// State-to-state comparison
"visible": { "$state": "/balance", "gte": { "$state": "/minOrder" } }
```

---

## Repeat

Render children once per item in a state array:

```json
{
    "type": "VStack",
    "children": ["item-template"],
    "repeat": { "statePath": "/todos", "key": "id" }
}
```

Inside repeated children, use `$item` and `$index`:

```json
{
    "type": "Text",
    "props": { "content": { "$item": "title" } }
}
```

---

## Actions

Actions are named intents. The AI declares *what* should happen; your app implements *how*.

### In the spec

```json
{
    "type": "Button",
    "props": { "label": "Delete" },
    "on": {
        "press": {
            "action": "removeState",
            "params": { "path": "/items", "index": 0 }
        }
    }
}
```

### Built-in actions

| Action | Params | Description |
|--------|--------|-------------|
| `setState` | `path`, `value` | Set a value at a state path |
| `pushState` | `path`, `value` | Append to a state array |
| `removeState` | `path`, `index` | Remove item from a state array by index |
| `toggleState` | `path` | Toggle a boolean state value |

### Custom actions

```swift
let executor = ActionExecutor()

executor.register("submitForm") { params, store in
    let email = store.get("/form/email")?.stringValue ?? ""
    // POST to API, update state with result...
    store.set("/form/submitted", value: .bool(true))
}

JSONRenderer(spec: spec, actionExecutor: executor)
```

---

## State Management

### Architecture

`StateStore` is a single `@Observable` state tree. SwiftUI views re-render automatically when state changes.

```swift
let store = StateStore(initialState: .object([
    "user": .object(["name": .string("Alice")]),
    "count": .int(0)
]))

store.get("/user/name")              // .string("Alice")
store.set("/count", value: .int(5))  // triggers SwiftUI re-render
store.remove("/user/name")           // removes the key
```

### State from spec

The spec's `state` field is automatically loaded into the store on first render:

```json
{
    "state": {
        "user": { "name": "World" },
        "settings": { "darkMode": false }
    }
}
```

### Path-based backend routing

Different path prefixes can route to different storage backends:

```
/user/name           → LocalStateBackend (in-memory, default)
/persisted/theme     → PersistedStateBackend (SwiftData, survives app restart)
/remote/profile      → YourCustomBackend
```

```swift
let persisted = PersistedStateBackend(
    pathPrefix: "/persisted",
    modelContainer: modelContainer
)
let store = StateStore(backends: [persisted])
```

Unprefixed paths default to local in-memory storage. Simple specs work without any backend configuration.

### Custom state backend

Conform to `StateBackend` to add your own storage (remote API, UserDefaults, etc.):

```swift
final class RemoteStateBackend: StateBackend, @unchecked Sendable {
    let pathPrefix = "/remote"
    private(set) var stateSlice: JSONValue = .object([:])

    func set(_ pointer: JSONPointer, value: JSONValue) {
        stateSlice = pointer.set(value, in: stateSlice)
        // sync to your API...
    }

    func remove(_ pointer: JSONPointer) {
        stateSlice = pointer.remove(from: stateSlice)
    }

    func initialize(with state: JSONValue) {
        stateSlice = deepMerge(base: stateSlice, overlay: state)
    }
}

let store = StateStore(backends: [
    RemoteStateBackend(),
    PersistedStateBackend(pathPrefix: "/persisted", modelContainer: container),
])
```

---

## Built-in Components

18 components ship out of the box. All are extensible.

### Layout

| Type | Key Props | SwiftUI View |
|------|-----------|-------------|
| `VStack` | `alignment`, `spacing` | `VStack` |
| `HStack` | `alignment`, `spacing` | `HStack` |
| `ZStack` | `alignment` | `ZStack` |
| `Spacer` | `minLength` | `Spacer` |
| `Divider` | — | `Divider` |

### Content

| Type | Key Props | SwiftUI View |
|------|-----------|-------------|
| `Text` | `content`, `font`, `color`, `weight`, `alignment` | `Text` |
| `Image` | `systemName`, `url`, `resizable`, `width`, `height` | `Image` / `AsyncImage` |
| `Label` | `title`, `systemImage` | `Label` |
| `Badge` | `text`, `color` | `Text` + capsule background |
| `Card` | `title`, `subtitle`, `padding`, `style` | Liquid glass (iOS 26+) / material fallback |

### Input

| Type | Key Props | SwiftUI View |
|------|-----------|-------------|
| `Button` | `label`, `style`, `disabled` | `Button` (emits `"press"`) |
| `TextField` | `placeholder`, `value` (`$bindState`) | `TextField` |
| `Toggle` | `label`, `isOn` (`$bindState`) | `Toggle` |
| `Slider` | `value` (`$bindState`), `min`, `max`, `step` | `Slider` |

### Feedback & Navigation

| Type | Key Props | SwiftUI View |
|------|-----------|-------------|
| `ProgressView` | `value`, `total`, `label` | `ProgressView` |
| `Link` | `title`, `url` | `Link` |
| `List` | `style` | `List` |
| `Form` | `style` | `Form` with `.formStyle(.grouped)` |

### Font values

`largeTitle`, `title`, `title2`, `title3`, `headline`, `subheadline`, `body`, `callout`, `footnote`, `caption`, `caption2`

### Color values

`red`, `blue`, `green`, `orange`, `yellow`, `purple`, `pink`, `gray`, `white`, `black`, `primary`, `secondary`, `brown`, `cyan`, `indigo`, `mint`, `teal`, or hex `#FF5733`

### Button styles

`bordered`, `borderedProminent` / `prominent`, `borderless`, `plain`

---

## Custom Components

### Declarative (recommended): `@Component` macro

Define your component as a SwiftUI view, annotate with `@Component`, and mark props with `@Prop`:

```swift
import JSONRenderClient

@Component("StarRating", description: "Star rating 1-5", events: ["tap"])
struct StarRating: View, RenderableComponent {
    @Prop var value: Int = 0
    @Prop var color: String = "yellow"

    init(ctx: ComponentRenderContext) {
        self.value = ctx.resolvedProps["value"]?.intValue ?? 0
        self.color = ctx.resolvedProps["color"]?.stringValue ?? "yellow"
    }

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= value ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
    }
}
```

The `@Component` macro auto-generates `ComponentDefinition` conformance with prop metadata, event names, and description — used for schema generation.

### Register via catalog

Group your components into a catalog and pass it to the registry:

```swift
struct MyCatalog: ComponentCatalog {
    static var components: [any ComponentDefinition.Type] {
        [StarRating.self, AvatarView.self]
    }
}

// Built-ins + your custom components
let registry = ComponentRegistry(MyCatalog.self)

JSONRenderer(spec: spec, registry: registry)
```

### Closure-based (simple one-offs)

For quick prototyping, you can still register components with closures:

```swift
let registry = ComponentRegistry.withBuiltIns()

registry.register("StarRating") { ctx in
    let rating = ctx.resolvedProps["value"]?.intValue ?? 0
    return AnyView(
        HStack {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
    )
}
```

### ComponentRenderContext

| Property | Type | Description |
|----------|------|-------------|
| `resolvedProps` | `[String: JSONValue]` | All props with expressions resolved to values |
| `bindings` | `[String: String]` | Prop name → state path for two-way bindings |
| `children` | `AnyView` | Rendered child elements |
| `store` | `StateStore` | Direct access to the state store |
| `emit` | `(String, [String: JSONValue]) -> Void` | Emit an event (triggers `on` action bindings) |
| `elementId` | `String` | The element's ID in the spec |
| `element` | `UIElement` | The raw element definition |

---

## Schema Generation

### Build plugin

Apply the `JSONRenderSchemaPlugin` to your target in `Package.swift` to auto-generate `components.json` during `swift build`:

```swift
.target(
    name: "MyApp",
    dependencies: ["JSONRenderSwift"],
    plugins: [.plugin(name: "JSONRenderSchemaPlugin", package: "JSONRenderSwift")]
)
```

The plugin scans your source files for `@Component` declarations and outputs a JSON schema that your backend AI agent can use to know what components are available.

### Runtime export

You can also export the schema at runtime:

```swift
let registry = ComponentRegistry(MyCatalog.self)
let schemaJSON = registry.exportSchema()
print(schemaJSON)
```

Output:
```json
{
  "components": {
    "StarRating": {
      "description": "Star rating 1-5",
      "events": ["tap"],
      "props": {
        "value": { "type": "int", "default": "0" },
        "color": { "type": "string", "default": "\"yellow\"" }
      }
    }
  }
}
```

---

## Full Example

```swift
import SwiftUI
import JSONRenderSwift

struct ChatResponseView: View {
    let jsonFromAI: String

    var body: some View {
        let spec = try? JSONDecoder().decode(
            Spec.self,
            from: jsonFromAI.data(using: .utf8) ?? Data()
        )
        JSONRenderer(spec: spec)
    }
}
```

With a custom action handler:

```swift
struct AppView: View {
    @State private var store = StateStore()
    @State private var executor: ActionExecutor = {
        let exec = ActionExecutor()
        exec.register("addTodo") { params, store in
            guard let text = store.get("/newTodo")?.stringValue, !text.isEmpty else { return }
            let item: JSONValue = .object([
                "id": .string(UUID().uuidString),
                "text": .string(text)
            ])
            let current = store.get("/todos")
            var arr: [JSONValue] = (current?.arrayValue) ?? []
            arr.append(item)
            store.set("/todos", value: .array(arr))
            store.set("/newTodo", value: .string(""))
        }
        return exec
    }()

    var body: some View {
        JSONRenderer(spec: todoSpec, store: store, actionExecutor: executor)
    }
}
```

---

## Architecture

```
JSON Spec (from AI)
    │
    ▼
┌──────────────┐
│  JSONRenderer │  ← top-level SwiftUI View
└──────┬───────┘
       │
       ▼
┌──────────────────┐     ┌───────────────────┐
│ ElementRenderer   │────▶│ ComponentRegistry  │
│ (recursive)       │     │ (type → View)      │
└──────┬───────────┘     └───────────────────┘
       │
       ├── PropResolver        resolves $state, $bindState, $template, $cond
       ├── VisibilityEvaluator evaluates visible conditions
       ├── RepeatRenderer      iterates $item/$index over state arrays
       │
       ▼
┌──────────────┐     ┌─────────────────────┐
│  StateStore   │────▶│ StateBackend(s)      │
│  (@Observable)│     │ Local | Persisted | … │
└──────────────┘     └─────────────────────┘
       │
       ▼
   SwiftUI re-renders automatically
```

## License

MIT
