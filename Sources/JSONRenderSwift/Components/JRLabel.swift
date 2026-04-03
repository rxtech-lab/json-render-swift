import SwiftUI

/// Built-in Label component.
/// Props: title (string), systemImage (string)
struct JRLabel: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let title = ctx.resolvedProps["title"]?.stringValue ?? ""
        let systemImage = ctx.resolvedProps["systemImage"]?.stringValue ?? "circle"

        Label(title, systemImage: systemImage)
    }
}
