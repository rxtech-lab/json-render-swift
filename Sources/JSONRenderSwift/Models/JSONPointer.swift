import Foundation

/// RFC 6901 JSON Pointer implementation for navigating JSONValue trees.
public struct JSONPointer: Sendable, Hashable {
    public let path: String
    public let components: [String]

    public init(_ path: String) {
        self.path = path
        if path.isEmpty || path == "/" {
            self.components = []
        } else {
            // Split on "/" and unescape per RFC 6901
            let raw = path.hasPrefix("/") ? String(path.dropFirst()) : path
            self.components = raw.split(separator: "/", omittingEmptySubsequences: false)
                .map { token in
                    token
                        .replacingOccurrences(of: "~1", with: "/")
                        .replacingOccurrences(of: "~0", with: "~")
                }
        }
    }

    /// Resolve a value at this pointer path in a JSONValue tree.
    public func resolve(in value: JSONValue) -> JSONValue? {
        var current = value
        for component in components {
            switch current {
            case .object(let dict):
                guard let next = dict[component] else { return nil }
                current = next
            case .array(let arr):
                guard let index = Int(component), index >= 0, index < arr.count else { return nil }
                current = arr[index]
            default:
                return nil
            }
        }
        return current
    }

    /// Set a value at this pointer path, returning a new JSONValue tree.
    public func set(_ newValue: JSONValue, in root: JSONValue) -> JSONValue {
        if components.isEmpty {
            return newValue
        }
        return setRecursive(components: components[...], newValue: newValue, in: root)
    }

    /// Remove the value at this pointer path, returning a new JSONValue tree.
    public func remove(from root: JSONValue) -> JSONValue {
        if components.isEmpty {
            return .null
        }
        return removeRecursive(components: components[...], from: root)
    }

    // MARK: - Private helpers

    private func setRecursive(components: ArraySlice<String>, newValue: JSONValue, in current: JSONValue) -> JSONValue {
        guard let key = components.first else {
            return newValue
        }

        let rest = components.dropFirst()

        if let index = Int(key) {
            // Array access
            var arr: [JSONValue]
            if case .array(let existing) = current {
                arr = existing
            } else {
                arr = []
            }
            // Extend array if needed
            while arr.count <= index {
                arr.append(.null)
            }
            if rest.isEmpty {
                arr[index] = newValue
            } else {
                arr[index] = setRecursive(components: rest, newValue: newValue, in: arr[index])
            }
            return .array(arr)
        } else {
            // Object access
            var dict: [String: JSONValue]
            if case .object(let existing) = current {
                dict = existing
            } else {
                dict = [:]
            }
            if rest.isEmpty {
                dict[key] = newValue
            } else {
                let child = dict[key] ?? .object([:])
                dict[key] = setRecursive(components: rest, newValue: newValue, in: child)
            }
            return .object(dict)
        }
    }

    private func removeRecursive(components: ArraySlice<String>, from current: JSONValue) -> JSONValue {
        guard let key = components.first else {
            return current
        }

        let rest = components.dropFirst()

        if let index = Int(key) {
            guard case .array(var arr) = current, index >= 0, index < arr.count else {
                return current
            }
            if rest.isEmpty {
                arr.remove(at: index)
            } else {
                arr[index] = removeRecursive(components: rest, from: arr[index])
            }
            return .array(arr)
        } else {
            guard case .object(var dict) = current else { return current }
            if rest.isEmpty {
                dict.removeValue(forKey: key)
            } else if let child = dict[key] {
                dict[key] = removeRecursive(components: rest, from: child)
            }
            return .object(dict)
        }
    }
}
