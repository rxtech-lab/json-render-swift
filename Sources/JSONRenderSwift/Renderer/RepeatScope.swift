import SwiftUI

/// Holds repeat iteration context (current item, index, base path) passed via SwiftUI environment.
public struct RepeatScopeValue: Sendable {
    public let item: JSONValue
    public let index: Int
    public let basePath: String

    public init(item: JSONValue, index: Int, basePath: String) {
        self.item = item
        self.index = index
        self.basePath = basePath
    }
}

// MARK: - Environment key

private struct RepeatScopeKey: EnvironmentKey {
    static let defaultValue: RepeatScopeValue? = nil
}

extension EnvironmentValues {
    public var repeatScope: RepeatScopeValue? {
        get { self[RepeatScopeKey.self] }
        set { self[RepeatScopeKey.self] = newValue }
    }
}
