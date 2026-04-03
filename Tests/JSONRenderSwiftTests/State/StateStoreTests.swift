import XCTest
@testable import JSONRenderSwift

final class StateStoreTests: XCTestCase {
    func testGetAndSet() {
        let store = StateStore(initialState: .object(["x": .int(1)]))
        XCTAssertEqual(store.get("/x"), .int(1))

        store.set("/x", value: .int(2))
        XCTAssertEqual(store.get("/x"), .int(2))
    }

    func testSetNested() {
        let store = StateStore()
        store.set("/user/name", value: .string("Alice"))
        XCTAssertEqual(store.get("/user/name"), .string("Alice"))
    }

    func testRemove() {
        let store = StateStore(initialState: .object([
            "a": .int(1),
            "b": .int(2)
        ]))
        store.remove("/a")
        XCTAssertNil(store.get("/a"))
        XCTAssertEqual(store.get("/b"), .int(2))
    }

    func testBatchUpdate() {
        let store = StateStore()
        store.update([
            "/x": .int(1),
            "/y": .int(2),
            "/z": .int(3)
        ])
        XCTAssertEqual(store.get("/x"), .int(1))
        XCTAssertEqual(store.get("/y"), .int(2))
        XCTAssertEqual(store.get("/z"), .int(3))
    }

    func testInitializeFromSpec() {
        let store = StateStore(initialState: .object(["existing": .bool(true)]))
        store.initializeFromSpec(.object([
            "user": .object(["name": .string("Bob")])
        ]))
        XCTAssertEqual(store.get("/user/name"), .string("Bob"))
        XCTAssertEqual(store.get("/existing"), .bool(true))
    }

    func testMultipleBackends() {
        let localBackend = LocalStateBackend(pathPrefix: "/local")
        let store = StateStore(backends: [localBackend])

        store.set("/local/setting", value: .string("dark"))
        store.set("/global", value: .int(1))

        XCTAssertEqual(store.get("/local/setting"), .string("dark"))
        XCTAssertEqual(store.get("/global"), .int(1))
    }

    func testArrayOperations() {
        let store = StateStore(initialState: .object([
            "items": .array([.string("a"), .string("b")])
        ]))

        // Read array
        if case .array(let arr) = store.get("/items") {
            XCTAssertEqual(arr.count, 2)
        } else {
            XCTFail("Expected array")
        }

        // Read array element
        XCTAssertEqual(store.get("/items/0"), .string("a"))
        XCTAssertEqual(store.get("/items/1"), .string("b"))
    }
}
