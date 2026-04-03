import SwiftUI

/// Built-in TextField component with two-way binding.
/// Props: placeholder (string), value ($bindState)
struct JRTextField: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let placeholder = ctx.resolvedProps["placeholder"]?.stringValue ?? ""
        let bindingPath = ctx.bindings["value"]

        if let path = bindingPath {
            let binding = Binding<String>(
                get: { ctx.store.get(path)?.stringValue ?? "" },
                set: { ctx.store.set(path, value: .string($0)) }
            )
            TextField(placeholder, text: binding)
        } else {
            // Read-only fallback
            let value = ctx.resolvedProps["value"]?.stringValue ?? ""
            TextField(placeholder, text: .constant(value))
                .disabled(true)
        }
    }
}
