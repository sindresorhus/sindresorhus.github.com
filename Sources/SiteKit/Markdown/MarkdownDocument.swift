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
		GitHub-flavored Markdown with extensions: heading IDs (`{#id}`) and directives, GitHub alerts, footnotes and inline notes in popovers, bare URLs as links, keyboard shortcuts split into keys, and the options, like collapsible sections. The created HTML gets the classes of the theme in the options.

		Limitations: the parser reads the text between block directives on its own, so the definition of a footnote must be in the same part as its reference, before the next block directive, not at the end of a file that has a block directive after the reference. A popover is not printed, so a printed page has no footnotes and notes.
		*/
		case extended

		/**
		GitHub release notes: bare URLs and emails become links, raw HTML other than `<kbd>` is escaped, and links allow only HTTP, HTTPS, mailto, and relative destinations, so another link is only its text. Images allow only HTTP, HTTPS, and relative destinations. Tables are in the container of the theme in the options, like in the extended style, so a wide table scrolls. No other extensions apply.
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
			let render: @Sendable (_ arguments: [DirectiveArgument], _ contentHTML: String) throws -> String

			/**
			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			*/
			public init<Arguments: Frontmatter>(render: @escaping @Sendable (_ arguments: Arguments, _ contentHTML: String) throws -> String) {
				self.render = { arguments, contentHTML in
					let value = SOML.Value.object(SOML.Object(arguments.map { ($0.name, SOML.Value.string($0.value)) }))
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
					let value: SOML.Value

					do throws(SOML.ParseError) {
						value = try SOML.Value(parsing: "{\(attributes)}")
					} catch {
						throw ContentError(reason: "\(error.message). Write them like `platform: \"macOS\"`.")
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

		Build the added nodes with their initializers, or parse them with their file as the source (`Document(parsing:file:options:)`), so they have no lines in this document. The nodes of another parse without a source keep its source ranges, so their lines would be wrong.
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
		public var imageSize: (@Sendable (String) -> PixelSize?)?

		/**
		Renders a fenced code block, like a component with syntax highlighting and a copy button. It gets the code and the language, which is the first word of the info string, like `swift`. Without it, a code block is `<pre><code class="language-swift">` with the code as text.
		*/
		public var codeBlock: (@Sendable (_ code: String, _ language: String?) -> String)?

		/**
		Renders the text of an inline note, like `^[Spotlight](note: "The search of macOS.")`. It gets the HTML of the text and the ID of the popover that the text opens, for a component with a script, so the text can wrap across lines. Without it, the text is a button with `popovertarget`, which needs no script, but does not wrap across lines, so the text of a note must be short.
		*/
		public var inlineNote: (@Sendable (_ textHTML: String, _ noteID: String) -> String)?

		public init(
			theme: MarkdownTheme = .default,
			collapsibleSections: CollapsibleSections? = nil,
			addsHeadingAnchors: Bool = false,
			headingDirectives: [any HeadingDirective.Type] = [],
			rewrite: (@Sendable (Document) -> Document)? = nil,
			inlineAttributes: InlineAttributesRenderer? = nil,
			blockDirectives: [String: BlockDirectiveRenderer] = [:],
			resolveLink: (@Sendable (String) throws -> String)? = nil,
			imageSize: (@Sendable (String) -> PixelSize?)? = nil,
			codeBlock: (@Sendable (_ code: String, _ language: String?) -> String)? = nil,
			inlineNote: (@Sendable (_ textHTML: String, _ noteID: String) -> String)? = nil
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
			self.codeBlock = codeBlock
			self.inlineNote = inlineNote
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
			public let destination: LinkDestination

			public init(title: String, destination: LinkDestination) {
				self.title = title
				self.destination = destination
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
	The headings in document order.

	Empty for the release notes style.
	*/
	public let headings: [Heading]

	/**
	The plain text of the first block, when it is a paragraph. HTML comments before it are skipped.
	*/
	public let introduction: String?

	/**
	The mistakes in the Markdown, like an image without a description, in document order, with their lines in the source, but without the file. For the release notes style, only an HTML comment that is not closed.
	*/
	public let problems: [ContentError]

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
		let convertOptions = ConvertOptions(style: style, options: options)
		let parsedDocument = Document(parsing: source, convertOptions: convertOptions)
		var document = parsedDocument

		if
			style == .extended,
			let rewrite = options.rewrite
		{
			document = rewrite(document)
		}

		// The styles and scripts that the Markdown uses, like those of its block directives. The page that shows the document adds them (``content``), like a preference in SwiftUI.
		let resources = PageResources()
		var renderer = HTMLRenderer(style: style, options: options, footnoteDefinitions: document.footnoteDefinitions, origin: .document(lineOffset: firstLine - 1))

		PageResources.$current.withValue(resources) {
			renderer.visit(document)
		}

		// A document inside another one, like the summary of a collapsible section, adds them to the outer one.
		PageResources.current?.include(resources)

		self.resources = resources
		// The popovers of the footnotes and the notes are at the end, as they can have paragraphs, which a paragraph cannot contain. Limitation: like on GitHub, a footnote definition without a reference is not shown, and the parser leaves it out, so it is not reported.
		self.html = renderer.html + renderer.popovers.joined()
		self.headings = renderer.headings
		self.problems = renderer.problems
		self.links = renderer.links
		// The introduction keeps the source punctuation, while the HTML gets smart punctuation. Smart punctuation only adds typographic quotes, dashes, and ellipses, so the source is only parsed again without it when the introduction has one. Footnote references are left out, as they have no text.
		let introduction = parsedDocument.introduction
		self.introduction = introduction?.contains(where: "‘’“”–—…".contains) == true ? Document(parsing: source, options: convertOptions.parseOptions.union(.disableSmartOpts)).introduction : introduction
	}
}

extension MarkdownDocument.Options {
	/**
	The options for Markdown inside the document, like a footnote definition or an inline note: without the options for the whole document, which are the collapsible sections, the heading anchors, and the rewrite.
	*/
	var forNestedMarkdown: Self {
		var options = self
		options.collapsibleSections = nil
		options.addsHeadingAnchors = false
		options.rewrite = nil
		return options
	}
}

extension MarkdownDocument {
	/**
	The HTML without the paragraph around it, for a short text, like a frontmatter field.

	Limitation: a short text with footnotes or inline notes is not one paragraph, as their popovers are after it, so they are not supported.
	*/
	public var inlineHTML: String {
		let html = html.trimmingCharacters(in: .newlines)

		guard
			let match = html.wholeMatch(of: /<p>(.*)<\/p>/.dotMatchesNewlines()),
			// Also a raw paragraph with attributes, like `<p class="note">`.
			!match.1.contains(/<p[\s>]/)
		else {
			return html
		}

		return String(match.1)
	}

	/**
	The HTML of the first paragraph without the `<p>` tags, and the HTML after it, so a page can show the introduction apart from the rest, like at the top of an app page. `nil` when the document does not start with a paragraph. HTML comments before the paragraph do not count, as the renderer leaves out comments.
	*/
	var htmlSeparatingIntroduction: (introduction: String, remainder: String)? {
		guard
			introduction != nil,
			let match = html.prefixMatch(of: /\s*<p>(.*?)<\/p>\n?/.dotMatchesNewlines())
		else {
			return nil
		}

		return (String(match.1), String(html[match.range.upperBound...]))
	}

	/**
	The HTML before the level 2 heading with the ID, and the HTML from that heading on, so a page can show something between two sections, like the projects on the about page. `nil` when the document has no level 2 heading with the ID. The heading must not be inside other markup, like a block directive.
	*/
	func htmlSeparated(beforeHeading id: String) -> (before: String, after: String)? {
		htmlSeparated(beforeHeadings: [id]).map { ($0[0], $0[1]) }
	}

	/**
	The HTML separated before each level 2 heading with one of the IDs, in their order, so a page can show something between several sections, like the numbers and the projects on the about page. It has one part more than the IDs: the HTML before the first heading, and the HTML from each heading to the next. `nil` when one of the IDs has no level 2 heading, or the headings are in another order. The headings must not be inside other markup, like a block directive.
	*/
	func htmlSeparated(beforeHeadings ids: [String]) -> [String]? {
		var parts = [String]()
		var remainder = html[...]

		for id in ids {
			guard let range = remainder.firstRange(of: "<h2 id=\"\(id)\"") else {
				return nil
			}

			parts.append(String(remainder[..<range.lowerBound]))
			remainder = remainder[range.lowerBound...]
		}

		return parts + [String(remainder)]
	}
}

public struct Heading: Sendable {
	public let level: Int

	/**
	The plain text of the heading without the custom ID suffix.
	*/
	public let text: String

	public let id: String

	/**
	The line in the Markdown source, starting at 1. `nil` for headings that are not in the source, like the ones that ``Options/rewrite`` adds.
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

extension ConvertOptions {
	/**
	The options to parse Markdown in the style: block directives when the options have them, footnotes only in the extended style, and bare URLs and emails as links, like on GitHub, with its autolink extension.

	Limitation: like on GitHub, a file name with an at sign, like `icon@2x.png`, is an email link. Write it as code.
	*/
	init(style: MarkdownDocument.Style, options: MarkdownDocument.Options) {
		let commonmarkOptions = style == .extended ? Self.defaultCommonmarkOptions : Self.defaultCommonmarkOptions.subtracting(.footnotes)

		self.init(
			parseOptions: style == .extended && !options.blockDirectives.isEmpty ? .parseBlockDirectives : [],
			commonmarkOptions: commonmarkOptions,
			extensions: Self.defaultCommonmarkExtensions + ["autolink"]
		)
	}
}

extension Document {
	/**
	Parses the Markdown of another file, like the part that a ``MarkdownDocument/Options/rewrite`` adds, with the parse options of the document, and the file as its source, so its nodes have no lines in the document.
	*/
	public init(parsing source: String, file: URL, options: MarkdownDocument.Options) {
		self.init(parsing: source.replacing("\r\n", with: "\n"), source: file, convertOptions: ConvertOptions(style: .extended, options: options))
	}

	/**
	The footnote definitions, by ID, also the ones in block directives. The parser moves the definitions to the end of their container. Of two definitions with the same ID, the first is used, and the renderer reports the second.
	*/
	fileprivate var footnoteDefinitions: [String: FootnoteDefinition] {
		func definitions(in markup: any Markup) -> [FootnoteDefinition] {
			markup.children.flatMap { child -> [FootnoteDefinition] in
				switch child {
				case let definition as FootnoteDefinition:
					[definition]
				// A definition is a block, so the inline content of a paragraph or a heading has none.
				case is any InlineContainer:
					[]
				default:
					definitions(in: child)
				}
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
		string[...].keyboardShortcutParts.map(\.text).joined()
	}
}

extension Substring {
	/**
	The text in parts: plain text, and the keys of each keyboard shortcut written as `++Cmd+K++`. The `++` must not touch a letter, a digit, or another `+`, so `C++` stays text.
	*/
	var keyboardShortcutParts: [(text: Substring, isShortcut: Bool)] {
		// Most text has no shortcut, and the search is slow.
		guard contains("++") else {
			return [(self, false)]
		}

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

	/**
	The ``htmlSeparated(beforeHeading:)`` as content of a page. Each part adds the styles and scripts of the whole document, so either part can be shown alone.
	*/
	public func contentSeparated(beforeHeading id: String) -> (before: MarkdownContent, after: MarkdownContent)? {
		htmlSeparated(beforeHeading: id).map { (MarkdownContent(html: $0.before, resources: resources), MarkdownContent(html: $0.after, resources: resources)) }
	}

	/**
	The ``htmlSeparated(beforeHeadings:)`` as content of a page. Each part adds the styles and scripts of the whole document, so any part can be shown alone.
	*/
	public func contentSeparated(beforeHeadings ids: [String]) -> [MarkdownContent]? {
		htmlSeparated(beforeHeadings: ids).map { $0.map { MarkdownContent(html: $0, resources: resources) } }
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
