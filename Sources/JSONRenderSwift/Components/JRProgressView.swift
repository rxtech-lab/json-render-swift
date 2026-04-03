import SwiftUI

/// Built-in ProgressView component.
/// Props: value (number), total (number), label (string)
struct JRProgressView: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let label = ctx.resolvedProps["label"]?.stringValue

        if let value = ctx.resolvedProps["value"]?.doubleValue {
            let total = ctx.resolvedProps["total"]?.doubleValue ?? 1.0
            ProgressView(value: value, total: total) {
                if let label {
                    Text(label)
                }
            }
        } else {
            // Indeterminate progress
            ProgressView {
                if let label {
                    Text(label)
                }
            }
        }
    }
}
