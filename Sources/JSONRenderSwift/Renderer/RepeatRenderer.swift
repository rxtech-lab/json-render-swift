import SwiftUI

/// Renders children once per item in a state array.
struct RepeatRenderer: View {
    let config: RepeatConfig
    let element: UIElement
    let spec: Spec
    let store: StateStore

    var body: some View {
        let items = resolveItems()

        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            let scope = RepeatScopeValue(
                item: item,
                index: index,
                basePath: "\(config.statePath)/\(index)"
            )

            ForEach(element.children ?? [], id: \.self) { childId in
                if let childElement = spec.elements[childId] {
                    ElementRenderer(elementId: childId, element: childElement, spec: spec, store: store)
                        .environment(\.repeatScope, scope)
                }
            }
        }
    }

    private func resolveItems() -> [JSONValue] {
        guard let value = JSONPointer(config.statePath).resolve(in: store.state),
              case .array(let arr) = value else {
            return []
        }
        return arr
    }
}
