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
	The start tag of a raw collapsible section, like `<details>` or `<summary class="a">`.
	*/
	nonisolated(unsafe) private static let collapsibleSectionTag = /(?i)<(?:details|summary)(?=[\s>\/])/

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

	/**
	The top-level blocks of the document with their HTML, in document order, so a page can split the document by its blocks (``MarkdownDocument/blocks``). A group of collapsible sections is one block.
	*/
	private(set) var blocks = [MarkdownDocument.Block]()

	private var slugger = HeadingSlugger()

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
		case inlineNote(line: SourceLocation.Line?)
	}

	private let origin: Origin

	// A parsed document can keep its file URL; only nodes from a different file are foreign.
	private let sourceURL: URL?

	/**
	The lines of the parsed source, to read what the Markdown tree leaves out, like whether a code fence is closed, or the cells of a table row that the parser drops. Empty when the source is not known, like for an inline note, which is parsed on its own.
	*/
	private let sourceLines: [Substring]

	init(
		style: MarkdownDocument.Style,
		options: MarkdownDocument.Options = .init(),
		footnoteDefinitions: [String: FootnoteDefinition] = [:],
		origin: Origin = .document(lineOffset: 0),
		sourceURL: URL? = nil,
		sourceLines: [Substring] = []
	) {
		let directiveNames = options.headingDirectives.map { $0.name }
		precondition(Set(directiveNames).count == directiveNames.count, "Heading directive registrations must have unique names.")

		self.style = style
		self.options = options
		self.footnoteDefinitions = footnoteDefinitions
		self.origin = origin
		self.sourceURL = sourceURL
		self.sourceLines = sourceLines
	}

	/**
	The source lines of the markup, from its first line to its last, or `nil` when they are not known, like for markup that a rewrite adds from another file.
	*/
	private func sourceLines(of markup: any Markup) -> ArraySlice<Substring>? {
		guard
			let range = markup.range,
			range.lowerBound.source == sourceURL,
			sourceLines.indices.contains(range.lowerBound.line - 1),
			sourceLines.indices.contains(range.upperBound.line - 1)
		else {
			return nil
		}

		return sourceLines[(range.lowerBound.line - 1)...(range.upperBound.line - 1)]
	}

	/**
	The line where the markup starts, in the file of the source. `nil` for markup that a rewrite adds from another file, which was parsed with the URL of its file as its source (``MarkdownDocument/Options/rewrite``).
	*/
	private func line(of markup: any Markup) -> SourceLocation.Line? {
		switch origin {
		case .document(let lineOffset):
			markup.range.flatMap { $0.lowerBound.source == sourceURL ? SourceLocation.Line($0.lowerBound.line + lineOffset) : nil }
		case .inlineNote(let line):
			line
		}
	}

	/**
	The lines of a directive in the document, from its first line to its last.
	*/
	private func lines(of directive: BlockDirective) -> ClosedRange<SourceLocation.Line>? {
		guard
			let firstLine = line(of: directive),
			let range = directive.range
		else {
			return nil
		}

		return firstLine...firstLine.offset(by: range.upperBound.line - range.lowerBound.line)
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
			for block in document.blockChildren {
				visitTopLevel(block)
			}

			return
		}

		let children = Array(document.blockChildren)
		var isInSections = sections.startHeadingID == nil
		var index = 0

		func sectionHeading(at index: Int) -> Markdown.Heading? {
			guard
				isInSections,
				index < children.count,
				let heading = children[index] as? Markdown.Heading,
				heading.headingLevel == sections.level
			else {
				return nil
			}

			return heading
		}

		while index < children.count {
			guard sectionHeading(at: index) != nil else {
				visitTopLevel(children[index])

				// When the sections follow a heading, they start after it, and end at the next heading with a lower level.
				if
					let heading = children[index] as? Markdown.Heading,
					let startHeadingID = sections.startHeadingID
				{
					if headings.last?.id == startHeadingID {
						isInSections = true
					} else if heading.headingLevel < sections.level {
						isInSections = false
					}
				}

				index += 1
				continue
			}

			// The sections up to the next heading with a lower level are one group. Each section ends at the next heading with its level or a lower one.
			let groupHTML = capturingHTML { renderer in
				renderer.html += "<div\(renderer.theme.classAttribute(.collapsibleSections))>\n"

				while let heading = sectionHeading(at: index) {
					let end = children[(index + 1)...].firstIndex { ($0 as? Markdown.Heading).map { $0.headingLevel <= sections.level } ?? false } ?? children.count
					renderer.renderCollapsibleSection(heading, content: children[(index + 1)..<end], name: sections.name)
					index = end
				}

				if let moreLink = sections.moreLink {
					renderer.html += renderer.theme.collapsibleMoreLink(moreLink) + "\n"
				}

				renderer.html += "</div>\n"
			}

			html += groupHTML
			blocks.append(MarkdownDocument.Block(kind: .other, html: groupHTML))
		}
	}

	/**
	Renders a top-level block, and records it with its HTML (``blocks``).
	*/
	private mutating func visitTopLevel(_ block: any BlockMarkup) {
		if let paragraph = block as? Paragraph {
			let inlineHTML = capturingHTML { $0.renderParagraphContent(paragraph) }
			let isLabel = isBoldLabel(paragraph)
			let paragraphHTML = "<p\(isLabel ? theme.classAttribute(.boldLabel) : "")>\(inlineHTML)</p>\n"
			html += paragraphHTML
			blocks.append(MarkdownDocument.Block(kind: .paragraph(inlineHTML: inlineHTML, isBoldLabel: isLabel), html: paragraphHTML))
			return
		}

		let blockHTML = capturingHTML {
			$0.visit(block)
		}

		html += blockHTML

		let kind: MarkdownDocument.Block.Kind = switch block {
		case is Markdown.Heading:
			headings.last.map { .heading(level: $0.level, id: $0.id) } ?? .other
		case let directive as BlockDirective:
			.directive(name: directive.name, lines: lines(of: directive))
		case is HTMLBlock:
			.html
		default:
			.other
		}

		blocks.append(MarkdownDocument.Block(kind: kind, html: blockHTML))
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
			$0.renderingInsideLink {
				$0.renderInlineChildren(of: heading, removingCustomID: true)
			}
		}

		let contentHTML = capturingHTML { renderer in
			for block in content {
				renderer.visit(block)
			}
		}

		let section = theme.collapsibleSection(
			id: recorded.id,
			name: name,
			headingLevel: recorded.level,
			titleHTML: titleHTML,
			contentHTML: "\n" + contentHTML
		)

		guard options.addsHeadingAnchors else {
			html += section + "\n"
			return
		}

		html += "<div\(theme.classAttribute(.anchoredSection))>\(theme.headingAnchor(for: recorded))\(section)</div>\n"
	}

	mutating func visitHeading(_ heading: Markdown.Heading) {
		guard style == .extended else {
			// Release notes are below the heading of their version (`<h2>`), so the page has one `<h1>`, and a heading is not at the level of the versions.
			let level = min(heading.level + 2, 6)
			html += "<h\(level)>"
			renderInlineChildren(of: heading)
			html += "</h\(level)>\n"
			return
		}

		let recorded = recordHeading(heading)
		let hasAnchor = options.addsHeadingAnchors && (HeadingLevel.h2...HeadingLevel.h4).contains(heading.headingLevel)
		// The link is inside the heading, so the heading is named by its text, as the name of the link would otherwise be part of the name of the heading, like “Tips Copy link to section: Tips”.
		let attributes = hasAnchor ? #"\#(theme.classAttribute(.anchoredHeading)) aria-label="\#(recorded.text.escapedForHTML)""# : ""
		html += #"<h\#(heading.level) id="\#(recorded.id.rawValue.escapedForHTML)"\#(attributes)>"#
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
		let (text, parsedCustomID) = heading.titleAndCustomID
		var customID: String?

		switch parsedCustomID {
		case .valid(let id):
			customID = id
		case .invalid(let invalidID):
			if invalidID.isEmpty {
				let slug = HeadingSlugger.slug(text)
				reportProblem("The custom ID `{#}` is empty\(slug.isEmpty ? "" : ". Write it like `{#\(slug)}`").", line: line(of: heading))
			} else {
				// Whitespace around the ID is a typo, like `{#a-question }`, so the suggestion is the ID that the author meant, not one with a hyphen at the end, which would break the links to it.
				let slug = HeadingSlugger.slug(invalidID.trimmingCharacters(in: .whitespaces))
				reportProblem("The custom ID `\(invalidID)` can only have letters, digits, underscores, and hyphens\(slug.isEmpty ? "" : ", like `{#\(slug)}`").", line: line(of: heading))
			}
		case nil:
			break
		}

		// An empty heading is a leftover of an edit, and it would be an empty heading for screen readers, with an ID that the slugger makes up.
		if text.isEmpty {
			reportProblem("The heading has no text.", line: line(of: heading))
		}

		// The ID is made before the checks below, as a second section with the same text often has the same ID as the first, and one problem is enough.
		let id = ElementID(customID ?? slugger.slug(for: text))

		// A second section with the text of another one shows the text twice in the section navigation, and gets an ID with a number, like `tips-1`, which changes when the first section is renamed. A heading whose ID is another heading's, like a custom ID that is the slug of another heading, is reported below instead, as that error names both headings.
		if
			heading.headingLevel == .h2,
			customID == nil,
			!text.isEmpty,
			!headings.contains(where: { $0.id == id }),
			let other = headings.first(where: { $0.level == .h2 && $0.text == text })
		{
			let otherPlace = other.line.map { " (line \($0))" } ?? ""
			reportProblem("The page already has a section “\(other.text)”\(otherPlace). Give the sections different headings.", line: line(of: heading) ?? other.line)
		}

		// The error names both headings. A heading that the build adds, like a shared question, has no line, so the error is then at the other heading, which is the one to change.
		if let other = headings.first(where: { $0.id == id }) {
			if
				line(of: heading) == nil,
				let otherLine = other.line
			{
				reportProblem("The heading ID `\(id)` is also the ID of “\(text)”, which the build adds to the page, like a shared question, so links to it are ambiguous. Give this heading another custom ID, like `{#\(id)-2}`.", line: otherLine)
			} else {
				let otherPlace = other.line.map { " at line \($0)" } ?? ""
				reportProblem("The heading ID `\(id)` is already the ID of “\(other.text)”\(otherPlace), so links to it are ambiguous. Give one of the headings another custom ID, like `{#\(id)-2}`.", line: line(of: heading))
			}
		}

		let recorded = Heading(
			level: heading.headingLevel,
			text: text,
			identity: customID == nil ? .generated(id) : .authored(id),
			line: line(of: heading)
		)
		headings.append(recorded)
		return recorded
	}

	mutating func visitParagraph(_ paragraph: Paragraph) {
		// The items of a tight list, like CommonMark, have no paragraphs around their text.
		guard
			let listItem = paragraph.parent as? ListItem,
			listItem.isInTightList
		else {
			let isLabel = isBoldLabel(paragraph)
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
	Whether a paragraph is a standalone bold label rather than prose.
	*/
	private func isBoldLabel(_ paragraph: Paragraph) -> Bool {
		style == .extended && paragraph.parent is ListItem == false && paragraph.childCount == 1 && paragraph.child(at: 0) is Strong
	}

	/**
	Renders the inline content. In a list item, a line that starts with `: ` is a subtitle, and a line that starts with `:: ` is a description.
	*/
	private mutating func renderParagraphContent(_ paragraph: Paragraph) {
		if
			style == .extended,
			paragraph.isTableWithoutDelimiterRow
		{
			reportProblem("The table has no delimiter row below its header, like `| --- | --- |`, so the page shows the pipes.", line: line(of: paragraph))
		}

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
		reportUnclosedFence(of: codeBlock)

		// The language is the first word of the info string, like GitHub.
		let language = codeBlock.language?.split(whereSeparator: \.isWhitespace).first.map(String.init)

		if let render = options.codeBlock {
			do {
				html += try render(codeBlock.code, language) + "\n"
				return
			} catch {
				reportProblem("The code block is invalid: \(error.reason)", line: line(of: codeBlock))
			}
		}

		let languageClass = language.map { #" class="language-\#($0.escapedForHTML)""# } ?? ""
		// Focusable, so keyboard users can scroll wide code.
		html += #"<pre tabindex="0"><code\#(languageClass)>\#(codeBlock.code.escapedForHTML)</code></pre>"# + "\n"
	}

	/**
	A fenced code block without its closing fence takes all the lines to the end of the document, like CommonMark says, so the problems of the rest of the file would be at other lines, or not found. The parser does not say whether the fence is closed, but the range of a closed block ends at its closing fence. Indented code is not fenced.
	*/
	private mutating func reportUnclosedFence(of codeBlock: CodeBlock) {
		guard
			style == .extended,
			let lines = sourceLines(of: codeBlock),
			let firstLine = lines.first,
			let opening = firstLine.fenceRun,
			// Indented code that starts with a fence has the fence as its first line of code.
			codeBlock.code.split(separator: "\n", omittingEmptySubsequences: false).first != firstLine.blockContent
		else {
			return
		}

		// A closing fence has the character of the opening one, and at least as many.
		if
			lines.count > 1,
			let closing = lines.last?.fenceRun,
			closing.character == opening.character,
			closing.count >= opening.count
		{
			return
		}

		let fence = String(repeating: opening.character, count: opening.count)
		reportProblem("The code block that starts here has no closing \(fence), so the rest of the file is code.", line: line(of: codeBlock))
	}

	mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
		if style == .extended {
			readDirectives(in: htmlBlock)
		}

		// A comment that is not closed before the next comment hides all the text between them, as Markdown ends both at the `-->` of the next one.
		for (commentLine, otherCommentLine) in htmlBlock.rawHTML.unclosedHTMLComments {
			let otherComment = line(of: htmlBlock).map { "the comment at line \($0.offset(by: otherCommentLine))" } ?? "the next comment"
			reportProblem("The HTML comment is not closed before \(otherComment). End it with `-->`.", line: line(of: htmlBlock)?.offset(by: commentLine))
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

		reportRawCollapsibleSection(in: rawHTML, line: line(of: htmlBlock))

		// The `<kbd>` elements of raw HTML are split into keys too. Like the HTML, they are not parsed, so a regex finds them.
		if style == .extended {
			rawHTML = resolvingRawLinks(in: rawHTML, of: htmlBlock).separatingKeyboardKeys(theme: theme)
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
		reportExtraCells(in: tableRow)
		html += "<tr>\n"
		descendInto(tableRow)
		html += "</tr>\n"
	}

	/**
	GFM leaves out the cells of a row after the columns of the header, so their text is lost. The parser drops them, so the source line of the row is read. Limitation: a cell with a `|` that is not escaped, like in code, which GFM also reads as a new cell, is counted as two.
	*/
	private mutating func reportExtraCells(in tableRow: Table.Row) {
		guard
			style == .extended,
			let table = tableRow.parent?.parent as? Table,
			let line = sourceLines(of: tableRow)?.first
		else {
			return
		}

		let columns = table.columnAlignments.count
		let cells = line.tableRowCells

		guard cells.count > columns else {
			return
		}

		let extraText = cells[columns...].joined(separator: " | ")
		reportProblem("The row has \(cells.count) cells, but the table has \(columns) columns, so the page leaves out “\(extraText)”.", line: self.line(of: tableRow))
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
			let table = sequence(first: tableCell as any Markup, next: \.parent).first(where: { $0 is Table }) as? Table,
			table.columnAlignments.indices.contains(column),
			let alignment = table.columnAlignments[column]
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

		renderText(string, line: line(of: text))
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

	/**
	- Parameter line: The line of the text, for the problems of its keyboard shortcuts.
	*/
	private mutating func renderText(_ text: Substring, line: SourceLocation.Line? = nil) {
		// Keyboard shortcuts written as `++Command+K++` become one `<kbd>` per key.
		guard style == .extended else {
			renderPlainText(text)
			return
		}

		for part in text.keyboardShortcutParts {
			switch part {
			case .text(let text):
				// The page would show the plus signs.
				if text.hasUnclosedKeyboardShortcut {
					reportProblem("The text has a `++` without its closing `++`, so the page shows the plus signs. Write a keyboard shortcut like `++Command+N++`.", line: line)
				}

				renderPlainText(text)
			case .shortcut(let text, let openingPunctuation, let punctuation):
				// The punctuation right before and after a shortcut is rendered with the shortcut, so it stays on its line.
				reportWrongKeyNames(in: String(text), line: line)
				html += keyboardShortcutHTML(
					String(text),
					openingPunctuation: openingPunctuation,
					punctuation: punctuation,
					line: line
				)
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
			addPopover(
				id: popoverID,
				element: .footnotePopover,
				content: definition.children,
				origin: origin
			)
		}

		return theme.footnoteReference(number: number, popoverID: popoverID)
	}

	/**
	The ID of the popover with a footnote. The numbers of a document are unique, so the ID is from the number, like `user-content-fn-1`, which is the ID of GitHub without the name of the footnote. Limitation: two documents on one page with footnotes give their first footnotes the same ID.
	*/
	private static func footnotePopoverID(number: Int) -> ElementID {
		ElementID("user-content-fn-\(number)")
	}

	/**
	Adds a popover at the end of the document with Markdown inside the document, like the definition of a footnote or an inline note. It renders with the options for nested Markdown (``MarkdownDocument/Options/forNestedMarkdown``), and its problems, links, and popovers are those of the document. A heading in it is a problem, as its ID could be the same as another ID of the page.
	*/
	private mutating func addPopover(
		id: ElementID,
		element: MarkdownElement,
		content: some Sequence<any Markup>,
		origin: Origin
	) {
		// An inline note is parsed on its own, so the lines of its Markdown are not lines of the source.
		var renderer = HTMLRenderer(
			style: style,
			options: options.forNestedMarkdown,
			origin: origin,
			sourceURL: sourceURL,
			sourceLines: element == .inlineNotePopover ? [] : sourceLines
		)

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
		// Code is not translated, as a translation would change it. Long code, like `com.sindresorhus.Dato.joinedVideoCall` or a path, can break before a dot and after a slash, like a URL in a book, instead of at any letter. `<wbr>` adds no text, so copying is the same.
		let code = inlineCode.code.escapedForHTML
		let breakableCode = code.count > 24 ? code.replacing(".", with: "<wbr>.").replacing("/", with: "/<wbr>") : code
		html += #"<code translate="no">\#(breakableCode)</code>"#
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

		let resolved = resolvedDestination(destination, of: link)

		// Like an image without a description: the link is not visible, and screen readers have no name for it. A link with raw HTML, like an `<img>` with `alt`, has a name that the Markdown does not show, so it is not checked.
		if
			style == .extended,
			link.plainText(includingImageDescriptions: true).allSatisfy(\.isWhitespace),
			link.descendants(of: InlineHTML.self).isEmpty
		{
			reportProblem("The link to `\(resolved)` has no text, so it is not visible, and screen readers have no name for it. Write its text, like `[Dato](\(destination))`.", line: line(of: link))
		}

		let title = link.title.map { #" title="\#($0.escapedForHTML)""# } ?? ""
		html += #"<a href="\#(resolved.escapedForHTML)"\#(title)>"#
		renderingInsideLink {
			$0.descendInto(link)
		}
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
		} else if let resolveLink = options.resolveLink {
			do {
				resolved = try resolveLink(destination)
			} catch {
				reportProblem("\(error)", line: line(of: markup))
			}
		}

		recordLink(resolved, of: markup)
		return resolved
	}

	/**
	Adds the link to the links, at the line of the markup, or at its line in another file, for markup that a rewrite adds from that file.
	*/
	private mutating func recordLink(_ destination: String, of markup: any Markup) {
		if
			let otherFile = markup.range?.lowerBound.source,
			otherFile != sourceURL
		{
			links.append(MarkdownDocument.Link(destination: destination, source: .file(otherFile, line: markup.range.map { SourceLocation.Line($0.lowerBound.line) })))
		} else {
			links.append(MarkdownDocument.Link(destination: destination, source: .document(line: line(of: markup))))
		}
	}

	mutating func visitInlineAttributes(_ attributes: InlineAttributes) {
		// Release notes have no inline attributes, so the text is only its content.
		guard style == .extended else {
			descendInto(attributes)
			return
		}

		let parsed: InlineAttributes.Parsed

		do {
			parsed = try attributes.parsed
		} catch {
			reportInvalidAttributes(attributes, error: error)
			descendInto(attributes)
			return
		}

		switch parsed {
		// An inline note is part of the extended style. Other attributes are for the renderer of the options.
		case .note(let note):
			renderInlineNote(attributes, note: note)
		case .attributes(let value):
			let contentHTML = capturingHTML {
				$0.descendInto(attributes)
			}

			// The decoder reports a missing key before an unknown one, but a misspelled key, like `notes`, is the likely cause.
			let knownKeys = InlineNoteAttributes.CodingKeys.allCases.map(\.stringValue) + (options.inlineAttributes?.keys ?? [])

			if let unknownKey = value.objectValue?.keys.first(where: { !knownKeys.contains($0) }) {
				let suggestion = unknownKey.closest(in: knownKeys).map { " Did you mean `\($0)`?" } ?? " Known attributes: \(knownKeys.map { "`\($0)`" }.joined(separator: ", "))."
				reportProblem("Unknown attribute `\(unknownKey)` in `\(attributes.attributes)`.\(suggestion)", line: line(of: attributes))
				html += contentHTML
				return
			}

			do {
				html += try options.inlineAttributes?.render(value, contentHTML) ?? contentHTML
			} catch {
				reportInvalidAttributes(attributes, error: error)
				html += contentHTML
			}
		}
	}

	/**
	Reports inline attributes that cannot be parsed or decoded, like a missing quote or an unknown key, with the error, which says what is wrong.
	*/
	private mutating func reportInvalidAttributes(_ attributes: InlineAttributes, error: any Error) {
		reportProblem("The inline attributes `\(attributes.attributes)` are invalid: \(error)", line: line(of: attributes))
	}

	/**
	An inline note, like `^[Spotlight](note: "The search of macOS.")`: the text opens the note in a popover (``MarkdownDocument/Options/inlineNote``), which is at the end of the document, like the popovers of the footnotes (``addPopover(id:element:content:origin:)``). The note is Markdown, rendered with the options of the document, so its links are resolved and checked like the text.

	Limitations: a note in a short text that is shown inline, like a frontmatter field, is not supported, as its popover is not inline HTML (``MarkdownDocument/inlineHTML``). A note cannot have headings, footnotes, or other notes, as their IDs could be the same as other IDs of the page, so they are problems.
	*/
	private mutating func renderInlineNote(_ attributes: InlineAttributes, note: String) {
		// The text opens the note, so its links are only text, like in the heading of a collapsible section.
		let contentHTML = capturingHTML {
			$0.renderingInsideLink {
				$0.descendInto(attributes)
			}
		}

		guard canHaveNote(attributes) else {
			html += contentHTML
			return
		}

		// The ID is from the place of the note in the file, so it is the same in each build. Limitation: two documents on one page with a note at the same line and column give their notes the same ID.
		let noteLine = line(of: attributes)
		let id = ElementID("user-content-note-\(noteLine?.rawValue ?? 0)-\(attributes.range?.lowerBound.column ?? 0)")

		html += options.inlineNote?(contentHTML, id) ?? theme.inlineNote(textHTML: contentHTML, popoverID: id)

		let noteDocument = Document(parsing: note, convertOptions: ConvertOptions(style: style, options: options))
		addPopover(
			id: id,
			element: .inlineNotePopover,
			content: noteDocument.children,
			origin: .inlineNote(line: noteLine)
		)
	}

	/**
	Whether the inline note can be here, which is a problem when it cannot. A link in the text of the note is only a problem, as the note still opens.
	*/
	private mutating func canHaveNote(_ attributes: InlineAttributes) -> Bool {
		guard linkDepth == 0 else {
			reportProblem("The note is inside a link, the heading of a collapsible section, or the text of another note, which cannot contain the text that opens it. Put it after the link or the note, or in the text below the heading.", line: line(of: attributes))
			return false
		}

		guard !isInlineNote else {
			reportProblem("A note cannot have another note, as their IDs could be the same. Put its text in the note.", line: line(of: attributes))
			return false
		}

		if attributes.containsLink {
			reportProblem("The text of a note cannot have a link, as it opens the note. Put the link in the note.", line: line(of: attributes))
		}

		return true
	}

	mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
		// Without its `}`, a directive takes the rest of the document as its content, and the range of the parser ends at its first line.
		if
			let lines = sourceLines(of: blockDirective),
			lines.first?.trimmingCharacters(in: .whitespaces).hasSuffix("{") == true,
			lines.last?.trimmingCharacters(in: .whitespaces).hasSuffix("}") == false
		{
			reportProblem("The block directive `@\(blockDirective.name)` that starts here has no closing `}`, so the rest of the file is its content.", line: line(of: blockDirective))
		}

		guard let renderer = options.blockDirectives[blockDirective.name] else {
			let names = options.blockDirectives.keys
			let suggestion = blockDirective.name.closest(in: names).map { "Did you mean `@\($0)`?" } ?? "Known directives: \(names.sorted().map { "`@\($0)`" }.joined(separator: ", "))."
			reportProblem("Unknown block directive `@\(blockDirective.name)`. \(suggestion)", line: line(of: blockDirective))
			descendInto(blockDirective)
			return
		}

		// A problem with the arguments or the content makes the directive only its content.
		let arguments: [DirectiveArgument]

		do {
			arguments = try blockDirective.parsedArguments()
		} catch {
			reportProblem(error.reason, line: line(of: blockDirective))
			descendInto(blockDirective)
			return
		}

		if let mistake = blockDirective.contentMistake(for: renderer.content) {
			reportProblem("`@\(blockDirective.name)` \(mistake)", line: line(of: blockDirective))
			descendInto(blockDirective)
			return
		}

		let content: [any BlockMarkup]

		do {
			content = try renderer.rewriteContent?(Array(blockDirective.blockChildren)) ?? Array(blockDirective.blockChildren)
		} catch {
			reportProblem("`@\(blockDirective.name)`: \(error)", line: line(of: blockDirective))
			descendInto(blockDirective)
			return
		}

		let contentHTML = capturingHTML { renderer in
			for block in content {
				renderer.visit(block)
			}
		}

		do {
			let directiveHTML = try renderer.render(arguments, contentHTML, .init(documentOptions: options))

			// The links that the directive renders from its arguments, like the icon of `@TinyApp`, are at its line, so a broken one names it. The content has recorded its own links.
			for match in (contentHTML.isEmpty ? directiveHTML : directiveHTML.replacing(contentHTML, with: "")).matches(of: Self.rawLinkAttribute) {
				recordLink(String(match.2).decodingHTMLEscapes, of: blockDirective)
			}

			html += directiveHTML + "\n"
		} catch {
			reportProblem("`@\(blockDirective.name)`: \(error)", line: line(of: blockDirective))
			html += contentHTML
		}
	}

	/**
	Renders content whose links must be plain text, restoring the enclosing link depth afterward.
	*/
	private mutating func renderingInsideLink(_ render: (inout Self) -> Void) {
		linkDepth += 1
		defer {
			linkDepth -= 1
		}

		render(&self)
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
	The keys of a shortcut written as `++Command+K++` must have their names on the keyboard of a Mac, so all the shortcuts of the site look the same: not a glyph, like `⌘`, an abbreviation, like `Cmd`, or a lowercase name, like `command` or `k`. Keys without a name are fine as glyphs, like `⌫` and `◀`. A raw `<kbd>` is not checked, as `website check` already asks to rewrite it as a shortcut.
	*/
	private mutating func reportWrongKeyNames(in shortcut: String, line: SourceLocation.Line?) {
		for key in KeyboardKey.keys(of: shortcut) {
			if let mistake = key.mistake(in: shortcut) {
				reportProblem(mistake, line: line)
			}
		}
	}

	/**
	Raw `<details>` and `<summary>` do not get the look of the collapsible sections of the site, so they are a problem when the options have a `Details` block directive.
	*/
	private mutating func reportRawCollapsibleSection(in rawHTML: String, line: SourceLocation.Line?) {
		guard
			style == .extended,
			options.blockDirectives["Details"] != nil,
			rawHTML.contains(Self.collapsibleSectionTag)
		else {
			return
		}

		reportProblem("Write a collapsible section with `@Details(summary: \"…\") { … }`, not with raw `<details>` and `<summary>`, so it has the look of the site.", line: line)
	}

	/**
	A keyboard shortcut, like `Command+K`, as one `<kbd>` per key (``KeyboardKey``).

	The modifiers must be in the order of Apple (``KeyboardKey/Modifier``), like in the menus of macOS, so a shortcut on a page looks like the one in the app. Another order is a problem, and so is a modifier that is given twice, which is reported instead of the order.
	*/
	private mutating func keyboardShortcutHTML(
		_ shortcut: String,
		openingPunctuation: Substring = "",
		punctuation: Substring = "",
		line: SourceLocation.Line?
	) -> String {
		let keys = KeyboardKey.keys(of: shortcut)
		let modifiers = keys.compactMap(\.modifier)
		let orderedKeys = keys.inAppleOrder
		let orderedModifiers = orderedKeys.compactMap(\.modifier)

		if let repeatedModifier = modifiers.first(where: { modifier in modifiers.count { $0 == modifier } > 1 }) {
			reportProblem("The keyboard shortcut `\(shortcut)` has \(repeatedModifier.rawValue) twice.", line: line)
		} else if modifiers != orderedModifiers {
			reportProblem("The modifiers of the keyboard shortcut `\(shortcut)` must be in the order of Apple: \(orderedModifiers.map(\.rawValue).joined(separator: ", ")), like `\(orderedKeys.map(\.name).joined(separator: "+"))`.", line: line)
		}

		return theme.keyboardShortcut(keys, openingPunctuation: openingPunctuation, punctuation: punctuation)
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
			html += keyboardShortcutHTML(text.string, line: line(of: inlineHTML))
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

		// After the comments, as a comment inside a line, like `<!-- <details> -->`, is one node.
		reportRawCollapsibleSection(in: rawHTML, line: line(of: inlineHTML))

		// Release notes keep only keyboard keys, like `<kbd>Delete</kbd>`.
		html += style == .releaseNotes && !["<kbd>", "</kbd>"].contains(rawHTML) ? rawHTML.escapedForHTML : resolvingRawLinks(in: rawHTML, of: inlineHTML)
	}

	/**
	The raw HTML with the `href` and `src` of its tags resolved like the destinations of Markdown links (``resolvedDestination(_:of:)``), so a file of the page bundle, like `<img src="screenshot1.jpg">`, works, and the links are recorded at the line of the HTML, which a broken link then names. Limitation: only values in double quotes are found, as the HTML is not parsed.
	*/
	private mutating func resolvingRawLinks(in rawHTML: String, of markup: any Markup) -> String {
		guard
			style == .extended,
			rawHTML.contains("href=") || rawHTML.contains("src=")
		else {
			return rawHTML
		}

		return rawHTML.replacing(Self.rawLinkAttribute) { match in
			let destination = String(match.2).decodingHTMLEscapes
			let resolved = resolvedDestination(destination, of: markup)
			return resolved == destination ? String(match.output.0) : "\(match.1)\(resolved.escapedForHTML)\""
		}
	}

	/**
	An `href` or `src` attribute of raw HTML in double quotes, like ` src="screenshot1.jpg"`, with the part before the value and the value.
	*/
	nonisolated(unsafe) private static let rawLinkAttribute = /(\s(?:href|src)=")([^"]*)"/

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
			reportAlertMarker(of: blockQuote)
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
	The marker at the start of a block quote, like `[!NOTE]`, also with a name that is not a kind of alert, like `[!WARN]`.
	*/
	nonisolated(unsafe) private static let alertMarker = /\[!([A-Za-z]+)\]/

	/**
	Reports a block quote that starts with an alert marker but is not an alert, which would show the marker as text in a quote: an unknown kind, like `> [!WARN]`, text after the marker, like `> [!NOTE] Text`, or no text.
	*/
	private mutating func reportAlertMarker(of blockQuote: BlockQuote) {
		guard
			let paragraph = blockQuote.child(at: 0) as? Paragraph,
			let text = paragraph.child(at: 0) as? Text,
			let match = text.string.prefixMatch(of: Self.alertMarker)
		else {
			return
		}

		let marker = "`\(match.0)`"
		let names = MarkdownAlert.allCases.map(\.title)

		guard names.contains(match.1.uppercased()) else {
			let known = names.map { "`[!\($0)]`" }.formattedList(.or)
			let suggestion = String(match.1).closest(in: names).map { " Did you mean `[!\($0)]`?" } ?? ""
			reportProblem("\(marker) is not an alert. Use \(known).\(suggestion)", line: line(of: blockQuote))
			return
		}

		// The parser makes an alert of a marker that is alone on its line with text after it, so this one has text on its line, or no text.
		guard
			paragraph.childCount == 1,
			text.string.count == match.0.count
		else {
			reportProblem("The marker \(marker) must be alone on its line. Put the text on the next line.", line: line(of: blockQuote))
			return
		}

		reportProblem("The alert \(marker) has no text. Write the text on the next line.", line: line(of: blockQuote))
	}

	/**
	Adds the values of the directive comments in the block to the heading above it. Unknown directives, invalid values, and directives that are not directly below a heading are problems.
	*/
	private mutating func readDirectives(in htmlBlock: HTMLBlock) {
		let (comments, isOnlyDirectives) = htmlBlock.parsedDirectiveComments

		guard comments.contains(where: { $0 != nil }) else {
			return
		}

		let isBelowHeading = isOnlyDirectives && htmlBlock.followsHeading && !headings.isEmpty
		let firstLine = line(of: htmlBlock)

		for (index, comment) in comments.enumerated() {
			guard let comment else {
				continue
			}

			let line = firstLine.map { $0.offset(by: index) }

			guard let directive = options.headingDirectives.first(where: { $0.name == comment.name }) else {
				let names = options.headingDirectives.map { $0.name.rawValue }
				let known = names.map { "`@\($0)`" }.sorted()
				let suggestion = comment.name.rawValue.closest(in: names).map { " Did you mean `@\($0)`?" } ?? (known.isEmpty ? "" : " Known directives: \(known.joined(separator: ", ")).")
				reportProblem("Unknown directive `@\(comment.name)`.\(suggestion)", line: line)
				continue
			}

			guard isBelowHeading else {
				reportProblem(comment.misplacedMessage, line: line)
				continue
			}

			// A second directive with the name would replace the values of the first, like keywords on two lines.
			guard !headings[headings.count - 1].contains(directive) else {
				reportProblem("The heading already has `@\(comment.name)`. Put all its values in one directive.", line: line)
				continue
			}

			// An empty directive is a leftover or a lost edit, which reads as if the heading has values.
			guard directive.isFlag || !comment.values.isEmpty else {
				reportProblem("`@\(comment.name)` needs at least one value.", line: line)
				continue
			}

			do {
				try headings[headings.count - 1].setDirective(directive, values: comment.values)
			} catch {
				reportProblem("The values of `@\(comment.name)` are invalid: \(error.reason)", line: line)
			}
		}
	}

	private mutating func reportProblem(_ message: String, line: SourceLocation.Line?) {
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

/**
The level of a heading, from the page title (`h1`) to the deepest subheading (`h6`). Levels from the Markdown parser are checked when recorded.
*/
public enum HeadingLevel: Int, CaseIterable, Comparable, Sendable {
	case h1 = 1
	case h2
	case h3
	case h4
	case h5
	case h6

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

extension Markdown.Heading {
	/**
	The level of the parsed heading, which is always 1 through 6. A code-built heading outside this range is a programmer error.
	*/
	public var headingLevel: HeadingLevel {
		guard let level = HeadingLevel(rawValue: level) else {
			preconditionFailure("A Markdown heading must have a level from 1 through 6, got \(level).")
		}
		return level
	}

	/**
	A heading at a typed level with a sequence of inline children.
	*/
	public init<Children: Sequence>(level: HeadingLevel, _ children: Children) where Children.Element == any InlineMarkup {
		self.init(level: level.rawValue, children)
	}

	/**
	A heading at a typed level with inline children.
	*/
	public init(level: HeadingLevel, _ children: any InlineMarkup...) {
		self.init(level: level, children)
	}

	/**
	A heading with a custom ID, like `## Install {#install}`, for a heading that code adds. The ID is in the last text of the heading, where the renderer reads it. It must contain letters, digits, underscores, and plain hyphens so it round-trips unchanged through custom-heading syntax; other element IDs are a programmer error.
	*/
	public init(level: HeadingLevel, _ title: String, id: ElementID) {
		self.init(level: level.rawValue)
		setTitle(title, id: id)
	}

	/**
	Replaces the text of the heading with the title and a custom ID, like ``init(level:_:id:)``. The heading keeps its place in the file, like its line.
	*/
	public mutating func setTitle(_ title: String, id: ElementID) {
		precondition(
			id.rawValue.wholeMatch(of: String.customHeadingIDCharacters) != nil && id.rawValue == id.rawValue.removingSmartPunctuation,
			"A custom heading ID must contain only letters, digits, underscores, and plain hyphens, got “\(id)”."
		)
		setInlineChildren([Text("\(title) {#\(id)}")])
	}

	/**
	The plain text of the heading without its custom ID, like `Install` for `## Install {#install}`.
	*/
	public var title: String {
		titleAndCustomID.title
	}

	/**
	The custom ID of the heading, like `install` for `## Install {#install}`. `nil` when the heading has none, or an invalid one, which rendering reports.
	*/
	public var customID: ElementID? {
		guard case .valid(let id) = titleAndCustomID.customID else {
			return nil
		}

		return ElementID(id)
	}

	/**
	The trailing `{#custom-id}` of a heading.
	*/
	fileprivate enum CustomID {
		case valid(String)

		/**
		The text between the braces of an ID that is not valid, like `with gifski` for `{#with gifski}`.
		*/
		case invalid(String)
	}

	/**
	The plain text and the trailing `{#custom-id}`, or `nil` for a heading without one.
	*/
	fileprivate var titleAndCustomID: (title: String, customID: CustomID?) {
		let text = plainText(includingImageDescriptions: false)

		// Only in text, like when rendering, as code like `` `{#id}` `` is shown as written.
		guard
			text.contains("{#"),
			child(at: childCount - 1) is Text,
			let match = text.firstMatch(of: String.customHeadingID)
		else {
			return (text.trimmingCharacters(in: .whitespaces), nil)
		}

		let title = String(text[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces)
		let id = match.1

		guard id.wholeMatch(of: String.customHeadingIDCharacters) != nil else {
			return (title, .invalid(String(id)))
		}

		return (title, .valid(String(id).removingSmartPunctuation))
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
	The comments that have another `<!--` in them, like `<!-- Draft` before `<!-- Note -->`, as the author forgot to close them. Each is the line of the comment and the line of the other `<!--`, as offsets from the first line of the HTML.
	*/
	fileprivate var unclosedHTMLComments: [(commentLine: Int, otherCommentLine: Int)] {
		matches(of: Self.htmlComment).compactMap { comment in
			guard let otherComment = comment.output.dropFirst(4).firstRange(of: "<!--") else {
				return nil
			}

			return (self[..<comment.range.lowerBound].count(where: \.isNewline), self[..<otherComment.lowerBound].count(where: \.isNewline))
		}
	}

	/**
	An HTML comment, like `<!-- Draft -->`.
	*/
	nonisolated(unsafe) private static let htmlComment = /(?s)<!--.*?-->/

	/**
	A custom heading ID at the end of a heading, like ` {#install}`, with any text between the braces, so an invalid ID is found too, like `{#with gifski}`.
	*/
	nonisolated(unsafe) fileprivate static let customHeadingID = /\s*\{#([^}]*)\}\s*$/

	/**
	The characters of a valid custom heading ID: letters, digits, underscores, and hyphens. Smart punctuation makes the `--` and `---` of an ID dashes, like of the slug `cut--paste` of “Cut & Paste”, so the ID can have dashes, which are hyphens in the ID.
	*/
	nonisolated(unsafe) fileprivate static let customHeadingIDCharacters = /[\w–—-]+/

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
	The HTML with each `<kbd>` that contains `+` split into one `<kbd>` per key, like a shortcut in the Markdown, for raw HTML, which is not parsed. Limitation: only the escapes of ``Swift/String/decodingHTMLEscapes`` are decoded, so another entity in a key, like `&nbsp;`, is shown as written. Write the shortcut in Markdown instead, like `++Command+K++`.
	*/
	fileprivate func separatingKeyboardKeys(theme: MarkdownTheme) -> String {
		guard contains("<kbd>") else {
			return self
		}

		return replacing(Self.keyboardShortcutElement) { match in
			// The text is HTML, so its escapes are decoded first, as each key escapes its name again.
			theme.keyboardShortcut(KeyboardKey.keys(of: String(match.1).decodingHTMLEscapes))
		}
	}

	/**
	A `<kbd>` with a `+` in it, like `<kbd>Command+K</kbd>`. Stored, as it runs for each raw `<kbd>`.
	*/
	nonisolated(unsafe) private static let keyboardShortcutElement = /<kbd>([^<]*\+[^<]*)<\/kbd>/
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

extension Paragraph {
	/**
	Whether each line of the paragraph starts and ends with `|`, like a table without its delimiter row (`| --- |`), which Markdown does not read as a table, so the page shows the pipes.
	*/
	fileprivate var isTableWithoutDelimiterRow: Bool {
		var lines = [""]

		for child in children {
			switch child {
			case is SoftBreak, is LineBreak:
				lines.append("")
			case let text as Text:
				lines[lines.count - 1] += text.string
			default:
				// Other markup, like code, is not a pipe.
				lines[lines.count - 1] += " "
			}
		}

		return lines.allSatisfy { line in
			let line = line.trimmingCharacters(in: .whitespaces)
			return line.count > 1 && line.hasPrefix("|") && line.hasSuffix("|")
		}
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

extension BlockDirective {
	/**
	What is wrong with the content for the rule of the directive, like “must contain one numbered list, and it has 3 blocks”, or `nil` when it follows the rule. HTML comments do not count, as the page does not show them, so a directive with braces and only a comment has no content.
	*/
	fileprivate func contentMistake(for rule: MarkdownDocument.Options.BlockDirectiveRenderer.Content) -> String? {
		let blocks = visibleBlockChildren
		let expected: String
		let isExpected: (any BlockMarkup) -> Bool

		switch rule {
		case .blocks:
			// An empty directive is a lost edit, like a deleted list. A directive without braces, like `@SocialLinks`, is on one line, so it is fine without content. Limitation: the parser does not keep the braces, so empty braces on the line of the directive, like `@Tips {}`, are not found, and neither are the empty braces of a directive whose arguments span lines, as its `)` can end it too.
			guard
				blocks.isEmpty,
				let range,
				argumentText.segments.allSatisfy({ $0.range?.lowerBound.line == range.lowerBound.line }),
				range.upperBound.line > range.lowerBound.line
			else {
				return nil
			}

			return "has no content. Write it between the braces, or remove the directive."
		case .empty:
			return blocks.isEmpty ? nil : "takes no content."
		case .orderedList:
			expected = "one numbered list"
			isExpected = { $0 is OrderedList }
		case .unorderedList:
			expected = "one bulleted list"
			isExpected = { $0 is UnorderedList }
		}

		guard !blocks.isEmpty else {
			return "must contain \(expected), and it has no content."
		}

		guard blocks.count == 1 else {
			// Several lists are usually indented content, which swift-markdown reads with the indentation of its first line removed from each line, so a nested list becomes part of the outer list, and the list is split.
			let hint = blocks.allSatisfy { $0 is any ListItemContainer } ? " A nested list must be indented more than its item, and the content of the directive must not be indented." : ""
			return "must contain \(expected), and it has \(blocks.count) blocks.\(hint)"
		}

		guard !isExpected(blocks[0]) else {
			return nil
		}

		let kind = switch blocks[0] {
		case is OrderedList:
			"a numbered list"
		case is UnorderedList:
			"a bulleted list"
		case is Paragraph:
			"a paragraph"
		default:
			"another block"
		}

		return "must contain \(expected), and it has \(kind)."
	}
}

extension Substring {
	/**
	The line without its indentation and the `>` of a block quote, like `` ```swift `` for `` > ```swift ``.
	*/
	fileprivate var blockContent: Substring {
		drop { $0.isWhitespace || $0 == ">" }
	}

	/**
	The fence character and its count at the start of the line, like `` ` `` and 3 for ```` ```swift ````, after the indentation and the `>` of a block quote, or `nil` when the line does not start with a fence.
	*/
	fileprivate var fenceRun: (character: Character, count: Int)? {
		let content = blockContent

		guard
			let character = content.first,
			character == "`" || character == "~"
		else {
			return nil
		}

		let count = content.prefix { $0 == character }.count
		return count >= 3 ? (character, count) : nil
	}

	/**
	The text of the cells of a table row, like `["A", "B"]` for `| A | B |`, split at each `|` that is not escaped, after the `>` of a block quote.
	*/
	fileprivate var tableRowCells: [String] {
		var row = blockContent.trimmingCharacters(in: .whitespaces)[...]

		if row.hasPrefix("|") {
			row = row.dropFirst()
		}

		if
			row.hasSuffix("|"),
			!row.hasSuffix("\\|")
		{
			row = row.dropLast()
		}

		var cells = [""]
		var isEscaped = false

		for character in row {
			if
				character == "|",
				!isEscaped
			{
				cells.append("")
			} else {
				cells[cells.count - 1].append(character)
			}

			isEscaped = character == "\\" && !isEscaped
		}

		return cells.map { $0.trimmingCharacters(in: .whitespaces) }
	}
}
