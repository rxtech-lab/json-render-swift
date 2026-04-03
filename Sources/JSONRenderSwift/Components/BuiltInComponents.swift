import SwiftUI

/// Registers all built-in components into a ComponentRegistry.
@MainActor
public enum BuiltInComponents {
    public static func registerAll(in registry: ComponentRegistry) {
        registry.register("Text") { ctx in JRText(ctx: ctx).eraseToAnyView() }
        registry.register("Button") { ctx in JRButton(ctx: ctx).eraseToAnyView() }
        registry.register("VStack") { ctx in JRVStack(ctx: ctx).eraseToAnyView() }
        registry.register("HStack") { ctx in JRHStack(ctx: ctx).eraseToAnyView() }
        registry.register("ZStack") { ctx in JRZStack(ctx: ctx).eraseToAnyView() }
        registry.register("TextField") { ctx in JRTextField(ctx: ctx).eraseToAnyView() }
        registry.register("Toggle") { ctx in JRToggle(ctx: ctx).eraseToAnyView() }
        registry.register("Slider") { ctx in JRSlider(ctx: ctx).eraseToAnyView() }
        registry.register("Image") { ctx in JRImage(ctx: ctx).eraseToAnyView() }
        registry.register("Label") { ctx in JRLabel(ctx: ctx).eraseToAnyView() }
        registry.register("Divider") { ctx in JRDivider(ctx: ctx).eraseToAnyView() }
        registry.register("Spacer") { ctx in JRSpacer(ctx: ctx).eraseToAnyView() }
        registry.register("ProgressView") { ctx in JRProgressView(ctx: ctx).eraseToAnyView() }
        registry.register("Link") { ctx in JRLink(ctx: ctx).eraseToAnyView() }
        registry.register("Card") { ctx in JRCard(ctx: ctx).eraseToAnyView() }
        registry.register("List") { ctx in JRList(ctx: ctx).eraseToAnyView() }
        registry.register("Badge") { ctx in JRBadge(ctx: ctx).eraseToAnyView() }
        registry.register("Form") { ctx in JRForm(ctx: ctx).eraseToAnyView() }
        registry.register("Section") { ctx in JRSection(ctx: ctx).eraseToAnyView() }
    }
}
