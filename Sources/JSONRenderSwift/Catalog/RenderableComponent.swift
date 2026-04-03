import SwiftUI
import JSONRenderClient

/// Protocol that bridges `@Component`-annotated SwiftUI views to the renderer.
///
/// Conform to this protocol alongside `@Component` to enable automatic registration.
/// The `@Component` macro generates `ComponentDefinition` conformance;
/// you provide `init(ctx:)` to map props from the render context to your view.
///
/// The macro can also generate `init(ctx:)` by reading `@Prop` declarations.
@MainActor
public protocol RenderableComponent: ComponentDefinition, View {
    init(ctx: ComponentRenderContext)
}

extension RenderableComponent {
    /// Default render implementation: creates Self from ctx and wraps in AnyView.
    public static func renderView(ctx: ComponentRenderContext) -> AnyView {
        AnyView(Self(ctx: ctx))
    }
}
