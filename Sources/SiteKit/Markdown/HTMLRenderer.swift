import Foundation
import Markdown
import SOML

/**
Renders a Markdown tree as HTML, like GitHub-flavored Markdown renderers do.
*/
struct HTMLRenderer: MarkupWalker {
	let style: MarkdownDocument.Style
	let options: MarkdownDocument.Options
	private(set) var html = ""
	private(set) var headings = [Heading]()

	/**
	The numbers of the GitHub-style footnotes, by ID, in the order of their first reference. The parser reads the references (`[^id]`) and the definitions (`[^id]: Text`), like GitHub, and the renderer numbers the references, and shows each definition in a popover, which its numbered reference opens. Unreferenced definitions are dropped.
	*/
	private var footnoteNumbers = [String: Int]()

	/**
	A reference to a footnote, like `[^note]`, with the ID. The parser turns a reference with a definition into a ``FootnoteReference``, so one in the text has no definition.
	*/
	nonisolated(unsafe) private static let footnoteReferencePattern = /\[\^([^\]\s]+)\]/

	/**
	The popovers of the footnotes and the inline notes, which the document adds at the end, as they can have paragraphs, which a paragraph cannot contain.
	*/
	private(set) var popovers = [String]()

	/**
	The footnote definitions of the document, by ID. Each is rendered in a popover at its first reference.
	*/
	private let footnoteDefinitions: [String: FootnoteDefinition]

	/**
	The IDs of the footnote definitions that the renderer visited, to find a repeated one.
	*/
	private var definedFootnoteIDs = Set<String>()

	private(set) var problems = [ContentError]()
	private(set) var links = [MarkdownDocument.Link]()
	private var slugger = HeadingSlugger()
	private var tableColumnAlignments = [Table.ColumnAlignment?]()

	/**
	How many tables have each region name, so each name is unique.
	*/
	private var tableLabelCounts = [String: Int]()

	/**
	How many links the renderer is inside, and the summary of a collapsible section and the text of an inline note, which cannot have links either. A link inside them is only its text, as nested links are invalid HTML. Limitation: raw `<a>` tags are not counted, so a link or bare URL in the text of one is a nested link. Use Markdown links.
	*/
	private var linkDepth = 0

	/**
	How many of the next nodes are already rendered: the text and the end tag of a raw `<kbd>`, which are rendered as keys with the start tag.
	*/
	private var renderedKeyboardNodes = 0

	/**
	Where the source is in its file, which gives the lines of its problems and links.
	*/
	enum Origin {
		/**
		The Markdown of the document, or of a part of it, like a footnote definition, after the given number of lines of the file.
		*/
		case document(lineOffset: Int)

		/**
		The Markdown of an inline note, which is one line of the file, so the lines of its Markdown are not lines of the file.
		*/
		case inlineNote(line: Int?)
	}

	private let origin: Origin

	init(style: MarkdownDocument.Style, options: MarkdownDocument.Options = .init(), footnoteDefinitions: [String: FootnoteDefinition] = [:], origin: Origin = .document(lineOffset: 0)) {
		self.style = style
		self.options = options
		self.footnoteDefinitions = footnoteDefinitions
		self.origin = origin
	}

	/**
	The line where the markup starts, in the file of the source. `nil` for markup that a rewrite adds from another file, which was parsed with the URL of its file as its source (``MarkdownDocument/Options/rewrite``).
	*/
	private func line(of markup: any Markup) -> Int? {
		switch origin {
		case .document(let lineOffset):
			markup.range.flatMap { $0.lowerBound.source == nil ? $0.lowerBound.line + lineOffset : nil }
		case .inlineNote(let line):
			line
		}
	}

	/**
	Whether the source is the Markdown of an inline note, which cannot have footnotes or other notes.
	*/
	private var isInlineNote: Bool {
		guard case .inlineNote = origin else {
			return false
		}

		return true
	}

	private var theme: MarkdownTheme {
		options.theme
	}

	// MARK: Blocks

	mutating func visitDocument(_ document: Document) {
		guard
			style == .extended,
			let sections = options.collapsibleSections
		else {
			descendInto(document)
			return
		}

		let blocks = Array(document.blockChildren)
		var isInSections = sections.startHeadingID == nil
		var index = 0

		func sectionHeading(at index: Int) -> Markdown.Heading? {
			guard
				isInSections,
				index < blocks.count,
				let heading = blocks[index] as? Markdown.Heading,
				heading.level == sections.level
			else {
				return nil
			}

			return heading
		}

		while index < blocks.count {
			guard sectionHeading(at: index) != nil else {
				visit(blocks[index])

				// When the sections follow a heading, they start after it, and end at the next heading with a lower level.
				if
					let heading = blocks[index] as? Markdown.Heading,
					let startHeadingID = sections.startHeadingID
				{
					if headings.last?.id == startHeadingID {
						isInSections = true
					} else if heading.level < sections.level {
						isInSections = false
					}
				}

				index += 1
				continue
			}

			// The sections up to the next heading with a lower level are one group. Each section ends at the next heading with its level or a lower one.
			html += "<div\(theme.classAttribute(.collapsibleSections))>\n"

			while let heading = sectionHeading(at: index) {
				let end = blocks[(index + 1)...].firstIndex { ($0 as? Markdown.Heading).map { $0.level <= sections.level } ?? false } ?? blocks.count
				renderCollapsibleSection(heading, content: blocks[(index + 1)..<end], name: sections.name)
				index = end
			}

			if let moreLink = sections.moreLink {
				html += theme.collapsibleMoreLink(moreLink) + "\n"
			}

			html += "</div>\n"
		}
	}

	/**
	Renders the heading and its content as a collapsible section. The heading stays a heading inside the summary, so it is in the outline of the page.
	*/
	private mutating func renderCollapsibleSection(_ heading: Markdown.Heading, content: ArraySlice<any BlockMarkup>, name: String?) {
		let recorded = recordHeading(heading)

		// A summary is a button, so a link in it is invalid, and a click would open the link instead of the section. The links of the heading are only their text, and a problem, as the link would be lost.
		if heading.containsLink {
			reportProblem("The heading of a collapsible section cannot have a link, as it is the button that opens the section. Put the link in the text below it.", line: line(of: heading))
		}

		let titleHTML = capturingHTML {
			$0.linkDepth += 1
			$0.renderInlineChildren(of: heading, removingCustomID: true)
			$0.linkDepth -= 1
		}

		let contentHTML = capturingHTML { renderer in
			for block in content {
				renderer.visit(block)
			}
		}

		let section = theme.collapsibleSection(id: recorded.id, name: name, headingLevel: heading.level, titleHTML: titleHTML, contentHTML: "\n" + contentHTML)

		guard options.addsHeadingAnchors else {
			html += section + "\n"
			return
		}

		html += "<div\(theme.classAttribute(.anchoredSection))>\(theme.headingAnchor(for: recorded))\(section)</div>\n"
	}

	mutating func visitHeading(_ heading: Markdown.Heading) {
		guard style == .extended else {
			html += "<h\(heading.level)>"
			renderInlineChildren(of: heading)
			html += "</h\(heading.level)>\n"
			return
		}

		let recorded = recordHeading(heading)
		let hasAnchor = options.addsHeadingAnchors && (2...4).contains(heading.level)
		// The link is inside the heading, so the heading is named by its text, as the name of the link would otherwise be part of the name of the heading, like “Tips Copy link to section: Tips”.
		let attributes = hasAnchor ? #"\#(theme.classAttribute(.anchoredHeading)) aria-label="\#(recorded.text.escapedForHTML)""# : ""
		html += #"<h\#(heading.level) id="\#(recorded.id.escapedForHTML)"\#(attributes)>"#
		renderInlineChildren(of: heading, removingCustomID: true)

		if hasAnchor {
			html += theme.headingAnchor(for: recorded)
		}

		html += "</h\(heading.level)>\n"
	}

	/**
	Adds the heading to the list of headings and returns it. Its ID is the custom ID (`{#id}`), or a slug of the text. An ID that another heading already has is a problem, like a custom ID that is the slug of another heading. The slugs do not change to avoid it, so the URLs of the sections keep working.
	*/
	private mutating func recordHeading(_ heading: Markdown.Heading) -> Heading {
		let (text, customID) = heading.plainTextAndCustomID
		let id = customID ?? slugger.slug(for: text)

		if headings.contains(where: { $0.id == id }) {
			reportProblem("The heading ID `\(id)` is already the ID of another heading, so links to it are ambiguous. Give one of the headings another custom ID, like `{#\(id)-2}`.", line: line(of: heading))
		}

		let recorded = Heading(level: heading.level, text: text, id: id, line: line(of: heading))
		headings.append(recorded)
		return recorded
	}

	mutating func visitParagraph(_ paragraph: Paragraph) {
		// The items of a tight list, like CommonMark, have no paragraphs around their text.
		guard
			let listItem = paragraph.parent as? ListItem,
			listItem.isInTightList
		else {
			let isLabel = style == .extended && paragraph.parent is ListItem == false && paragraph.childCount == 1 && paragraph.child(at: 0) is Strong
			html += isLabel ? "<p\(theme.classAttribute(.boldLabel))>" : "<p>"
			renderParagraphContent(paragraph)
			html += "</p>\n"
			return
		}

		renderParagraphContent(paragraph)

		if paragraph.indexInParent < listItem.childCount - 1 {
			html += "\n"
		}
	}

	/**
	Renders the inline content. In a list item, a line that starts with `: ` is a subtitle, and a line that starts with `:: ` is a description.
	*/
	private mutating func renderParagraphContent(_ paragraph: Paragraph) {
		guard
			style == .extended,
			paragraph.parent is ListItem
		else {
			descendInto(paragraph)
			return
		}

		var openSpan = false
		var isLineStart = false

		for child in paragraph.children {
			if child is SoftBreak || child is LineBreak {
				if openSpan {
					html += "</span>"
					openSpan = false
				}

				visit(child)
				isLineStart = true
				continue
			}

			if
				isLineStart,
				let text = child as? Text,
				let (element, rest) = Self.listLineMarker(text.string)
			{
				html += "<span\(theme.classAttribute(element))>"
				openSpan = true
				renderTextCheckingFootnotes(rest, of: text)
			} else {
				visit(child)
			}

			isLineStart = false
		}

		if openSpan {
			html += "</span>"
		}
	}

	/**
	The element of a `: ` (subtitle) or `:: ` (description) line, and the text after the marker.
	*/
	private static func listLineMarker(_ text: String) -> (MarkdownElement, Substring)? {
		if text.hasPrefix(":: ") {
			return (.listDescription, text.dropFirst(3))
		}

		if text.hasPrefix(": ") {
			return (.listSubtitle, text.dropFirst(2))
		}

		return nil
	}

	mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
		if
			style == .extended,
			renderAlert(blockQuote)
		{
			return
		}

		html += "<blockquote>\n"
		descendInto(blockQuote)
		html += "</blockquote>\n"
	}

	mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
		// The language is the first word of the info string, like GitHub.
		let language = codeBlock.language?.split(whereSeparator: \.isWhitespace).first.map(String.init)

		if let render = options.codeBlock {
			html += render(codeBlock.code, language) + "\n"
			return
		}

		let languageClass = language.map { #" class="language-\#($0.escapedForHTML)""# } ?? ""
		// Focusable, so keyboard users can scroll wide code.
		html += #"<pre tabindex="0"><code\#(languageClass)>\#(codeBlock.code.escapedForHTML)</code></pre>"# + "\n"
	}

	mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
		if style == .extended {
			readDirectives(in: htmlBlock)
		}

		// Comments are notes for the author, like drafts and heading directives, so they are not published.
		var rawHTML = htmlBlock.rawHTML.removingHTMLComments

		// An unclosed comment would hide the rest of the page in the browser, including the footer of the site.
		if let commentStart = rawHTML.firstRange(of: "<!--") {
			reportProblem("The HTML comment is not closed. End it with `-->`.", line: line(of: htmlBlock))
			rawHTML = String(rawHTML[..<commentStart.lowerBound])
		}

		guard !rawHTML.allSatisfy(\.isWhitespace) else {
			return
		}

		// The `<kbd>` elements of raw HTML are split into keys too. Like the HTML, they are not parsed, so a regex finds them.
		if style == .extended {
			rawHTML = rawHTML.separatingKeyboardKeys(theme: theme)
		}

		// A table in raw HTML gets the same container as a Markdown table. Limitation: a raw table with a blank line inside is several HTML blocks, so it gets no container.
		let trimmedHTML = rawHTML.trimmingCharacters(in: .whitespacesAndNewlines)

		if
			style == .extended,
			trimmedHTML.hasPrefix("<table>") || trimmedHTML.hasPrefix("<table "),
			trimmedHTML.hasSuffix("</table>")
		{
			html += theme.tableContainer(label: tableLabel(), tableHTML: rawHTML) + "\n"
		} else {
			html += style == .releaseNotes ? rawHTML.escapedForHTML : rawHTML
		}
	}

	mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
		html += "<hr>\n"
	}

	mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
		html += "<ul>\n"
		descendInto(unorderedList)
		html += "</ul>\n"
	}

	mutating func visitOrderedList(_ orderedList: OrderedList) {
		html += orderedList.startIndex == 1 ? "<ol>\n" : #"<ol start="\#(orderedList.startIndex)">"# + "\n"
		descendInto(orderedList)
		html += "</ol>\n"
	}

	mutating func visitListItem(_ listItem: ListItem) {
		html += "<li>"

		switch listItem.checkbox {
		case .checked:
			html += #"<input type="checkbox" disabled checked> "#
		case .unchecked:
			html += #"<input type="checkbox" disabled> "#
		case nil:
			break
		}

		if !listItem.isInTightList {
			html += "\n"
		}

		descendInto(listItem)
		html += "</li>\n"
	}

	mutating func visitTable(_ table: Table) {
		tableColumnAlignments = table.columnAlignments
		let label = tableLabel()

		let tableHTML = capturingHTML {
			$0.descendInto(table)
		}

		html += theme.tableContainer(label: label, tableHTML: "<table>\n" + tableHTML + "</table>\n") + "\n"
	}

	/**
	Every table is a region, so its container can be scrolled with the keyboard. Tables have no caption to name them, so the region is named after the heading above it, and a second table under the same heading gets a number, as each region needs a unique name. A table without a heading with text above it is named “Table”.
	*/
	private mutating func tableLabel() -> String {
		let heading = headings.last?.text ?? ""
		let label = heading.isEmpty ? "Table" : heading
		let count = tableLabelCounts[label, default: 0] + 1
		tableLabelCounts[label] = count
		return count == 1 ? label : "\(label) (\(count))"
	}

	mutating func visitTableHead(_ tableHead: Table.Head) {
		html += "<thead><tr>\n"
		descendInto(tableHead)
		html += "</tr></thead>\n"
	}

	mutating func visitTableBody(_ tableBody: Table.Body) {
		guard !tableBody.isEmpty else {
			return
		}

		html += "<tbody>\n"
		descendInto(tableBody)
		html += "</tbody>\n"
	}

	mutating func visitTableRow(_ tableRow: Table.Row) {
		html += "<tr>\n"
		descendInto(tableRow)
		html += "</tr>\n"
	}

	mutating func visitTableCell(_ tableCell: Table.Cell) {
		// A cell that a span covers has a span of 0, and no cell of its own, but it still counts as a column.
		guard
			tableCell.colspan > 0,
			tableCell.rowspan > 0
		else {
			return
		}

		let tag = tableCell.parent is Table.Head ? "th" : "td"
		let column = tableCell.indexInParent
		var attributes = ""

		if
			tableColumnAlignments.indices.contains(column),
			let alignment = tableColumnAlignments[column]
		{
			attributes += #" align="\#(alignment)""#
		}

		if tableCell.rowspan > 1 {
			attributes += #" rowspan="\#(tableCell.rowspan)""#
		}

		if tableCell.colspan > 1 {
			attributes += #" colspan="\#(tableCell.colspan)""#
		}

		html += "<\(tag)\(attributes)>"
		descendInto(tableCell)
		html += "</\(tag)>\n"
	}

	// MARK: Inlines

	mutating func visitText(_ text: Text) {
		guard renderedKeyboardNodes == 0 else {
			renderedKeyboardNodes -= 1
			return
		}

		renderTextCheckingFootnotes(text.string[...], of: text)
	}

	/**
	Renders part of the string of a text node. A footnote reference with a definition is a ``FootnoteReference``, so one in the text, like `[^note]`, has no definition, which is reported.
	*/
	private mutating func renderTextCheckingFootnotes(_ string: Substring, of text: Text) {
		if
			style == .extended,
			string.contains("[^")
		{
			// The parser reads the content of a block directive on its own, so a definition outside the directive is not found, and the parser leaves out a definition without a reference.
			let isInBlockDirective = sequence(first: text as any Markup, next: \.parent).contains { $0 is BlockDirective }

			for match in string.matches(of: Self.footnoteReferencePattern) {
				// A note is parsed on its own, so the definitions of the document are not found.
				if isInlineNote {
					reportProblem("The footnote `[^\(match.1)]` is inside a note, which cannot have footnotes.", line: line(of: text))
				} else if isInBlockDirective {
					reportProblem("The footnote `[^\(match.1)]` has no definition in its block directive. A footnote in a block directive, like `@Tips`, needs its definition, like `[^\(match.1)]: The note.`, inside the same directive.", line: line(of: text))
				} else {
					reportProblem("The footnote `[^\(match.1)]` has no definition, like `[^\(match.1)]: The note.` If it is not a footnote, write it as code. The parser reads the text between block directives on its own, so a definition after a block directive, like at the end of the file, is only for the footnotes after that directive. A definition inside a block directive is only for the footnotes in that directive.", line: line(of: text))
				}
			}
		}

		renderText(string)
	}

	mutating func visitFootnoteReference(_ footnoteReference: FootnoteReference) {
		let id = footnoteReference.footnoteID

		// A footnote reference is a button, and it must not be inside a link, the heading of a collapsible section, or the text of a note.
		guard linkDepth == 0 else {
			reportProblem("The footnote `[^\(id)]` is inside a link, the heading of a collapsible section, or the text of a note, which cannot have links. Put it after the link or the note, or in the text below the heading.", line: line(of: footnoteReference))
			renderText("[^\(id)]")
			return
		}

		// The definitions and notes are rendered on their own, without the definitions of the document.
		guard let referenceHTML = self.footnoteReference(id: id) else {
			reportProblem("The footnote `[^\(id)]` is inside another footnote or a note, which cannot have footnotes.", line: line(of: footnoteReference))
			renderText("[^\(id)]")
			return
		}

		html += referenceHTML
	}

	/**
	The definitions are rendered in popovers at the end, not where they are. The parser reads the parts between block directives on their own, so two parts can define the same ID, and the references of both would show the first definition, which is a problem.
	*/
	mutating func visitFootnoteDefinition(_ footnoteDefinition: FootnoteDefinition) {
		let id = footnoteDefinition.footnoteID

		// The first definition of an ID is not a problem.
		guard !definedFootnoteIDs.insert(id).inserted else {
			return
		}

		reportProblem("The footnote `[^\(id)]` is already defined, so its references would show the first definition. Give one of them another ID.", line: line(of: footnoteDefinition))
	}

	private mutating func renderText(_ text: Substring) {
		// Keyboard shortcuts written as `++Cmd+K++` become one `<kbd>` per key.
		guard style == .extended else {
			renderPlainText(text)
			return
		}

		for part in text.keyboardShortcutParts {
			if part.isShortcut {
				html += keyboardShortcutHTML(String(part.text))
			} else {
				renderPlainText(part.text)
			}
		}
	}

	private mutating func renderPlainText(_ text: Substring) {
		html += String(text).escapedForHTML
	}

	/**
	The numbered button that opens a footnote, or `nil` when the footnote is not defined. The first reference adds the popover with the definition, which resolves and reports its links like the text.
	*/
	private mutating func footnoteReference(id: String) -> String? {
		guard let definition = footnoteDefinitions[id] else {
			return nil
		}

		// A footnote that is not referenced yet gets the next number.
		let number = footnoteNumbers[id, default: footnoteNumbers.count + 1]
		let popoverID = Self.footnotePopoverID(number: number)

		if footnoteNumbers[id] == nil {
			footnoteNumbers[id] = number
			addPopover(id: popoverID, element: .footnotePopover, content: definition.children, origin: origin)
		}

		return theme.footnoteReference(number: number, popoverID: popoverID)
	}

	/**
	The ID of the popover with a footnote. The numbers of a document are unique, so the ID is from the number, like `user-content-fn-1`, which is the ID of GitHub without the name of the footnote. Limitation: two documents on one page with footnotes give their first footnotes the same ID.
	*/
	private static func footnotePopoverID(number: Int) -> String {
		"user-content-fn-\(number)"
	}

	/**
	Adds a popover at the end of the document with Markdown inside the document, like the definition of a footnote or an inline note. It renders with the options for nested Markdown (``MarkdownDocument/Options/forNestedMarkdown``), and its problems, links, and popovers are those of the document. A heading in it is a problem, as its ID could be the same as another ID of the page.
	*/
	private mutating func addPopover(id: String, element: MarkdownElement, content: some Sequence<any Markup>, origin: Origin) {
		var renderer = HTMLRenderer(style: style, options: options.forNestedMarkdown, origin: origin)

		for block in content {
			renderer.visit(block)
		}

		problems += renderer.problems
		links += renderer.links

		for heading in renderer.headings {
			reportProblem("A footnote or a note cannot have headings, like “\(heading.text)”, as their IDs could be the same as other IDs of the page.", line: heading.line)
		}

		popovers.append(theme.popover(id: id, element: element, contentHTML: renderer.html) + "\n")
		popovers += renderer.popovers
	}

	mutating func visitInlineCode(_ inlineCode: InlineCode) {
		html += "<code>\(inlineCode.code.escapedForHTML)</code>"
	}

	mutating func visitEmphasis(_ emphasis: Emphasis) {
		html += "<em>"
		descendInto(emphasis)
		html += "</em>"
	}

	mutating func visitStrong(_ strong: Strong) {
		html += "<strong>"
		descendInto(strong)
		html += "</strong>"
	}

	mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
		html += "<del>"
		descendInto(strikethrough)
		html += "</del>"
	}

	mutating func visitLink(_ link: Link) {
		let destination = link.destination ?? ""

		// An unsafe link of release notes, like `javascript:`, is only its text too.
		guard
			linkDepth == 0,
			style == .extended || destination.isSafeReleaseNotesDestination(isImage: false)
		else {
			descendInto(link)
			return
		}

		let title = link.title.map { #" title="\#($0.escapedForHTML)""# } ?? ""
		html += #"<a href="\#(resolvedDestination(destination, of: link).escapedForHTML)"\#(title)>"#
		linkDepth += 1
		descendInto(link)
		linkDepth -= 1
		html += "</a>"
	}

	mutating func visitImage(_ image: Image) {
		let source = resolvedDestination(image.source ?? "", of: image)
		let description = image.plainText(includingImageDescriptions: true)

		if
			style == .extended,
			description.allSatisfy(\.isWhitespace)
		{
			reportProblem("The image `\(source)` has no description (alt text). Describe it, like `![Screenshot of the settings](…)`.", line: line(of: image))
		}

		html += #"<img src="\#(source.escapedForHTML)" alt="\#(description.escapedForHTML)""#

		if let size = options.imageSize?(source) {
			html += #" width="\#(size.width)" height="\#(size.height)""#
		}

		if let title = image.title {
			html += #" title="\#(title.escapedForHTML)""#
		}

		html += ">"
	}

	/**
	The destination after ``MarkdownDocument/Options/resolveLink``, recorded in the links. A destination that cannot be resolved is a problem. An unsafe image source of release notes is empty.
	*/
	private mutating func resolvedDestination(_ destination: String, of markup: any Markup) -> String {
		var resolved = destination

		if
			style == .releaseNotes,
			!destination.isSafeReleaseNotesDestination(isImage: markup is Image)
		{
			resolved = ""
		}

		if
			style == .extended,
			let resolveLink = options.resolveLink
		{
			do {
				resolved = try resolveLink(destination)
			} catch {
				reportProblem("\(error)", line: line(of: markup))
			}
		}

		links.append(MarkdownDocument.Link(destination: resolved, line: line(of: markup)))
		return resolved
	}

	mutating func visitInlineAttributes(_ attributes: InlineAttributes) {
		// An inline note is part of the extended style. Other attributes are for the renderer of the options.
		if
			style == .extended,
			let value = try? SOML.Value(parsing: "{\(attributes.attributes)}"),
			value["note"] != nil
		{
			renderInlineNote(attributes, value: value)
			return
		}

		let contentHTML = capturingHTML {
			$0.descendInto(attributes)
		}

		guard
			style == .extended,
			let renderer = options.inlineAttributes
		else {
			html += contentHTML
			return
		}

		do {
			html += try renderer.render(attributes.attributes, contentHTML)
		} catch {
			reportProblem("The inline attributes `\(attributes.attributes)` are invalid: \(error)", line: line(of: attributes))
			html += contentHTML
		}
	}

	/**
	An inline note, like `^[Spotlight](note: "The search of macOS.")`: the text opens the note in a popover (``MarkdownDocument/Options/inlineNote``), which is at the end of the document, like the popovers of the footnotes (``addPopover(id:element:content:origin:)``). The note is Markdown, rendered with the options of the document, so its links are resolved and checked like the text.

	Limitations: a note in a short text that is shown inline, like a frontmatter field, is not supported, as its popover is not inline HTML (``MarkdownDocument/inlineHTML``). A note cannot have headings, footnotes, or other notes, as their IDs could be the same as other IDs of the page, so they are problems.
	*/
	private mutating func renderInlineNote(_ attributes: InlineAttributes, value: SOML.Value) {
		// The text opens the note, so its links are only text, like in the heading of a collapsible section.
		let contentHTML = capturingHTML {
			$0.linkDepth += 1
			$0.descendInto(attributes)
			$0.linkDepth -= 1
		}

		guard let note = noteMarkdown(of: attributes, value: value) else {
			html += contentHTML
			return
		}

		// The ID is from the place of the note in the file, so it is the same in each build. Limitation: two documents on one page with a note at the same line and column give their notes the same ID.
		let noteLine = line(of: attributes)
		let id = "user-content-note-\(noteLine ?? 0)-\(attributes.range?.lowerBound.column ?? 0)"

		html += options.inlineNote?(contentHTML, id) ?? theme.inlineNote(textHTML: contentHTML, popoverID: id)

		let noteDocument = Document(parsing: note, convertOptions: ConvertOptions(style: style, options: options))
		addPopover(id: id, element: .inlineNotePopover, content: noteDocument.children, origin: .inlineNote(line: noteLine))
	}

	/**
	The Markdown of an inline note, or `nil` when the note cannot be here, or its attributes are invalid, which are problems. A link in the text of the note is only a problem, as the note still opens.
	*/
	private mutating func noteMarkdown(of attributes: InlineAttributes, value: SOML.Value) -> String? {
		guard linkDepth == 0 else {
			reportProblem("The note is inside a link, the heading of a collapsible section, or the text of another note, which cannot contain the text that opens it. Put it after the link or the note, or in the text below the heading.", line: line(of: attributes))
			return nil
		}

		guard !isInlineNote else {
			reportProblem("A note cannot have another note, as their IDs could be the same. Put its text in the note.", line: line(of: attributes))
			return nil
		}

		if attributes.containsLink {
			reportProblem("The text of a note cannot have a link, as it opens the note. Put the link in the note.", line: line(of: attributes))
		}

		do {
			return try InlineNoteAttributes.decode(from: value, root: "attributes").note
		} catch {
			reportProblem("The inline attributes `\(attributes.attributes)` are invalid: \(error)", line: line(of: attributes))
			return nil
		}
	}

	mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
		let contentHTML = capturingHTML {
			$0.descendInto(blockDirective)
		}

		guard let renderer = options.blockDirectives[blockDirective.name] else {
			reportProblem("Unknown block directive `@\(blockDirective.name)`. Known directives: \(options.blockDirectives.keys.sorted().map { "`@\($0)`" }.joined(separator: ", ")).", line: line(of: blockDirective))
			html += contentHTML
			return
		}

		var parseErrors = [DirectiveArgumentText.ParseError]()
		let arguments = blockDirective.argumentText.parseNameValueArguments(parseErrors: &parseErrors)

		// One mistake, like a missing quote, gives several parse errors and arguments that are read wrong, so only the first error is reported, and the directive is only its content.
		if let parseError = parseErrors.first {
			reportProblem("The arguments of `@\(blockDirective.name)` are invalid: \(parseError.message). Write them like `name: \"Value\"`, with a comma between them.", line: line(of: blockDirective))
			html += contentHTML
			return
		}

		do {
			html += try renderer.render(arguments, contentHTML) + "\n"
		} catch {
			reportProblem("`@\(blockDirective.name)`: \(error)", line: line(of: blockDirective))
			html += contentHTML
		}
	}

	/**
	The HTML that the closure renders, instead of adding it to the output.
	*/
	private mutating func capturingHTML(_ render: (inout Self) -> Void) -> String {
		let outer = html
		html = ""
		render(&self)
		let captured = html
		html = outer
		return captured
	}

	/**
	A keyboard shortcut, like `Cmd+K`, as one `<kbd>` per key. Smart punctuation changed keys like quotes, but a key is the character on the keyboard.
	*/
	private func keyboardShortcutHTML(_ shortcut: String) -> String {
		theme.keyboardShortcut(keysHTML: shortcut.removingSmartPunctuation.keyboardKeys.map(\.escapedForHTML))
	}

	mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
		guard renderedKeyboardNodes == 0 else {
			renderedKeyboardNodes -= 1
			return
		}

		let rawHTML = inlineHTML.rawHTML

		// A raw `<kbd>Cmd+K</kbd>` is three nodes: the start tag, the text, and the end tag. Like GitHub, its keys are split.
		if
			style == .extended,
			rawHTML == "<kbd>",
			let parent = inlineHTML.parent,
			let text = parent.child(at: inlineHTML.indexInParent + 1) as? Text,
			(parent.child(at: inlineHTML.indexInParent + 2) as? InlineHTML)?.rawHTML == "</kbd>"
		{
			html += keyboardShortcutHTML(text.string)
			renderedKeyboardNodes = 2
			return
		}

		guard !rawHTML.hasPrefix("<!--") else {
			// A directive inside a line would silently do nothing, as it belongs on its own line below the heading.
			if
				style == .extended,
				let comment = DirectiveComment(line: rawHTML[...])
			{
				reportProblem(comment.misplacedMessage, line: line(of: inlineHTML))
			}

			return
		}

		// Release notes keep only keyboard keys, like `<kbd>Delete</kbd>`.
		html += style == .releaseNotes && !["<kbd>", "</kbd>"].contains(rawHTML) ? rawHTML.escapedForHTML : rawHTML
	}

	mutating func visitLineBreak(_ lineBreak: LineBreak) {
		html += "<br>\n"
	}

	mutating func visitSoftBreak(_ softBreak: SoftBreak) {
		html += "\n"
	}

	// MARK: Extensions

	/**
	Renders a GitHub alert (`> [!NOTE]`). Returns `false` if the block quote is not an alert.
	*/
	private mutating func renderAlert(_ blockQuote: BlockQuote) -> Bool {
		// The parser decides what an alert is, like on GitHub: the marker is alone on its line, in any case, so `[!Tip]` is a tip, and content follows it.
		guard
			let aside = Aside(gitHubAlert: blockQuote),
			let kind = MarkdownAlert(rawValue: aside.kind.rawValue.lowercased())
		else {
			return false
		}

		// The content renders once, into this renderer, so its links and footnotes are counted.
		let contentHTML = capturingHTML { renderer in
			for block in aside.content {
				renderer.visit(block)
			}
		}

		html += theme.alert(kind, contentHTML: contentHTML) + "\n"
		return true
	}

	/**
	Adds the values of the directive comments in the block to the heading above it. Unknown directives, invalid values, and directives that are not directly below a heading are problems.
	*/
	private mutating func readDirectives(in htmlBlock: HTMLBlock) {
		let comments = htmlBlock.directiveComments

		guard comments.contains(where: { $0 != nil }) else {
			return
		}

		let isBelowHeading = htmlBlock.isOnlyDirectives && htmlBlock.followsHeading && !headings.isEmpty
		let firstLine = line(of: htmlBlock)

		for (index, comment) in comments.enumerated() {
			guard let comment else {
				continue
			}

			let line = firstLine.map { $0 + index }

			guard let directive = options.headingDirectives.first(where: { $0.name == comment.name }) else {
				let known = options.headingDirectives.map { "`@\($0.name)`" }.sorted()
				reportProblem("Unknown directive `@\(comment.name)`.\(known.isEmpty ? "" : " Known directives: \(known.joined(separator: ", ")).")", line: line)
				continue
			}

			guard isBelowHeading else {
				reportProblem(comment.misplacedMessage, line: line)
				continue
			}

			// A second directive with the name would replace the values of the first, like keywords on two lines.
			guard headings[headings.count - 1].directives[comment.name] == nil else {
				reportProblem("The heading already has `@\(comment.name)`. Put all its values in one directive.", line: line)
				continue
			}

			do {
				headings[headings.count - 1].directives[comment.name] = try directive.decode(comment.values)
			} catch {
				reportProblem("The values of `@\(comment.name)` are invalid: \((error as? DecodingError)?.reason ?? "\(error)")", line: line)
			}
		}
	}

	private mutating func reportProblem(_ message: String, line: Int?) {
		problems.append(ContentError(line: line, reason: message))
	}

	private mutating func renderInlineChildren(of markup: any Markup, removingCustomID: Bool = false) {
		let lastIndex = markup.childCount - 1

		for (index, child) in markup.children.enumerated() {
			if
				removingCustomID,
				index == lastIndex,
				let text = child as? Text
			{
				renderTextCheckingFootnotes(text.string.removingCustomHeadingID[...], of: text)
			} else {
				visit(child)
			}
		}
	}
}

extension Markdown.Heading {
	/**
	The plain text and the ID from a trailing `{#custom-id}`.
	*/
	fileprivate var plainTextAndCustomID: (text: String, id: String?) {
		let text = plainText(includingImageDescriptions: false)

		// Only in text, like when rendering, as code like `` `{#id}` `` is shown as written.
		guard
			text.contains("{#"),
			child(at: childCount - 1) is Text,
			let match = text.firstMatch(of: String.customHeadingID)
		else {
			return (text.trimmingCharacters(in: .whitespaces), nil)
		}

		return (String(text[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces), String(match.1).removingSmartPunctuation)
	}
}

extension ListItem {
	/**
	Whether the item is in a tight list, as CommonMark defines it, which the parser knows.
	*/
	fileprivate var isInTightList: Bool {
		(parent as? any ListItemContainer)?.isTight ?? true
	}
}

extension String {
	/**
	The HTML without `<!-- … -->` comments.
	*/
	var removingHTMLComments: String {
		contains("<!--") ? replacing(Self.htmlComment, with: "") : self
	}

	/**
	An HTML comment, like `<!-- Draft -->`.
	*/
	nonisolated(unsafe) private static let htmlComment = /(?s)<!--.*?-->/

	/**
	A custom heading ID at the end of a heading, like ` {#install}`. Smart punctuation makes the `--` and `---` of an ID dashes, like of the slug `cut--paste` of “Cut & Paste”, so the ID can have dashes, which are hyphens in the ID.
	*/
	nonisolated(unsafe) fileprivate static let customHeadingID = /\s*\{#([\w–—-]+)\}\s*$/

	/**
	The heading text without its custom ID, like `Install` for `Install {#install}`.
	*/
	public var removingCustomHeadingID: String {
		contains("{#") ? replacing(Self.customHeadingID, with: "") : self
	}
}

extension Link {
	/**
	Whether the parser made the link from a bare URL or email, like `https://example.com`, so its text is the address.
	*/
	fileprivate var isBareURL: Bool {
		guard
			childCount == 1,
			let text = (child(at: 0) as? Text)?.string,
			let destination
		else {
			return false
		}

		return [text, "mailto:\(text)", "http://\(text)"].contains(destination)
	}
}

extension String {
	/**
	The HTML with each `<kbd>` that contains `+` split into one `<kbd>` per key, for raw HTML, which is not parsed.
	*/
	fileprivate func separatingKeyboardKeys(theme: MarkdownTheme) -> String {
		guard contains("<kbd>") else {
			return self
		}

		return replacing(/<kbd>([^<]*\+[^<]*)<\/kbd>/) { match in
			theme.keyboardShortcut(keysHTML: String(match.1).keyboardKeys)
		}
	}
}

extension String {
	/**
	Whether external release notes can use this link or image without an executable or local-file URL.
	*/
	fileprivate func isSafeReleaseNotesDestination(isImage: Bool) -> Bool {
		guard
			!unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7F }),
			let components = URLComponents(string: trimmingCharacters(in: .whitespaces))
		else {
			return false
		}

		guard let scheme = components.scheme?.lowercased() else {
			return true
		}

		return scheme == "https" || scheme == "http" || (!isImage && scheme == "mailto")
	}
}

extension Markup {
	/**
	Whether the markup has a link that is not a bare URL. A bare URL is only text in a button, like the heading of a collapsible section, so it is not a lost link.
	*/
	fileprivate var containsLink: Bool {
		if
			let link = self as? Link,
			!link.isBareURL
		{
			return true
		}

		return children.contains(where: \.containsLink)
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

/**
The inline attributes of a note, like `^[Spotlight](note: "The search of macOS.")`.
*/
@Frontmatter
private struct InlineNoteAttributes {
	@NonEmpty var note: String
}
