import Elementary
import Foundation
import Markdown

/**
GitHub-style footnotes: the parser reads the references (`[^id]`) and the definitions (`[^id]: Text`), like GitHub, and the renderer numbers the references and renders the definitions at the end. Numbers follow the order of the first reference, and unreferenced definitions are dropped.
*/
enum Footnotes {
	struct Footnote {
		let id: String
		let definition: FootnoteDefinition

		/**
		The ID in the anchors of the footnote: the ID with only letters, digits, `_`, and `-`, and a number when another footnote of the document already has it, like `a-b-2` for `a.b` after `a-b`.
		*/
		let anchorID: String

		var referenceAnchors = [String]()

		init(id: String, definition: FootnoteDefinition, otherFootnotes: [Self]) {
			self.id = id
			self.definition = definition

			let base = id.lowercased().replacing(/[^a-z0-9_-]+/, with: "-")
			var anchorID = base
			var number = 1

			while otherFootnotes.contains(where: { $0.anchorID == anchorID }) {
				number += 1
				anchorID = "\(base)-\(number)"
			}

			self.anchorID = anchorID
		}

		/**
		The ID of the footnote in the list at the end.
		*/
		var definitionID: String {
			"user-content-fn-\(anchorID)"
		}

		/**
		The ID of the popover with the footnote.
		*/
		var popoverID: String {
			"user-content-fn-popover-\(anchorID)"
		}

		/**
		The ID of a reference to the footnote, by its number in the text, starting at 1, like GitHub: `user-content-fnref-note` for the first and `user-content-fnref-note-2` for the second.
		*/
		func referenceID(occurrence: Int) -> String {
			occurrence == 1 ? "user-content-fnref-\(anchorID)" : "user-content-fnref-\(anchorID)-\(occurrence)"
		}

		/**
		The numbered reference to the footnote in the text: a button that opens its popover, or a link to it in the list at the end.

		- Parameter anchor: The ID of the reference, from ``referenceID(occurrence:)``.
		*/
		func referenceHTML(number: Int, anchor: String, opensPopover: Bool, theme: MarkdownTheme) -> String {
			sup {
				if opensPopover {
					button(.type(.button), .popoverTarget(popoverID), .id(anchor), .data("footnote-ref", value: ""), .class(theme.classes(for: .footnoteReference))) {
						"\(number)"
					}
					.accessibilityLabel("Footnote \(number)")
				} else {
					a(.href("#\(definitionID)"), .id(anchor), .data("footnote-ref", value: ""), .ariaDescribedBy(Heading.footnotesID)) {
						"\(number)"
					}
				}
			}
			.render()
		}
	}

	/**
	A reference to a footnote, like `[^note]`, with the ID. The parser turns a reference with a definition into a ``FootnoteReference``, so one in the text has no definition.
	*/
	nonisolated(unsafe) static let reference = /\[\^([^\]\s]+)\]/

	/**
	Renders the footnotes section, and optionally a popover for each footnote after it. Each definition is rendered with the given closure.

	The popovers are outside the text, as a paragraph cannot contain one. A popover is placed next to the reference that opened it.
	*/
	static func sectionHTML(for footnotes: [Footnote], theme: MarkdownTheme, withPopovers: Bool, renderingDefinitionsWith render: (Footnote) -> String) -> String {
		guard !footnotes.isEmpty else {
			return ""
		}

		// Each definition renders once, for the list and the popover, so its problems and links are counted once.
		let definitionsHTML = footnotes.map(render)

		let backReferenceClasses = theme.classes(for: .footnoteBackReference)

		let items = footnotes.enumerated().map { index, footnote in
			let backReferences = footnote.referenceAnchors.enumerated().map { referenceIndex, anchor in
				let label = footnote.referenceAnchors.count == 1
					? "Back to reference \(index + 1)"
					: "Back to reference \(index + 1)-\(referenceIndex + 1)"

				// The text presentation selector, so the arrow is text in the color of the link, not a blue emoji.
				return a(.href("#\(anchor)"), .data("footnote-backref", value: "")) {
					"↩\u{FE0E}"
				}
				.accessibilityLabel(label)
				.attributes(.class(backReferenceClasses), when: !backReferenceClasses.isEmpty)
				.render()
			}
			.joined(separator: " ")

			var definitionHTML = definitionsHTML[index]
			if let paragraphEnd = definitionHTML.range(of: "</p>", options: .backwards) {
				definitionHTML.insert(contentsOf: " \(backReferences)", at: paragraphEnd.lowerBound)
			} else {
				definitionHTML += backReferences
			}

			return definitionHTML
		}

		let list = section(.data("footnotes", value: ""), .class(theme.classes(for: .footnotes))) {
			"\n"
			h2(.class(theme.classes(for: .visuallyHidden)), .id(Heading.footnotesID)) {
				"Footnotes"
			}
			"\n"
			ol {
				"\n"
				for (footnote, itemHTML) in zip(footnotes, items) {
					li(.id(footnote.definitionID)) {
						HTMLRaw(itemHTML)
					}
					"\n"
				}
			}
			"\n"
		}

		let popovers = withPopovers
			? zip(footnotes, definitionsHTML).map { footnote, html in
				div(.popover, .id(footnote.popoverID), .role("note"), .class(theme.classes(for: .footnotePopover))) {
					HTMLRaw(html)
				}
				.render()
			}
			.joined(separator: "\n")
			: ""

		return list.render() + "\n" + popovers
	}
}
