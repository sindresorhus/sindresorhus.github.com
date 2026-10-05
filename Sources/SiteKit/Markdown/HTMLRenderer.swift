import Foundation
import Markdown

/**
Renders a Markdown tree as HTML, like GitHub-flavored Markdown renderers do.
*/
struct HTMLRenderer: MarkupWalker {
	let style: MarkdownDocument.Style
	let options: MarkdownDocument.Options
	private(set) var html = ""
	private(set) var headings = [Heading]()

	/**
	The footnotes in the order of their first reference.
	*/
	private(set) var footnotes = [Footnotes.Footnote]()

	/**
	The footnote definitions of the document, by ID. They are rendered in the footnotes section, in the order of their first reference.
	*/
	private let footnoteDefinitions: [String: FootnoteDefinition]

	private(set) var problems = [MarkdownDocument.Problem]()
	private(set) var links = [MarkdownDocument.Link]()
	private var slugger = HeadingSlugger()
	private var tableColumnAlignments = [Table.ColumnAlignment?]()
	private var tableColumn = 0
	private var isInTableHead = false

	/**
	How many tables have each region name, so each name is unique.
	*/
	private var tableLabelCounts = [String: Int]()

	/**
	How many links the renderer is inside, and the summary of a collapsible section, which cannot have links either. A link inside them is only its text, as nested links are invalid HTML. Limitation: raw `<a>` tags are not counted, so a link or bare URL in the text of one is a nested link. Use Markdown links.
	*/
	private var linkDepth = 0

	/**
	How many of the next nodes are already rendered: the text and the end tag of a raw `<kbd>`, which are rendered as keys with the start tag.
	*/
	private var renderedKeyboardNodes = 0

	/**
	How many lines are above the source in its file.
	*/
	private let lineOffset: Int

	init(style: MarkdownDocument.Style, options: MarkdownDocument.Options = .init(), footnoteDefinitions: [String: FootnoteDefinition] = [:], lineOffset: Int = 0) {
		self.style = style
		self.options = options
		self.footnoteDefinitions = footnoteDefinitions
		self.lineOffset = lineOffset
	}

	/**
	The line where the markup starts, in the file of the source.
	*/
	private func line(of markup: any Markup) -> Int? {
		markup.range.map { $0.lowerBound.line + lineOffset }
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
		var isGroupOpen = false
		var index = 0

		func closeGroup(_ renderer: inout Self) {
			guard isGroupOpen else {
				return
			}

			if let moreLink = sections.moreLink {
				renderer.html += renderer.theme.collapsibleMoreLink(moreLink) + "\n"
			}

			renderer.html += "</div>\n"
			isGroupOpen = false
		}

		while index < blocks.count {
			let heading = blocks[index] as? Markdown.Heading

			// A heading with a lower level ends the group, and ends the sections when they follow a heading.
			if
				let heading,
				heading.level < sections.level
			{
				closeGroup(&self)

				if sections.startHeadingID != nil {
					isInSections = false
				}
			}

			guard
				isInSections,
				let heading,
				heading.level == sections.level
			else {
				visit(blocks[index])

				if
					heading != nil,
					let startHeadingID = sections.startHeadingID,
					headings.last?.id == startHeadingID
				{
					isInSections = true
				}

				index += 1
				continue
			}

			let end = blocks[(index + 1)...].firstIndex { ($0 as? Markdown.Heading).map { $0.level <= sections.level } ?? false } ?? blocks.count

			if !isGroupOpen {
				html += #"<div class="\#(theme.classes(for: .collapsibleSections))">"# + "\n"
				isGroupOpen = true
			}

			renderCollapsibleSection(heading, content: blocks[(index + 1)..<end], name: sections.name)
			index = end
		}

		closeGroup(&self)
	}

	/**
	Renders the heading and its content as a collapsible section. The heading stays a heading inside the summary, so it is in the outline of the page.
	*/
	private mutating func renderCollapsibleSection(_ heading: Markdown.Heading, content: ArraySlice<any BlockMarkup>, name: String?) {
		let id = recordHeading(heading)

		// A bare URL is only text in the heading, so it is not a lost link.
		func containsLink(_ markup: any Markup) -> Bool {
			((markup as? Link).map { !$0.isBareURL } ?? false) || markup.children.contains(where: containsLink)
		}

		// A summary is a button, so a link in it is invalid, and a click would open the link instead of the section. The links of the heading are only their text, and a problem, as the link would be lost.
		if containsLink(heading) {
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

		let section = theme.collapsibleSection(id: id, name: name, headingLevel: heading.level, titleHTML: titleHTML, contentHTML: "\n" + contentHTML)

		guard options.addsHeadingAnchors else {
			html += section + "\n"
			return
		}

		html += #"<div class="\#(theme.classes(for: .anchoredSection))">\#(theme.headingAnchor(id: id))\#(section)</div>"# + "\n"
	}

	mutating func visitHeading(_ heading: Markdown.Heading) {
		guard style == .extended else {
			html += "<h\(heading.level)>"
			renderInlineChildren(of: heading)
			html += "</h\(heading.level)>\n"
			return
		}

		let id = recordHeading(heading)
		let hasAnchor = options.addsHeadingAnchors && (2...4).contains(heading.level)
		let classAttribute = hasAnchor ? #" class="\#(theme.classes(for: .anchoredHeading))""# : ""
		html += #"<h\#(heading.level) id="\#(id.escapedForHTML)"\#(classAttribute)>"#
		renderInlineChildren(of: heading, removingCustomID: true)

		if hasAnchor {
			html += theme.headingAnchor(id: id)
		}

		html += "</h\(heading.level)>\n"
	}

	/**
	Adds the heading to the list of headings and returns its ID: the custom ID (`{#id}`), or a slug of the text.
	*/
	private mutating func recordHeading(_ heading: Markdown.Heading) -> String {
		let (text, customID) = heading.plainTextAndCustomID
		let id = customID ?? slugger.slug(for: text)
		headings.append(Heading(level: heading.level, text: text, id: id, line: line(of: heading)))
		return id
	}

	mutating func visitParagraph(_ paragraph: Paragraph) {
		// The items of a tight list, like CommonMark, have no paragraphs around their text.
		guard
			let listItem = paragraph.parent as? ListItem,
			listItem.isInTightList
		else {
			html += "<p>"
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
				html += #"<span class="\#(theme.classes(for: element))">"#
				openSpan = true
				renderTextCheckingFootnotes(rest[...], of: text)
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
	private static func listLineMarker(_ text: String) -> (MarkdownElement, String)? {
		if text.hasPrefix(":: ") {
			return (.listDescription, String(text.dropFirst(3)))
		}

		if text.hasPrefix(": ") {
			return (.listSubtitle, String(text.dropFirst(2)))
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
		if let commentStart = rawHTML.range(of: "<!--") {
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
			trimmedHTML.hasPrefix("<table>") || trimmedHTML.hasPrefix("<table "),
			trimmedHTML.hasSuffix("</table>")
		{
			html += theme.tableContainer(label: tableLabel(), tableHTML: rawHTML) + "\n"
		} else {
			html += rawHTML
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
		isInTableHead = true
		tableColumn = 0
		html += "<thead><tr>\n"
		descendInto(tableHead)
		html += "</tr></thead>\n"
		isInTableHead = false
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
		tableColumn = 0
		html += "<tr>\n"
		descendInto(tableRow)
		html += "</tr>\n"
	}

	mutating func visitTableCell(_ tableCell: Table.Cell) {
		// A cell that a span covers has a span of 0, and no cell of its own.
		guard
			tableCell.colspan > 0,
			tableCell.rowspan > 0
		else {
			tableColumn += 1
			return
		}

		let tag = isInTableHead ? "th" : "td"
		var attributes = ""

		if
			tableColumnAlignments.indices.contains(tableColumn),
			let alignment = tableColumnAlignments[tableColumn]
		{
			attributes += #" align="\#(alignment)""#
		}

		if tableCell.rowspan > 1 {
			attributes += #" rowspan="\#(tableCell.rowspan)""#
		}

		if tableCell.colspan > 1 {
			attributes += #" colspan="\#(tableCell.colspan)""#
		}

		tableColumn += 1
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

			for match in string.matches(of: Footnotes.reference) {
				if isInBlockDirective {
					reportProblem("The footnote `[^\(match.1)]` has no definition in its block directive. A footnote in a block directive, like `@Tips`, needs its definition, like `[^\(match.1)]: The note.`, inside the same directive.", line: line(of: text))
				} else {
					reportProblem("The footnote `[^\(match.1)]` has no definition, like `[^\(match.1)]: The note.` If it is not a footnote, write it as code. A definition inside a block directive is only for the footnotes in that directive.", line: line(of: text))
				}
			}
		}

		renderText(string)
	}

	mutating func visitFootnoteReference(_ footnoteReference: FootnoteReference) {
		let id = footnoteReference.footnoteID

		// A footnote reference is a link, and a link must not be inside another link or the heading of a collapsible section.
		guard linkDepth == 0 else {
			reportProblem("The footnote `[^\(id)]` is inside a link or the heading of a collapsible section, which cannot have links. Put it after the link, or in the text below the heading.", line: line(of: footnoteReference))
			renderText("[^\(id)]")
			return
		}

		// The definitions are rendered on their own, without the definitions of the document.
		guard let referenceHTML = self.footnoteReference(id: id) else {
			reportProblem("The footnote `[^\(id)]` is inside another footnote. Footnotes cannot be nested.", line: line(of: footnoteReference))
			renderText("[^\(id)]")
			return
		}

		html += referenceHTML
	}

	/**
	The definitions are rendered in the footnotes section, not where they are.
	*/
	mutating func visitFootnoteDefinition(_ footnoteDefinition: FootnoteDefinition) {}

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
	The numbered link to a footnote, or `nil` when the footnote is not defined.
	*/
	private mutating func footnoteReference(id: String) -> String? {
		guard let definition = footnoteDefinitions[id] else {
			return nil
		}

		let index = footnotes.firstIndex { $0.id == id } ?? {
			footnotes.append(Footnotes.Footnote(id: id, definition: definition, otherFootnotes: footnotes))
			return footnotes.count - 1
		}()

		let anchor = footnotes[index].referenceID(occurrence: footnotes[index].referenceAnchors.count + 1)
		footnotes[index].referenceAnchors.append(anchor)

		return footnotes[index].referenceHTML(number: index + 1, anchor: anchor, opensPopover: options.showsFootnotesInPopovers, theme: theme)
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
		guard linkDepth == 0 else {
			descendInto(link)
			return
		}

		let title = link.title.map { #" title="\#($0.escapedForHTML)""# } ?? ""
		html += #"<a href="\#(resolvedDestination(link.destination ?? "", of: link).escapedForHTML)"\#(title)>"#
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
	The destination after ``MarkdownDocument/Options/resolveLink``, recorded in the links. A destination that cannot be resolved is a problem.
	*/
	private mutating func resolvedDestination(_ destination: String, of markup: any Markup) -> String {
		var resolved = destination

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

	mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
		let contentHTML = capturingHTML {
			$0.descendInto(blockDirective)
		}

		guard let renderer = options.blockDirectives[blockDirective.name] else {
			reportProblem("Unknown block directive `@\(blockDirective.name)`. Known directives: \(options.blockDirectives.keys.sorted().map { "`@\($0)`" }.joined(separator: ", ")).", line: line(of: blockDirective))
			html += contentHTML
			return
		}

		var problems = [DirectiveArgumentText.ParseError]()
		let arguments = blockDirective.argumentText.parseNameValueArguments(parseErrors: &problems)

		for argumentProblem in problems {
			reportProblem("The arguments of `@\(blockDirective.name)` are invalid: \(argumentProblem).", line: line(of: blockDirective))
		}

		do {
			html += try renderer.render(Dictionary(arguments.map { ($0.name, $0.value) }) { first, _ in first }, contentHTML) + "\n"
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
				reportProblem("The directive `@\(comment.name)` must be directly below a heading, on its own line, with only other directives between.", line: line(of: inlineHTML))
			}

			return
		}

		html += rawHTML
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
				reportProblem("The directive `@\(comment.name)` must be directly below a heading, on its own line, with only other directives between.", line: line)
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
		problems.append(MarkdownDocument.Problem(line: line, message: message))
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

		return (String(text[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces), String(match.1))
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
		contains("<!--") ? replacing(/(?s)<!--.*?-->/, with: "") : self
	}

	/**
	A custom heading ID at the end of a heading, like ` {#install}`.
	*/
	nonisolated(unsafe) fileprivate static let customHeadingID = /\s*\{#([\w-]+)\}\s*$/

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
