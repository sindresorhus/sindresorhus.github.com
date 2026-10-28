import Foundation
import Markdown

/**
Metadata about a section, in an HTML comment directly below its heading, like `<!-- @faq.platforms macOS iOS -->`. Other directive comments may be in between.

The values are separated by whitespace and passed to ``decode(values:)``, which checks their shape and returns the value. A directive without values is a problem, unless it is a flag (``HeadingDirectiveFlag``), as an empty directive is a leftover that reads as if it has values. String lists and flags have default parsers; other values define their own parser, such as a rank that needs one integer.

```swift
enum Platforms: HeadingDirective {
	static let name = "faq.platforms"
	static func decode(values: [String]) throws -> [Platform] {
		try values.map { try Platform(validating: $0) }
	}
}

heading[Platforms.self] // [.macOS, .iOS]
```

Add the type to ``MarkdownDocument/Options/headingDirectives``, and the renderer reports unknown directives and invalid values with their lines.
*/
public protocol HeadingDirective: Sendable {
	associatedtype Value: Sendable

	/**
	The name after the `@`, like `faq.platforms`.
	*/
	static var name: String { get }

	/**
	Checks and decodes the whitespace-separated values of a directive comment.
	*/
	static func decode(values: [String]) throws -> Value
}

/**
The value of a directive that is a flag, without values, like `<!-- @faq.general -->`. Values are a problem. Check the flag with ``Heading/contains(_:)``.

```swift
enum General: HeadingDirective {
	static let name = "faq.general"
	typealias Value = HeadingDirectiveFlag
}
```
*/
public struct HeadingDirectiveFlag: Sendable {
	public init() {}
}

extension HeadingDirective {
	/**
	Whether the directive is a flag, which takes no values (``HeadingDirectiveFlag``).
	*/
	static var isFlag: Bool {
		Value.self == HeadingDirectiveFlag.self
	}
}

extension HeadingDirective where Value == [String] {
	/**
	A string-list directive keeps its values as written.
	*/
	public static func decode(values: [String]) -> [String] {
		values
	}
}

extension HeadingDirective where Value == HeadingDirectiveFlag {
	/**
	A flag accepts no values.
	*/
	public static func decode(values: [String]) throws -> HeadingDirectiveFlag {
		guard values.isEmpty else {
			throw ContentError(reason: "It is a flag, so it takes no values.")
		}

		return HeadingDirectiveFlag()
	}
}

/**
A directive comment, like `<!-- @faq.keywords launch open -->`.
*/
struct DirectiveComment {
	let name: String
	let values: [String]

	/**
	Whether the comment is alone on its line, which a directive must be.
	*/
	let isOnOwnLine: Bool

	/**
	The problem of a directive that is not where it belongs.
	*/
	var misplacedMessage: String {
		"The directive `@\(name)` must be directly below a heading, on its own line, with only other directives between."
	}

	/**
	The start of a directive comment, with the name and the rest of the line. The name stops before `--`, so a flag like `<!--@faq.general-->` has no space before the end.
	*/
	nonisolated(unsafe) private static let pattern = /<!--\s*@((?:[\w.]|-(?!-))+)(.*)/

	nonisolated(unsafe) private static let commentEnd = /-->$/

	/**
	Reads the directive comment in the line. `nil` when the line has none.
	*/
	init?(line: Substring) {
		guard
			line.contains("@"),
			let match = line.firstMatch(of: Self.pattern)
		else {
			return nil
		}

		let rest = match.2.trimmingCharacters(in: .whitespaces)
		let values = rest.replacing(Self.commentEnd, with: "")
		self.name = String(match.1)

		// Another comment on the line, like `<!-- @a x --><!-- @b y -->`, is not part of the values.
		self.isOnOwnLine = line[..<match.range.lowerBound].allSatisfy(\.isWhitespace) && rest.hasSuffix("-->") && !values.contains("-->") && !values.contains("<!--")
		self.values = values.split(whereSeparator: \.isWhitespace).map(String.init)
	}
}

extension HTMLBlock {
	/**
	The directive comment of each line, or `nil` for a line without one, together with whether all nonempty lines are directives. Parse once so placement and rendering use the same interpretation.
	*/
	var parsedDirectiveComments: (comments: [DirectiveComment?], isOnlyDirectives: Bool) {
		var comments = [DirectiveComment?]()
		var isOnlyDirectives = true

		for line in rawHTML.split(separator: "\n", omittingEmptySubsequences: false) {
			let comment = DirectiveComment(line: line)
			comments.append(comment)
			isOnlyDirectives = isOnlyDirectives && (comment?.isOnOwnLine ?? line.allSatisfy(\.isWhitespace))
		}

		return (comments, isOnlyDirectives)
	}

	/**
	Whether every line that is not empty is a directive comment on its own line.
	*/
	public var isOnlyDirectives: Bool {
		parsedDirectiveComments.isOnlyDirectives
	}

	/**
	Whether the block follows a heading, with only blocks of directives in between.
	*/
	var followsHeading: Bool {
		var previous = previousSibling

		while let block = previous as? HTMLBlock {
			guard block.isOnlyDirectives else {
				return false
			}

			previous = block.previousSibling
		}

		return previous is Markdown.Heading
	}
}

extension Markup {
	fileprivate var previousSibling: any Markup? {
		guard
			let parent,
			indexInParent > 0
		else {
			return nil
		}

		return parent.child(at: indexInParent - 1)
	}
}
