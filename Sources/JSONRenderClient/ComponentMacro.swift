/// Macro that generates `ComponentDefinition` conformance for a SwiftUI view.
///
/// Usage:
/// ```swift
/// @Component("StarRating", description: "Star rating display", events: ["tap"])
/// struct StarRating: View {
///     @Prop var value: Int = 0
///     @Prop var color: String = "yellow"
///
///     var body: some View { ... }
/// }
/// ```
///
/// The macro generates:
/// - `static var componentName` from the first argument
/// - `static var propDefinitions` from `@Prop` properties
/// - `static var eventNames` from the `events` argument
/// - `static var componentDescription` from the `description` argument
/// - `ComponentDefinition` protocol conformance via extension
@attached(member, names: named(componentName), named(propDefinitions), named(eventNames), named(componentDescription))
@attached(extension, conformances: ComponentDefinition)
public macro Component(_ name: String, description: String = "", events: [String] = [])
    = #externalMacro(module: "JSONRenderMacros", type: "ComponentMacro")
