/**
GitHub-style footnotes, which swift-markdown does not parse.

Definitions (`[^id]: Text`, with indented continuation lines) are removed from the source here. References (`[^id]`) are replaced with numbered links by the renderer, in the text of the Markdown tree, so a reference in code stays as it is. Numbers follow the order of the first reference, and unreferenced definitions are dropped.
*/
struct Footnotes {
	struct Footnote {
		let id: String
		let definition: String
		var referenceAnchors = [String]()

		var anchorID: String {
			id.lowercased().replacing(/[^a-z0-9_-]+/, with: "-")
		}

		/**
		The ID of the popover with the footnote.
		*/
		var popoverID: String {
			"user-content-fn-popover-\(anchorID)"
		}
	}

	/**
	The source without the definitions. Fenced code blocks are left alone.
	*/
	let source: String

	/**
	The Markdown of each definition, by ID.
	*/
	let definitions: [String: String]

	init(extractingFrom source: String) {
		(self.source, self.definitions) = Self.extractDefinitions(from: source)
	}

	/**
	Renders the footnotes section, and optionally a popover for each footnote after it. Each definition is rendered with the given closure.

	The popovers are outside the text, as a paragraph cannot contain one. A popover is placed next to the reference that opened it.
	*/
	static func sectionHTML(for footnotes: [Footnote], theme: MarkdownTheme, withPopovers: Bool, renderingDefinitionsWith render: (String) -> String) -> String {
		guard !footnotes.isEmpty else {
			return ""
		}

		// Each definition renders once, for the list and the popover, so its problems and links are counted once.
		let definitionsHTML = footnotes.map { render($0.definition) }

		let items = footnotes.enumerated().map { index, footnote in
			let backReferences = footnote.referenceAnchors.enumerated().map { referenceIndex, anchor in
				let label = footnote.referenceAnchors.count == 1
					? "Back to reference \(index + 1)"
					: "Back to reference \(index + 1)-\(referenceIndex + 1)"
				let classes = theme.classes(for: .footnoteBackReference)
				let classAttribute = classes.isEmpty ? "" : #" class="\#(classes)""#
				return ##"<a href="#\##(anchor)" data-footnote-backref="" aria-label="\##(label)"\##(classAttribute)>↩</a>"##
			}
			.joined(separator: " ")

			var definitionHTML = definitionsHTML[index]
			if let paragraphEnd = definitionHTML.range(of: "</p>", options: .backwards) {
				definitionHTML.insert(contentsOf: " \(backReferences)", at: paragraphEnd.lowerBound)
			} else {
				definitionHTML += backReferences
			}

			return #"<li id="user-content-fn-\#(footnote.anchorID)">\#(definitionHTML)</li>"#
		}

		let popovers = withPopovers
			? zip(footnotes, definitionsHTML).map { footnote, html in #"<div popover id="\#(footnote.popoverID)" role="note" class="\#(theme.classes(for: .footnotePopover))">\#(html)</div>"# }.joined(separator: "\n")
			: ""

		return """
		<section data-footnotes="" class="\(theme.classes(for: .footnotes))">
		<h2 class="\(theme.classes(for: .visuallyHidden))" id="footnote-label">Footnotes</h2>
		<ol>
		\(items.joined(separator: "\n"))
		</ol>
		</section>
		\(popovers)
		"""
	}

	private static func extractDefinitions(from source: String) -> (body: String, definitions: [String: String]) {
		let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
		var definitions = [String: String]()
		var bodyLines = [Substring]()
		var index = 0

		var isInCodeBlock = false

		while index < lines.count {
			if lines[index].isCodeFence {
				isInCodeBlock.toggle()
			}

			guard
				!isInCodeBlock,
				lines[index].hasPrefix("[^"),
				let match = lines[index].wholeMatch(of: /\[\^([^\]]+)\]:\s*(.*)/)
			else {
				bodyLines.append(lines[index])
				index += 1
				continue
			}

			var definitionLines = [String(match.2)]
			index += 1

			while index < lines.count {
				let line = lines[index]

				if let continuation = line.droppingIndentation {
					definitionLines.append(String(continuation))
					index += 1
				} else if
					line.allSatisfy(\.isWhitespace),
					index + 1 < lines.count,
					lines[index + 1].droppingIndentation != nil
				{
					definitionLines.append("")
					index += 1
				} else {
					break
				}
			}

			definitions[String(match.1)] = definitionLines.joined(separator: "\n")
		}

		return (bodyLines.joined(separator: "\n"), definitions)
	}
}

extension Substring {
	fileprivate var isCodeFence: Bool {
		let line = drop { $0 == " " }
		return line.hasPrefix("```") || line.hasPrefix("~~~")
	}

	/**
	The line without one level of indentation (a tab or four spaces), or `nil` if it is not indented.
	*/
	fileprivate var droppingIndentation: Substring? {
		if hasPrefix("\t") {
			return dropFirst()
		}

		if hasPrefix("    ") {
			return dropFirst(4)
		}

		return nil
	}
}
