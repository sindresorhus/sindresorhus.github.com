import Markdown

/**
Rewrites Markdown with the syntax of the site as plain CommonMark, for readers that get the Markdown instead of the page, like AI assistants that read `llms-full.txt`.

- A keyboard shortcut, like `++Command+K++`, is its keys, `Command+K`.
- A heading has no custom ID (`{#id}`).
- HTML comments, like heading directives (`<!-- @faq.keywords … -->`), are removed, also in text.
- An inline note, like `^[Spotlight](note: "The search of macOS.")`, is its text with the note in parentheses.
- The text of other inline attributes, like a platform badge, is in parentheses, as the page shows it apart from the text around it.
- A block directive is the blocks that `blockDirective` gives for it, which are rewritten too, so a directive can contain another one.

```swift
var rewriter = PlainMarkdownRewriter { directive in
	Array(directive.blockChildren)
}

let markdown = rewriter.visit(document)?.format()
```
*/
public struct PlainMarkdownRewriter: MarkupRewriter {
	private let blockDirective: (BlockDirective) -> [any BlockMarkup]
	private let linkDestination: ((String) -> String)?

	/**
	Whether the rewriter changed anything since it was created, so a block without the syntax of the site can keep its source.
	*/
	public private(set) var didChange = false

	/**
	- Parameter linkDestination: Resolves parsed link and image destinations, without interpreting text that only looks like a link.
	- Parameter blockDirective: The blocks of a block directive, like a heading with the title and the content of the directive.
	*/
	public init(linkDestination: ((String) -> String)? = nil, blockDirective: @escaping (BlockDirective) -> [any BlockMarkup]) {
		self.blockDirective = blockDirective
		self.linkDestination = linkDestination
	}

	/**
	Rewrites the children, and replaces block directives and inline attributes, which can be several blocks or inline elements. A node is only built again when a child changed, as most of a document has none of the syntax of the site.
	*/
	public mutating func defaultVisit(_ markup: any Markup) -> (any Markup)? {
		let didChangeBefore = didChange
		didChange = false
		let children = markup.children.flatMap { rewritten($0) }

		guard didChange else {
			didChange = didChangeBefore
			return markup
		}

		return markup.withUncheckedChildren(children)
	}

	private mutating func rewritten(_ markup: any Markup) -> [any Markup] {
		switch markup {
		case let directive as BlockDirective:
			didChange = true
			return blockDirective(directive).flatMap { rewritten($0) }
		case let attributes as InlineAttributes:
			didChange = true
			return inlineMarkup(of: attributes)
		default:
			return visit(markup).map { [$0] } ?? []
		}
	}

	public mutating func visitText(_ text: Markdown.Text) -> (any Markup)? {
		let string = text.plainString

		guard string != text.string else {
			return text
		}

		didChange = true
		return Markdown.Text(string)
	}

	public mutating func visitHeading(_ heading: Markdown.Heading) -> (any Markup)? {
		guard let heading = defaultVisit(heading) as? Markdown.Heading else {
			return nil
		}

		let content = Array(heading.inlineChildren)

		guard
			let lastText = content.last as? Markdown.Text,
			lastText.string.removingCustomHeadingID != lastText.string
		else {
			return heading
		}

		didChange = true
		return Markdown.Heading(level: heading.level, content.dropLast() + [Markdown.Text(lastText.string.removingCustomHeadingID)])
	}

	/**
	Rewrites a parsed link destination and its children while preserving an unchanged node’s source.
	*/
	public mutating func visitLink(_ link: Markdown.Link) -> (any Markup)? {
		guard var link = defaultVisit(link) as? Markdown.Link else {
			return nil
		}

		if
			let destination = link.destination,
			let resolved = linkDestination?(destination),
			resolved != destination
		{
			didChange = true
			link.destination = resolved
		}

		return link
	}

	/**
	Rewrites a parsed image source with the same resolution rule as a link.
	*/
	public mutating func visitImage(_ image: Markdown.Image) -> (any Markup)? {
		guard var image = defaultVisit(image) as? Markdown.Image else {
			return nil
		}

		if
			let source = image.source,
			let resolved = linkDestination?(source),
			resolved != source
		{
			didChange = true
			image.source = resolved
		}

		return image
	}

	public mutating func visitHTMLBlock(_ html: HTMLBlock) -> (any Markup)? {
		let rawHTML = html.rawHTML.removingHTMLComments

		guard rawHTML != html.rawHTML else {
			return html
		}

		didChange = true
		return rawHTML.allSatisfy(\.isWhitespace) ? nil : HTMLBlock(rawHTML)
	}

	public mutating func visitInlineHTML(_ html: InlineHTML) -> (any Markup)? {
		let rawHTML = html.rawHTML.removingHTMLComments

		guard rawHTML != html.rawHTML else {
			return html
		}

		didChange = true
		return rawHTML.isEmpty ? nil : InlineHTML(rawHTML)
	}

	/**
	The text of an inline note with the note in parentheses, or the text of other attributes in parentheses. Limitation: only the paragraphs of a note are kept, as a note is short text in a popover.
	*/
	private mutating func inlineMarkup(of attributes: InlineAttributes) -> [any Markup] {
		let text = attributes.children.flatMap { rewritten($0) }

		// Invalid attributes are a problem of the renderer, which fails the build.
		guard case .note(let note)? = try? attributes.parsed else {
			return [Markdown.Text("(")] + text + [Markdown.Text(")")]
		}

		// The note is Markdown, and can have several paragraphs.
		let noteParagraphs = Document(parsing: note).children
			.compactMap { $0 as? Paragraph }
			.compactMap { visit($0) }
			.map { Array($0.children) }

		let separator: [any Markup] = [Markdown.Text(" ")]
		return text + [Markdown.Text(" (")] + Array(noteParagraphs.joined(separator: separator)) + [Markdown.Text(")")]
	}
}
