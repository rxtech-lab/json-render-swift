import SwiftUI

/// Built-in VStack component.
/// Props: alignment (string), spacing (number)
struct JRVStack: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let alignment = parseHorizontalAlignment(ctx.resolvedProps["alignment"]?.stringValue)
        let spacing = ctx.resolvedProps["spacing"]?.doubleValue.map { CGFloat($0) }

        VStack(alignment: alignment, spacing: spacing) {
            ctx.children
        }
    }
}
