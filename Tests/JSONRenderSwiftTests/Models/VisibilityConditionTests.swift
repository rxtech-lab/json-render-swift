import XCTest
@testable import JSONRenderSwift

final class VisibilityConditionTests: XCTestCase {
    private func decode(_ json: String) throws -> VisibilityCondition {
        try JSONDecoder().decode(VisibilityCondition.self, from: json.data(using: .utf8)!)
    }

    func testDecodeLiteralTrue() throws {
        let cond = try decode("true")
        XCTAssertEqual(cond, .literal(true))
    }

    func testDecodeLiteralFalse() throws {
        let cond = try decode("false")
        XCTAssertEqual(cond, .literal(false))
    }

    func testDecodeSingleStateCondition() throws {
        let cond = try decode("""
        {"$state": "/form/hasErrors"}
        """)
        if case .single(let single) = cond,
           case .state(let path) = single.source {
            XCTAssertEqual(path, "/form/hasErrors")
            XCTAssertFalse(single.operators.hasOperators)
        } else {
            XCTFail("Expected single state condition")
        }
    }

    func testDecodeStateWithEq() throws {
        let cond = try decode("""
        {"$state": "/user/role", "eq": "admin"}
        """)
        if case .single(let single) = cond,
           case .state(let path) = single.source {
            XCTAssertEqual(path, "/user/role")
            XCTAssertEqual(single.operators.eq, .value(.string("admin")))
        } else {
            XCTFail("Expected single state condition with eq")
        }
    }

    func testDecodeStateWithGt() throws {
        let cond = try decode("""
        {"$state": "/cart/total", "gt": 100}
        """)
        if case .single(let single) = cond,
           case .state(let path) = single.source {
            XCTAssertEqual(path, "/cart/total")
            XCTAssertEqual(single.operators.gt, .value(.int(100)))
        } else {
            XCTFail("Expected single state condition with gt")
        }
    }

    func testDecodeOr() throws {
        let json = """
        {
            "$or": [
                {"$state": "/user/isVIP"},
                {"$state": "/cart/total", "gt": 200}
            ]
        }
        """
        let cond = try decode(json)
        if case .or(let conditions) = cond {
            XCTAssertEqual(conditions.count, 2)
        } else {
            XCTFail("Expected OR condition")
        }
    }

    func testDecodeArray() throws {
        let json = """
        [
            {"$state": "/form/isValid"},
            {"$state": "/form/hasChanges"}
        ]
        """
        let cond = try decode(json)
        if case .allOf(let conditions) = cond {
            XCTAssertEqual(conditions.count, 2)
        } else {
            XCTFail("Expected allOf condition")
        }
    }

    func testDecodeStateToStateComparison() throws {
        let json = """
        {"$state": "/user/balance", "gte": {"$state": "/order/minimum"}}
        """
        let cond = try decode(json)
        if case .single(let single) = cond {
            XCTAssertEqual(single.operators.gte, .stateRef(path: "/order/minimum"))
        } else {
            XCTFail("Expected single condition")
        }
    }

    func testDecodeNot() throws {
        let json = """
        {"$state": "/form/hasErrors", "not": true}
        """
        let cond = try decode(json)
        if case .single(let single) = cond {
            XCTAssertEqual(single.operators.not, true)
        } else {
            XCTFail("Expected single condition with not")
        }
    }
}
