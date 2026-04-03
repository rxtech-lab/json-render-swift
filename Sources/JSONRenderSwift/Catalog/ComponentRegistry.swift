import SwiftUI
import JSONRenderClient

/// Context passed to component render functions.
@MainActor
public struct ComponentRenderContext {
    public let elementId: String
    public let element: UIElement
    public let resolvedProps: [String: JSONValue]
    public let bindings: [String: String]
    public let children: AnyView
    public let store: StateStore
    public let emit: (String, [String: JSONValue]) -> Void
}

/// Type-erased component render function.
public typealias ComponentRenderFn = @MainActor (ComponentRenderContext) -> AnyView

/// Registry that maps component type names to SwiftUI view render functions.
@MainActor
@Observable
public final class ComponentRegistry {
    private var renderers: [String: ComponentRenderFn] = [:]
    private var definitions: [String: any ComponentDefinition.Type] = [:]

    public init() {}

    /// Create a registry from one or more catalogs, with built-ins included.
    ///
    /// ```swift
    /// let registry = ComponentRegistry(MyCatalog.self)
    /// ```
    public convenience init(_ catalogs: any ComponentCatalog.Type...) {
        self.init()
        BuiltInComponents.registerAll(in: self)
        for catalog in catalogs {
            for componentType in catalog.components {
                registerDefinition(componentType)
            }
        }
    }

    /// Register a component renderer for a given type name.
    public func register(_ type: String, renderer: @escaping ComponentRenderFn) {
        renderers[type] = renderer
    }

    /// Register a `RenderableComponent` type (used by catalogs).
    public func registerDefinition(_ type: any ComponentDefinition.Type) {
        definitions[type.componentName] = type
        if let renderable = type as? any RenderableComponent.Type {
            let renderFn = renderable
            register(type.componentName) { ctx in
                renderFn.renderView(ctx: ctx)
            }
        }
    }

    /// Look up a renderer for a component type.
    public func resolve(_ type: String) -> ComponentRenderFn? {
        renderers[type]
    }

    /// Check if a component type is registered.
    public func hasComponent(_ type: String) -> Bool {
        renderers[type] != nil
    }

    /// All registered component type names.
    public var registeredTypes: [String] {
        Array(renderers.keys.sorted())
    }

    /// All registered component definitions (for schema export).
    public var registeredDefinitions: [String: any ComponentDefinition.Type] {
        definitions
    }

    /// Export a JSON schema of all registered components.
    public func exportSchema() -> String {
        var components: [String: Any] = [:]
        for (name, def) in definitions {
            var props: [String: Any] = [:]
            for prop in def.propDefinitions {
                var propInfo: [String: Any] = ["type": prop.type.rawValue]
                if let d = prop.defaultValue { propInfo["default"] = d }
                if let desc = prop.description { propInfo["description"] = desc }
                if prop.binding { propInfo["binding"] = true }
                props[prop.name] = propInfo
            }
            var comp: [String: Any] = ["props": props]
            if !def.eventNames.isEmpty { comp["events"] = def.eventNames }
            if !def.componentDescription.isEmpty { comp["description"] = def.componentDescription }
            components[name] = comp
        }
        let schema: [String: Any] = ["components": components]
        if let data = try? JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    /// Create a registry pre-loaded with all built-in components.
    public static func withBuiltIns() -> ComponentRegistry {
        let registry = ComponentRegistry()
        BuiltInComponents.registerAll(in: registry)
        return registry
    }
}

// MARK: - Environment key

private struct ComponentRegistryKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: ComponentRegistry = ComponentRegistry()
}

extension EnvironmentValues {
    public var componentRegistry: ComponentRegistry {
        get { self[ComponentRegistryKey.self] }
        set { self[ComponentRegistryKey.self] = newValue }
    }
}
