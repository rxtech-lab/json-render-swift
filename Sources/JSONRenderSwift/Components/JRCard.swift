import SwiftUI

/// Built-in Card component — a styled container with optional title and subtitle.
/// Uses liquid glass effect on iOS 26+, falls back to material background on older versions.
/// Props: title (string), subtitle (string), padding (string|number), style (string: "regular"|"clear")
struct JRCard: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let padding = resolvePadding()

        cardContent
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .applyCardStyle(glassStyle: ctx.resolvedProps["style"]?.stringValue)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = ctx.resolvedProps["title"]?.stringValue {
                Text(title)
                    .font(.headline)
            }
            if let subtitle = ctx.resolvedProps["subtitle"]?.stringValue {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ctx.children
        }
    }

    private func resolvePadding() -> CGFloat {
        if let num = ctx.resolvedProps["padding"]?.doubleValue {
            return CGFloat(num)
        }
        switch ctx.resolvedProps["padding"]?.stringValue?.lowercased() {
        case "sm": return 8
        case "md": return 16
        case "lg": return 24
        case "xl": return 32
        default: return 16
        }
    }
}

// MARK: - Glass effect with fallback

private extension View {
    @ViewBuilder
    func applyCardStyle(glassStyle: String?) -> some View {
        if #available(iOS 26, macOS 26, *) {
            switch glassStyle?.lowercased() {
            case "clear":
                self.glassEffect(.clear, in: .rect(cornerRadius: 16))
            default:
                self.glassEffect(.regular, in: .rect(cornerRadius: 16))
            }
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
