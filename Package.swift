// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "JSONRenderSwift",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "JSONRenderSwift",
            targets: ["JSONRenderSwift"]
        ),
        .library(
            name: "JSONRenderClient",
            targets: ["JSONRenderClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.10.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        // Macro implementation (compiler plugin)
        .macro(
            name: "JSONRenderMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // Client-side declarations (@Component, @Prop, ComponentCatalog)
        .target(
            name: "JSONRenderClient",
            dependencies: ["JSONRenderMacros"]
        ),

        // Main library
        .target(
            name: "JSONRenderSwift",
            dependencies: ["JSONRenderClient"]
        ),

        // Schema generator CLI tool (used by build plugin)
        .executableTarget(
            name: "SchemaGeneratorTool",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),

        // Build plugin
        .plugin(
            name: "JSONRenderSchemaPlugin",
            capability: .buildTool(),
            dependencies: ["SchemaGeneratorTool"]
        ),

        // Tests
        .testTarget(
            name: "JSONRenderSwiftTests",
            dependencies: [
                "JSONRenderSwift",
                .product(name: "ViewInspector", package: "ViewInspector"),
            ]
        ),
        .testTarget(
            name: "JSONRenderMacroTests",
            dependencies: [
                "JSONRenderMacros",
                "JSONRenderClient",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
