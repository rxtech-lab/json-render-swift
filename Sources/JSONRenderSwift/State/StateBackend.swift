import Foundation

/// Protocol for state storage backends.
/// Each backend manages a subtree of the overall state, identified by a path prefix.
public protocol StateBackend: AnyObject, Sendable {
    /// The path prefix this backend handles (e.g. "/persisted").
    /// Use empty string for the default backend.
    var pathPrefix: String { get }

    /// Current state subtree managed by this backend.
    var stateSlice: JSONValue { get }

    /// Set a value at the given pointer path (relative to the full state tree).
    func set(_ pointer: JSONPointer, value: JSONValue)

    /// Remove a value at the given pointer path.
    func remove(_ pointer: JSONPointer)

    /// Initialize or merge initial state into this backend.
    func initialize(with state: JSONValue)
}
