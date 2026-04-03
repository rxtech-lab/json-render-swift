import Foundation
import SwiftData

/// SwiftData model for persisting state key-value pairs.
@Model
public final class PersistedStateEntry {
    @Attribute(.unique)
    public var key: String

    public var jsonData: Data

    public init(key: String, value: JSONValue) {
        self.key = key
        self.jsonData = (try? JSONEncoder().encode(value)) ?? Data()
    }

    public var value: JSONValue {
        (try? JSONDecoder().decode(JSONValue.self, from: jsonData)) ?? .null
    }

    public func updateValue(_ newValue: JSONValue) {
        self.jsonData = (try? JSONEncoder().encode(newValue)) ?? Data()
    }
}
