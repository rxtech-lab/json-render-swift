import XCTest
@testable import JSONRenderSwift

final class JSONPointerTests: XCTestCase {
    // MARK: - Parsing

    func testEmptyPath() {
        let pointer = JSONPointer("")
        XCTAssertEqual(pointer.components, [])
    }

    func testRootSlash() {
        let pointer = JSONPointer("/")
        XCTAssertEqual(pointer.components, [])
    }

    func testSimplePath() {
        let pointer = JSONPointer("/user/name")
        XCTAssertEqual(pointer.components, ["user", "name"])
    }

    func testPathWithArrayIndex() {
        let pointer = JSONPointer("/items/0/title")
        XCTAssertEqual(pointer.components, ["items", "0", "title"])
    }

    func testEscaping() {
        // RFC 6901: ~0 = ~, ~1 = /
        let pointer = JSONPointer("/a~0b/c~1d")
        XCTAssertEqual(pointer.components, ["a~b", "c/d"])
    }

    // MARK: - Resolve

    func testResolveSimple() {
        let state: JSONValue = .object([
            "user": .object([
                "name": .string("Alice")
            ])
        ])
        let result = JSONPointer("/user/name").resolve(in: state)
        XCTAssertEqual(result, .string("Alice"))
    }

    func testResolveArray() {
        let state: JSONValue = .object([
            "items": .array([
                .string("a"),
                .string("b"),
                .string("c")
            ])
        ])
        XCTAssertEqual(JSONPointer("/items/1").resolve(in: state), .string("b"))
    }

    func testResolveNested() {
        let state: JSONValue = .object([
            "a": .object([
                "b": .object([
                    "c": .int(42)
                ])
            ])
        ])
        XCTAssertEqual(JSONPointer("/a/b/c").resolve(in: state), .int(42))
    }

    func testResolveMissing() {
        let state: JSONValue = .object(["x": .int(1)])
        XCTAssertNil(JSONPointer("/y").resolve(in: state))
        XCTAssertNil(JSONPointer("/x/y").resolve(in: state))
    }

    // MARK: - Set

    func testSetSimple() {
        let state: JSONValue = .object(["x": .int(1)])
        let result = JSONPointer("/x").set(.int(2), in: state)
        XCTAssertEqual(JSONPointer("/x").resolve(in: result), .int(2))
    }

    func testSetNested() {
        let state: JSONValue = .object([:])
        let result = JSONPointer("/a/b/c").set(.string("hello"), in: state)
        XCTAssertEqual(JSONPointer("/a/b/c").resolve(in: result), .string("hello"))
    }

    func testSetPreservesOtherKeys() {
        let state: JSONValue = .object([
            "a": .int(1),
            "b": .int(2)
        ])
        let result = JSONPointer("/a").set(.int(10), in: state)
        XCTAssertEqual(JSONPointer("/a").resolve(in: result), .int(10))
        XCTAssertEqual(JSONPointer("/b").resolve(in: result), .int(2))
    }

    func testSetArray() {
        let state: JSONValue = .object([
            "items": .array([.string("a"), .string("b")])
        ])
        let result = JSONPointer("/items/1").set(.string("B"), in: state)
        XCTAssertEqual(JSONPointer("/items/1").resolve(in: result), .string("B"))
        XCTAssertEqual(JSONPointer("/items/0").resolve(in: result), .string("a"))
    }

    // MARK: - Remove

    func testRemoveKey() {
        let state: JSONValue = .object([
            "a": .int(1),
            "b": .int(2)
        ])
        let result = JSONPointer("/a").remove(from: state)
        XCTAssertNil(JSONPointer("/a").resolve(in: result))
        XCTAssertEqual(JSONPointer("/b").resolve(in: result), .int(2))
    }

    func testRemoveArrayItem() {
        let state: JSONValue = .object([
            "items": .array([.string("a"), .string("b"), .string("c")])
        ])
        let result = JSONPointer("/items/1").remove(from: state)
        if case .array(let arr) = JSONPointer("/items").resolve(in: result) {
            XCTAssertEqual(arr.count, 2)
            XCTAssertEqual(arr[0], .string("a"))
            XCTAssertEqual(arr[1], .string("c"))
        } else {
            XCTFail("Expected array")
        }
    }
}
