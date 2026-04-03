import SwiftUI

/// Built-in Image component.
/// Props: systemName (string), url (string), resizable (bool), aspectRatio (string), width (number), height (number)
struct JRImage: View {
    let ctx: ComponentRenderContext

    var body: some View {
        if let systemName = ctx.resolvedProps["systemName"]?.stringValue {
            let image = Image(systemName: systemName)
            applyModifiers(to: image)
        } else if let urlString = ctx.resolvedProps["url"]?.stringValue,
                  let url = URL(string: urlString) {
            let resizable = ctx.resolvedProps["resizable"]?.boolValue ?? true
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    if resizable {
                        image.resizable()
                            .aspectRatio(contentMode: parseContentMode())
                    } else {
                        image
                    }
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.gray)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(
                width: ctx.resolvedProps["width"]?.doubleValue.map { CGFloat($0) },
                height: ctx.resolvedProps["height"]?.doubleValue.map { CGFloat($0) }
            )
        } else {
            Image(systemName: "photo")
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func applyModifiers(to image: Image) -> some View {
        let resizable = ctx.resolvedProps["resizable"]?.boolValue ?? false
        let color = ctx.resolvedProps["color"]?.stringValue

        let modified: any View = if resizable {
            image.resizable()
                .aspectRatio(contentMode: parseContentMode())
                .frame(
                    width: ctx.resolvedProps["width"]?.doubleValue.map { CGFloat($0) },
                    height: ctx.resolvedProps["height"]?.doubleValue.map { CGFloat($0) }
                )
        } else {
            image.frame(
                width: ctx.resolvedProps["width"]?.doubleValue.map { CGFloat($0) },
                height: ctx.resolvedProps["height"]?.doubleValue.map { CGFloat($0) }
            )
        }

        if let color {
            AnyView(modified).foregroundColor(parseColor(color))
        } else {
            AnyView(modified)
        }
    }

    private func parseContentMode() -> ContentMode {
        switch ctx.resolvedProps["aspectRatio"]?.stringValue?.lowercased() {
        case "fill": return .fill
        default: return .fit
        }
    }
}
