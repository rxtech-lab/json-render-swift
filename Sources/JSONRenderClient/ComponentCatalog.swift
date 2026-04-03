import Foundation

/// Protocol for declaring a catalog of available components.
///
/// Usage:
/// ```swift
/// struct MyCatalog: ComponentCatalog {
///     static var components: [any ComponentDefinition.Type] {
///         [StarRating.self, AvatarView.self]
///     }
/// }
/// ```
@MainActor
public protocol ComponentCatalog {
    static var components: [any ComponentDefinition.Type] { get }
}
