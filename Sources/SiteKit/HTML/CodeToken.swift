import SwiftIDEUtils
import SwiftParser
import SwiftSyntax

/**
A kind of token that highlighted code colors, like a keyword. See ``Swift/String/swiftCodeParts``.
*/
public enum CodeToken: String, CaseIterable, Sendable {
	case keyword
	case type
	case attribute
	case string
	case number
	case comment

	/**
	The name of a declaration that is not a type, like a property, a function, or an enum case.
	*/
	case declaration

	/**
	A function or a member that the code uses, like `padding` in `.padding(.rootEm(1))`, `tablet` in `.from(.tablet)`, `path` in `app.path`, or `title` in `\.title`.
	*/
	case member

	/**
	The kind of a token that the parser of Swift classified, or `nil` for a token that is not colored, like an identifier or an operator.
	*/
	init?(_ classification: SyntaxClassification) {
		switch classification {
		case .keyword, .ifConfigDirective:
			self = .keyword
		case .type:
			self = .type
		case .attribute:
			self = .attribute
		case .stringLiteral, .regexLiteral:
			self = .string
		case .integerLiteral, .floatLiteral:
			self = .number
		case .lineComment, .blockComment, .docLineComment, .docBlockComment:
			self = .comment
		case .argumentLabel, .dollarIdentifier, .editorPlaceholder, .identifier, .none, .operator:
			return nil
		}
	}

	/**
	The kind of a name, from where it is in the code, as the parser does not know what a name refers to. Like editors without the compiler, a name that starts with an uppercase letter is a type, as Swift names types like that.
	*/
	init?(identifier token: TokenSyntax) {
		guard let parent = token.parent else {
			return nil
		}

		// Like `set` in `private(set)`.
		if parent.is(DeclModifierDetailSyntax.self) {
			self = .keyword
			return
		}

		if
			let declaration = parent.asProtocol((any NamedDeclSyntax).self),
			declaration.name.id == token.id
		{
			self = [.actorDecl, .associatedTypeDecl, .classDecl, .enumDecl, .protocolDecl, .structDecl, .typeAliasDecl].contains(parent.kind) ? .type : .declaration
			return
		}

		if
			parent.as(IdentifierPatternSyntax.self)?.identifier.id == token.id
				|| parent.as(EnumCaseElementSyntax.self)?.name.id == token.id
		{
			self = .declaration
			return
		}

		// A freestanding macro, like `#URL`, has the color of an attached macro, like `@Frontmatter`.
		if
			parent.as(MacroExpansionExprSyntax.self)?.macroName.id == token.id
				|| parent.as(MacroExpansionDeclSyntax.self)?.macroName.id == token.id
		{
			self = .attribute
			return
		}

		if token.text.first?.isUppercase == true {
			self = .type
			return
		}

		guard
			let reference = parent.as(DeclReferenceExprSyntax.self),
			let grandparent = reference.parent,
			grandparent.as(MemberAccessExprSyntax.self)?.declName.id == reference.id
				|| grandparent.as(FunctionCallExprSyntax.self)?.calledExpression.id == reference.id
				|| grandparent.is(KeyPathPropertyComponentSyntax.self)
		else {
			return nil
		}

		self = .member
	}
}

extension String {
	/**
	The parts of Swift code for syntax highlighting, in order, with the kind of each part that is colored. Together, the parts are the whole code, also the whitespace.

	The parser of Swift classifies the tokens, so the colors are right also for new syntax, and a name gets its kind from where it is, like a member after a period (``CodeToken/init(identifier:)``). It accepts code with errors, like a part of a declaration, as a code block often shows only a few lines.

	```swift
	for part in code.swiftCodeParts {
		if let token = part.token {
			span {
				part.text
			}
			.style(Styles(token))
		} else {
			part.text
		}
	}
	```
	*/
	public var swiftCodeParts: [(text: String, token: CodeToken?)] {
		let bytes = Array(utf8)
		let tree = Parser.parse(source: self)

		var parts = [(text: String, token: CodeToken?)]()

		for classifiedRange in tree.classifications {
			var text = String(decoding: bytes[classifiedRange.range.lowerBound.utf8Offset..<classifiedRange.range.upperBound.utf8Offset], as: UTF8.self)

			// A string with interpolation can have an empty part.
			guard !text.isEmpty else {
				continue
			}

			// A name gets its kind from where it is, like a member after a period.
			guard classifiedRange.kind == .identifier else {
				parts.append((text, CodeToken(classifiedRange.kind)))
				continue
			}

			let token = tree.token(at: classifiedRange.range.lowerBound).flatMap(CodeToken.init(identifier:))

			// The `#` of a freestanding macro, like `#URL`, is at the end of the part before its name, so it moves to the name, to get its color.
			if
				token == .attribute,
				let previous = parts.last,
				previous.text.hasSuffix("#")
			{
				parts[parts.count - 1].text = String(previous.text.dropLast())
				text = "#" + text

				if parts[parts.count - 1].text.isEmpty {
					parts.removeLast()
				}
			}

			parts.append((text, token))
		}

		return parts
	}
}
