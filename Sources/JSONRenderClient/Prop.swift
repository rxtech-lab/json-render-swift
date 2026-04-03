import Foundation

/// Property wrapper that marks a property as a component prop.
/// The `@Component` macro reads `@Prop` annotations to generate prop metadata.
@propertyWrapper
public struct Prop<Value>: Sendable where Value: Sendable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
