import SwiftUI

/// Built-in HStack component.
/// Props: alignment (string), spacing (number)
struct JRHStack: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let alignment = parseVerticalAlignment(ctx.resolvedProps["alignment"]?.stringValue)
        let spacing = ctx.resolvedProps["spacing"]?.doubleValue.map { CGFloat($0) }

        HStack(alignment: alignment, spacing: spacing) {
            ctx.children
        }
    }
}
