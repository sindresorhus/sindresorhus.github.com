import Foundation
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/**
Implementation of `#URL("https://example.com")`, which checks the URL when the code compiles, instead of crashing on a force unwrap when it runs.

The argument must be a string literal without interpolation, and an absolute URL with a scheme.
*/
public enum URLMacro: ExpressionMacro {
	public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
		let (literal, text) = try node.stringLiteralArgument()

		guard
			let url = URL(string: text),
			url.scheme?.isEmpty == false
		else {
			throw MacroExpansionErrorMessage("Not an absolute URL: “\(text)”.")
		}

		return "URL(string: \(literal))!"
	}
}

/**
Implementation of `#path("/apps")`, which checks a `RoutePath` when the code compiles, instead of crashing when a page first uses it.

The argument must be a string literal without interpolation, and a path as the site writes it: `/`, or `/` and components, without `/` at the end, and without empty, `.`, or `..` components. The macro module cannot use SiteKit, so this repeats the checks of `RoutePath`, and it is stricter, as a literal can be written in its final form.
*/
public enum RoutePathMacro: ExpressionMacro {
	public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
		let (literal, text) = try node.stringLiteralArgument()
		let components = text.split(separator: "/", omittingEmptySubsequences: false).dropFirst()

		guard
			text.hasPrefix("/"),
			text == "/" || !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
		else {
			throw MacroExpansionErrorMessage("Not a path like “/apps/faq”: “\(text)”. A path starts with “/”, and has no “//”, “.”, or “..”, and no “/” at the end.")
		}

		return "RoutePath(\(literal))"
	}
}

/**
Implementation of `#repository("sindresorhus/ky")`, which checks a `GitHubRepositoryName` when the code compiles, instead of crashing when it is first used.

The argument must be a string literal without interpolation, with an owner and a name and one slash between them.
*/
public enum GitHubRepositoryMacro: ExpressionMacro {
	public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
		let (_, text) = try node.stringLiteralArgument()
		let parts = text.split(separator: "/", omittingEmptySubsequences: false)

		guard
			parts.count == 2,
			!parts[0].isEmpty,
			!parts[1].isEmpty
		else {
			throw MacroExpansionErrorMessage("Not a GitHub repo like “sindresorhus/ky”: “\(text)”.")
		}

		return "GitHubRepositoryName(owner: \(literal: String(parts[0])), name: \(literal: String(parts[1])))"
	}
}

extension FreestandingMacroExpansionSyntax {
	/**
	The first argument, which must be a string literal without interpolation, and its represented value, with escape sequences resolved.
	*/
	fileprivate func stringLiteralArgument() throws -> (literal: StringLiteralExprSyntax, text: String) {
		guard
			let literal = arguments.first?.expression.as(StringLiteralExprSyntax.self),
			let text = literal.representedLiteralValue
		else {
			throw MacroExpansionErrorMessage("#\(macroName.text) needs a string literal without interpolation.")
		}

		return (literal.trimmed, text)
	}
}
