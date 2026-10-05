import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(SiteKitMacros)
import SiteKitMacros

@Suite
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
#endif
