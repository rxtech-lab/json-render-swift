import Foundation
import Observation

/// Centralized state store for json-render.
/// Uses JSON Pointer paths for get/set and routes to appropriate backends.
@Observable
public final class StateStore: @unchecked Sendable {
    /// The unified state tree.
    public private(set) var state: JSONValue

    private var backends: [StateBackend]
    private let defaultBackend: LocalStateBackend
    private let lock = NSLock()

    /// Create a store with optional additional backends.
    /// The default (local in-memory) backend is always included.
    public init(initialState: JSONValue = .object([:]), backends: [StateBackend] = []) {
        self.defaultBackend = LocalStateBackend(pathPrefix: "", initialState: initialState)
        self.backends = backends
        self.state = initialState
        rebuildState()
    }

    /// Get a value at a JSON Pointer path.
    public func get(_ path: String) -> JSONValue? {
        JSONPointer(path).resolve(in: state)
    }

    /// Set a value at a JSON Pointer path.
    public func set(_ path: String, value: JSONValue) {
        lock.lock()
        let pointer = JSONPointer(path)
        let backend = routeBackend(for: path)
        backend.set(pointer, value: value)
        lock.unlock()
        rebuildState()
    }

    /// Remove a value at a JSON Pointer path.
    public func remove(_ path: String) {
        lock.lock()
        let pointer = JSONPointer(path)
        let backend = routeBackend(for: path)
        backend.remove(pointer)
        lock.unlock()
        rebuildState()
    }

    /// Batch update multiple paths at once.
    public func update(_ updates: [String: JSONValue]) {
        lock.lock()
        for (path, value) in updates {
            let pointer = JSONPointer(path)
            let backend = routeBackend(for: path)
            backend.set(pointer, value: value)
        }
        lock.unlock()
        rebuildState()
    }

    /// Initialize state from a spec's state field.
    public func initializeFromSpec(_ specState: JSONValue) {
        defaultBackend.initialize(with: specState)
        rebuildState()
    }

    /// Create a SwiftUI Binding for a state path.
    public func binding(for path: String, fallback: String = "") -> (get: () -> String, set: (String) -> Void) {
        (
            get: { [weak self] in
                self?.get(path)?.stringValue ?? fallback
            },
            set: { [weak self] newValue in
                self?.set(path, value: .string(newValue))
            }
        )
    }

    // MARK: - Private

    private func routeBackend(for path: String) -> StateBackend {
        // Find the backend with the longest matching prefix
        var best: StateBackend = defaultBackend
        var bestLen = 0
        for backend in backends {
            let prefix = backend.pathPrefix
            if !prefix.isEmpty && path.hasPrefix(prefix) && prefix.count > bestLen {
                best = backend
                bestLen = prefix.count
            }
        }
        return best
    }

    private func rebuildState() {
        var merged = defaultBackend.stateSlice
        for backend in backends {
            merged = deepMerge(base: merged, overlay: backend.stateSlice)
        }
        state = merged
    }
}
