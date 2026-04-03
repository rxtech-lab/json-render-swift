import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct JSONRenderMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
    ]
}
