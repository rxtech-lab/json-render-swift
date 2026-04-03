import SwiftUI

/// Built-in Section component — groups children inside a Form or List with optional header/footer.
/// Props: header (string), footer (string)
struct JRSection: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let header = ctx.resolvedProps["header"]?.stringValue
        let footer = ctx.resolvedProps["footer"]?.stringValue

        Section {
            ctx.children
        } header: {
            if let header {
                Text(header)
            }
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
}
