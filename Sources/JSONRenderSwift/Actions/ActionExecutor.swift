import SwiftUI

/// Handles dispatching and executing named actions.
@MainActor
@Observable
public final class ActionExecutor {
    public typealias ActionHandler = @MainActor (
        _ params: [String: JSONValue],
        _ store: StateStore
    ) -> Void

    private var handlers: [String: ActionHandler] = [:]

    public init() {
        registerBuiltIns()
    }

    /// Register a custom action handler.
    public func register(_ action: String, handler: @escaping ActionHandler) {
        handlers[action] = handler
    }

    /// Execute an action by name with resolved parameters.
    public func execute(action: String, params: [String: JSONValue], store: StateStore) {
        guard let handler = handlers[action] else {
            #if DEBUG
            print("[JSONRenderSwift] No handler for action: \(action)")
            #endif
            return
        }
        handler(params, store)
    }

    // MARK: - Built-in actions

    private func registerBuiltIns() {
        handlers["setState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            let value = params["value"] ?? .null
            store.set(path, value: value)
        }

        handlers["pushState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            let value = params["value"] ?? .null
            let current = store.get(path)
            var arr: [JSONValue]
            if case .array(let existing) = current {
                arr = existing
            } else {
                arr = []
            }
            arr.append(value)
            store.set(path, value: .array(arr))
        }

        handlers["removeState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            guard let index = params["index"]?.intValue else { return }
            let current = store.get(path)
            guard case .array(var arr) = current, index >= 0, index < arr.count else { return }
            arr.remove(at: index)
            store.set(path, value: .array(arr))
        }

        handlers["toggleState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            let current = store.get(path)
            let currentBool = current?.boolValue ?? false
            store.set(path, value: .bool(!currentBool))
        }

        handlers["incrementState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            let amount = params["amount"]?.doubleValue ?? 1
            let current = store.get(path)?.doubleValue ?? 0
            if amount == amount.rounded() && current == current.rounded() {
                store.set(path, value: .int(Int(current + amount)))
            } else {
                store.set(path, value: .double(current + amount))
            }
        }

        handlers["decrementState"] = { params, store in
            guard let path = params["path"]?.stringValue else { return }
            let amount = params["amount"]?.doubleValue ?? 1
            let current = store.get(path)?.doubleValue ?? 0
            if amount == amount.rounded() && current == current.rounded() {
                store.set(path, value: .int(Int(current - amount)))
            } else {
                store.set(path, value: .double(current - amount))
            }
        }
    }
}

// MARK: - Environment key

private struct ActionExecutorKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: ActionExecutor = ActionExecutor()
}

extension EnvironmentValues {
    public var actionExecutor: ActionExecutor {
        get { self[ActionExecutorKey.self] }
        set { self[ActionExecutorKey.self] = newValue }
    }
}
