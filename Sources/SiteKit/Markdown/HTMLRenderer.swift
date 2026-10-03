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

	private let footnoteDefinitions: [String: String]

	private(set) var problems = [MarkdownDocument.Problem]()
	private(set) var links = [MarkdownDocument.Link]()
	private var slugger = HeadingSlugger()
	private var tableColumnAlignments = [Table.ColumnAlignment?]()
	private var tableColumn = 0
	private var isInTableHead = false

	/**
	How many links the renderer is inside, including raw `<a>` tags. Bare URLs are not linked inside a link, as nested links are invalid HTML.
	*/
	private var linkDepth = 0

	/**
	Whether each list the renderer is inside is loose, innermost last. Computed once per list, as it looks at every item.
	*/
	private var looseLists = [Bool]()

	init(style: MarkdownDocument.Style, options: MarkdownDocument.Options = .init(), footnoteDefinitions: [String: String] = [:]) {
		self.style = style
		self.options = options
		self.footnoteDefinitions = footnoteDefinitions
	}

	private var theme: MarkdownTheme {
		options.theme
	}

	private var addsHeadingIDs: Bool {
		style == .extended
	}

	private var rendersAlerts: Bool {
		style == .extended
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
				renderer.html += #"<a href="\#(moreLink.url.escapedForHTML)" class="\#(renderer.theme.classes(for: .collapsibleMoreLink))">\#(moreLink.title.escapedForHTML)</a>"# + "\n"
			}

			renderer.html += "</div>\n"
			isGroupOpen = false
		}

		while index < blocks.count {
			let heading = blocks[index] as? Markdown.Heading

			// A heading with a lower level ends the group, and ends the sections when they follow a heading.
			if let heading, heading.level < sections.level {
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

				if heading != nil, let startHeadingID = sections.startHeadingID, headings.last?.id == startHeadingID {
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

	private mutating func renderCollapsibleSection(_ heading: Markdown.Heading, content: ArraySlice<any BlockMarkup>, name: String?) {
		let id = recordHeading(heading)
		let nameAttribute = name.map { #" name="\#($0.escapedForHTML)""# } ?? ""
		html += #"<details id="\#(id.escapedForHTML)"\#(nameAttribute) class="\#(theme.classes(for: .collapsibleSection))"><summary class="\#(theme.classes(for: .collapsibleSummary))"><span class="\#(theme.classes(for: .collapsibleTitle))">"#
		renderInlineChildren(of: heading, removingCustomID: true)
		html += #"</span><span class="\#(theme.classes(for: .collapsibleChevron))" aria-hidden="true"></span>"#

		if options.addsHeadingAnchors {
			html += headingAnchor(id: id)
		}

		html += #"</summary><div class="\#(theme.classes(for: .collapsibleContent))">"# + "\n"

		for block in content {
			visit(block)
		}

		html += "</div></details>\n"
	}

	mutating func visitHeading(_ heading: Markdown.Heading) {
		guard addsHeadingIDs else {
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
			html += headingAnchor(id: id)
		}

		html += "</h\(heading.level)>\n"
	}

	/**
	Adds the heading to the list of headings and returns its ID: the custom ID (`{#id}`), or a slug of the text.
	*/
	private mutating func recordHeading(_ heading: Markdown.Heading) -> String {
		let (text, customID) = heading.plainTextAndCustomID
		let id = customID ?? slugger.slug(for: text)
		headings.append(Heading(level: heading.level, text: text, id: id))
		return id
	}

	/**
	A link to the section, with a link icon and a check icon that `site.js` shows after copying the URL.
	*/
	private func headingAnchor(id: String) -> String {
		let icon = { (element: MarkdownElement, path: String) in
			#"<svg class="\#(theme.classes(for: element))" width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="\#(path)"/></svg>"#
		}

		return ##"<a href="#\##(id.escapedForHTML)" class="\##(theme.classes(for: .headingAnchor))" aria-label="Copy link to section" data-copy-link="">"##
			+ icon(.headingAnchorLinkIcon, "M7.775 3.275a.75.75 0 001.06 1.06l1.25-1.25a2 2 0 112.83 2.83l-2.5 2.5a2 2 0 01-2.83 0 .75.75 0 00-1.06 1.06 3.5 3.5 0 004.95 0l2.5-2.5a3.5 3.5 0 00-4.95-4.95l-1.25 1.25zm-.025 9.45a.75.75 0 01-1.06-1.06l-1.25 1.25a2 2 0 01-2.83-2.83l2.5-2.5a2 2 0 012.83 0 .75.75 0 001.06-1.06 3.5 3.5 0 00-4.95 0l-2.5 2.5a3.5 3.5 0 004.95 4.95l1.25-1.25z")
			+ icon(.headingAnchorCheckIcon, "M13.78 4.22a.75.75 0 010 1.06l-7.25 7.25a.75.75 0 01-1.06 0L2.22 9.28a.75.75 0 011.06-1.06L6 10.94l6.72-6.72a.75.75 0 011.06 0z")
			+ "</a>"
	}

	mutating func visitParagraph(_ paragraph: Paragraph) {
		guard
			let listItem = paragraph.parent as? ListItem,
			looseLists.last == false
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
				renderText(rest[...])
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
		if rendersAlerts, renderAlert(blockQuote) {
			return
		}

		html += "<blockquote>\n"
		descendInto(blockQuote)
		html += "</blockquote>\n"
	}

	mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
		let languageClass = codeBlock.language.map { #" class="language-\#($0.escapedForHTML)""# } ?? ""
		// Focusable, so keyboard users can scroll wide code.
		let pre = #"<pre tabindex="0"><code\#(languageClass)>\#(codeBlock.code.escapedForHTML)</code></pre>"#

		guard options.addsCopyButtons else {
			html += pre + "\n"
			return
		}

		let theme = options.theme
		let language = codeBlock.language.map { #"<span class="\#(theme.classes(for: .codeBlockLanguage))">\#($0.escapedForHTML)</span>"# } ?? ""
		let button = #"<button type="button" class="\#(theme.classes(for: .copyButton))" data-copy-code=""><span>Copy</span><span>Copied</span></button>"#
		html += #"<div class="\#(theme.classes(for: .codeBlock))" data-code-block=""><div class="\#(theme.classes(for: .codeBlockBar))">\#(language)\#(button)</div>\#(pre)</div>"# + "\n"
	}

	mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
		if addsHeadingIDs {
			attachDirectives(from: htmlBlock)
			checkDirectives(in: htmlBlock)
		}

		// Comments are notes for the author, like drafts and heading directives, so they are not published.
		let rawHTML = htmlBlock.rawHTML.removingHTMLComments

		if !rawHTML.allSatisfy(\.isWhitespace) {
			html += rawHTML
		}
	}

	mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
		html += "<hr>\n"
	}

	mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
		html += "<ul>\n"
		looseLists.append(unorderedList.isLoose)
		descendInto(unorderedList)
		looseLists.removeLast()
		html += "</ul>\n"
	}

	mutating func visitOrderedList(_ orderedList: OrderedList) {
		html += orderedList.startIndex == 1 ? "<ol>\n" : #"<ol start="\#(orderedList.startIndex)">"# + "\n"
		looseLists.append(orderedList.isLoose)
		descendInto(orderedList)
		looseLists.removeLast()
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

		if looseLists.last == true {
			html += "\n"
		}

		descendInto(listItem)
		html += "</li>\n"
	}

	mutating func visitTable(_ table: Table) {
		tableColumnAlignments = table.columnAlignments
		html += "<table>\n"
		descendInto(table)
		html += "</table>\n"
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
		var remainder = text.string[...]

		// Footnotes are only in the extended style. A reference without a definition is reported, even when the document has no definitions.
		if
			style == .extended,
			remainder.contains("[^")
		{
			while let match = remainder.firstMatch(of: /\[\^([^\]\s]+)\]/) {
				renderText(remainder[..<match.range.lowerBound])

				if let reference = footnoteReference(id: String(match.1)) {
					html += reference
				} else {
					problem("The footnote `[^\(match.1)]` has no definition, like `[^\(match.1)]: The note.` If it is not a footnote, write it as code.", line: text.range?.lowerBound.line)
					renderText(match.output.0)
				}

				remainder = remainder[match.range.upperBound...]
			}
		}

		renderText(remainder)
	}

	private mutating func renderText(_ text: Substring) {
		var remainder = text

		// Keyboard shortcuts written as `++Cmd+K++` become `<kbd>` elements, which are split into keys later. The `++` must not touch a letter, so `C++` stays text.
		if
			style == .extended,
			remainder.contains("++")
		{
			while let match = remainder.firstMatch(of: /\+\+(\S(?:[^\n]*?\S)?)\+\+/) {
				let before = remainder[..<match.range.lowerBound].last
				let after = remainder[match.range.upperBound...].first

				guard
					before.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true,
					after.map({ !$0.isLetter && !$0.isNumber && $0 != "+" }) ?? true
				else {
					// Only the opening `++` is text, as the closing one can open a shortcut.
					let openingEnd = remainder.index(match.range.lowerBound, offsetBy: 2)
					renderPlainText(remainder[..<openingEnd])
					remainder = remainder[openingEnd...]
					continue
				}

				renderPlainText(remainder[..<match.range.lowerBound])
				html += "<kbd>\(String(match.1).escapedForHTML)</kbd>"
				remainder = remainder[match.range.upperBound...]
			}
		}

		renderPlainText(remainder)
	}

	private mutating func renderPlainText(_ text: Substring) {
		// Like GitHub (and markdown-it with `linkify`), bare URLs and emails become links.
		html += linkDepth == 0 ? String(text).linkingBareURLs : String(text).escapedForHTML
	}

	/**
	The numbered link to a footnote, or `nil` when the footnote is not defined.
	*/
	private mutating func footnoteReference(id: String) -> String? {
		guard let definition = footnoteDefinitions[id] else {
			return nil
		}

		let index = footnotes.firstIndex { $0.id == id } ?? {
			footnotes.append(Footnotes.Footnote(id: id, definition: definition))
			return footnotes.count - 1
		}()

		let occurrence = footnotes[index].referenceAnchors.count + 1
		let anchorID = footnotes[index].anchorID
		let anchor = occurrence == 1 ? "user-content-fnref-\(anchorID)" : "user-content-fnref-\(anchorID)-\(occurrence)"
		footnotes[index].referenceAnchors.append(anchor)

		guard !options.showsFootnotesInPopovers else {
			return ##"<sup><button type="button" popovertarget="\##(footnotes[index].popoverID)" id="\##(anchor)" data-footnote-ref="" aria-label="Footnote \##(index + 1)" class="\##(options.theme.classes(for: .footnoteReference))">\##(index + 1)</button></sup>"##
		}

		return ##"<sup><a href="#user-content-fn-\##(anchorID)" id="\##(anchor)" data-footnote-ref="" aria-describedby="footnote-label">\##(index + 1)</a></sup>"##
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
			problem("The image `\(source)` has no description (alt text). Describe it, like `![Screenshot of the settings](…)`.", line: image.range?.lowerBound.line)
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
	private mutating func resolvedDestination(_ destination: String, of markup: Markup) -> String {
		var resolved = destination

		if style == .extended, let resolveLink = options.resolveLink {
			do {
				resolved = try resolveLink(destination)
			} catch {
				problem("\(error)", line: markup.range?.lowerBound.line)
			}
		}

		links.append(MarkdownDocument.Link(destination: resolved, line: markup.range?.lowerBound.line))
		return resolved
	}

	mutating func visitInlineAttributes(_ attributes: InlineAttributes) {
		let contentHTML = capturingHTML {
			$0.descendInto(attributes)
		}

		guard
			style == .extended,
			let render = options.inlineAttributes
		else {
			html += contentHTML
			return
		}

		do {
			html += try render(attributes.attributes, contentHTML)
		} catch {
			problem("\(error)", line: attributes.range?.lowerBound.line)
			html += contentHTML
		}
	}

	mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
		let contentHTML = capturingHTML {
			$0.descendInto(blockDirective)
		}

		guard let render = options.blockDirectives[blockDirective.name] else {
			problem("Unknown block directive `@\(blockDirective.name)`. Known directives: \(options.blockDirectives.keys.sorted().map { "`@\($0)`" }.joined(separator: ", ")).", line: blockDirective.range?.lowerBound.line)
			html += contentHTML
			return
		}

		var problems = [DirectiveArgumentText.ParseError]()
		let arguments = blockDirective.argumentText.parseNameValueArguments(parseErrors: &problems)

		for argumentProblem in problems {
			problem("The arguments of `@\(blockDirective.name)` are invalid: \(argumentProblem).", line: blockDirective.range?.lowerBound.line)
		}

		do {
			html += try render(Dictionary(arguments.map { ($0.name, $0.value) }) { first, _ in first }, contentHTML) + "\n"
		} catch {
			problem("\(error)", line: blockDirective.range?.lowerBound.line)
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

	mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
		let rawHTML = inlineHTML.rawHTML

		guard !rawHTML.hasPrefix("<!--") else {
			return
		}

		let lowercasedHTML = rawHTML.lowercased()

		if lowercasedHTML.hasPrefix("<a"), rawHTML.wholeMatch(of: /(?i)<a(\s[^>]*)?>/) != nil {
			linkDepth += 1
		} else if lowercasedHTML.hasPrefix("</a"), rawHTML.wholeMatch(of: /(?i)<\/a\s*>/) != nil {
			linkDepth = max(linkDepth - 1, 0)
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
		// The kind is checked on the text before rendering, so the paragraph renders once, into this renderer, with its links and footnotes counted.
		guard
			let paragraph = blockQuote.child(at: 0) as? Paragraph,
			let text = paragraph.child(at: 0) as? Text,
			let kindMatch = text.string.prefixMatch(of: /\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]/),
			let kind = MarkdownAlert(rawValue: kindMatch.1.lowercased())
		else {
			return false
		}

		let paragraphHTML = capturingHTML { renderer in
			renderer.renderInlineChildren(of: paragraph)
		}

		guard let match = paragraphHTML.wholeMatch(of: /(?s)\[!(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](.*)/) else {
			return false
		}

		let body = match.1.trimmingCharacters(in: .whitespacesAndNewlines)
		let icon = #"<svg class="\#(theme.classes(for: .alertIcon))" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="\#(kind.iconPath)"></path></svg>"#

		html += #"<div class="\#(theme.classes(for: .alert(kind)))" dir="auto">"#
		html += #"<p class="\#(theme.classes(for: .alertTitle))" dir="auto">\#(icon)\#(kind.title)</p>"#

		if !body.isEmpty {
			html += "<p>\(body)</p>\n"
		}

		for child in blockQuote.children.dropFirst() {
			visit(child)
		}

		html += "</div>\n"
		return true
	}

	/**
	Reports directive comments with unknown names, and directive comments that are not directly below a heading, as they would do nothing.
	*/
	private mutating func checkDirectives(in htmlBlock: HTMLBlock) {
		guard let knownDirectives = options.headingDirectives else {
			return
		}

		let lines = htmlBlock.rawHTML.split(separator: "\n")
		let isAttached = isDirectlyBelowHeading(htmlBlock) && lines.allSatisfy { HeadingDirectives().parsing($0) != nil }
		let firstLine = htmlBlock.range?.lowerBound.line

		for (index, line) in lines.enumerated() {
			guard let name = HeadingDirectives.name(in: line) else {
				continue
			}

			let lineNumber = firstLine.map { $0 + index }

			if !knownDirectives.contains(name) {
				problem("Unknown directive `@\(name)`. Known directives: \(knownDirectives.sorted().map { "`@\($0)`" }.joined(separator: ", ")).", line: lineNumber)
			} else if !isAttached {
				problem("The directive `@\(name)` must be directly below a heading, with only other directives between.", line: lineNumber)
			}
		}
	}

	/**
	Whether the block follows a heading, with only blocks of directives in between.
	*/
	private func isDirectlyBelowHeading(_ htmlBlock: HTMLBlock) -> Bool {
		var previous = htmlBlock.previousSibling

		while let block = previous as? HTMLBlock {
			guard block.rawHTML.split(separator: "\n").allSatisfy({ HeadingDirectives().parsing($0) != nil }) else {
				return false
			}

			previous = block.previousSibling
		}

		return previous is Markdown.Heading
	}

	private mutating func problem(_ message: String, line: Int?) {
		problems.append(MarkdownDocument.Problem(line: line, message: message))
	}

	/**
	Attaches `<!-- @namespace.name values -->` comments to the heading they directly follow. Other directive comments may be in between.
	*/
	private mutating func attachDirectives(from htmlBlock: HTMLBlock) {
		var previous = htmlBlock.previousSibling

		while let block = previous as? HTMLBlock {
			var scratch = HeadingDirectives()
			guard block.rawHTML.split(separator: "\n").allSatisfy({ scratch.parse($0) }) else {
				return
			}

			previous = block.previousSibling
		}

		guard previous is Markdown.Heading, !headings.isEmpty else {
			return
		}

		for line in htmlBlock.rawHTML.split(separator: "\n") {
			guard headings[headings.count - 1].directives.parse(line) else {
				return
			}
		}
	}

	private mutating func renderInlineChildren(of markup: Markup, removingCustomID: Bool = false) {
		let lastIndex = markup.childCount - 1

		for (index, child) in markup.children.enumerated() {
			if
				removingCustomID,
				index == lastIndex,
				let text = child as? Text
			{
				html += text.string.removingCustomHeadingID.escapedForHTML
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
		let text = plainText(includingImageDescriptions: false).removingFootnoteReferences

		guard
			text.contains("{#"),
			let match = text.firstMatch(of: /\s*\{#([\w-]+)\}\s*$/)
		else {
			return (text.trimmingCharacters(in: .whitespaces), nil)
		}

		return (String(text[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces), String(match.1))
	}
}

extension ListItemContainer {
	/**
	Whether a blank line separates any items, or any blocks inside an item, which makes CommonMark wrap item content in paragraphs.
	*/
	fileprivate var isLoose: Bool {
		// The range of a block can include trailing blank lines, so the end is where its last block ends. Inline ranges are not used, as cmark reports wrong positions after a hard line break.
		func contentEndLine(_ markup: Markup) -> Int? {
			markup.children.reversed().lazy.filter { $0 is BlockMarkup }.compactMap(contentEndLine).first ?? markup.range?.upperBound.line
		}

		func isSeparatedByBlankLine(_ first: Markup, _ second: Markup) -> Bool {
			guard
				let end = contentEndLine(first),
				let start = second.range?.lowerBound.line
			else {
				return false
			}

			return start - end > 1
		}

		let items = Array(listItems)

		for (item, next) in zip(items, items.dropFirst()) where isSeparatedByBlankLine(item, next) {
			return true
		}

		return items.contains { item in
			let blocks = Array(item.children)
			return zip(blocks, blocks.dropFirst()).contains { isSeparatedByBlankLine($0, $1) }
		}
	}
}

extension Markup {
	fileprivate var previousSibling: Markup? {
		guard let parent, indexInParent > 0 else {
			return nil
		}

		return parent.child(at: indexInParent - 1)
	}
}

extension String {
	/**
	The text with `&`, `<`, `>`, and `"` escaped, for HTML and XML text and attribute values.

	It works on Unicode scalars, as a combining mark after a quote makes them one character, which would not equal the quote.
	*/
	public var escapedForHTML: String {
		var result = ""
		result.reserveCapacity(utf8.count)

		for scalar in unicodeScalars {
			switch scalar {
			case "&":
				result += "&amp;"
			case "<":
				result += "&lt;"
			case ">":
				result += "&gt;"
			case "\"":
				result += "&quot;"
			default:
				result.unicodeScalars.append(scalar)
			}
		}

		return result
	}

	nonisolated(unsafe) private static let bareURLOrEmail = /(?i)(?<url>https?:\/\/[^\s<]+)|[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/

	private static let openingBrackets: [Character: Character] = [")": "(", "]": "[", "}": "{"]

	/**
	Whether an email address ends in a top-level domain that linkify-it links without `mailto:`: a two-letter country code or one of a few generic ones.
	*/
	private var hasLinkableTopLevelDomain: Bool {
		let topLevelDomain = split(separator: ".").last?.lowercased() ?? ""
		return topLevelDomain.count == 2 || ["biz", "com", "edu", "gov", "net", "org", "pro", "web", "xxx", "aero", "asia", "coop", "info", "museum", "name", "shop"].contains(topLevelDomain)
	}

	/**
	The HTML without `<!-- … -->` comments.
	*/
	var removingHTMLComments: String {
		contains("<!--") ? replacing(/(?s)<!--.*?-->/, with: "") : self
	}

	fileprivate var removingCustomHeadingID: String {
		contains("{#") ? replacing(/\s*\{#[\w-]+\}\s*$/, with: "") : self
	}

	/**
	Escapes the text and links bare URLs and email addresses, like markdown-it's `linkify`. Trailing punctuation is kept outside the link.
	*/
	fileprivate var linkingBareURLs: String {
		var result = ""
		var remainder = self[...]

		while let match = remainder.firstMatch(of: Self.bareURLOrEmail) {
			var token = String(match.output.0)
			let isEmail = match.output.url == nil

			// Like linkify-it, an email needs a known top-level domain, so file names like `icon@2x.png` stay text.
			guard !isEmail || token.hasLinkableTopLevelDomain else {
				result += String(remainder[..<match.range.upperBound]).escapedForHTML
				remainder = remainder[match.range.upperBound...]
				continue
			}

			result += String(remainder[..<match.range.lowerBound]).escapedForHTML

			// Trailing punctuation stays outside the link. A closing bracket stays inside when it closes one in the URL, like `…/Swift_(programming_language)`.
			var trailing = ""
			while let last = token.last, ".,;:!?)]}".contains(last) {
				if
					let opening = Self.openingBrackets[last],
					token.count(where: { $0 == opening }) >= token.count(where: { $0 == last })
				{
					break
				}

				trailing.insert(token.removeLast(), at: trailing.startIndex)
			}

			let href = isEmail ? "mailto:\(token)" : token
			result += #"<a href="\#(href.escapedForHTML)">\#(token.escapedForHTML)</a>\#(trailing.escapedForHTML)"#
			remainder = remainder[match.range.upperBound...]
		}

		return result + String(remainder).escapedForHTML
	}
}
