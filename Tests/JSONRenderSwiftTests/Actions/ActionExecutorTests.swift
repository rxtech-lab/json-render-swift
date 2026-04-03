import XCTest
@testable import JSONRenderSwift

@MainActor
final class ActionExecutorTests: XCTestCase {
    func testSetState() {
        let executor = ActionExecutor()
        let store = StateStore(initialState: .object(["count": .int(0)]))

        executor.execute(
            action: "setState",
            params: ["path": .string("/count"), "value": .int(42)],
            store: store
        )
        XCTAssertEqual(store.get("/count"), .int(42))
    }

    func testPushState() {
        let executor = ActionExecutor()
        let store = StateStore(initialState: .object([
            "items": .array([.string("a")])
        ]))

        executor.execute(
            action: "pushState",
            params: ["path": .string("/items"), "value": .string("b")],
            store: store
        )

        if case .array(let arr) = store.get("/items") {
            XCTAssertEqual(arr.count, 2)
            XCTAssertEqual(arr[1], .string("b"))
        } else {
            XCTFail("Expected array")
        }
    }

    func testPushStateCreatesArray() {
        let executor = ActionExecutor()
        let store = StateStore()

        executor.execute(
            action: "pushState",
            params: ["path": .string("/items"), "value": .string("first")],
            store: store
        )

        if case .array(let arr) = store.get("/items") {
            XCTAssertEqual(arr.count, 1)
            XCTAssertEqual(arr[0], .string("first"))
        } else {
            XCTFail("Expected array")
        }
    }

    func testRemoveState() {
        let executor = ActionExecutor()
        let store = StateStore(initialState: .object([
            "items": .array([.string("a"), .string("b"), .string("c")])
        ]))

        executor.execute(
            action: "removeState",
            params: ["path": .string("/items"), "index": .int(1)],
            store: store
        )

        if case .array(let arr) = store.get("/items") {
            XCTAssertEqual(arr.count, 2)
            XCTAssertEqual(arr[0], .string("a"))
            XCTAssertEqual(arr[1], .string("c"))
        } else {
            XCTFail("Expected array")
        }
    }

    func testToggleState() {
        let executor = ActionExecutor()
        let store = StateStore(initialState: .object([
            "darkMode": .bool(false)
        ]))

        executor.execute(
            action: "toggleState",
            params: ["path": .string("/darkMode")],
            store: store
        )
        XCTAssertEqual(store.get("/darkMode"), .bool(true))

        executor.execute(
            action: "toggleState",
            params: ["path": .string("/darkMode")],
            store: store
        )
        XCTAssertEqual(store.get("/darkMode"), .bool(false))
    }

    func testCustomHandler() {
        let executor = ActionExecutor()
        let store = StateStore()
        var called = false

        executor.register("myAction") { params, store in
            called = true
            store.set("/result", value: params["input"] ?? .null)
        }

        executor.execute(
            action: "myAction",
            params: ["input": .string("test")],
            store: store
        )
        XCTAssertTrue(called)
        XCTAssertEqual(store.get("/result"), .string("test"))
    }

    func testUnknownActionDoesNotCrash() {
        let executor = ActionExecutor()
        let store = StateStore()
        // Should not crash, just log in debug
        executor.execute(action: "nonExistent", params: [:], store: store)
    }
}
