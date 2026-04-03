import SwiftUI

/// Built-in Button component.
/// Props: label (string), style (string), disabled (bool)
/// Events: "press"
struct JRButton: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let label = ctx.resolvedProps["label"]?.stringValue ?? "Button"
        let disabled = ctx.resolvedProps["disabled"]?.boolValue ?? false
        let style = ctx.resolvedProps["style"]?.stringValue?.lowercased()

        Group {
            switch style {
            case "bordered":
                makeButton(label: label).buttonStyle(.bordered)
            case "borderedprominent", "prominent":
                makeButton(label: label).buttonStyle(.borderedProminent)
            case "borderless":
                makeButton(label: label).buttonStyle(.borderless)
            case "plain":
                makeButton(label: label).buttonStyle(.plain)
            default:
                makeButton(label: label).buttonStyle(.automatic)
            }
        }
        .disabled(disabled)
    }

    private func makeButton(label: String) -> some View {
        Button(action: {
            ctx.emit("press", [:])
        }) {
            if hasChildren {
                ctx.children
            } else {
                Text(label)
            }
        }
    }

    private var hasChildren: Bool {
        ctx.element.children != nil && !(ctx.element.children?.isEmpty ?? true)
    }
}
