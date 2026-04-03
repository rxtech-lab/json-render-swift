import SwiftUI

/// Built-in Toggle component with two-way binding.
/// Props: label (string), isOn ($bindState)
struct JRToggle: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let label = ctx.resolvedProps["label"]?.stringValue ?? ""
        let bindingPath = ctx.bindings["isOn"]

        if let path = bindingPath {
            let binding = Binding<Bool>(
                get: { ctx.store.get(path)?.boolValue ?? false },
                set: { ctx.store.set(path, value: .bool($0)) }
            )
            Toggle(label, isOn: binding)
        } else {
            let value = ctx.resolvedProps["isOn"]?.boolValue ?? false
            Toggle(label, isOn: .constant(value))
                .disabled(true)
        }
    }
}
