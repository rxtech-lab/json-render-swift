import Foundation

/// In-memory state backend. State is lost when the app terminates.
public final class LocalStateBackend: StateBackend, @unchecked Sendable {
    public let pathPrefix: String
    public private(set) var stateSlice: JSONValue

    private let lock = NSLock()

    public init(pathPrefix: String = "", initialState: JSONValue = .object([:])) {
        self.pathPrefix = pathPrefix
        self.stateSlice = initialState
    }

    public func set(_ pointer: JSONPointer, value: JSONValue) {
        lock.lock()
        defer { lock.unlock() }
        stateSlice = pointer.set(value, in: stateSlice)
    }

    public func remove(_ pointer: JSONPointer) {
        lock.lock()
        defer { lock.unlock() }
        stateSlice = pointer.remove(from: stateSlice)
    }

    public func initialize(with state: JSONValue) {
        lock.lock()
        defer { lock.unlock() }
        stateSlice = deepMerge(base: stateSlice, overlay: state)
    }
}

/// Deep merge two JSONValue objects. Overlay wins for conflicts.
func deepMerge(base: JSONValue, overlay: JSONValue) -> JSONValue {
    guard case .object(let baseDict) = base,
          case .object(let overlayDict) = overlay else {
        return overlay
    }
    var result = baseDict
    for (key, value) in overlayDict {
        if let existing = result[key] {
            result[key] = deepMerge(base: existing, overlay: value)
        } else {
            result[key] = value
        }
    }
    return .object(result)
}
