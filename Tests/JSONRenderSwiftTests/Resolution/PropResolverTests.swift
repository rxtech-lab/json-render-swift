import XCTest
@testable import JSONRenderSwift

final class PropResolverTests: XCTestCase {
    private let state: JSONValue = .object([
        "user": .object(["name": .string("Alice"), "isAdmin": .bool(true)]),
        "count": .int(42),
        "items": .array([
            .object(["title": .string("Item A")]),
            .object(["title": .string("Item B")])
        ])
    ])

    private var context: ResolutionContext {
        ResolutionContext(state: state)
    }

    // MARK: - Literals

    func testResolveLiterals() {
        XCTAssertEqual(PropResolver.resolve(.null, context: context), .null)
        XCTAssertEqual(PropResolver.resolve(.bool(true), context: context), .bool(true))
        XCTAssertEqual(PropResolver.resolve(.int(42), context: context), .int(42))
        XCTAssertEqual(PropResolver.resolve(.double(3.14), context: context), .double(3.14))
        XCTAssertEqual(PropResolver.resolve(.string("hi"), context: context), .string("hi"))
    }

    func testResolveArray() {
        let result = PropResolver.resolve(.array([.int(1), .stateRef(path: "/count")]), context: context)
        XCTAssertEqual(result, .array([.int(1), .int(42)]))
    }

    func testResolveObject() {
        let result = PropResolver.resolve(.object(["name": .stateRef(path: "/user/name")]), context: context)
        XCTAssertEqual(result, .object(["name": .string("Alice")]))
    }

    // MARK: - State ref

    func testResolveStateRef() {
        XCTAssertEqual(PropResolver.resolve(.stateRef(path: "/user/name"), context: context), .string("Alice"))
        XCTAssertEqual(PropResolver.resolve(.stateRef(path: "/count"), context: context), .int(42))
    }

    func testResolveStateRefMissing() {
        XCTAssertEqual(PropResolver.resolve(.stateRef(path: "/missing"), context: context), .null)
    }

    // MARK: - Bind state ref

    func testResolveBindStateRef() {
        XCTAssertEqual(PropResolver.resolve(.bindStateRef(path: "/user/name"), context: context), .string("Alice"))
    }

    // MARK: - Item ref

    func testResolveItemRef() {
        let ctx = ResolutionContext(
            state: state,
            repeatItem: .object(["title": .string("Test Item")]),
            repeatIndex: 0
        )
        XCTAssertEqual(PropResolver.resolve(.itemRef(field: "title"), context: ctx), .string("Test Item"))
    }

    func testResolveItemRefEmpty() {
        let ctx = ResolutionContext(
            state: state,
            repeatItem: .string("whole item"),
            repeatIndex: 0
        )
        XCTAssertEqual(PropResolver.resolve(.itemRef(field: ""), context: ctx), .string("whole item"))
    }

    func testResolveItemRefNoContext() {
        XCTAssertEqual(PropResolver.resolve(.itemRef(field: "title"), context: context), .null)
    }

    // MARK: - Index ref

    func testResolveIndexRef() {
        let ctx = ResolutionContext(state: state, repeatItem: .null, repeatIndex: 3)
        XCTAssertEqual(PropResolver.resolve(.indexRef, context: ctx), .int(3))
    }

    func testResolveIndexRefNoContext() {
        XCTAssertEqual(PropResolver.resolve(.indexRef, context: context), .null)
    }

    // MARK: - Template

    func testResolveTemplate() {
        let result = PropResolver.resolve(.template("Hello, ${/user/name}!"), context: context)
        XCTAssertEqual(result, .string("Hello, Alice!"))
    }

    func testResolveTemplateMissing() {
        let result = PropResolver.resolve(.template("Hi ${/missing}!"), context: context)
        XCTAssertEqual(result, .string("Hi !"))
    }

    // MARK: - Cond

    func testResolveCondTrue() {
        let result = PropResolver.resolve(
            .cond(
                condition: .single(SingleCondition(
                    source: .state(path: "/user/isAdmin"),
                    operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil)
                )),
                then: .string("Admin Panel"),
                else: .string("Dashboard")
            ),
            context: context
        )
        XCTAssertEqual(result, .string("Admin Panel"))
    }

    func testResolveCondFalse() {
        let result = PropResolver.resolve(
            .cond(
                condition: .single(SingleCondition(
                    source: .state(path: "/user/isAdmin"),
                    operators: ConditionOperators(eq: .value(.bool(false)), neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil)
                )),
                then: .string("Admin Panel"),
                else: .string("Dashboard")
            ),
            context: context
        )
        XCTAssertEqual(result, .string("Dashboard"))
    }

    // MARK: - Resolve all

    func testResolveAll() {
        let props: [String: PropValue] = [
            "title": .string("Static"),
            "name": .stateRef(path: "/user/name"),
            "count": .int(5)
        ]
        let resolved = PropResolver.resolveAll(props, context: context)
        XCTAssertEqual(resolved["title"], .string("Static"))
        XCTAssertEqual(resolved["name"], .string("Alice"))
        XCTAssertEqual(resolved["count"], .int(5))
    }

    // MARK: - Resolve bindings

    func testResolveBindings() {
        let props: [String: PropValue] = [
            "value": .bindStateRef(path: "/form/email"),
            "label": .string("Email"),
            "isOn": .bindStateRef(path: "/settings/darkMode")
        ]
        let bindings = PropResolver.resolveBindings(props, repeatBasePath: nil)
        XCTAssertEqual(bindings["value"], "/form/email")
        XCTAssertEqual(bindings["isOn"], "/settings/darkMode")
        XCTAssertNil(bindings["label"])
    }
}
