import Elementary
import Foundation
import Markdown
import SOML

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
		Renders a block directive, like `@Details(summary: "More") { … }`, from its arguments and the HTML of its content.

		The arguments are decoded strictly, like frontmatter. Each argument is a string, so a number or a flag is a `String` property that the renderer converts.

		```swift
		@Frontmatter
		struct DetailsArguments {
			@NonEmpty var summary: String
		}

		let details = BlockDirectiveRenderer { (arguments: DetailsArguments, contentHTML) in
			theme.collapsibleSection(titleHTML: arguments.summary, contentHTML: contentHTML)
		}
		```
		*/
		public struct BlockDirectiveRenderer: Sendable {
			let render: @Sendable (_ arguments: [String: String], _ contentHTML: String) throws -> String

			/**
			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			*/
			public init<Arguments: Frontmatter>(render: @escaping @Sendable (_ arguments: Arguments, _ contentHTML: String) throws -> String) {
				self.render = { arguments, contentHTML in
					let value = SOML.Value.object(SOML.Object(arguments.sorted(using: KeyPathComparator(\.key)).map { ($0.key, SOML.Value.string($0.value)) }))
					return try render(Arguments.decode(from: value, root: "arguments"), contentHTML)
				}
			}

			/**
			A directive without arguments, like `@Tips { … }`.

			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			*/
			public init(render: @escaping @Sendable (_ contentHTML: String) throws -> String) {
				self.render = { arguments, contentHTML in
					guard arguments.isEmpty else {
						throw ContentError(reason: "It takes no arguments.")
					}

					return try render(contentHTML)
				}
			}
		}

		/**
		Renders text with inline attributes, like `^[macOS only](platform: "macOS")`, from the attributes and the HTML of the text.

		The attributes are decoded strictly, like frontmatter.
		*/
		public struct InlineAttributesRenderer: Sendable {
			let render: @Sendable (_ attributes: String, _ contentHTML: String) throws -> String

			/**
			- Parameter render: Throw a ``ContentError`` to report a problem with the attributes.
			*/
			public init<Attributes: Frontmatter>(render: @escaping @Sendable (_ attributes: Attributes, _ contentHTML: String) throws -> String) {
				self.render = { attributes, contentHTML in
					// The attributes are an object without the braces, which is a SOML object with them.
					guard let value = try? SOML.Value(parsing: "{\(attributes)}") else {
						throw ContentError(reason: "They are not valid, like `platform: \"macOS\"`.")
					}

					return try render(Attributes.decode(from: value, root: "attributes"), contentHTML)
				}
			}
		}

		public var theme: MarkdownTheme
		public var collapsibleSections: CollapsibleSections?

		/**
		Adds a link to each `##` to `####` heading that has an ID, and to each collapsible section. Clicking it copies the URL of the section (with a script).
		*/
		public var addsHeadingAnchors: Bool

		/**
		The known heading directives, like `<!-- @faq.keywords launch open -->`. A directive with another name or invalid values, or one that is not directly below a heading, is a problem. This is also true when the list is empty, so every comment like `<!-- @name … -->` in a document with heading IDs must be a known directive.
		*/
		public var headingDirectives: [any HeadingDirective.Type]

		/**
		Changes the Markdown tree before it is rendered, like adding a section.

		Build the added nodes with their initializers, not from another `Document(parsing:)`, as the nodes of another parse keep its source ranges, so their lines would be wrong.
		*/
		public var rewrite: (@Sendable (Document) -> Document)?

		/**
		Renders text with inline attributes, like `^[macOS only](platform: "macOS")`. Without it, the text is rendered without the attributes.
		*/
		public var inlineAttributes: InlineAttributesRenderer?

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
		Renders a fenced code block, like a component with syntax highlighting and a copy button. It gets the code and the language, which is the first word of the info string, like `swift`. Without it, a code block is `<pre><code class="language-swift">` with the code as text.
		*/
		public var codeBlock: (@Sendable (_ code: String, _ language: String?) -> String)?

		public init(
			theme: MarkdownTheme = .default,
			collapsibleSections: CollapsibleSections? = nil,
			addsHeadingAnchors: Bool = false,
			headingDirectives: [any HeadingDirective.Type] = [],
			rewrite: (@Sendable (Document) -> Document)? = nil,
			inlineAttributes: InlineAttributesRenderer? = nil,
			blockDirectives: [String: BlockDirectiveRenderer] = [:],
			resolveLink: (@Sendable (String) throws -> String)? = nil,
			imageSize: (@Sendable (String) -> (width: Int, height: Int)?)? = nil,
			showsFootnotesInPopovers: Bool = false,
			codeBlock: (@Sendable (_ code: String, _ language: String?) -> String)? = nil
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
			self.codeBlock = codeBlock
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
	The styles and scripts that the Markdown uses, like those of its block directives, which render with the document, before the page.
	*/
	let resources: PageResources

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
		self.init(parsing: source, firstLine: 1, style: style, options: options)
	}

	/**
	- Parameter firstLine: The line of the source in its file, so the lines of problems, headings, and links are lines in the file.
	*/
	init(parsing source: String, firstLine: Int, style: Style = .extended, options: Options) {
		// Source positions and line-based extensions assume `\n` line endings, but GitHub release notes use `\r\n`.
		let source = source.replacing("\r\n", with: "\n")
		let parseOptions: ParseOptions = style == .extended && !options.blockDirectives.isEmpty ? .parseBlockDirectives : []
		// Bare URLs and emails are links, like on GitHub, with its autolink extension. Limitation: like on GitHub, a file name with an at sign, like `icon@2x.png`, is an email link. Write it as code. Footnotes are only in the extended style.
		let commonmarkOptions = style == .extended ? ConvertOptions.defaultCommonmarkOptions : ConvertOptions.defaultCommonmarkOptions.subtracting(.footnotes)
		let convertOptions = ConvertOptions(parseOptions: parseOptions, commonmarkOptions: commonmarkOptions, extensions: ConvertOptions.defaultCommonmarkExtensions + ["autolink"])
		var document = Document(parsing: source, convertOptions: convertOptions)

		if
			style == .extended,
			let rewrite = options.rewrite
		{
			document = rewrite(document)
		}

		// The styles and scripts that the Markdown uses, like those of its block directives. The page that shows the document adds them (``content``), like a preference in SwiftUI.
		let resources = PageResources()
		var renderer = HTMLRenderer(style: style, options: options, footnoteDefinitions: document.footnoteDefinitions, lineOffset: firstLine - 1)

		PageResources.$current.withValue(resources) {
			renderer.visit(document)
		}
		var html = renderer.html
		var headings = renderer.headings
		var problems = renderer.problems
		var links = renderer.links

		if !renderer.footnotes.isEmpty {
			// The definitions resolve and report their links like the text, but without the options for the whole document. Limitation: like on GitHub, a definition without a reference is not shown, and the parser leaves it out, so it is not reported.
			var definitionOptions = options
			definitionOptions.collapsibleSections = nil
			definitionOptions.addsHeadingAnchors = false
			definitionOptions.rewrite = nil
			definitionOptions.showsFootnotesInPopovers = false

			html += PageResources.$current.withValue(resources) {
				Footnotes.sectionHTML(for: renderer.footnotes, theme: options.theme, withPopovers: options.showsFootnotesInPopovers) { footnote in
					var definitionRenderer = HTMLRenderer(style: style, options: definitionOptions, lineOffset: firstLine - 1)

					for block in footnote.definition.children {
						definitionRenderer.visit(block)
					}

					problems += definitionRenderer.problems
					links += definitionRenderer.links
					return definitionRenderer.html
				}
			}

			headings.append(Heading(level: 2, text: "Footnotes", id: Heading.footnotesID, line: nil))
		}

		// A document inside another one, like the summary of a collapsible section, adds them to the outer one.
		PageResources.current?.include(resources)

		self.resources = resources
		self.html = html
		self.headings = headings
		self.problems = problems
		self.links = links
		// The introduction keeps the source punctuation, while the HTML gets smart punctuation. Footnote references are left out, as they have no text.
		self.introduction = Document(parsing: source, options: parseOptions.union(.disableSmartOpts)).introduction
	}
}

extension MarkdownDocument {
	/**
	The HTML without the paragraph around it, for a short text, like a frontmatter field.
	*/
	public var inlineHTML: String {
		let html = html.trimmingCharacters(in: .newlines)

		guard
			let match = html.wholeMatch(of: /<p>(.*)<\/p>/.dotMatchesNewlines()),
			!match.1.contains("<p>")
		else {
			return html
		}

		return String(match.1)
	}

	/**
	The HTML of the first paragraph without the `<p>` tags, and the HTML after it, so a page can show the introduction apart from the rest, like at the top of an app page. `nil` when the document does not start with a paragraph. HTML comments before the paragraph are left out.
	*/
	public var htmlSeparatingIntroduction: (introduction: String, remainder: String)? {
		guard
			introduction != nil,
			let match = html.prefixMatch(of: /\s*(?:<!--.*?-->\s*)*<p>(.*?)<\/p>\n?/.dotMatchesNewlines())
		else {
			return nil
		}

		return (String(match.1), String(html[match.range.upperBound...]))
	}
}

public struct Heading: Sendable {
	/**
	The ID of the heading of the footnotes, which the renderer adds at the end when there are footnotes.
	*/
	public static let footnotesID = "footnote-label"

	public let level: Int

	/**
	The plain text of the heading without the custom ID suffix.
	*/
	public let text: String

	public let id: String

	/**
	The line in the Markdown source, starting at 1. `nil` for headings that are not in the source, like the footnotes heading.
	*/
	public let line: Int?

	/**
	The values of the directives directly below the heading, by name.
	*/
	var directives = [String: any Sendable]()

	/**
	The value of a directive comment directly below the heading, like the platforms of `<!-- @faq.platforms macOS iOS -->`. `nil` when the heading does not have the directive.
	*/
	public subscript<Directive: HeadingDirective>(directive: Directive.Type) -> Directive.Value? {
		directives[Directive.name] as? Directive.Value
	}

	/**
	Whether the heading has the directive, like a flag such as `<!-- @faq.general -->`.
	*/
	public func contains<Directive: HeadingDirective>(_ directive: Directive.Type) -> Bool {
		directives[Directive.name] != nil
	}
}

extension Document {
	/**
	The footnote definitions, by ID, also the ones in block directives. The parser moves the definitions to the end of their container.
	*/
	fileprivate var footnoteDefinitions: [String: FootnoteDefinition] {
		func definitions(in markup: any Markup) -> [FootnoteDefinition] {
			markup.children.flatMap { child in
				(child as? FootnoteDefinition).map { [$0] } ?? definitions(in: child)
			}
		}

		return Dictionary(definitions(in: self).map { ($0.footnoteID, $0) }) { first, _ in
			first
		}
	}

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

		// A footnote reference has no text, and the whitespace is collapsed after, so a reference between spaces leaves one space.
		let text = paragraph.plainText(includingImageDescriptions: false)
			.replacing(/\s+/, with: " ")
			.trimmingCharacters(in: .whitespaces)

		return text.isEmpty ? nil : text
	}
}

extension Markdown.Text {
	/**
	The text with each keyboard shortcut, like `++Cmd+K++`, as its keys, like `Cmd+K`.
	*/
	fileprivate var plainString: String {
		string.contains("++") ? string[...].keyboardShortcutParts.map(\.text).joined() : string
	}
}

extension Substring {
	/**
	The text in parts: plain text, and the keys of each keyboard shortcut written as `++Cmd+K++`. The `++` must not touch a letter, a digit, or another `+`, so `C++` stays text.
	*/
	var keyboardShortcutParts: [(text: Substring, isShortcut: Bool)] {
		var parts = [(text: Substring, isShortcut: Bool)]()
		var remainder = self

		while let match = remainder.firstMatch(of: /\+\+(\S(?:[^\n]*?\S)?)\+\+/) {
			let before = remainder[..<match.range.lowerBound].last
			let after = remainder[match.range.upperBound...].first

			guard
				before.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true,
				after.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true
			else {
				// Only the opening `++` is text, as the closing one can open a shortcut.
				let openingEnd = remainder.index(match.range.lowerBound, offsetBy: 2)
				parts.append((remainder[..<openingEnd], false))
				remainder = remainder[openingEnd...]
				continue
			}

			parts.append((remainder[..<match.range.lowerBound], false))
			parts.append((match.1, true))
			remainder = remainder[match.range.upperBound...]
		}

		parts.append((remainder, false))
		return parts
	}
}

extension String {
	/**
	The text with the punctuation of the source, which smart punctuation changed: `…` to `...`, dashes to `--` and `---`, and typographic quotes to straight quotes. For text that is not prose, like a key.
	*/
	var removingSmartPunctuation: String {
		replacing("…", with: "...")
			.replacing("—", with: "---")
			.replacing("–", with: "--")
			.replacing(/[‘’]/, with: "'")
			.replacing(/[“”]/, with: "\"")
	}

	fileprivate var isOnlyHTMLComments: Bool {
		removingHTMLComments.allSatisfy(\.isWhitespace)
	}

	/**
	The keys of a shortcut like `Cmd+Shift+K`. A `+` that starts a key, like in `Cmd++`, or ends the shortcut, like in `Ctrl+`, is the plus key.
	*/
	var keyboardKeys: [String] {
		var keys = [String]()
		var key = ""

		for character in self {
			if
				character == "+",
				!key.isEmpty
			{
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
		// A keyboard shortcut in text, like `++Cmd+K++`, is its keys.
		case let text as Markdown.Text:
			text.plainString
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

extension MarkdownDocument {
	/**
	The HTML as content of a page, which adds the styles and scripts that the Markdown uses to the page.
	*/
	public var content: MarkdownContent {
		MarkdownContent(html: html, resources: resources)
	}

	/**
	The ``inlineHTML`` as content of a page.
	*/
	public var inlineContent: MarkdownContent {
		MarkdownContent(html: inlineHTML, resources: resources)
	}

	/**
	The ``htmlSeparatingIntroduction`` as content of a page. Each part adds the styles and scripts of the whole document, so either part can be shown alone.
	*/
	public var contentSeparatingIntroduction: (introduction: MarkdownContent, remainder: MarkdownContent)? {
		htmlSeparatingIntroduction.map { (MarkdownContent(html: $0.introduction, resources: resources), MarkdownContent(html: $0.remainder, resources: resources)) }
	}
}

/**
Rendered Markdown as content of a page. It adds the styles and scripts that the Markdown uses, like those of its block directives, to the page that shows it, like a preference in SwiftUI, as the Markdown renders before the page.
*/
public struct MarkdownContent: HTML, Sendable {
	public let html: String
	let resources: PageResources

	public var body: HTMLRaw {
		PageResources.current?.include(resources)
		return HTMLRaw(html)
	}
}
