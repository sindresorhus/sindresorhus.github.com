import Foundation
import Markdown

/**
Rendered Markdown with the information pages need about it.

```swift
let document = MarkdownDocument(parsing: "## Install {#install}\n\nRun `brew install`.")
document.html // <h2 id="install">Install</h2>…
document.headings.first?.id // "install"
```
*/
public struct MarkdownDocument: Sendable {
	/**
	Which Markdown extensions are applied.
	*/
	public enum Style: Sendable {
		/**
		GitHub-flavored Markdown with extensions: heading IDs (`{#id}`) and directives, GitHub alerts, footnotes, bare URLs as links, keyboard shortcuts split into keys, and the options, like collapsible sections. The created HTML gets the classes of the theme in the options.
		*/
		case extended

		/**
		GitHub release notes, rendered like markdown-it with `linkify`: bare URLs and emails become links, and no other extensions apply.
		*/
		case releaseNotes
	}

	/**
	Options for the extended style.
	*/
	public struct Options: Sendable {
		/**
		Renders a block directive, like `@Details(summary: "More") { … }`, from its arguments and the HTML of its content. Throw to report a problem with the directive.
		*/
		public typealias BlockDirectiveRenderer = @Sendable (_ arguments: [String: String], _ contentHTML: String) throws -> String

		public var theme: MarkdownTheme
		public var collapsibleSections: CollapsibleSections?

		/**
		Adds a link to each `##` to `####` heading that has an ID, and to each collapsible section. Clicking it copies the URL of the section (with a script).
		*/
		public var addsHeadingAnchors: Bool

		/**
		The names of the heading directives, like `faq.keywords`. A directive with another name, or one that is not directly below a heading, is a problem. `nil` allows any directive.
		*/
		public var headingDirectives: Set<String>?

		/**
		Changes the Markdown tree before it is rendered, like adding a section.
		*/
		public var rewrite: (@Sendable (Document) -> Document)?

		/**
		Renders text with inline attributes, like `^[macOS only](platform: "macOS")`, from the attributes and the HTML of the text. Throw to report a problem. Without it, the text is rendered without the attributes.
		*/
		public var inlineAttributes: (@Sendable (_ attributes: String, _ contentHTML: String) throws -> String)?

		/**
		The block directives (DocC syntax), by name. Other directives are problems. When it is empty, block directives are not parsed.
		*/
		public var blockDirectives: [String: BlockDirectiveRenderer]

		/**
		The destination of a link or image, like `/dato` for `dato.md`. Throw to report a broken link.
		*/
		public var resolveLink: (@Sendable (String) throws -> String)?

		/**
		The size of an image by its source, for the `width` and `height` attributes, so the layout does not move while the image loads.
		*/
		public var imageSize: (@Sendable (String) -> (width: Int, height: Int)?)?

		/**
		Shows a footnote in a popover when its reference is clicked, so it can be read in place, without a script. The footnotes are still listed at the end.
		*/
		public var showsFootnotesInPopovers: Bool

		/**
		Adds a bar to each code block with its language and a copy button. A script copies the code when a button with `data-copy-code` is clicked, from the `code` element in the container with `data-code-block`.
		*/
		public var addsCopyButtons: Bool

		public init(
			theme: MarkdownTheme = .default,
			collapsibleSections: CollapsibleSections? = nil,
			addsHeadingAnchors: Bool = false,
			headingDirectives: Set<String>? = nil,
			rewrite: (@Sendable (Document) -> Document)? = nil,
			inlineAttributes: (@Sendable (_ attributes: String, _ contentHTML: String) throws -> String)? = nil,
			blockDirectives: [String: BlockDirectiveRenderer] = [:],
			resolveLink: (@Sendable (String) throws -> String)? = nil,
			imageSize: (@Sendable (String) -> (width: Int, height: Int)?)? = nil,
			showsFootnotesInPopovers: Bool = false,
			addsCopyButtons: Bool = false
		) {
			self.theme = theme
			self.collapsibleSections = collapsibleSections
			self.addsHeadingAnchors = addsHeadingAnchors
			self.headingDirectives = headingDirectives
			self.rewrite = rewrite
			self.inlineAttributes = inlineAttributes
			self.blockDirectives = blockDirectives
			self.resolveLink = resolveLink
			self.imageSize = imageSize
			self.showsFootnotesInPopovers = showsFootnotesInPopovers
			self.addsCopyButtons = addsCopyButtons
		}
	}

	/**
	A mistake in the Markdown, like an image without a description.
	*/
	public struct Problem: Hashable, Sendable, CustomStringConvertible {
		/**
		The line in the Markdown source, starting at 1.
		*/
		public let line: Int?

		public let message: String

		public var description: String {
			line.map { "Line \($0): \(message)" } ?? message
		}
	}

	/**
	A link in the Markdown, with its line, so a broken link can be reported where it is written.
	*/
	public struct Link: Hashable, Sendable {
		/**
		The destination in the HTML, after ``Options/resolveLink``.
		*/
		public let destination: String

		public let line: Int?
	}

	/**
	Headings of one level that become collapsible sections (`<details>`), with the content up to the next such heading, like the questions of a FAQ.
	*/
	public struct CollapsibleSections: Sendable {
		/**
		A link after the sections.
		*/
		public struct MoreLink: Sendable {
			public let title: String
			public let url: String

			public init(title: String, url: String) {
				self.title = title
				self.url = url
			}
		}

		/**
		The level of the headings, like 4 for `####`.
		*/
		public let level: Int

		/**
		The ID of the heading the sections follow. The sections end at the next heading with a lower level. When `nil`, every heading of the level in the document becomes a section.
		*/
		public let startHeadingID: String?

		/**
		The `name` of the sections, so only one is open at a time.
		*/
		public let name: String?

		public let moreLink: MoreLink?

		public init(level: Int, startHeadingID: String? = nil, name: String? = nil, moreLink: MoreLink? = nil) {
			self.level = level
			self.startHeadingID = startHeadingID
			self.name = name
			self.moreLink = moreLink
		}
	}

	public let html: String

	/**
	The headings in document order, including the footnotes heading when there are footnotes.

	Empty for the release notes style.
	*/
	public let headings: [Heading]

	/**
	The plain text of the first block, when it is a paragraph. HTML comments before it are skipped.
	*/
	public let introduction: String?

	/**
	The mistakes in the Markdown, in document order. Empty for the release notes style.
	*/
	public let problems: [Problem]

	/**
	The links and images, in document order.
	*/
	public let links: [Link]

	public init(parsing source: String, style: Style = .extended, options: Options = Options()) {
		// Source positions and line-based extensions assume `\n` line endings, but GitHub release notes use `\r\n`.
		let source = source.replacing("\r\n", with: "\n")
		let footnotes = style == .extended ? Footnotes(extractingFrom: source) : nil
		var document = Document(parsing: footnotes?.source ?? source, options: style == .extended && !options.blockDirectives.isEmpty ? .parseBlockDirectives : [])

		if style == .extended, let rewrite = options.rewrite {
			document = rewrite(document)
		}

		var renderer = HTMLRenderer(style: style, options: options, footnoteDefinitions: footnotes?.definitions ?? [:])
		renderer.visit(document)
		var html = renderer.html
		var headings = renderer.headings
		var problems = renderer.problems
		var links = renderer.links

		// A definition without a reference is not shown, so it is likely a typo in the reference.
		for id in (footnotes?.definitions.keys).map(Array.init)?.sorted() ?? [] where !renderer.footnotes.contains(where: { $0.id == id }) {
			problems.append(Problem(line: nil, message: "The footnote `[^\(id)]` is defined but not used."))
		}

		if !renderer.footnotes.isEmpty {
			// The definitions resolve and report their links like the text, but without the options for the whole document. Their lines are not known, as they are removed from the source.
			var definitionOptions = options
			definitionOptions.collapsibleSections = nil
			definitionOptions.addsHeadingAnchors = false
			definitionOptions.rewrite = nil
			definitionOptions.showsFootnotesInPopovers = false

			html += Footnotes.sectionHTML(for: renderer.footnotes, theme: options.theme, withPopovers: options.showsFootnotesInPopovers) { definition in
				let document = MarkdownDocument(parsing: definition, options: definitionOptions)
				problems += document.problems.map { Problem(line: nil, message: $0.message) }
				links += document.links.map { Link(destination: $0.destination, line: nil) }
				return document.html
			}

			headings.append(Heading(level: 2, text: "Footnotes", id: "footnote-label"))
		}

		if style == .extended {
			html = html.separatingKeyboardKeys(separatorClasses: options.theme.classes(for: .keySeparator))
		}

		self.html = html
		self.headings = headings
		self.problems = problems
		self.links = links
		// The introduction keeps the source punctuation, while the HTML gets smart punctuation. Footnote references are left out.
		self.introduction = Document(parsing: source, options: .disableSmartOpts).introduction.map(\.removingFootnoteReferences)
	}
}

extension MarkdownDocument {
	/**
	Renders a short text, like a frontmatter field, without the paragraph around it.
	*/
	public static func inlineHTML(_ source: String, options: Options = Options()) -> String {
		let html = MarkdownDocument(parsing: source, options: options).html.trimmingCharacters(in: .newlines)

		guard
			let match = html.wholeMatch(of: /<p>(.*)<\/p>/.dotMatchesNewlines()),
			!match.1.contains("<p>")
		else {
			return html
		}

		return String(match.1)
	}
}

public struct Heading: Hashable, Sendable {
	public let level: Int

	/**
	The plain text of the heading without the custom ID suffix.
	*/
	public let text: String

	public let id: String

	/**
	Values from `<!-- @namespace.name value value -->` comments directly below the heading.
	*/
	public internal(set) var directives = HeadingDirectives()
}

/**
Metadata attached to a heading with HTML comments, like `<!-- @faq.keywords launch open -->`.
*/
public struct HeadingDirectives: Hashable, Sendable {
	private var values: [String: [String]] = [:]

	/**
	The whitespace-separated values of a directive, like `directives["faq.keywords"]`.
	*/
	public subscript(name: String) -> [String] {
		get {
			values[name] ?? []
		}
		set {
			values[name] = newValue
		}
	}

	/**
	Parses a directive comment line and stores its values. Returns `false` if the line is not a directive.
	*/
	mutating func parse(_ line: some StringProtocol) -> Bool {
		guard let (name, values) = parsing(line) else {
			return false
		}

		self[name] = values
		return true
	}

	/**
	The name and values of a directive comment line, or `nil` if the line is not a directive.
	*/
	func parsing(_ line: some StringProtocol) -> (name: String, values: [String])? {
		guard
			line.contains("@"),
			let match = line.trimmingCharacters(in: .whitespaces).wholeMatch(of: /<!--\s*@(\w+\.\w+)\s+(.+?)\s*-->/)
		else {
			return nil
		}

		return (String(match.1), match.2.split(whereSeparator: \.isWhitespace).map(String.init))
	}

	/**
	The name of a comment that looks like a directive, like `faq.keyword` in `<!-- @faq.keyword open -->`, even without values.
	*/
	static func name(in line: some StringProtocol) -> String? {
		String(line).firstMatch(of: /<!--\s*@([\w.-]+)/).map { String($0.1) }
	}
}

extension Document {
	fileprivate var introduction: String? {
		let firstBlock = blockChildren.first { block in
			guard let html = block as? HTMLBlock else {
				return true
			}

			return !html.rawHTML.isOnlyHTMLComments
		}

		guard let paragraph = firstBlock as? Paragraph else {
			return nil
		}

		let text = paragraph.plainText(includingImageDescriptions: false)
			.replacing(/\s+/, with: " ")
			.trimmingCharacters(in: .whitespaces)

		return text.isEmpty ? nil : text
	}
}

extension String {
	/**
	The text without footnote references, like `[^1]`.
	*/
	var removingFootnoteReferences: String {
		contains("[^") ? replacing(/\[\^[^\]\s]+\]/, with: "") : self
	}

	fileprivate var isOnlyHTMLComments: Bool {
		removingHTMLComments.allSatisfy(\.isWhitespace)
	}

	/**
	Splits each `<kbd>` that contains `+` into one `<kbd>` per key, like GitHub does. A `+` right after a separator is the plus key, so `Cmd++` is `Cmd` and `+`. A lone `+` key is kept.
	*/
	fileprivate func separatingKeyboardKeys(separatorClasses: String) -> String {
		guard contains("<kbd>") else {
			return self
		}

		return replacing(/<kbd>([^<]*\+[^<]*)<\/kbd>/) { match in
			let keys = String(match.1).keyboardKeys

			guard keys.count > 1 else {
				return String(match.0)
			}

			return keys.enumerated()
				.map { index, key in
					let separator = index == 0 ? "" : #"<span class="\#(separatorClasses)" aria-hidden="true">+</span>"#
					return "\(separator)<kbd>\(key)</kbd>"
				}
				.joined()
		}
	}

	/**
	The keys of a shortcut like `Cmd+Shift+K`. A `+` that starts a key, like in `Cmd++`, or ends the shortcut, like in `Ctrl+`, is the plus key.
	*/
	var keyboardKeys: [String] {
		var keys = [String]()
		var key = ""

		for character in self {
			if character == "+", !key.isEmpty {
				keys.append(key)
				key = ""
			} else {
				key.append(character)
			}
		}

		keys.append(key.isEmpty ? "+" : key)
		return keys
	}
}

extension Markup {
	/**
	The text content: text, inline code, and the text inside emphasis and links. HTML tags are left out.
	*/
	func plainText(includingImageDescriptions: Bool) -> String {
		switch self {
		case let text as Markdown.Text:
			text.string
		case let code as InlineCode:
			code.code
		case is SoftBreak, is LineBreak:
			" "
		case is InlineHTML:
			""
		case is Markdown.Image where !includingImageDescriptions:
			""
		default:
			children.map { $0.plainText(includingImageDescriptions: includingImageDescriptions) }.joined()
		}
	}
}
