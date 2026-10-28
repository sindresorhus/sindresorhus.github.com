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
		GitHub release notes: bare URLs and emails become links, raw HTML other than `<kbd>` is escaped, and links allow only HTTP, HTTPS, mailto, and relative destinations, so another link is only its text. Images allow only HTTP, HTTPS, and relative destinations. The safe destinations then go through ``Options/resolveLink``, like a relative link that is resolved against the page of the release. Tables are in the container of the theme in the options, like in the extended style, so a wide table scrolls. The headings go two levels down, like `#` as `<h3>`, as a page shows each release below a heading of its version (`<h2>`), so it has one `<h1>`. No other extensions apply.
		*/
		case releaseNotes
	}

	/**
	Options for the extended style. Release notes use only the theme, for the container of tables, and ``resolveLink``.
	*/
	public struct Options: Sendable {
		/**
		Renders a block directive, like `@Details(summary: "More") { … }`, from its arguments and the HTML of its content, and gives its blocks in plain Markdown, for readers that get the Markdown instead of the page (``plainBlocks(of:)``).

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
			/**
			What the content of a directive must be. Other content is a problem, with the line of the directive.
			*/
			public enum Content: Sendable {
				/**
				Any blocks, but not empty braces, like `@Tips {\n}`, which are a lost edit. A directive without braces has no content, like `@Trial(…)`.
				*/
				case blocks

				/**
				No content, like `@SocialLinks`.
				*/
				case empty

				/**
				Exactly one numbered list, like the steps of `@Steps { 1. … }`.
				*/
				case orderedList

				/**
				Exactly one bulleted list, like the cards of `@Cards { - … }`.
				*/
				case unorderedList
			}

			/**
			What a directive gets from the document while it renders, like the options of the document for the Markdown of an argument.
			*/
			public struct Context: Sendable {
				/**
				The options of the document without the ones for the whole document, like the block directives and ``Options/rewrite``.
				*/
				let inlineOptions: Options

				init(documentOptions: Options) {
					var options = documentOptions.forNestedMarkdown
					options.blockDirectives = [:]
					self.inlineOptions = options
				}

				/**
				The inline Markdown of an argument, like the title of a section, with the options of the document, so it gets the same checks, like of links, keyboard shortcuts, and inline attributes, but no block directives. Requires one paragraph, ignoring comment-only blocks, without footnotes or inline notes. A problem is thrown, so the directive reports it at its line.

				Limitation: The links of the argument are not in the links of the document, so a link to a page that does not exist, like `/datto`, is reported at the page, not at the line. A link that ``Options/resolveLink`` resolves is checked here.
				*/
				public func inlineDocument(parsing markdown: String) throws(ContentError) -> MarkdownDocument {
					let document = MarkdownDocument(parsing: markdown, options: inlineOptions)

					if let problem = document.problems.first {
						throw ContentError(reason: problem.reason)
					}

					// Comment-only blocks show nothing and do not change the shape of an inline argument.
					guard document.singleInlineParagraph != nil else {
						throw ContentError(reason: "Expected one paragraph of inline Markdown without footnotes or inline notes.")
					}

					return document
				}
			}

			let content: Content
			let rewriteContent: (@Sendable (_ content: [any BlockMarkup]) throws -> [any BlockMarkup])?
			let render: @Sendable (_ arguments: [DirectiveArgument], _ contentHTML: String, _ context: Context) throws -> String
			private let plain: @Sendable (_ arguments: [DirectiveArgument], _ content: [any BlockMarkup]) throws -> [any BlockMarkup]

			/**
			- Parameter content: What the content of the directive must be.
			- Parameter rewriteContent: Changes the Markdown of valid content before it is rendered, like a word that becomes a badge. Throw a ``ContentError`` to report a problem with the content.
			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			- Parameter plain: The blocks in plain Markdown, from the arguments and the content, like the title of a section as a heading above the content. Default: the content.
			*/
			public init<Arguments: Frontmatter>(
				content: Content = .blocks,
				rewriteContent: (@Sendable (_ content: [any BlockMarkup]) throws -> [any BlockMarkup])? = nil,
				render: @escaping @Sendable (_ arguments: Arguments, _ contentHTML: String) throws -> String,
				plain: @escaping @Sendable (_ arguments: Arguments, _ content: [any BlockMarkup]) -> [any BlockMarkup] = { $1 }
			) {
				self.init(
					content: content,
					rewriteContent: rewriteContent,
					render: { arguments, contentHTML, _ in
						try render(arguments, contentHTML)
					},
					plain: plain
				)
			}

			/**
			A directive whose renderer needs the document, like for the Markdown of an argument (``Context/inlineDocument(parsing:)``).

			- Parameter content: What the content of the directive must be.
			- Parameter rewriteContent: Changes the Markdown of valid content before it is rendered, like a word that becomes a badge. Throw a ``ContentError`` to report a problem with the content.
			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			- Parameter plain: The blocks in plain Markdown, from the arguments and the content, like the title of a section as a heading above the content. Default: the content.
			*/
			public init<Arguments: Frontmatter>(
				content: Content = .blocks,
				rewriteContent: (@Sendable (_ content: [any BlockMarkup]) throws -> [any BlockMarkup])? = nil,
				render: @escaping @Sendable (_ arguments: Arguments, _ contentHTML: String, _ context: Context) throws -> String,
				plain: @escaping @Sendable (_ arguments: Arguments, _ content: [any BlockMarkup]) -> [any BlockMarkup] = { $1 }
			) {
				self.content = content
				self.rewriteContent = rewriteContent
				self.render = { arguments, contentHTML, context in
					try render(Arguments.decode(directiveArguments: arguments), contentHTML, context)
				}
				self.plain = { arguments, content in
					try plain(Arguments.decode(directiveArguments: arguments), content)
				}
			}

			/**
			A directive without arguments, like `@Cards { … }`.

			- Parameter content: What the content of the directive must be.
			- Parameter rewriteContent: Changes the Markdown of valid content before it is rendered, like a word that becomes a badge. Throw a ``ContentError`` to report a problem with the content.
			- Parameter render: Throw a ``ContentError`` to report a problem with the directive.
			- Parameter plain: The blocks in plain Markdown, from the content. Default: the content.
			*/
			public init(
				content: Content = .blocks,
				rewriteContent: (@Sendable (_ content: [any BlockMarkup]) throws -> [any BlockMarkup])? = nil,
				render: @escaping @Sendable (_ contentHTML: String) throws -> String,
				plain: @escaping @Sendable (_ content: [any BlockMarkup]) -> [any BlockMarkup] = { $0 }
			) {
				self.content = content
				self.rewriteContent = rewriteContent
				self.render = { arguments, contentHTML, _ in
					guard arguments.isEmpty else {
						throw ContentError(reason: "It takes no arguments.")
					}

					return try render(contentHTML)
				}
				self.plain = { _, content in
					plain(content)
				}
			}

			/**
			The blocks of the directive in plain Markdown (``PlainMarkdownRewriter``), or its content when its arguments are invalid, which the build already reported.
			*/
			public func plainBlocks(of directive: BlockDirective) -> [any BlockMarkup] {
				let content = Array(directive.blockChildren)
				return (try? plain(directive.parsedArguments(), content)) ?? content
			}
		}

		/**
		Renders text with inline attributes, like `^[macOS only](platform: "macOS")`, from the attributes and the HTML of the text.

		The attributes are decoded strictly, like frontmatter.
		*/
		public struct InlineAttributesRenderer: Sendable {
			let render: @Sendable (_ attributes: SOML.Value, _ contentHTML: String) throws -> String

			/**
			- Parameter render: Throw a ``ContentError`` to report a problem with the attributes.
			*/
			public init<Attributes: Frontmatter>(render: @escaping @Sendable (_ attributes: Attributes, _ contentHTML: String) throws -> String) {
				self.render = { value, contentHTML in
					try render(Attributes.decode(from: value, root: "attributes"), contentHTML)
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
		The destination of a link or image, like `/dato` for `dato.md`. Throw to report a broken link. It also applies to release notes, after their check of the destination.
		*/
		public var resolveLink: (@Sendable (String) throws -> String)?

		/**
		The size of an image by its source, for the `width` and `height` attributes, so the layout does not move while the image loads.
		*/
		public var imageSize: (@Sendable (String) -> PixelSize?)?

		/**
		Renders a fenced code block, like a component with syntax highlighting and a copy button. It gets the code and the language, which is the first word of the info string, like `swift`. Throw to report a problem, like an unknown language, and the block is plain. Without it, a code block is `<pre><code class="language-swift">` with the code as text.
		*/
		public var codeBlock: (@Sendable (_ code: String, _ language: String?) throws(ContentError) -> String)?

		/**
		Renders the text of an inline note, like `^[Spotlight](note: "The search of macOS.")`. It gets the HTML of the text and the ID of the popover that the text opens, for a component with a script, so the text can wrap across lines. Without it, the text is a button with `popovertarget`, which needs no script, but does not wrap across lines, so the text of a note must be short.
		*/
		public var inlineNote: (@Sendable (_ textHTML: String, _ noteID: ElementID) -> String)?

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
			codeBlock: (@Sendable (_ code: String, _ language: String?) throws(ContentError) -> String)? = nil,
			inlineNote: (@Sendable (_ textHTML: String, _ noteID: ElementID) -> String)? = nil
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

		/**
		The source document of a link, retaining the distinction between the current file and inserted content.
		*/
		public enum Source: Hashable, Sendable {
			case document(line: Int?)
			case file(URL, line: Int?)
		}

		public let source: Source

		/**
		The original source line, when available.
		*/
		public var line: Int? {
			switch source {
			case .document(let line), .file(_, let line):
				line
			}
		}

		/**
		The file of a link that a rewrite adds from another file, like a shared answer of a FAQ (``Options/rewrite``), so it can be reported once, in that file. Its ``line`` is then the line in the Markdown of that file, as it was parsed. `nil` for a link in the Markdown of the document.
		*/
		public var otherFile: URL? {
			guard case .file(let file, _) = source else {
				return nil
			}

			return file
		}
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
		The level of the headings, like `.h4` for `####`.
		*/
		public let level: HeadingLevel

		/**
		The ID of the heading the sections follow. The sections end at the next heading with a lower level. When `nil`, every heading of the level in the document becomes a section.
		*/
		public let startHeadingID: ElementID?

		/**
		The `name` of the sections, so only one is open at a time.
		*/
		public let name: String?

		public let moreLink: MoreLink?

		public init(
			level: HeadingLevel,
			startHeadingID: ElementID? = nil,
			name: String? = nil,
			moreLink: MoreLink? = nil
		) {
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

	/**
	The top-level blocks with their HTML, in document order, so a page can split the document by its blocks, like the introduction of an app page, without searching the HTML. A group of collapsible sections is one block. The ``html`` is their HTML and then the popovers of the footnotes and the notes.
	*/
	public let blocks: [Block]

	/**
	The popovers of the footnotes and the notes, which are at the end of the HTML, after the blocks.
	*/
	private let popoversHTML: String

	/**
	A top-level block of the document, with its HTML.
	*/
	public enum Block: Sendable {
		public enum Kind: Sendable, Equatable {
			case paragraph

			/**
			A heading, with its ID, like `faq`.
			*/
			case heading(level: HeadingLevel, id: ElementID)

			/**
			A block directive, like `@QuickAnswer`, with its lines in the file. The lines are `nil` for a directive that a rewrite adds.
			*/
			case directive(name: String, lines: ClosedRange<Int>?)

			/**
			Raw HTML, like a comment. A block of only comments has no HTML.
			*/
			case html

			case other
		}

		case paragraph(inlineHTML: String, attributes: String = "")
		case heading(level: HeadingLevel, id: ElementID, html: String)
		case directive(name: String, lines: ClosedRange<Int>?, html: String)
		case html(String)
		case other(String)

		/**
		The structural kind, independent of the rendered content.
		*/
		public var kind: Kind {
			switch self {
			case .paragraph:
				.paragraph
			case .heading(let level, let id, _):
				.heading(level: level, id: id)
			case .directive(let name, let lines, _):
				.directive(name: name, lines: lines)
			case .html:
				.html
			case .other:
				.other
			}
		}

		/**
		The rendered block, deriving a paragraph's wrapper from its inline content.
		*/
		public var html: String {
			switch self {
			case .paragraph(let inlineHTML, let attributes):
				"<p\(attributes)>\(inlineHTML)</p>\n"
			case .heading(_, _, let html), .directive(_, _, let html), .html(let html), .other(let html):
				html
			}
		}

		/**
		The level of the heading, or `nil` for another block.
		*/
		public var headingLevel: HeadingLevel? {
			guard case .heading(let level, _) = kind else {
				return nil
			}

			return level
		}

		/**
		The name of the block directive, like `QuickAnswer`, or `nil` for another block.
		*/
		public var directiveName: String? {
			guard case .directive(let name, _) = kind else {
				return nil
			}

			return name
		}

		/**
		Whether the block shows nothing, like an HTML comment, which is a note for the author.
		*/
		public var isEmpty: Bool {
			html.allSatisfy(\.isWhitespace)
		}
	}

	public init(parsing source: String, style: Style = .extended, options: Options = Options()) {
		self.init(
			parsing: source,
			firstLine: 1,
			style: style,
			options: options
		)
	}

	/**
	- Parameter firstLine: The line of the source in its file, so the lines of problems, headings, and links are lines in the file.
	*/
	init(
		parsing source: String,
		firstLine: Int,
		style: Style = .extended,
		options: Options
	) {
		// Source positions and line-based extensions assume `\n` line endings, but GitHub release notes use `\r\n`.
		let source = source.normalizingWindowsLineEndings
		let convertOptions = ConvertOptions(style: style, options: options)
		self.init(rendering: Document(parsing: source, convertOptions: convertOptions), source: source, firstLine: firstLine, style: style, options: options)
	}

	/**
	Renders an already parsed document, keeping its source identity for diagnostics and inserted blocks. The source text is used only to preserve the introduction’s punctuation.
	*/
	public init(rendering parsedDocument: Document, source: String, firstLine: Int = 1, style: Style = .extended, options: Options = Options()) {
		let convertOptions = ConvertOptions(style: style, options: options)
		var document = parsedDocument

		if
			style == .extended,
			let rewrite = options.rewrite
		{
			document = rewrite(document)
		}

		// The styles and scripts that the Markdown uses, like those of its block directives. The page that shows the document adds them (``content``), like a preference in SwiftUI.
		let resources = PageResources()
		var renderer = HTMLRenderer(
			style: style,
			options: options,
			footnoteDefinitions: document.footnoteDefinitions,
			origin: .document(lineOffset: firstLine - 1),
			sourceURL: parsedDocument.range?.lowerBound.source
		)

		PageResources.$current.withValue(resources) {
			renderer.visit(document)
		}

		// A document inside another one, like the summary of a collapsible section, adds them to the outer one.
		PageResources.current?.include(resources)

		self.resources = resources
		// The popovers of the footnotes and the notes are at the end, as they can have paragraphs, which a paragraph cannot contain. Limitation: like on GitHub, a footnote definition without a reference is not shown, and the parser leaves it out, so it is not reported.
		self.popoversHTML = renderer.popovers.joined()
		self.html = renderer.html + popoversHTML
		self.blocks = renderer.blocks
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
		singleInlineParagraph ?? html.trimmingCharacters(in: .newlines)
	}

	/**
	The inline HTML of exactly one visible paragraph without trailing popovers.
	*/
	private var singleInlineParagraph: String? {
		// Comments render as nothing, so they are not blocks of the text.
		let visibleBlocks = blocks.filter { !$0.isEmpty }
		guard
			visibleBlocks.count == 1,
			popoversHTML.isEmpty
		else {
			return nil
		}

		return visibleBlocks.first?.inlineParagraphContentHTML
	}
}

extension MarkdownDocument.Block {
	/**
	The inline content of a paragraph, including a bold label whose class belongs to the paragraph rather than its text.
	*/
	fileprivate var inlineParagraphContentHTML: String? {
		guard case .paragraph(let inlineHTML, _) = self else {
			return nil
		}

		return inlineHTML
	}

	/**
	The HTML of a paragraph without its `<p>` tags. `nil` for another block, and for a paragraph with a class, like a bold label, which is not plain text.
	*/
	fileprivate var paragraphContentHTML: String? {
		guard case .paragraph(let inlineHTML, attributes: "") = self else {
			return nil
		}

		return inlineHTML
	}
}

public struct Heading: Sendable {
	public let level: HeadingLevel

	/**
	The plain text of the heading without the custom ID suffix.
	*/
	public let text: String

	/**
	An authored identifier or a slug generated from the heading text.
	*/
	public enum Identity: Sendable {
		case authored(ElementID)
		case generated(ElementID)

		/**
		The element ID regardless of its origin.
		*/
		public var id: ElementID {
			switch self {
			case .authored(let id), .generated(let id):
				id
			}
		}
	}

	public let identity: Identity

	/**
	The identifier used by links to the heading.
	*/
	public var id: ElementID {
		identity.id
	}

	/**
	Whether the ID is a custom ID (`{#id}`), not a slug of the text, so it does not change with the text.
	*/
	public var hasCustomID: Bool {
		if case .authored = identity {
			return true
		}

		return false
	}

	/**
	The line in the Markdown source, starting at 1. `nil` for headings that are not in the source, like the ones that ``Options/rewrite`` adds.
	*/
	public let line: Int?

	/**
	The values of the directives directly below the heading, by directive type.
	*/
	private var directives = [ObjectIdentifier: any Sendable]()

	/**
	Records a heading with a single source of truth for the ID and its provenance.
	*/
	init(level: HeadingLevel, text: String, identity: Identity, line: Int?) {
		self.level = level
		self.text = text
		self.identity = identity
		self.line = line
	}

	/**
	Decodes metadata under the identity of the type that owns its value.
	*/
	mutating func setDirective<Directive: HeadingDirective>(_ directive: Directive.Type, values: [String]) throws {
		directives[ObjectIdentifier(directive)] = try Directive.decode(values: values)
	}

	/**
	The value of a directive comment directly below the heading, like the platforms of `<!-- @faq.platforms macOS iOS -->`. `nil` when the heading does not have the directive.
	*/
	public subscript<Directive: HeadingDirective>(directive: Directive.Type) -> Directive.Value? {
		directives[ObjectIdentifier(Directive.self)] as? Directive.Value
	}

	/**
	Whether the heading has the directive, like a flag such as `<!-- @faq.general -->`.
	*/
	public func contains<Directive: HeadingDirective>(_ directive: Directive.Type) -> Bool {
		directives[ObjectIdentifier(Directive.self)] != nil
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
		self.init(parsing: source.normalizingWindowsLineEndings, source: file, convertOptions: ConvertOptions(style: .extended, options: options))
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
		let firstBlock = blockChildren.first { !$0.isCommentOnly }

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

extension BlockDirective {
	/**
	The arguments, like `title: "Text"` of `@Feature(title: "Text")`. A mistake in the syntax, like a missing quote, is an error.
	*/
	func parsedArguments() throws(ContentError) -> [DirectiveArgument] {
		var parseErrors = [DirectiveArgumentText.ParseError]()
		let arguments = argumentText.parseNameValueArguments(parseErrors: &parseErrors)

		// One mistake, like a missing quote, gives several parse errors and arguments that are read wrong, so only the first error is reported.
		if let parseError = parseErrors.first {
			throw ContentError(reason: "The arguments of `@\(name)` are invalid: \(parseError.message). Write them like `name: \"Value\"`, with a comma between them.")
		}

		return arguments
	}

	/**
	The arguments decoded as the type, like the renderer of the directive decodes them (``MarkdownDocument/Options/BlockDirectiveRenderer``), for code that reads the Markdown tree without rendering it, like a plain text version of a page or a check of the content (``Markdown/Markup/blockDirectives``).

	```swift
	let trial = try directive.arguments(as: TrialArguments.self)
	```
	*/
	public func arguments<Arguments: Frontmatter>(as type: Arguments.Type) throws(ContentErrors) -> Arguments {
		let arguments: [DirectiveArgument]

		do {
			arguments = try parsedArguments()
		} catch {
			throw ContentErrors([error])
		}

		return try Arguments.decode(directiveArguments: arguments)
	}

	/**
	The blocks of the content, without HTML blocks that are only comments, like a note for the author, which the page does not show.
	*/
	var visibleBlockChildren: [any BlockMarkup] {
		blockChildren.filter { !$0.isCommentOnly }
	}
}

extension Markup {
	/**
	Whether the markup is an HTML block containing only comments and whitespace.
	*/
	public var isCommentOnly: Bool {
		(self as? HTMLBlock)?.rawHTML.isOnlyHTMLComments ?? false
	}

	/**
	The block directives inside the markup, in document order, also the ones inside other directives, like a `@Trial` inside `@Details`.

	```swift
	let trials = Document(parsing: source, options: .parseBlockDirectives).blockDirectives.filter { $0.name == "Trial" }
	```
	*/
	public var blockDirectives: [BlockDirective] {
		descendants(of: BlockDirective.self)
	}

	/**
	The descendants of the kind, in document order, excluding the markup itself. This visits every descendant without pruning containers.
	*/
	public func descendants<Kind: Markup>(of type: Kind.Type) -> [Kind] {
		var result = [Kind]()

		func appendDescendants(of markup: any Markup) {
			for child in markup.children {
				if let match = child as? Kind {
					result.append(match)
				}

				appendDescendants(of: child)
			}
		}

		appendDescendants(of: self)
		return result
	}
}

extension Frontmatter {
	/**
	Decodes the arguments of a block directive. Each argument is a string, so a number or a flag is a `String` property, or a type that decodes from a string.
	*/
	fileprivate static func decode(directiveArguments: [DirectiveArgument]) throws(ContentErrors) -> Self {
		try decode(from: .object(SOML.Object(directiveArguments.map { ($0.name, SOML.Value.string($0.value)) })), root: "arguments")
	}
}

extension DirectiveArgumentText.ParseError {
	/**
	The mistake in the arguments of a block directive, like “a `:` is missing”.
	*/
	fileprivate var message: String {
		switch self {
		case .duplicateArgument(let name, _, _):
			"`\(name)` is given twice"
		case .missingExpectedCharacter(let character, _):
			"a `\(character)` is missing"
		case .unexpectedCharacter(let character, _):
			"a `\(character)` is not expected"
		}
	}
}

extension InlineAttributes {
	/**
	What the attributes of `^[text](attributes)` are.
	*/
	enum Parsed {
		/**
		An inline note, like `^[Spotlight](note: "The search of macOS.")`, with the Markdown of the note.
		*/
		case note(String)

		/**
		Other attributes, like `platform: "macOS"`, for the renderer of the options (``MarkdownDocument/Options/inlineAttributes``).
		*/
		case attributes(SOML.Value)
	}

	/**
	The attributes, parsed and checked in one place, so the renderer and the plain Markdown agree on what a note is. The attributes are an object without the braces, which is a SOML object with them. Attributes with a `note` are a note, which must have only a `note` with text.
	*/
	var parsed: Parsed {
		get throws(ContentErrors) {
			let value: SOML.Value

			do throws(SOML.ParseError) {
				value = try SOML.Value(parsing: "{\(attributes)}")
			} catch {
				throw ContentErrors([ContentError(reason: "\(error.message). Write them like `note: \"…\"` or `platform: \"macOS\"`.")])
			}

			guard value["note"] != nil else {
				return .attributes(value)
			}

			return try .note(InlineNoteAttributes.decode(from: value, root: "attributes").note)
		}
	}
}

/**
The inline attributes of a note, like `^[Spotlight](note: "The search of macOS.")`.
*/
@Frontmatter
private struct InlineNoteAttributes {
	@NonEmpty var note: String
}

extension Markdown.Text {
	/**
	The text with each keyboard shortcut, like `++Command+K++`, as its keys, like `Command+K`.
	*/
	var plainString: String {
		string[...].keyboardShortcutParts.map { part in
			switch part {
			case .text(let text):
				String(text)
			case .shortcut(let text, let punctuation):
				String(text) + punctuation
			}
		}.joined()
	}
}

extension Substring {
	/**
	A fragment of text or a complete keyboard shortcut with the closing punctuation that stays on its line.
	*/
	enum KeyboardShortcutPart {
		case text(Substring)
		case shortcut(text: Substring, trailingPunctuation: Substring)
	}

	/**
	The punctuation that must not start a line, like the comma after a keyboard shortcut.
	*/
	private static let closingShortcutPunctuation: Set<Character> = [",", ".", ";", ":", "!", "?", ")", "”", "’"]

	// The rest of the keys is lazy too, so a shortcut of one key, like `++Q++`, ends at its own plus signs, not at the ones of the next shortcut on the line.
	nonisolated(unsafe) private static let keyboardShortcut = /\+\+(\S(?:[^\n]*?\S)??)\+\+/

	/**
	The text in parts: plain text, and the keys of each keyboard shortcut written as `++Command+K++`. The `++` must not touch a letter, a digit, or another `+`, so `C++` stays text.
	*/
	var keyboardShortcutParts: [KeyboardShortcutPart] {
		// Most text has no shortcut, and the search is slow.
		guard contains("++") else {
			return [.text(self)]
		}

		var parts = [KeyboardShortcutPart]()
		var remainder = self

		while let match = remainder.firstMatch(of: Self.keyboardShortcut) {
			let before = remainder[..<match.range.lowerBound].last
			let after = remainder[match.range.upperBound...].first

			guard
				before.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true,
				after.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true
			else {
				// Only the opening `++` is text, as the closing one can open a shortcut.
				let openingEnd = remainder.index(match.range.lowerBound, offsetBy: 2)
				parts.append(.text(remainder[..<openingEnd]))
				remainder = remainder[openingEnd...]
				continue
			}

			let text = remainder[..<match.range.lowerBound]
			if !text.isEmpty {
				parts.append(.text(text))
			}

			let afterShortcut = remainder[match.range.upperBound...]
			let punctuation = afterShortcut.prefix { Self.closingShortcutPunctuation.contains($0) }
			parts.append(.shortcut(text: match.1, trailingPunctuation: punctuation))
			remainder = afterShortcut.dropFirst(punctuation.count)
		}

		if !remainder.isEmpty {
			parts.append(.text(remainder))
		}

		return parts
	}

	/**
	Whether the text has a `++` that starts a keyboard shortcut without its closing `++`, like in `Press ++Command+N to …`: a `++` that does not touch a letter, a digit, or another `+` before it, with a key right after it. So `C++` and `a ++ b` are text. For the plain parts of ``keyboardShortcutParts``. Limitation: a `++` before a word in plain text, like the increment `++index`, is reported too. Write it as code.
	*/
	var hasUnclosedKeyboardShortcut: Bool {
		ranges(of: "++").contains { range in
			let before = self[..<range.lowerBound].last
			let after = self[range.upperBound...].first

			guard
				let after,
				!after.isWhitespace,
				after != "+"
			else {
				return false
			}

			return before.map { !$0.isLetter && !$0.isNumber && $0 != "+" } ?? true
		}
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
			.replacing("‘", with: "'")
			.replacing("’", with: "'")
			.replacing("“", with: "\"")
			.replacing("”", with: "\"")
	}

	fileprivate var isOnlyHTMLComments: Bool {
		removingHTMLComments.allSatisfy(\.isWhitespace)
	}
}

extension Markup {
	/**
	The text content: text, inline code, and the text inside emphasis and links. HTML tags are left out.
	*/
	func plainText(includingImageDescriptions: Bool) -> String {
		switch self {
		// A keyboard shortcut in text, like `++Command+K++`, is its keys.
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
		MarkdownContent(blocks: blocks[...], trailingHTML: popoversHTML, resources: resources)
	}

	/**
	The ``inlineHTML`` as content of a page.
	*/
	public var inlineContent: MarkdownContent {
		MarkdownContent(html: inlineHTML, resources: resources)
	}

	/**
	The first paragraph without the `<p>` tags, and the content after it, so a page can show the introduction apart from the rest, like at the top of an app page. `nil` when the document does not start with a paragraph. HTML comments before the paragraph do not count, as the renderer leaves out comments. Each part adds the styles and scripts of the whole document, so either part can be shown alone.
	*/
	public var contentSeparatingIntroduction: (introduction: MarkdownContent, remainder: MarkdownContent)? {
		guard introduction != nil else {
			return nil
		}

		return content.separatingIntroduction
	}

	/**
	The content before the level 2 heading with the ID, and the content from that heading on (``MarkdownContent/separated(beforeHeading:)``).
	*/
	public func contentSeparated(beforeHeading id: ElementID) -> (before: MarkdownContent, after: MarkdownContent)? {
		content.separated(beforeHeading: id)
	}

	/**
	The content separated before each level 2 heading with one of the IDs (``MarkdownContent/separated(beforeHeadings:)``).
	*/
	public func contentSeparated(beforeHeadings ids: [ElementID]) -> [MarkdownContent]? {
		content.separated(beforeHeadings: ids)
	}
}

/**
Rendered Markdown as content of a page. It adds the styles and scripts that the Markdown uses, like those of its block directives, to the page that shows it, like a preference in SwiftUI, as the Markdown renders before the page.

It keeps the top-level blocks of the document (``MarkdownDocument/blocks``), so a page can split it by its blocks, not by searching the HTML. Each part adds the styles and scripts of the whole document, so any part can be shown alone.
*/
public struct MarkdownContent: HTML, Sendable {
	let blocks: ArraySlice<MarkdownDocument.Block>

	/**
	The HTML after the blocks, like the popovers of the footnotes, which stays with the last part when the content is split.
	*/
	let trailingHTML: String

	let resources: PageResources

	init(blocks: ArraySlice<MarkdownDocument.Block>, trailingHTML: String, resources: PageResources) {
		self.blocks = blocks
		self.trailingHTML = trailingHTML
		self.resources = resources
	}

	/**
	Content that is not split, like a short inline text.
	*/
	init(html: String, resources: PageResources) {
		self.init(blocks: [.other(html)], trailingHTML: "", resources: resources)
	}

	public var html: String {
		blocks.map(\.html).joined() + trailingHTML
	}

	public var body: HTMLRaw {
		PageResources.current?.include(resources)
		return HTMLRaw(html)
	}

	/**
	The first paragraph without the `<p>` tags, and the content after it. `nil` when the first block that shows something is not a paragraph.
	*/
	var separatingIntroduction: (introduction: Self, remainder: Self)? {
		guard
			let index = blocks.firstIndex(where: { !$0.isEmpty }),
			let introduction = blocks[index].paragraphContentHTML
		else {
			return nil
		}

		return (Self(html: introduction, resources: resources), Self(blocks: blocks[(index + 1)...], trailingHTML: trailingHTML, resources: resources))
	}

	/**
	The content before the level 2 heading with the ID, and the content from that heading on, so a page can show something between them, like the reviews of an app after its description. `nil` when the content has no level 2 heading with the ID at the top level. A heading inside other markup, like a block directive, is not a place to split.
	*/
	public func separated(beforeHeading id: ElementID) -> (before: Self, after: Self)? {
		guard let index = blocks.firstIndex(where: { $0.kind == .heading(level: .h2, id: id) }) else {
			return nil
		}

		return split(at: index)
	}

	/**
	The content before the first level 2 heading at the top level, like the description of an app before its first section, and the content from that heading on. `nil` without one.
	*/
	public var separatedBeforeFirstSection: (before: Self, after: Self)? {
		guard let index = blocks.firstIndex(where: { $0.headingLevel == .h2 }) else {
			return nil
		}

		return split(at: index)
	}

	/**
	The content separated before each level 2 heading with one of the IDs, in their order, so a page can show something between several sections, like the numbers and the projects on the about page. It has one part more than the IDs: the content before the first heading, and the content from each heading to the next. `nil` when one of the IDs has no level 2 heading at the top level, or the headings are in another order.
	*/
	public func separated(beforeHeadings ids: [ElementID]) -> [Self]? {
		var parts = [Self]()
		var remainder = self

		for id in ids {
			guard let index = remainder.blocks.firstIndex(where: { $0.kind == .heading(level: .h2, id: id) }) else {
				return nil
			}

			let (before, after) = remainder.split(at: index)
			parts.append(before)
			remainder = after
		}

		return parts + [remainder]
	}

	/**
	Splits without losing collected styles or duplicating trailing popovers, which belong only to the last part of a document.
	*/
	private func split(at index: ArraySlice<MarkdownDocument.Block>.Index) -> (before: Self, after: Self) {
		(Self(blocks: blocks[..<index], trailingHTML: "", resources: resources), Self(blocks: blocks[index...], trailingHTML: trailingHTML, resources: resources))
	}
}

extension Markdown.Link {
	/**
	Creates a Markdown link from a typed destination and a plain-text label.
	*/
	public init(destination: LinkDestination, text: String) {
		self.init(destination: destination.description, Markdown.Text(text))
	}
}
