import SwiftUI

/// Top-level view that renders a JSON spec into SwiftUI.
///
/// Usage:
/// ```swift
/// let registry = ComponentRegistry.withBuiltIns()
/// let store = StateStore()
///
/// JSONRenderer(spec: mySpec, registry: registry, store: store)
/// ```
public struct JSONRenderer: View {
    let spec: Spec?
    let registry: ComponentRegistry
    let store: StateStore
    let actionExecutor: ActionExecutor

    @State private var initialized = false

    public init(
        spec: Spec?,
        registry: ComponentRegistry? = nil,
        store: StateStore? = nil,
        actionExecutor: ActionExecutor? = nil
    ) {
        self.spec = spec
        self.registry = registry ?? .withBuiltIns()
        self.store = store ?? StateStore()
        self.actionExecutor = actionExecutor ?? ActionExecutor()
    }

    public var body: some View {
        Group {
            if let spec, let rootElement = spec.elements[spec.root] {
                ElementRenderer(
                    elementId: spec.root,
                    element: rootElement,
                    spec: spec,
                    store: store
                )
            }
        }
        .environment(\.componentRegistry, registry)
        .environment(\.actionExecutor, actionExecutor)
        .onAppear {
            if !initialized, let specState = spec?.state {
                store.initializeFromSpec(specState)
                initialized = true
            }
        }
        .onChange(of: spec) { _, newSpec in
            if let specState = newSpec?.state {
                store.initializeFromSpec(specState)
            }
        }
    }
}
