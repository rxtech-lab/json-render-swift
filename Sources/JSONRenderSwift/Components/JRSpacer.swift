import SwiftUI

/// Built-in Spacer component.
/// Props: minLength (number)
struct JRSpacer: View {
    let ctx: ComponentRenderContext

    var body: some View {
        let minLength = ctx.resolvedProps["minLength"]?.doubleValue.map { CGFloat($0) }
        Spacer(minLength: minLength)
    }
}
