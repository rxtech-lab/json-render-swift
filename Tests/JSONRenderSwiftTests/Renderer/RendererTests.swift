import SwiftUI
import ViewInspector
import XCTest

@testable import JSONRenderSwift

@MainActor
final class RendererTests: XCTestCase {

    // MARK: - Direct component tests (bypass renderer, test components directly)

    func testJRTextRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "t1",
            element: UIElement(type: "Text", props: ["content": .string("Hello")]),
            resolvedProps: ["content": .string("Hello World")],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRText(ctx: ctx)
        let inspection = try view.inspect()
        let text = try inspection.find(ViewType.Text.self)
        XCTAssertEqual(try text.string(), "Hello World")
    }

    func testJRButtonRenders() throws {
        var emitted = false
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "b1",
            element: UIElement(type: "Button", props: ["label": .string("Tap")]),
            resolvedProps: ["label": .string("Tap Me")],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { event, _ in
                if event == "press" { emitted = true }
            }
        )
        let view = JRButton(ctx: ctx)
        let inspection = try view.inspect()
        let button = try inspection.find(ViewType.Button.self)
        try button.tap()
        XCTAssertTrue(emitted)
    }

    func testJRToggleRenders() throws {
        let store = StateStore(initialState: .object(["dark": .bool(false)]))
        let ctx = ComponentRenderContext(
            elementId: "t1",
            element: UIElement(
                type: "Toggle",
                props: ["label": .string("Dark"), "isOn": .bindStateRef(path: "/dark")]),
            resolvedProps: ["label": .string("Dark Mode"), "isOn": .bool(false)],
            bindings: ["isOn": "/dark"],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRToggle(ctx: ctx)
        let inspection = try view.inspect()
        let toggle = try inspection.find(ViewType.Toggle.self)
        XCTAssertNotNil(toggle)
    }

    func testJRTextFieldRenders() throws {
        let store = StateStore(initialState: .object(["name": .string("Alice")]))
        let ctx = ComponentRenderContext(
            elementId: "tf1",
            element: UIElement(
                type: "TextField",
                props: ["placeholder": .string("Name"), "value": .bindStateRef(path: "/name")]),
            resolvedProps: ["placeholder": .string("Name"), "value": .string("Alice")],
            bindings: ["value": "/name"],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRTextField(ctx: ctx)
        let inspection = try view.inspect()
        let textField = try inspection.find(ViewType.TextField.self)
        XCTAssertNotNil(textField)
    }

    func testJRCardRenders() throws {
        let store = StateStore()
        let children = AnyView(Text("Body"))
        let ctx = ComponentRenderContext(
            elementId: "c1",
            element: UIElement(
                type: "Card", props: ["title": .string("Card Title")], children: ["body"]),
            resolvedProps: ["title": .string("Card Title"), "subtitle": .string("Subtitle")],
            bindings: [:],
            children: children,
            store: store,
            emit: { _, _ in }
        )
        let view = JRCard(ctx: ctx)
        let inspection = try view.inspect()
        let texts = inspection.findAll(ViewType.Text.self)
        let strings = texts.compactMap { try? $0.string() }
        XCTAssertTrue(strings.contains("Card Title"))
        XCTAssertTrue(strings.contains("Subtitle"))
    }

    func testJRBadgeRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "bg1",
            element: UIElement(type: "Badge", props: ["text": .string("New")]),
            resolvedProps: ["text": .string("New"), "color": .string("green")],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRBadge(ctx: ctx)
        let inspection = try view.inspect()
        let text = try inspection.find(ViewType.Text.self)
        XCTAssertEqual(try text.string(), "New")
    }

    func testJRLabelRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "l1",
            element: UIElement(type: "Label", props: [:]),
            resolvedProps: ["title": .string("Settings"), "systemImage": .string("gear")],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRLabel(ctx: ctx)
        let inspection = try view.inspect()
        let label = try inspection.find(ViewType.Label.self)
        XCTAssertNotNil(label)
    }

    func testJRDividerRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "d1",
            element: UIElement(type: "Divider", props: [:]),
            resolvedProps: [:],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRDivider(ctx: ctx)
        let inspection = try view.inspect()
        let divider = try inspection.find(ViewType.Divider.self)
        XCTAssertNotNil(divider)
    }

    func testJRSpacerRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "s1",
            element: UIElement(type: "Spacer", props: [:]),
            resolvedProps: [:],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRSpacer(ctx: ctx)
        let inspection = try view.inspect()
        let spacer = try inspection.find(ViewType.Spacer.self)
        XCTAssertNotNil(spacer)
    }

    func testJRProgressViewRenders() throws {
        let store = StateStore()
        let ctx = ComponentRenderContext(
            elementId: "pv1",
            element: UIElement(type: "ProgressView", props: [:]),
            resolvedProps: ["value": .double(0.5), "total": .double(1.0)],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { _, _ in }
        )
        let view = JRProgressView(ctx: ctx)
        let inspection = try view.inspect()
        let pv = try inspection.find(ViewType.ProgressView.self)
        XCTAssertNotNil(pv)
    }

    func testJRVStackRenders() throws {
        let store = StateStore()
        let children = AnyView(
            VStack {
                Text("A")
                Text("B")
            })
        let ctx = ComponentRenderContext(
            elementId: "vs1",
            element: UIElement(type: "VStack", props: [:], children: ["a", "b"]),
            resolvedProps: ["spacing": .double(8)],
            bindings: [:],
            children: children,
            store: store,
            emit: { _, _ in }
        )
        let view = JRVStack(ctx: ctx)
        let inspection = try view.inspect()
        let vstack = try inspection.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testJRHStackRenders() throws {
        let store = StateStore()
        let children = AnyView(
            HStack {
                Text("A")
                Text("B")
            })
        let ctx = ComponentRenderContext(
            elementId: "hs1",
            element: UIElement(type: "HStack", props: [:], children: ["a", "b"]),
            resolvedProps: [:],
            bindings: [:],
            children: children,
            store: store,
            emit: { _, _ in }
        )
        let view = JRHStack(ctx: ctx)
        let inspection = try view.inspect()
        let hstack = try inspection.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    // MARK: - Integration: spec decode + resolve

    func testSpecDecodeAndResolve() throws {
        let json = """
            {
                "root": "card-1",
                "elements": {
                    "card-1": {"type": "Card", "props": {"title": "Demo"}, "children": ["greeting"]},
                    "greeting": {"type": "Text", "props": {"content": {"$template": "Hello, ${/user/name}!"}}, "children": []}
                },
                "state": {"user": {"name": "World"}}
            }
            """
        let spec = try JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
        let store = StateStore(initialState: spec.state ?? .object([:]))

        // Resolve the greeting element's props
        let greeting = spec.elements["greeting"]!
        let context = ResolutionContext(state: store.state)
        let resolvedProps = PropResolver.resolveAll(greeting.props, context: context)
        XCTAssertEqual(resolvedProps["content"], .string("Hello, World!"))
    }

    func testVisibilityHidesElement() {
        let state: JSONValue = .object(["show": .bool(false)])
        let context = ResolutionContext(state: state)
        let cond = VisibilityCondition.single(
            SingleCondition(
                source: .state(path: "/show"),
                operators: ConditionOperators(
                    eq: nil, neq: nil, gt: nil, gte: nil, lt: nil, lte: nil, not: nil)
            )
        )
        XCTAssertFalse(VisibilityEvaluator.evaluate(cond, context: context))
    }

    func testRegistryResolvesBuiltIns() {
        let registry = ComponentRegistry.withBuiltIns()
        XCTAssertTrue(registry.hasComponent("Text"))
        XCTAssertTrue(registry.hasComponent("Button"))
        XCTAssertTrue(registry.hasComponent("VStack"))
        XCTAssertTrue(registry.hasComponent("HStack"))
        XCTAssertTrue(registry.hasComponent("ZStack"))
        XCTAssertTrue(registry.hasComponent("TextField"))
        XCTAssertTrue(registry.hasComponent("Toggle"))
        XCTAssertTrue(registry.hasComponent("Slider"))
        XCTAssertTrue(registry.hasComponent("Image"))
        XCTAssertTrue(registry.hasComponent("Label"))
        XCTAssertTrue(registry.hasComponent("Divider"))
        XCTAssertTrue(registry.hasComponent("Spacer"))
        XCTAssertTrue(registry.hasComponent("ProgressView"))
        XCTAssertTrue(registry.hasComponent("Link"))
        XCTAssertTrue(registry.hasComponent("Card"))
        XCTAssertTrue(registry.hasComponent("List"))
        XCTAssertTrue(registry.hasComponent("Badge"))
        XCTAssertFalse(registry.hasComponent("NonExistent"))
        XCTAssertEqual(registry.registeredTypes.count, 19)
    }

    func testCustomComponentRegistration() {
        let registry = ComponentRegistry()
        registry.register("MyWidget") { ctx in
            AnyView(Text("Custom: \(ctx.resolvedProps["title"]?.stringValue ?? "")"))
        }
        XCTAssertTrue(registry.hasComponent("MyWidget"))
        XCTAssertFalse(registry.hasComponent("Text"))  // No built-ins
    }

    func testCounterButtonIncrementsStateAndUpdatesText() throws {
        let store = StateStore(initialState: .object(["count": .int(0)]))
        let executor = ActionExecutor()

        // Render the count label — initially "Count: 0"
        func makeLabel() -> JRText {
            let context = ResolutionContext(state: store.state)
            let template: [String: PropValue] = ["content": .template("Count: ${/count}")]
            let resolvedProps = PropResolver.resolveAll(template, context: context)
            let ctx = ComponentRenderContext(
                elementId: "count-label",
                element: UIElement(type: "Text", props: ["content": .template("Count: ${/count}")]),
                resolvedProps: resolvedProps,
                bindings: [:],
                children: AnyView(EmptyView()),
                store: store,
                emit: { _, _ in }
            )
            return JRText(ctx: ctx)
        }

        // Verify initial text
        let initialLabel = makeLabel()
        let initialText = try initialLabel.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try initialText.string(), "Count: 0")

        // Build and tap the increment button
        let btnCtx = ComponentRenderContext(
            elementId: "counter-btn",
            element: UIElement(type: "Button", props: ["label": .string("+1")]),
            resolvedProps: ["label": .string("+1")],
            bindings: [:],
            children: AnyView(EmptyView()),
            store: store,
            emit: { event, _ in
                if event == "press" {
                    executor.execute(
                        action: "incrementState",
                        params: ["path": .string("/count")],
                        store: store
                    )
                }
            }
        )
        let button = try JRButton(ctx: btnCtx).inspect().find(ViewType.Button.self)
        try button.tap()

        // Verify the text now reflects the incremented count
        let updatedLabel = makeLabel()
        let updatedText = try updatedLabel.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try updatedText.string(), "Count: 1")
    }
}
