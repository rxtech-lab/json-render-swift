import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(JSONRenderMacros)
import JSONRenderMacros

let testMacros: [String: Macro.Type] = [
    "Component": ComponentMacro.self,
]
#endif

final class ComponentMacroTests: XCTestCase {

    func testBasicComponentGeneratesName() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            #"""
            @Component("StarRating")
            struct StarRating: View {
                @Prop var value: Int = 0

                var body: some View {
                    Text("stars")
                }
            }
            """#,
            expandedSource: #"""
            struct StarRating: View {
                @Prop var value: Int = 0

                var body: some View {
                    Text("stars")
                }

                static var componentName: String {
                    "StarRating"
                }

                static var propDefinitions: [PropDefinition] {
                    [PropDefinition(name: "value", type: .int, defaultValue: "0", description: nil, binding: false)]
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension StarRating: ComponentDefinition {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testComponentNoProps() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("Separator")
            struct Separator: View {
                var body: some View {
                    Divider()
                }
            }
            """,
            expandedSource: """
            struct Separator: View {
                var body: some View {
                    Divider()
                }

                static var componentName: String {
                    "Separator"
                }

                static var propDefinitions: [PropDefinition] {
                    []
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension Separator: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testComponentDescription() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("Avatar", description: "User avatar")
            struct Avatar: View {
                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct Avatar: View {
                var body: some View {
                    EmptyView()
                }

                static var componentName: String {
                    "Avatar"
                }

                static var propDefinitions: [PropDefinition] {
                    []
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    "User avatar"
                }
            }

            extension Avatar: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testComponentEvents() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("MyButton", events: ["press", "longPress"])
            struct MyButton: View {
                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct MyButton: View {
                var body: some View {
                    EmptyView()
                }

                static var componentName: String {
                    "MyButton"
                }

                static var propDefinitions: [PropDefinition] {
                    []
                }

                static var eventNames: [String] {
                    ["press", "longPress"]
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension MyButton: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSinglePropType() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("Counter")
            struct Counter: View {
                @Prop var count: Int = 0

                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct Counter: View {
                @Prop var count: Int = 0

                var body: some View {
                    EmptyView()
                }

                static var componentName: String {
                    "Counter"
                }

                static var propDefinitions: [PropDefinition] {
                    [PropDefinition(name: "count", type: .int, defaultValue: "0", description: nil, binding: false)]
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension Counter: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBoolProp() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("Toggle")
            struct MyToggle: View {
                @Prop var enabled: Bool = true

                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct MyToggle: View {
                @Prop var enabled: Bool = true

                var body: some View {
                    EmptyView()
                }

                static var componentName: String {
                    "Toggle"
                }

                static var propDefinitions: [PropDefinition] {
                    [PropDefinition(name: "enabled", type: .bool, defaultValue: "true", description: nil, binding: false)]
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension MyToggle: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDoubleProp() throws {
        #if canImport(JSONRenderMacros)
        assertMacroExpansion(
            """
            @Component("Slider")
            struct MySlider: View {
                @Prop var value: Double = 0.5

                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct MySlider: View {
                @Prop var value: Double = 0.5

                var body: some View {
                    EmptyView()
                }

                static var componentName: String {
                    "Slider"
                }

                static var propDefinitions: [PropDefinition] {
                    [PropDefinition(name: "value", type: .double, defaultValue: "0.5", description: nil, binding: false)]
                }

                static var eventNames: [String] {
                    []
                }

                static var componentDescription: String {
                    ""
                }
            }

            extension MySlider: ComponentDefinition {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
