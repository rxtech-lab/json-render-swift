import SwiftUI

/// Built-in Text component.
/// Props: content (string), font (string), color (string), weight (string), alignment (string)
struct JRText: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let content = ctx.resolvedProps["content"]?.stringValue ?? ""
        var text = Text(content)

        // Font
        if let fontName = ctx.resolvedProps["font"]?.stringValue {
            text = text.font(parseFont(fontName))
        }

        // Weight
        if let weightName = ctx.resolvedProps["weight"]?.stringValue {
            text = text.fontWeight(parseWeight(weightName))
        }

        // Color
        if let colorName = ctx.resolvedProps["color"]?.stringValue {
            text = text.foregroundColor(parseColor(colorName))
        }

        return text
            .multilineTextAlignment(parseTextAlignment(ctx.resolvedProps["alignment"]?.stringValue))
    }
}

// MARK: - Parsing helpers

func parseFont(_ name: String) -> Font {
    switch name.lowercased() {
    case "largetitle": return .largeTitle
    case "title": return .title
    case "title2": return .title2
    case "title3": return .title3
    case "headline": return .headline
    case "subheadline": return .subheadline
    case "body": return .body
    case "callout": return .callout
    case "footnote": return .footnote
    case "caption": return .caption
    case "caption2": return .caption2
    default: return .body
    }
}

func parseWeight(_ name: String) -> Font.Weight {
    switch name.lowercased() {
    case "ultralight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
}

func parseColor(_ name: String) -> Color {
    switch name.lowercased() {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "orange": return .orange
    case "yellow": return .yellow
    case "purple": return .purple
    case "pink": return .pink
    case "gray", "grey": return .gray
    case "white": return .white
    case "black": return .black
    case "primary": return .primary
    case "secondary": return .secondary
    case "clear": return .clear
    case "brown": return .brown
    case "cyan": return .cyan
    case "indigo": return .indigo
    case "mint": return .mint
    case "teal": return .teal
    default:
        // Try hex color
        if name.hasPrefix("#") {
            return Color(hex: name)
        }
        return .primary
    }
}

func parseTextAlignment(_ name: String?) -> TextAlignment {
    switch name?.lowercased() {
    case "center": return .center
    case "trailing", "right": return .trailing
    case "leading", "left": return .leading
    default: return .leading
    }
}

func parseHorizontalAlignment(_ name: String?) -> HorizontalAlignment {
    switch name?.lowercased() {
    case "center": return .center
    case "trailing", "right": return .trailing
    case "leading", "left": return .leading
    default: return .center
    }
}

func parseVerticalAlignment(_ name: String?) -> VerticalAlignment {
    switch name?.lowercased() {
    case "top": return .top
    case "bottom": return .bottom
    case "center": return .center
    default: return .center
    }
}

func parseAlignment(_ name: String?) -> Alignment {
    switch name?.lowercased() {
    case "topleft", "topleading": return .topLeading
    case "top": return .top
    case "topright", "toptrailing": return .topTrailing
    case "left", "leading": return .leading
    case "center": return .center
    case "right", "trailing": return .trailing
    case "bottomleft", "bottomleading": return .bottomLeading
    case "bottom": return .bottom
    case "bottomright", "bottomtrailing": return .bottomTrailing
    default: return .center
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
