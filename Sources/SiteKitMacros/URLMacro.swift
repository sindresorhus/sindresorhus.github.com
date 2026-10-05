import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/**
Implementation of `#URL("https://example.com")`, which checks the URL when the code compiles, instead of crashing on a force unwrap when it runs.

The argument must be a string literal without interpolation, and an absolute URL with a scheme.
*/
public enum URLMacro: ExpressionMacro {
	public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
		guard
			let argument = node.arguments.first?.expression,
			let literal = argument.as(StringLiteralExprSyntax.self),
			literal.segments.count == 1,
			let text = literal.segments.first?.as(StringSegmentSyntax.self)?.content.text
		else {
			throw MacroExpansionErrorMessage("#URL needs a string literal without interpolation.")
		}

		guard
			let url = URL(string: text),
			url.scheme?.isEmpty == false
		else {
			throw MacroExpansionErrorMessage("Not an absolute URL: “\(text)”.")
		}

		return "URL(string: \(literal))!"
	}
}
