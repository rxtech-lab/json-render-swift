import XCTest
@testable import JSONRenderSwift

final class AnyCodableTests: XCTestCase {
    func testDecodeNull() throws {
        let data = "null".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .null)
        XCTAssertTrue(value.isNull)
    }

    func testDecodeBool() throws {
        let data = "true".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .bool(true))
        XCTAssertEqual(value.boolValue, true)
    }

    func testDecodeInt() throws {
        let data = "42".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .int(42))
        XCTAssertEqual(value.intValue, 42)
    }

    func testDecodeDouble() throws {
        let data = "3.14".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .double(3.14))
    }

    func testDecodeString() throws {
        let data = "\"hello\"".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .string("hello"))
    }

    func testDecodeArray() throws {
        let data = "[1, \"two\", true]".data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(value, .array([.int(1), .string("two"), .bool(true)]))
    }

    func testDecodeObject() throws {
        let json = """
        {"name": "Alice", "age": 30}
        """
        let value = try JSONDecoder().decode(JSONValue.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(value.objectValue?["name"], .string("Alice"))
        XCTAssertEqual(value.objectValue?["age"], .int(30))
    }

    func testRoundTrip() throws {
        let original: JSONValue = .object([
            "name": .string("test"),
            "values": .array([.int(1), .null, .bool(false)]),
            "nested": .object(["x": .double(1.5)])
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testTruthiness() {
        XCTAssertFalse(JSONValue.null.isTruthy)
        XCTAssertFalse(JSONValue.bool(false).isTruthy)
        XCTAssertTrue(JSONValue.bool(true).isTruthy)
        XCTAssertFalse(JSONValue.int(0).isTruthy)
        XCTAssertTrue(JSONValue.int(1).isTruthy)
        XCTAssertFalse(JSONValue.string("").isTruthy)
        XCTAssertTrue(JSONValue.string("a").isTruthy)
        XCTAssertFalse(JSONValue.array([]).isTruthy)
        XCTAssertTrue(JSONValue.array([.null]).isTruthy)
    }

    func testDisplayString() {
        XCTAssertEqual(JSONValue.null.displayString, "")
        XCTAssertEqual(JSONValue.bool(true).displayString, "true")
        XCTAssertEqual(JSONValue.int(42).displayString, "42")
        XCTAssertEqual(JSONValue.string("hi").displayString, "hi")
    }

    func testLiterals() {
        let null: JSONValue = nil
        XCTAssertEqual(null, .null)

        let bool: JSONValue = true
        XCTAssertEqual(bool, .bool(true))

        let int: JSONValue = 42
        XCTAssertEqual(int, .int(42))

        let str: JSONValue = "hello"
        XCTAssertEqual(str, .string("hello"))
    }
}
