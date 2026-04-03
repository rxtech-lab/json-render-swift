import SwiftUI

/// Built-in Badge component — a small label with a colored background capsule.
/// Props: text (string), color (string)
struct JRBadge: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let text = ctx.resolvedProps["text"]?.stringValue ?? ""
        let color = ctx.resolvedProps["color"]?.stringValue.map { parseColor($0) } ?? .blue

        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(Capsule().fill(color))
    }
}
