import Foundation
import Markdown
import SOML

/**
Metadata about a section, in an HTML comment directly below its heading, like `<!-- @faq.platforms macOS iOS -->`. Other directive comments may be in between.

The values are separated by whitespace, and are decoded as a list of strings, strictly like frontmatter. So `[Platform]` rejects an unknown platform, and a number, like a rank, is decoded from its string. A directive without values is an empty list. `Value` must decode from a list, like an array or a set. A single value, like `Int`, never decodes.

```swift
enum Platforms: HeadingDirective {
	static let name = "faq.platforms"
	typealias Value = [Platform]
}

heading[Platforms.self] // [.macOS, .iOS]
```

Add the type to ``MarkdownDocument/Options/headingDirectives``, and the renderer reports unknown directives and invalid values with their lines.
*/
public protocol HeadingDirective: Sendable {
	associatedtype Value: Decodable & Sendable

	/**
	The name after the `@`, like `faq.platforms`.
	*/
	static var name: String { get }
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
public struct HeadingDirectiveFlag: Decodable, Sendable {
	public init(from decoder: any Decoder) throws {
		let values = try decoder.unkeyedContainer()

		guard values.isAtEnd else {
			throw DecodingError.dataCorruptedError(in: values, debugDescription: "It is a flag, so it takes no values.")
		}
	}
}

extension HeadingDirective {
	static func decode(_ values: [String]) throws -> any Sendable {
		try SOML.Decoder.frontmatter.decode(Value.self, from: .array(values.map { .string($0) }))
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
	Reads the directive comment in the line. `nil` when the line has none.
	*/
	init?(line: Substring) {
		guard
			line.contains("@"),
			// The name stops before `--`, so a flag like `<!--@faq.general-->` has no space before the end.
			let match = line.firstMatch(of: /<!--\s*@((?:[\w.]|-(?!-))+)(.*)/)
		else {
			return nil
		}

		let rest = match.2.trimmingCharacters(in: .whitespaces)
		let values = rest.replacing(/-->$/, with: "")
		self.name = String(match.1)

		// Another comment on the line, like `<!-- @a x --><!-- @b y -->`, is not part of the values.
		self.isOnOwnLine = line[..<match.range.lowerBound].allSatisfy(\.isWhitespace) && rest.hasSuffix("-->") && !values.contains("-->") && !values.contains("<!--")
		self.values = values.split(whereSeparator: \.isWhitespace).map(String.init)
	}
}

extension HTMLBlock {
	/**
	The directive comment of each line, or `nil` for a line without one.
	*/
	var directiveComments: [DirectiveComment?] {
		rawHTML.split(separator: "\n", omittingEmptySubsequences: false).map(DirectiveComment.init(line:))
	}

	/**
	Whether every line that is not empty is a directive comment on its own line.
	*/
	public var isOnlyDirectives: Bool {
		zip(rawHTML.split(separator: "\n", omittingEmptySubsequences: false), directiveComments).allSatisfy { line, comment in
			comment?.isOnOwnLine ?? line.allSatisfy(\.isWhitespace)
		}
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
	fileprivate var previousSibling: (any Markup)? {
		guard
			let parent,
			indexInParent > 0
		else {
			return nil
		}

		return parent.child(at: indexInParent - 1)
	}
}
