import Foundation

/// Configuration for repeating an element for each item in a state array.
public struct RepeatConfig: Sendable, Equatable, Codable {
    /// JSON Pointer path to the array in state.
    public let statePath: String
    /// Field name within each item to use as a stable key for identity.
    public let key: String?

    public init(statePath: String, key: String? = nil) {
        self.statePath = statePath
        self.key = key
    }
}
