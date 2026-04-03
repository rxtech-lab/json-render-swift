import Foundation
import SwiftData

/// SwiftData-backed state backend for persistent state.
/// Paths routed to this backend are persisted across app launches.
public final class PersistedStateBackend: StateBackend, @unchecked Sendable {
    public let pathPrefix: String
    public private(set) var stateSlice: JSONValue

    private let modelContext: ModelContext
    private let lock = NSLock()

    public init(pathPrefix: String = "/persisted", modelContainer: ModelContainer) {
        self.pathPrefix = pathPrefix
        self.modelContext = ModelContext(modelContainer)
        self.stateSlice = .object([:])
        loadAll()
    }

    public func set(_ pointer: JSONPointer, value: JSONValue) {
        lock.lock()
        defer { lock.unlock() }

        stateSlice = pointer.set(value, in: stateSlice)
        persistEntry(key: pointer.path, value: value)
    }

    public func remove(_ pointer: JSONPointer) {
        lock.lock()
        defer { lock.unlock() }

        stateSlice = pointer.remove(from: stateSlice)
        deleteEntry(key: pointer.path)
    }

    public func initialize(with state: JSONValue) {
        lock.lock()
        defer { lock.unlock() }

        stateSlice = deepMerge(base: stateSlice, overlay: state)
        // Persist all top-level keys
        if case .object(let dict) = state {
            for (key, value) in dict {
                persistEntry(key: "/\(key)", value: value)
            }
        }
    }

    // MARK: - Private

    private func loadAll() {
        let descriptor = FetchDescriptor<PersistedStateEntry>()
        guard let entries = try? modelContext.fetch(descriptor) else { return }

        var root: JSONValue = .object([:])
        for entry in entries {
            let pointer = JSONPointer(entry.key)
            root = pointer.set(entry.value, in: root)
        }
        stateSlice = root
    }

    private func persistEntry(key: String, value: JSONValue) {
        let descriptor = FetchDescriptor<PersistedStateEntry>(
            predicate: #Predicate<PersistedStateEntry> { $0.key == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.updateValue(value)
        } else {
            let entry = PersistedStateEntry(key: key, value: value)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func deleteEntry(key: String) {
        let descriptor = FetchDescriptor<PersistedStateEntry>(
            predicate: #Predicate<PersistedStateEntry> { $0.key == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try? modelContext.save()
        }
    }
}
