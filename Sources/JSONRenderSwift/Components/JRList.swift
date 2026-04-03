import SwiftUI

/// Built-in List component — renders children in a SwiftUI List.
/// Props: style (string)
struct JRList: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let style = ctx.resolvedProps["style"]?.stringValue?.lowercased()

        Group {
            switch style {
            case "plain":
                List { ctx.children }.listStyle(.plain)
            case "inset":
                List { ctx.children }.listStyle(.inset)
            case "sidebar":
                List { ctx.children }.listStyle(.sidebar)
            default:
                List { ctx.children }.listStyle(.automatic)
            }
        }
    }
}
