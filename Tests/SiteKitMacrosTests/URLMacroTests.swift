import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(SiteKitMacros)
import SiteKitMacros

struct URLMacroTests {
	private let macros = [
		"URL": MacroSpec(type: URLMacro.self),
	]

	@Test
	func `an absolute URL becomes a URL`() {
		assertMacroExpansion(
			#"let url = #URL("https://sindresorhus.com/apps")"#,
			expandedSource: #"let url = URL(string: "https://sindresorhus.com/apps")!"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `URL validation uses the represented string and preserves its spelling`() {
		assertMacroExpansion(
			#"let url = #URL("https\u{3a}//example.com")"#,
			expandedSource: #"let url = URL(string: "https\u{3a}//example.com")!"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `a relative URL or interpolation is a compile error`() {
		assertMacroExpansion(
			#"let url = #URL("/apps")"#,
			expandedSource: #"let url = #URL("/apps")"#,
			diagnostics: [
				DiagnosticSpec(message: "Not an absolute URL: “/apps”.", line: 1, column: 11),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)

		assertMacroExpansion(
			#"let url = #URL("https://\(host)")"#,
			expandedSource: #"let url = #URL("https://\(host)")"#,
			diagnostics: [
				DiagnosticSpec(message: "#URL needs a string literal without interpolation.", line: 1, column: 11),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}
}

struct RoutePathMacroTests {
	private let macros = [
		"path": MacroSpec(type: RoutePathMacro.self),
	]

	@Test
	func `a path becomes a route path`() {
		assertMacroExpansion(
			#"let path = #path("/apps/faq")"#,
			expandedSource: #"let path = RoutePath("/apps/faq")"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)

		assertMacroExpansion(
			#"let path = #path("/")"#,
			expandedSource: #"let path = RoutePath("/")"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test(arguments: ["apps", "/apps/", "/apps//faq", "/apps/../faq", "/./apps", ""])
	func `a path that is not in its final form is a compile error`(path: String) {
		assertMacroExpansion(
			"let path = #path(\"\(path)\")",
			expandedSource: "let path = #path(\"\(path)\")",
			diagnostics: [
				DiagnosticSpec(message: "Not a path like “/apps/faq”: “\(path)”. A path starts with “/”, and has no “//”, “.”, or “..”, and no “/” at the end.", line: 1, column: 12),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `path validation uses the represented string and preserves its spelling`() {
		assertMacroExpansion(
			#"let path = #path("\u{2f}apps")"#,
			expandedSource: #"let path = RoutePath("\u{2f}apps")"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}
}

struct GitHubRepositoryMacroTests {
	private let macros = [
		"repository": MacroSpec(type: GitHubRepositoryMacro.self),
	]

	@Test
	func `an owner and a name become a repo`() {
		assertMacroExpansion(
			#"let repository = #repository("sindresorhus/ky")"#,
			expandedSource: #"let repository = GitHubRepositoryName(owner: "sindresorhus", name: "ky")"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test(arguments: ["ky", "sindresorhus/", "/ky", "sindresorhus/ky/issues"])
	func `a repo without an owner and a name is a compile error`(repository: String) {
		assertMacroExpansion(
			"let repository = #repository(\"\(repository)\")",
			expandedSource: "let repository = #repository(\"\(repository)\")",
			diagnostics: [
				DiagnosticSpec(message: "Not a GitHub repo like “sindresorhus/ky”: “\(repository)”.", line: 1, column: 18),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `repository expansion uses the represented owner and name`() {
		assertMacroExpansion(
			#"let repository = #repository("sindresorh\u{75}s\u{2f}ky")"#,
			expandedSource: #"let repository = GitHubRepositoryName(owner: "sindresorhus", name: "ky")"#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}
}
#endif
