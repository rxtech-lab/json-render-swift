import XCTest
@testable import JSONRenderSwift

final class VisibilityEvaluatorTests: XCTestCase {
    private let state: JSONValue = .object([
        "form": .object([
            "isValid": .bool(true),
            "isDirty": .bool(false),
            "hasErrors": .bool(false)
        ]),
        "user": .object([
            "role": .string("admin"),
            "balance": .int(500)
        ]),
        "cart": .object([
            "total": .int(150),
            "itemCount": .int(3)
        ]),
        "order": .object([
            "minimum": .int(100)
        ])
    ])

    private var context: ResolutionContext {
        ResolutionContext(state: state)
    }

    func testNilConditionIsVisible() {
        XCTAssertTrue(VisibilityEvaluator.evaluate(nil, context: context))
    }

    func testLiteralTrue() {
        XCTAssertTrue(VisibilityEvaluator.evaluate(.literal(true), context: context))
    }

    func testLiteralFalse() {
        XCTAssertFalse(VisibilityEvaluator.evaluate(.literal(false), context: context))
    }

    func testTruthyState() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/form/isValid"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testFalsyState() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/form/isDirty"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertFalse(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testEqOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/user/role"), operators: ConditionOperators(eq: .value(.string("admin")), neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))

        let notEqual = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/user/role"), operators: ConditionOperators(eq: .value(.string("user")), neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertFalse(VisibilityEvaluator.evaluate(notEqual, context: context))
    }

    func testNeqOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/user/role"), operators: ConditionOperators(eq: nil, neq: .value(.string("user")), gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testGtOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/cart/total"), operators: ConditionOperators(eq: nil, neq: nil, gt: .value(.int(100)), gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))

        let notGt = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/cart/total"), operators: ConditionOperators(eq: nil, neq: nil, gt: .value(.int(200)), gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertFalse(VisibilityEvaluator.evaluate(notGt, context: context))
    }

    func testGteOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/cart/total"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: .value(.int(150)), lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testLtOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/cart/total"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: .value(.int(200)), lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testNotOperator() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/form/hasErrors"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: true))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testAndCondition() {
        let cond = VisibilityCondition.and([
            .single(SingleCondition(source: .state(path: "/form/isValid"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))),
            .single(SingleCondition(source: .state(path: "/cart/total"), operators: ConditionOperators(eq: nil, neq: nil, gt: .value(.int(100)), gte: nil, lt: nil, lte: nil, not: nil)))
        ])
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testOrCondition() {
        let cond = VisibilityCondition.or([
            .single(SingleCondition(source: .state(path: "/form/isDirty"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))),
            .single(SingleCondition(source: .state(path: "/form/isValid"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil)))
        ])
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testStateToStateComparison() {
        let cond = VisibilityCondition.single(
            SingleCondition(source: .state(path: "/user/balance"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: .stateRef(path: "/order/minimum"), lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testRepeatItemCondition() {
        let ctx = ResolutionContext(
            state: state,
            repeatItem: .object(["isOverdue": .bool(true), "price": .int(250)]),
            repeatIndex: 2
        )
        let cond = VisibilityCondition.single(
            SingleCondition(source: .item(field: "isOverdue"), operators: ConditionOperators(eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: ctx))
    }

    func testRepeatIndexCondition() {
        let ctx = ResolutionContext(state: state, repeatItem: .null, repeatIndex: 2)
        let cond = VisibilityCondition.single(
            SingleCondition(source: .index, operators: ConditionOperators(eq: nil, neq: nil, gt: .value(.int(0)), gte: nil, lt: nil, lte: nil, not: nil))
        )
        XCTAssertTrue(VisibilityEvaluator.evaluate(cond, context: ctx))
    }
}
