import SwiftUI

/// Recursively renders a single element from the spec.
public struct ElementRenderer: View {
    let elementId: String
    let element: UIElement
    let spec: Spec

    @Environment(\.repeatScope) private var repeatScope
    @Environment(\.componentRegistry) private var registry
    @Environment(\.actionExecutor) private var actionExecutor

    private let store: StateStore

    public init(elementId: String, element: UIElement, spec: Spec, store: StateStore) {
        self.elementId = elementId
        self.element = element
        self.spec = spec
        self.store = store
    }

    public var body: some View {
        let context = ResolutionContext(
            state: store.state,
            repeatItem: repeatScope?.item,
            repeatIndex: repeatScope?.index
        )

        // 1. Evaluate visibility
        if VisibilityEvaluator.evaluate(element.visible, context: context) {
            // 2. Resolve props
            let resolvedProps = PropResolver.resolveAll(element.props, context: context)
            let bindings = PropResolver.resolveBindings(element.props, repeatBasePath: repeatScope?.basePath)

            // 3. Look up component in registry
            if let renderFn = registry.resolve(element.type) {
                // 4. Build children view
                let childrenView = buildChildren(context: context)

                // 5. Render component
                let renderContext = ComponentRenderContext(
                    elementId: elementId,
                    element: element,
                    resolvedProps: resolvedProps,
                    bindings: bindings,
                    children: childrenView,
                    store: store,
                    emit: { [element, store, actionExecutor] eventName, params in
                        // Dispatch action bindings for this event
                        if let actionBindings = element.on?[eventName] {
                            for binding in actionBindings.bindings {
                                // Merge resolved params from the action binding with emitted params
                                let actionContext = ResolutionContext(
                                    state: store.state,
                                    repeatItem: nil,
                                    repeatIndex: nil
                                )
                                var resolvedParams = binding.params.map {
                                    PropResolver.resolveAll($0, context: actionContext)
                                } ?? [:]
                                // Overlay emitted params
                                for (k, v) in params { resolvedParams[k] = v }

                                actionExecutor.execute(
                                    action: binding.action,
                                    params: resolvedParams,
                                    store: store
                                )
                            }
                        }
                    }
                )
                renderFn(renderContext)
            } else {
                // Unknown component type — render children only with a debug overlay
                #if DEBUG
                VStack {
                    Text("Unknown: \(element.type)")
                        .font(.caption)
                        .foregroundColor(.red)
                    buildChildren(context: context)
                }
                .eraseToAnyView()
                #else
                buildChildren(context: context)
                    .eraseToAnyView()
                #endif
            }
        }
    }

    private func buildChildren(context: ResolutionContext) -> AnyView {
        if let repeatConfig = element.repeat {
            return RepeatRenderer(config: repeatConfig, element: element, spec: spec, store: store)
                .eraseToAnyView()
        } else if let children = element.children, !children.isEmpty {
            return ForEach(children, id: \.self) { childId in
                if let childElement = spec.elements[childId] {
                    ElementRenderer(elementId: childId, element: childElement, spec: spec, store: store)
                }
            }
            .eraseToAnyView()
        } else {
            return EmptyView().eraseToAnyView()
        }
    }
}

// MARK: - View erasure helper

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
