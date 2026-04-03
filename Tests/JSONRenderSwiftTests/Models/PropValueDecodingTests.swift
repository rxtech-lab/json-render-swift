import XCTest
@testable import JSONRenderSwift

final class PropValueDecodingTests: XCTestCase {
    private func decode(_ json: String) throws -> PropValue {
        try JSONDecoder().decode(PropValue.self, from: json.data(using: .utf8)!)
    }

    // MARK: - Literals

    func testDecodeLiteralString() throws {
        let value = try decode("\"hello\"")
        XCTAssertEqual(value, .string("hello"))
    }

    func testDecodeLiteralInt() throws {
        let value = try decode("42")
        XCTAssertEqual(value, .int(42))
    }

    func testDecodeLiteralBool() throws {
        let value = try decode("true")
        XCTAssertEqual(value, .bool(true))
    }

    func testDecodeLiteralNull() throws {
        let value = try decode("null")
        XCTAssertEqual(value, .null)
    }

    func testDecodeLiteralArray() throws {
        let value = try decode("[1, \"two\"]")
        XCTAssertEqual(value, .array([.int(1), .string("two")]))
    }

    // MARK: - Expressions

    func testDecodeStateRef() throws {
        let value = try decode("""
        {"$state": "/user/name"}
        """)
        XCTAssertEqual(value, .stateRef(path: "/user/name"))
    }

    func testDecodeBindStateRef() throws {
        let value = try decode("""
        {"$bindState": "/form/email"}
        """)
        XCTAssertEqual(value, .bindStateRef(path: "/form/email"))
    }

    func testDecodeItemRef() throws {
        let value = try decode("""
        {"$item": "title"}
        """)
        XCTAssertEqual(value, .itemRef(field: "title"))
    }

    func testDecodeItemRefEmpty() throws {
        let value = try decode("""
        {"$item": ""}
        """)
        XCTAssertEqual(value, .itemRef(field: ""))
    }

    func testDecodeBindItemRef() throws {
        let value = try decode("""
        {"$bindItem": "value"}
        """)
        XCTAssertEqual(value, .bindItemRef(field: "value"))
    }

    func testDecodeIndexRef() throws {
        let value = try decode("""
        {"$index": true}
        """)
        XCTAssertEqual(value, .indexRef)
    }

    func testDecodeTemplate() throws {
        let value = try decode("""
        {"$template": "Hello ${/user/name}!"}
        """)
        XCTAssertEqual(value, .template("Hello ${/user/name}!"))
    }

    func testDecodeCond() throws {
        let json = """
        {
            "$cond": {"$state": "/user/isAdmin"},
            "$then": "Admin",
            "$else": "User"
        }
        """
        let value = try decode(json)
        if case .cond(let condition, let thenVal, let elseVal) = value {
            XCTAssertEqual(thenVal, .string("Admin"))
            XCTAssertEqual(elseVal, .string("User"))
            if case .single(let single) = condition,
               case .state(let path) = single.source {
                XCTAssertEqual(path, "/user/isAdmin")
            } else {
                XCTFail("Expected single state condition")
            }
        } else {
            XCTFail("Expected cond")
        }
    }

    // MARK: - Plain object

    func testDecodePlainObject() throws {
        let json = """
        {"title": "Hello", "count": 5}
        """
        let value = try decode(json)
        if case .object(let dict) = value {
            XCTAssertEqual(dict["title"], .string("Hello"))
            XCTAssertEqual(dict["count"], .int(5))
        } else {
            XCTFail("Expected object")
        }
    }

    // MARK: - Round trip

    func testRoundTripStateRef() throws {
        let original = PropValue.stateRef(path: "/user/name")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PropValue.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testRoundTripTemplate() throws {
        let original = PropValue.template("Hello ${/name}")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PropValue.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
