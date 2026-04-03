import SwiftUI

/// Built-in ZStack component.
/// Props: alignment (string)
struct JRZStack: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let alignment = parseAlignment(ctx.resolvedProps["alignment"]?.stringValue)

        ZStack(alignment: alignment) {
            ctx.children
        }
    }
}
