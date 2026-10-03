import Foundation
import Markdown

public struct MarkdownAppContext: Sendable {
	public let title: String
	public let platforms: [String]

	public init(title: String, platforms: [String]) {
		self.title = title
		self.platforms = platforms
	}
}

public enum MarkdownProcessor {
	public static func process(_ source: String, appContext: MarkdownAppContext? = nil) -> ProcessedMarkdown {
		var workingSource = source
		if let appContext {
			workingSource = injectFeedbackFAQ(into: workingSource, context: appContext)
		}

		let footnotes = extractFootnotes(from: workingSource)
		var headingScan = scanHeadings(in: footnotes.source)
		if !footnotes.orderedIDs.isEmpty {
			headingScan.append(HeadingInfo(level: 2, text: "Footnotes", id: "footnote-label"))
		}
		let metadata = scanHeadingMetadata(in: footnotes.source, headings: headingScan)
		let renderSource = footnotes.source.replacingOccurrences(
			of: #"(?m)^(#{1,6}\s+.*?)[ \t]+\{#[A-Za-z0-9_-]+\}[ \t]*$"#,
			with: "$1",
			options: .regularExpression
		)
		let document = Document(parsing: renderSource)
		var renderer = SiteMarkdownRenderer(headings: headingScan)
		renderer.visit(document)
		var html = postProcessHTML(renderer.result)
		html += renderFootnotes(footnotes)
		let introduction = firstParagraphText(in: workingSource)
		return ProcessedMarkdown(html: html, headings: headingScan, headingMetadata: metadata, introduction: introduction)
	}

	private struct FootnoteExtraction {
		let source: String
		let orderedIDs: [String]
		let definitions: [String: String]
		let referenceAnchors: [String: [String]]
	}

	private static func extractFootnotes(from source: String) -> FootnoteExtraction {
		let lines = source
			.replacingOccurrences(of: "\r\n", with: "\n")
			.components(separatedBy: "\n")
		let definitionRegex = try! NSRegularExpression(
			pattern: #"^\[\^([^\]]+)\]:\s*(.*)$"#
		)

		var definitions: [String: String] = [:]
		var bodyLines: [String] = []
		var index = 0

		while index < lines.count {
			let line = lines[index]
			let range = NSRange(line.startIndex..<line.endIndex, in: line)

			guard
				let match = definitionRegex.firstMatch(in: line, range: range),
				let idRange = Range(match.range(at: 1), in: line),
				let bodyRange = Range(match.range(at: 2), in: line)
			else {
				bodyLines.append(line)
				index += 1
				continue
			}

			let id = String(line[idRange])
			var definitionLines = [String(line[bodyRange])]
			index += 1

			while index < lines.count {
				let continuation = lines[index]

				if continuation.hasPrefix("    ") {
					definitionLines.append(String(continuation.dropFirst(4)))
					index += 1
					continue
				}

				if continuation.hasPrefix("\t") {
					definitionLines.append(String(continuation.dropFirst()))
					index += 1
					continue
				}

				if continuation.trimmingCharacters(in: .whitespaces).isEmpty,
					index + 1 < lines.count
				{
					let next = lines[index + 1]
					if next.hasPrefix("    ") || next.hasPrefix("\t") {
						definitionLines.append("")
						index += 1
						continue
					}
				}

				break
			}

			definitions[id] = definitionLines.joined(separator: "\n")
		}

		var body = bodyLines.joined(separator: "\n")
		let referenceRegex = try! NSRegularExpression(pattern: #"\[\^([^\]]+)\]"#)
		let matches = referenceRegex.matches(
			in: body,
			range: NSRange(body.startIndex..<body.endIndex, in: body)
		)

		var orderedIDs: [String] = []
		var numbers: [String: Int] = [:]
		var counts: [String: Int] = [:]
		var referenceAnchors: [String: [String]] = [:]
		var replacements: [(Range<String.Index>, String)] = []

		for match in matches {
			guard
				let fullRange = Range(match.range(at: 0), in: body),
				let idRange = Range(match.range(at: 1), in: body)
			else {
				continue
			}

			let id = String(body[idRange])
			guard definitions[id] != nil else {
				continue
			}

			let number: Int
			if let existing = numbers[id] {
				number = existing
			} else {
				number = orderedIDs.count + 1
				numbers[id] = number
				orderedIDs.append(id)
			}

			let occurrence = counts[id, default: 0] + 1
			counts[id] = occurrence

			let safeID = footnoteID(id)
			let referenceAnchor = occurrence == 1
				? "user-content-fnref-\(safeID)"
				: "user-content-fnref-\(safeID)-\(occurrence)"
			referenceAnchors[id, default: []].append(referenceAnchor)

			let html = "<sup><a href=\"#user-content-fn-\(safeID)\" id=\"\(referenceAnchor)\" data-footnote-ref=\"\" aria-describedby=\"footnote-label\">\(number)</a></sup>"
			replacements.append((fullRange, html))
		}

		for (range, replacement) in replacements.reversed() {
			body.replaceSubrange(range, with: replacement)
		}

		return FootnoteExtraction(
			source: body,
			orderedIDs: orderedIDs,
			definitions: definitions,
			referenceAnchors: referenceAnchors
		)
	}

	private static func renderFootnotes(_ footnotes: FootnoteExtraction) -> String {
		guard !footnotes.orderedIDs.isEmpty else {
			return ""
		}

		let items = footnotes.orderedIDs.enumerated().map { index, id in
			let safeID = footnoteID(id)
			let definition = footnotes.definitions[id] ?? ""
			var definitionHTML = renderFragment(definition)
			let anchors = footnotes.referenceAnchors[id] ?? []

			let backlinks = anchors.enumerated().map { referenceIndex, anchor in
				let label = anchors.count == 1
					? "Back to reference \(index + 1)"
					: "Back to reference \(index + 1)-\(referenceIndex + 1)"
				return "<a href=\"#\(anchor)\" data-footnote-backref=\"\" aria-label=\"\(label)\" class=\"data-footnote-backref\">↩</a>"
			}.joined(separator: " ")

			if let paragraphEnd = definitionHTML.range(of: "</p>", options: .backwards) {
				definitionHTML.insert(contentsOf: " \(backlinks)", at: paragraphEnd.lowerBound)
			} else {
				definitionHTML += backlinks
			}

			return #"<li id="user-content-fn-\#(safeID)">\#(definitionHTML)</li>"#
		}.joined(separator: "\n")

		return """
		<section data-footnotes="" class="footnotes">
		<h2 class="sr-only" id="footnote-label">Footnotes</h2>
		<ol>
		\(items)
		</ol>
		</section>
		"""
	}

	private static func renderFragment(_ source: String) -> String {
		let headings = scanHeadings(in: source)
		let document = Document(parsing: source)
		var renderer = SiteMarkdownRenderer(headings: headings)
		renderer.visit(document)
		return postProcessHTML(renderer.result)
	}

	private static func footnoteID(_ id: String) -> String {
		id.lowercased().replacingOccurrences(
			of: #"[^a-z0-9_-]+"#,
			with: "-",
			options: .regularExpression
		)
	}

	private static func scanHeadings(in source: String) -> [HeadingInfo] {
		let lines = source.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
		let regex = try! NSRegularExpression(pattern: #"^(#{1,6})\s+(.+?)(?:\s+\{#([A-Za-z0-9_-]+)\})?\s*$"#)
		var result: [HeadingInfo] = []
		var used: [String: Int] = [:]
		var inFence = false
		for line in lines {
			let trimmed = line.trimmingCharacters(in: .whitespaces)
			if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") { inFence.toggle(); continue }
			guard !inFence else { continue }
			let range = NSRange(line.startIndex..<line.endIndex, in: line)
			guard let match = regex.firstMatch(in: line, range: range),
				let hashesRange = Range(match.range(at: 1), in: line),
				let textRange = Range(match.range(at: 2), in: line)
			else { continue }
			let level = line[hashesRange].count
			let rawText = String(line[textRange]).trimmingCharacters(in: .whitespaces)
			let explicitID: String? = match.range(at: 3).location == NSNotFound ? nil : Range(match.range(at: 3), in: line).map { String(line[$0]) }
			let base = explicitID ?? TextUtilities.slugify(stripMarkdown(rawText))
			let count = used[base, default: 0]
			used[base] = count + 1
			let id = count == 0 ? base : "\(base)-\(count)"
			result.append(HeadingInfo(level: level, text: stripMarkdown(rawText), id: id))
		}
		return result
	}

	private static func scanHeadingMetadata(in source: String, headings: [HeadingInfo]) -> [String: [String: FAQMetadata]] {
		let lines = source.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
		let headingRegex = try! NSRegularExpression(pattern: #"^(#{1,6})\s+(.+?)(?:\s+\{#([A-Za-z0-9_-]+)\})?\s*$"#)
		let directiveRegex = try! NSRegularExpression(pattern: #"^<!--\s*@([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)\s+(.+?)\s*-->$"#)
		var result: [String: [String: FAQMetadata]] = [:]
		var headingIndex = -1
		var currentHeadingID: String?
		for line in lines {
			let range = NSRange(line.startIndex..<line.endIndex, in: line)
			if headingRegex.firstMatch(in: line, range: range) != nil {
				headingIndex += 1
				currentHeadingID = headings.indices.contains(headingIndex) ? headings[headingIndex].id : nil
				continue
			}
			guard let match = directiveRegex.firstMatch(in: line, range: range), let currentHeadingID else {
				if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { currentHeadingID = nil }
				continue
			}
			guard let namespaceRange = Range(match.range(at: 1), in: line),
				let attributeRange = Range(match.range(at: 2), in: line),
				let valueRange = Range(match.range(at: 3), in: line)
			else { continue }
			let namespace = String(line[namespaceRange])
			let attribute = String(line[attributeRange])
			let values = String(line[valueRange]).split(whereSeparator: \.isWhitespace).map(String.init)
			var faq = result[currentHeadingID]?[namespace] ?? FAQMetadata()
			if attribute == "keywords" { faq.keywords = values }
			if attribute == "platforms" { faq.platforms = values }
			result[currentHeadingID, default: [:]][namespace] = faq
		}
		return result
	}

	private static func injectFeedbackFAQ(into source: String, context: MarkdownAppContext) -> String {
		guard let faqRange = source.range(of: #"(?m)^##\s+Frequently Asked Questions(?:\s+\{#faq\})?\s*$"#, options: .regularExpression) else { return source }
		let sectionStart = faqRange.upperBound
		let remaining = source[sectionStart...]
		let boundary = remaining.range(of: #"(?m)^##\s+"#, options: .regularExpression)?.lowerBound ?? source.endIndex
		let faqSection = String(source[sectionStart..<boundary])
		let feedbackURL = "https://sindresorhus.com/feedback?product=\(context.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? context.title)&referrer=Website-FAQ"
		let paragraph = "Click the feedback button in the app or [send it here.](\(feedbackURL))"

		if let existing = faqSection.range(of: #"(?mi)^####\s+.*feature request.*$"#, options: .regularExpression) {
			let absoluteLower = source.index(sectionStart, offsetBy: faqSection.distance(from: faqSection.startIndex, to: existing.lowerBound))
			let absoluteUpper = source.index(sectionStart, offsetBy: faqSection.distance(from: faqSection.startIndex, to: existing.upperBound))
			let line = String(source[absoluteLower..<absoluteUpper]).replacingOccurrences(of: #"\s+\{#[^}]+\}\s*$"#, with: "", options: .regularExpression)
			var copy = source
			copy.replaceSubrange(absoluteLower..<absoluteUpper, with: line + " {#feedback}")
			let insert = copy.index(absoluteLower, offsetBy: (line + " {#feedback}").count)
			copy.insert(contentsOf: "\n\n\(paragraph)", at: insert)
			return copy
		}

		var copy = source
		copy.insert(contentsOf: "\n\n#### I have a feature request, bug report, or some feedback {#feedback}\n\n\(paragraph)", at: sectionStart)
		return copy
	}

	private static func firstParagraphText(in source: String) -> String? {
		let lines = source
			.replacingOccurrences(of: "\r\n", with: "\n")
			.components(separatedBy: "\n")

		var index = 0

		func skipBlankLines() {
			while index < lines.count && lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
				index += 1
			}
		}

		skipBlankLines()

		while index < lines.count {
			let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
			guard trimmed.hasPrefix("<!--") else {
				break
			}

			while index < lines.count {
				let line = lines[index]
				index += 1
				if line.contains("-->") {
					break
				}
			}
			skipBlankLines()
		}

		guard index < lines.count else {
			return nil
		}

		let first = lines[index].trimmingCharacters(in: .whitespaces)

		let isNonParagraphBlock =
			first.range(of: #"^#{1,6}\s+"#, options: .regularExpression) != nil
			|| first.hasPrefix("```")
			|| first.hasPrefix("~~~")
			|| first.hasPrefix(">")
			|| first.hasPrefix("<")
			|| first.hasPrefix("![")
			|| first.range(of: #"^[-+*]\s+"#, options: .regularExpression) != nil
			|| first.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) != nil
			|| first.range(of: #"^(?:---+|___+|\*\*\*+)$"#, options: .regularExpression) != nil

		guard !isNonParagraphBlock else {
			return nil
		}

		var paragraphLines: [String] = []
		while index < lines.count {
			let line = lines[index]
			if line.trimmingCharacters(in: .whitespaces).isEmpty {
				break
			}
			paragraphLines.append(line)
			index += 1
		}

		var text = paragraphLines.joined(separator: "\n")
		text = text.replacingOccurrences(
			of: #"(?s)<!--.*?-->"#,
			with: "",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"!\[[^\]]*\]\([^)]*\)"#,
			with: "",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"\[([^\]]+)\]\([^)]*\)"#,
			with: "$1",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"<(https?://[^>]+)>"#,
			with: "$1",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"\x60([^\x60]*)\x60"#,
			with: "$1",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"<[^>]+>"#,
			with: "",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"(?<!\\)(?:\*\*|__|\*|_|~~)"#,
			with: "",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"\\([\\\x60*{}\[\]()#+\-.!_>])"#,
			with: "$1",
			options: .regularExpression
		)
		text = text.replacingOccurrences(
			of: #"\\?\n|\s+"#,
			with: " ",
			options: .regularExpression
		)
		text = text.trimmingCharacters(in: .whitespacesAndNewlines)

		return text.isEmpty ? nil : text
	}


	private static func stripMarkdown(_ value: String) -> String {
		value
			.replacingOccurrences(of: #"\{#[A-Za-z0-9_-]+\}\s*$"#, with: "", options: .regularExpression)
			.replacingOccurrences(of: #"!\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
			.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
			.replacingOccurrences(of: "`", with: "")
			.replacingOccurrences(of: "*", with: "")
			.replacingOccurrences(of: "_", with: "")
			.trimmingCharacters(in: .whitespaces)
	}

	private static func postProcessHTML(_ html: String) -> String {
		var result = html
		let regex = try! NSRegularExpression(pattern: #"<kbd>([^<]*\+[^<]*)</kbd>"#)
		let matches = regex.matches(in: result, range: NSRange(result.startIndex..<result.endIndex, in: result))

		for match in matches.reversed() {
			guard
				let range = Range(match.range(at: 1), in: result),
				let fullRange = Range(match.range(at: 0), in: result)
			else {
				continue
			}

			let source = String(result[range])
			guard source != "+" else {
				continue
			}

			let parts = source.split(separator: "+", omittingEmptySubsequences: false).map(String.init)
			let rendered = parts.enumerated().map { index, part in
				let key = part.isEmpty && index == parts.count - 1 ? "+" : part
				let separator = index == 0 ? "" : #"<span class="kbd-sep" aria-hidden="true">+</span>"#
				return separator + "<kbd>\(TextUtilities.escapeHTML(key))</kbd>"
			}.joined()
			result.replaceSubrange(fullRange, with: rendered)
		}

		return result
	}
}

private struct SiteMarkdownRenderer: MarkupWalker {
	var result = ""
	var headings: [HeadingInfo]
	var headingIndex = 0
	var inTableHead = false
	var tableColumnAlignments: [Markdown.Table.ColumnAlignment?]?
	var currentTableColumn = 0

	mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
		let preview = Self.renderChildren(of: blockQuote)
		let alertRegex = try! NSRegularExpression(
			pattern: #"(?s)^\s*<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*?)</p>(.*)$"#
		)
		let range = NSRange(preview.startIndex..<preview.endIndex, in: preview)

		if
			let match = alertRegex.firstMatch(in: preview, range: range),
			let kindRange = Range(match.range(at: 1), in: preview),
			let firstBodyRange = Range(match.range(at: 2), in: preview),
			let remainderRange = Range(match.range(at: 3), in: preview)
		{
			let kind = String(preview[kindRange]).lowercased()
			let title = kind.prefix(1).uppercased() + kind.dropFirst()
			let firstBody = String(preview[firstBodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
			let remainder = String(preview[remainderRange])
			result += #"<div class="markdown-alert markdown-alert-\#(kind)">"#
			result += #"<p class="markdown-alert-title">\#(title)</p>"#
			if !firstBody.isEmpty {
				result += "<p>\(firstBody)</p>"
			}
			result += remainder
			result += "</div>\n"
		} else {
			result += "<blockquote>\n"
			descendInto(blockQuote)
			result += "</blockquote>\n"
		}
	}

	mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
		let language = codeBlock.language.map { " class=\"language-\($0)\"" } ?? ""
		result += "<pre><code\(language)>\(TextUtilities.escapeHTML(codeBlock.code))</code></pre>\n"
	}

	mutating func visitHeading(_ heading: Heading) {
		let info = headings.indices.contains(headingIndex) ? headings[headingIndex] : HeadingInfo(level: heading.level, text: "", id: "")
		headingIndex += 1
		result += "<h\(heading.level) id=\"\(TextUtilities.escapeHTML(info.id))\">"
		descendInto(heading)
		result += "</h\(heading.level)>\n"
	}

	mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) { result += "<hr>\n" }
	mutating func visitHTMLBlock(_ html: HTMLBlock) { result += html.rawHTML }
	mutating func visitListItem(_ listItem: ListItem) {
		result += "<li>"
		if let checkbox = listItem.checkbox { result += checkbox == .checked ? #"<input type="checkbox" disabled checked> "# : #"<input type="checkbox" disabled> "# }
		descendInto(listItem)
		result += "</li>\n"
	}
	mutating func visitOrderedList(_ orderedList: OrderedList) {
		result += orderedList.startIndex == 1 ? "<ol>\n" : "<ol start=\"\(orderedList.startIndex)\">\n"
		descendInto(orderedList); result += "</ol>\n"
	}
	mutating func visitUnorderedList(_ unorderedList: UnorderedList) { result += "<ul>\n"; descendInto(unorderedList); result += "</ul>\n" }
	mutating func visitParagraph(_ paragraph: Paragraph) { result += "<p>"; descendInto(paragraph); result += "</p>\n" }
	mutating func visitTable(_ table: Markdown.Table) { result += "<table>\n"; tableColumnAlignments = table.columnAlignments; descendInto(table); tableColumnAlignments = nil; result += "</table>\n" }
	mutating func visitTableHead(_ tableHead: Markdown.Table.Head) { result += "<thead><tr>\n"; inTableHead = true; currentTableColumn = 0; descendInto(tableHead); inTableHead = false; result += "</tr></thead>\n" }
	mutating func visitTableBody(_ tableBody: Markdown.Table.Body) { if !tableBody.isEmpty { result += "<tbody>\n"; descendInto(tableBody); result += "</tbody>\n" } }
	mutating func visitTableRow(_ tableRow: Markdown.Table.Row) { result += "<tr>\n"; currentTableColumn = 0; descendInto(tableRow); result += "</tr>\n" }
	mutating func visitTableCell(_ tableCell: Markdown.Table.Cell) {
		let tag = inTableHead ? "th" : "td"
		var attrs = ""
		if let alignments = tableColumnAlignments, currentTableColumn < alignments.count, let alignment = alignments[currentTableColumn] { attrs += " align=\"\(alignment)\"" }
		currentTableColumn += 1
		if tableCell.rowspan > 1 { attrs += " rowspan=\"\(tableCell.rowspan)\"" }
		if tableCell.colspan > 1 { attrs += " colspan=\"\(tableCell.colspan)\"" }
		result += "<\(tag)\(attrs)>"; descendInto(tableCell); result += "</\(tag)>\n"
	}
	mutating func visitInlineCode(_ inlineCode: InlineCode) { result += "<code>\(TextUtilities.escapeHTML(inlineCode.code))</code>" }
	mutating func visitEmphasis(_ emphasis: Emphasis) { result += "<em>"; descendInto(emphasis); result += "</em>" }
	mutating func visitStrong(_ strong: Strong) { result += "<strong>"; descendInto(strong); result += "</strong>" }
	mutating func visitImage(_ image: Image) {
		let alt = (0..<image.childCount).compactMap { image.child(at: $0) }.map(MarkdownProcessorPlainText.text).joined()
		result += "<img src=\"\(TextUtilities.escapeHTML(image.source ?? ""))\" alt=\"\(TextUtilities.escapeHTML(alt))\""
		if let title = image.title { result += " title=\"\(TextUtilities.escapeHTML(title))\"" }
		result += ">"
	}
	mutating func visitInlineHTML(_ inlineHTML: InlineHTML) { result += inlineHTML.rawHTML }
	mutating func visitLineBreak(_ lineBreak: LineBreak) { result += "<br>\n" }
	mutating func visitSoftBreak(_ softBreak: SoftBreak) { result += "\n" }
	mutating func visitLink(_ link: Link) { result += "<a href=\"\(TextUtilities.escapeHTML(link.destination ?? ""))\">"; descendInto(link); result += "</a>" }
	mutating func visitText(_ text: Markdown.Text) { result += TextUtilities.escapeHTML(text.string) }
	mutating func visitStrikethrough(_ strikethrough: Strikethrough) { result += "<del>"; descendInto(strikethrough); result += "</del>" }

	private static func renderChildren(of markup: Markup) -> String {
		var renderer = SiteMarkdownRenderer(headings: [])
		for index in 0..<markup.childCount { if let child = markup.child(at: index) { renderer.visit(child) } }
		return renderer.result
	}
}

private enum MarkdownProcessorPlainText {
	static func text(_ markup: Markup) -> String {
		if let text = markup as? Markdown.Text { return text.string }
		if let code = markup as? InlineCode { return code.code }
		return (0..<markup.childCount).compactMap { markup.child(at: $0) }.map(text).joined()
	}
}
