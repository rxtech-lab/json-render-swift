import PackagePlugin

@main
struct JSONRenderSchemaPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let outputPath = context.pluginWorkDirectoryURL
            .appending(path: "components.json")

        let inputFiles = sourceTarget.sourceFiles.map(\.url)

        return [
            .buildCommand(
                displayName: "Generate component schema for \(target.name)",
                executable: try context.tool(named: "SchemaGeneratorTool").url,
                arguments: [target.directoryURL.path(), outputPath.path()],
                inputFiles: inputFiles,
                outputFiles: [outputPath]
            ),
        ]
    }
}
