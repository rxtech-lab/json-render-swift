import SwiftUI

/// Built-in Form component — wraps children in a SwiftUI Form with grouped style.
/// Props: style (string) — "grouped" (default), "automatic", "columns"
struct JRForm: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let style = ctx.resolvedProps["style"]?.stringValue?.lowercased()

        switch style {
        case "automatic":
            Form { ctx.children }.formStyle(.automatic)
        case "columns":
            Form { ctx.children }.formStyle(.columns)
        default:
            Form { ctx.children }.formStyle(.grouped)
        }
    }
}
