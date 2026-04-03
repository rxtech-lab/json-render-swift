import XCTest
@testable import JSONRenderSwift

final class TemplateInterpolatorTests: XCTestCase {
    private let state: JSONValue = .object([
        "user": .object(["name": .string("Alice"), "age": .int(30)]),
        "greeting": .string("Hello")
    ])

    func testSimpleInterpolation() {
        let result = TemplateInterpolator.interpolate("Hello, ${/user/name}!", state: state)
        XCTAssertEqual(result, "Hello, Alice!")
    }

    func testMultipleInterpolations() {
        let result = TemplateInterpolator.interpolate("${/greeting}, ${/user/name}!", state: state)
        XCTAssertEqual(result, "Hello, Alice!")
    }

    func testMissingPath() {
        let result = TemplateInterpolator.interpolate("Hi ${/missing}!", state: state)
        XCTAssertEqual(result, "Hi !")
    }

    func testNoInterpolation() {
        let result = TemplateInterpolator.interpolate("No vars here", state: state)
        XCTAssertEqual(result, "No vars here")
    }

    func testNumericValue() {
        let result = TemplateInterpolator.interpolate("Age: ${/user/age}", state: state)
        XCTAssertEqual(result, "Age: 30")
    }

    func testDollarSignWithoutBrace() {
        let result = TemplateInterpolator.interpolate("Price: $5", state: state)
        XCTAssertEqual(result, "Price: $5")
    }

    func testEmptyTemplate() {
        let result = TemplateInterpolator.interpolate("", state: state)
        XCTAssertEqual(result, "")
    }

    func testRepeatIndex() {
        let result = TemplateInterpolator.interpolate("Index: ${$index}", state: state, repeatIndex: 3)
        XCTAssertEqual(result, "Index: 3")
    }

    func testRepeatItem() {
        let item: JSONValue = .object(["name": .string("Bob")])
        let result = TemplateInterpolator.interpolate("Name: ${$item.name}", state: state, repeatItem: item)
        XCTAssertEqual(result, "Name: Bob")
    }
}
