import XCTest
@testable import JSONRenderSwift

final class SpecDecodingTests: XCTestCase {
    func testDecodeSimpleSpec() throws {
        let json = """
        {
            "root": "card-1",
            "elements": {
                "card-1": {
                    "type": "Card",
                    "props": {"title": "Hello"},
                    "children": ["text-1"]
                },
                "text-1": {
                    "type": "Text",
                    "props": {"content": "World"},
                    "children": []
                }
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(spec.root, "card-1")
        XCTAssertEqual(spec.elements.count, 2)
        XCTAssertEqual(spec.elements["card-1"]?.type, "Card")
        XCTAssertEqual(spec.elements["card-1"]?.props["title"], .string("Hello"))
        XCTAssertEqual(spec.elements["card-1"]?.children, ["text-1"])
        XCTAssertEqual(spec.elements["text-1"]?.type, "Text")
    }

    func testDecodeSpecWithState() throws {
        let json = """
        {
            "root": "root",
            "elements": {
                "root": {
                    "type": "Text",
                    "props": {"content": {"$state": "/user/name"}}
                }
            },
            "state": {
                "user": {"name": "Alice"}
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(spec.elements["root"]?.props["content"], .stateRef(path: "/user/name"))
        if case .object(let state) = spec.state,
           case .object(let user) = state["user"] {
            XCTAssertEqual(user["name"], .string("Alice"))
        } else {
            XCTFail("Expected state object")
        }
    }

    func testDecodeSpecWithVisibility() throws {
        let json = """
        {
            "root": "btn",
            "elements": {
                "btn": {
                    "type": "Button",
                    "props": {"label": "Submit"},
                    "visible": {"$state": "/form/isDirty", "eq": true}
                }
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertNotNil(spec.elements["btn"]?.visible)
    }

    func testDecodeSpecWithRepeat() throws {
        let json = """
        {
            "root": "list",
            "elements": {
                "list": {
                    "type": "VStack",
                    "props": {},
                    "children": ["item"],
                    "repeat": {"statePath": "/items", "key": "id"}
                },
                "item": {
                    "type": "Text",
                    "props": {"content": {"$item": "title"}}
                }
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(spec.elements["list"]?.repeat?.statePath, "/items")
        XCTAssertEqual(spec.elements["list"]?.repeat?.key, "id")
        XCTAssertEqual(spec.elements["item"]?.props["content"], .itemRef(field: "title"))
    }

    func testDecodeSpecWithActions() throws {
        let json = """
        {
            "root": "btn",
            "elements": {
                "btn": {
                    "type": "Button",
                    "props": {"label": "Click"},
                    "on": {
                        "press": {
                            "action": "setState",
                            "params": {"path": "/count", "value": 1}
                        }
                    }
                }
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        let onPress = spec.elements["btn"]?.on?["press"]
        XCTAssertNotNil(onPress)
        if case .single(let binding) = onPress {
            XCTAssertEqual(binding.action, "setState")
        } else {
            XCTFail("Expected single action binding")
        }
    }

    func testDecodeSpecWithBindState() throws {
        let json = """
        {
            "root": "input",
            "elements": {
                "input": {
                    "type": "TextField",
                    "props": {
                        "placeholder": "Name",
                        "value": {"$bindState": "/user/name"}
                    }
                }
            },
            "state": {"user": {"name": "World"}}
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(spec.elements["input"]?.props["value"], .bindStateRef(path: "/user/name"))
    }

    func testDecodeSpecWithTemplate() throws {
        let json = """
        {
            "root": "greeting",
            "elements": {
                "greeting": {
                    "type": "Text",
                    "props": {"content": {"$template": "Hello, ${/user/name}!"}}
                }
            }
        }
        """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(spec.elements["greeting"]?.props["content"], .template("Hello, ${/user/name}!"))
    }

    func testRoundTrip() throws {
        let spec = Spec(
            root: "root",
            elements: [
                "root": UIElement(
                    type: "VStack",
                    props: ["spacing": .int(8)],
                    children: ["child"]
                ),
                "child": UIElement(
                    type: "Text",
                    props: ["content": .stateRef(path: "/msg")]
                )
            ],
            state: .object(["msg": .string("Hello")])
        )
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Spec.self, from: data)
        XCTAssertEqual(decoded.root, spec.root)
        XCTAssertEqual(decoded.elements.count, spec.elements.count)
    }
}
