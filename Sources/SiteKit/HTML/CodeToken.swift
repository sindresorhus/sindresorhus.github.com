import SOML
import SwiftIDEUtils
import SwiftParser
import SwiftSyntax

/**
A kind of token that highlighted code colors, like a keyword. See ``Swift/String/swiftCodeParts``, ``Swift/String/somlCodeParts``, ``Swift/String/javaScriptCodeParts``, and ``Swift/String/shellCodeParts``.
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
	The kind of a token that the lexer of SOML classified, or `nil` for a token that is not colored, like punctuation. A key has the color of the name of a declaration, and a date, an instant, and a duration have the color of a number.
	*/
	init?(_ kind: SOML.Token.Kind) {
		switch kind {
		case .comment:
			self = .comment
		case .key:
			self = .declaration
		case .string, .escape:
			self = .string
		case .number, .date, .instant, .duration:
			self = .number
		case .keyword:
			self = .keyword
		case .punctuation, .invalid:
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

/**
A fragment of highlighted source code. A missing token keeps the text uncolored, including whitespace between tokens.
*/
public struct CodePart: Sendable {
	public var text: String
	public let token: CodeToken?

	/**
	Creates a fragment with the source text and its optional highlighting kind.
	*/
	public init(text: String, token: CodeToken?) {
		self.text = text
		self.token = token
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
	public var swiftCodeParts: [CodePart] {
		let bytes = Array(utf8)
		let tree = Parser.parse(source: self)

		var parts = [CodePart]()

		for classifiedRange in tree.classifications {
			var text = String(decoding: bytes[classifiedRange.range.lowerBound.utf8Offset..<classifiedRange.range.upperBound.utf8Offset], as: UTF8.self)

			// A string with interpolation can have an empty part.
			guard !text.isEmpty else {
				continue
			}

			// A name gets its kind from where it is, like a member after a period.
			guard classifiedRange.kind == .identifier else {
				parts.append(CodePart(text: text, token: CodeToken(classifiedRange.kind)))
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

			parts.append(CodePart(text: text, token: token))
		}

		return parts
	}

	/**
	The parts of SOML code for syntax highlighting, in order, with the kind of each part that is colored, like ``swiftCodeParts``. Together, the parts are the whole code, also the whitespace.

	The lexer of SOML never fails, so it also highlights a part of a document.
	*/
	public var somlCodeParts: [CodePart] {
		SOML.Token.parts(in: self).map { CodePart(text: String($0.text), token: $0.kind.flatMap(CodeToken.init)) }
	}

	/**
	A comment, a string, a number, or a word of JavaScript, for ``javaScriptCodeParts``. A string is in single, double, or back quotes, with escapes.
	*/
	nonisolated(unsafe) private static let javaScriptToken = #/(?<comment>//[^\n]*|/\*[\s\S]*?\*/)|(?<string>'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*"|`(?:[^`\\]|\\[\s\S])*`)|(?<number>\d+(?:\.\d+)?)|(?<word>[A-Za-z_$][\w$]*)/#

	/**
	The words of JavaScript that ``javaScriptCodeParts`` colors as keywords.
	*/
	private static let javaScriptKeywords: Set = [
		"async",
		"await",
		"break",
		"case",
		"catch",
		"class",
		"const",
		"continue",
		"default",
		"delete",
		"do",
		"else",
		"export",
		"extends",
		"false",
		"finally",
		"for",
		"from",
		"function",
		"if",
		"import",
		"in",
		"instanceof",
		"let",
		"new",
		"null",
		"of",
		"return",
		"switch",
		"this",
		"throw",
		"true",
		"try",
		"typeof",
		"undefined",
		"var",
		"void",
		"while",
		"yield",
	]

	/**
	The parts of JavaScript code for syntax highlighting, in order, with the kind of each part that is colored, like ``swiftCodeParts``. Together, the parts are the whole code, also the whitespace.

	A small lexer colors comments, strings, numbers, and keywords, and the other code is plain. Limitations: a regex literal is plain, the interpolations of a template literal have the color of the string, and a keyword after a period, like `delete` in `map.delete(key)`, is colored as a keyword.
	*/
	public var javaScriptCodeParts: [CodePart] {
		codeParts(colored: matches(of: Self.javaScriptToken).compactMap { match -> (range: Range<Index>, token: CodeToken)? in
			let token: CodeToken? = if match.output.comment != nil {
				.comment
			} else if match.output.string != nil {
				.string
			} else if match.output.number != nil {
				.number
			} else if Self.javaScriptKeywords.contains(String(match.output.0)) {
				.keyword
			} else {
				nil
			}

			// Other words stay in the plain text around them.
			return token.map { (range: match.range, token: $0) }
		})
	}

	/**
	A comment or a string of shell code, for ``shellCodeParts``. A comment starts with `#` at the start of a line or after a space, so the `#` in a word, like a URL, is not a comment. A string is in single quotes, or in double quotes with escapes.
	*/
	nonisolated(unsafe) private static let shellToken = #/(?:^|[ \t])(?<comment>#[^\n]*)|(?<string>'[^'\n]*'|"(?:[^"\\\n]|\\.)*")/#.anchorsMatchLineEndings()

	/**
	The parts of shell code for syntax highlighting, like a command in Terminal, in order, with the kind of each part that is colored, like ``swiftCodeParts``. Together, the parts are the whole code, also the whitespace.

	A small lexer colors comments, like `# Deactivate Lungo`, and strings, like the URL in `open 'lungo:toggle'`, and the other code is plain. Limitations: a variable, like `$file`, a heredoc, and an escaped quote outside a string, like `'it'\''s'`, are plain or split.
	*/
	public var shellCodeParts: [CodePart] {
		codeParts(colored: matches(of: Self.shellToken).compactMap { match -> (range: Range<Index>, token: CodeToken)? in
			// The space before a comment is plain.
			if let comment = match.output.comment {
				return (range: comment.startIndex..<comment.endIndex, token: .comment)
			}

			return match.output.string.map { (range: $0.startIndex..<$0.endIndex, token: .string) }
		})
	}

	/**
	The parts of the code, in order: each colored range with its kind, and the text between them as plain parts.
	*/
	private func codeParts(colored: [(range: Range<Index>, token: CodeToken)]) -> [CodePart] {
		var parts = [CodePart]()
		var plainStart = startIndex

		for (range, token) in colored {
			if plainStart < range.lowerBound {
				parts.append(CodePart(text: String(self[plainStart..<range.lowerBound]), token: nil))
			}

			parts.append(CodePart(text: String(self[range]), token: token))
			plainStart = range.upperBound
		}

		if plainStart < endIndex {
			parts.append(CodePart(text: String(self[plainStart...]), token: nil))
		}

		return parts
	}
}
