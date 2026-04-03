import SwiftUI

/// Built-in Link component.
/// Props: title (string), url (string)
struct JRLink: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let title = ctx.resolvedProps["title"]?.stringValue ?? "Link"
        let urlString = ctx.resolvedProps["url"]?.stringValue ?? ""

        if let url = URL(string: urlString) {
            Link(title, destination: url)
        } else {
            Text(title)
                .foregroundColor(.blue)
        }
    }
}
