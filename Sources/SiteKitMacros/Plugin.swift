import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SiteKitMacrosPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		FrontmatterMacro.self,
		GitHubRepositoryMacro.self,
		KeyMacro.self,
		RoutePathMacro.self,
		URLMacro.self,
	]
}
