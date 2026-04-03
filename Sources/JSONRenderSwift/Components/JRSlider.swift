import SwiftUI

/// Built-in Slider component with two-way binding.
/// Props: value ($bindState), min (number), max (number), step (number), label (string)
struct JRSlider: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let minVal = ctx.resolvedProps["min"]?.doubleValue ?? 0
        let maxVal = ctx.resolvedProps["max"]?.doubleValue ?? 1
        let step = ctx.resolvedProps["step"]?.doubleValue
        let label = ctx.resolvedProps["label"]?.stringValue ?? ""
        let bindingPath = ctx.bindings["value"]

        if let path = bindingPath {
            let binding = Binding<Double>(
                get: { ctx.store.get(path)?.doubleValue ?? minVal },
                set: { newValue in
                    let snapped: Double
                    if let step, step > 0 {
                        snapped = (newValue / step).rounded() * step
                    } else {
                        snapped = newValue
                    }
                    ctx.store.set(path, value: .double(snapped))
                }
            )
            Slider(value: binding, in: minVal...maxVal) {
                Text(label)
            }
        } else {
            let value = ctx.resolvedProps["value"]?.doubleValue ?? minVal
            Slider(value: .constant(value), in: minVal...maxVal) {
                Text(label)
            }
            .disabled(true)
        }
    }
}
