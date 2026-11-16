import Elementary
import SiteKit

/**
The text of an inline note in Markdown, like `^[Spotlight](note: "The search of macOS.")` (``SiteKit/MarkdownDocument/Options/inlineNote``): a link that wraps like the text around it and opens the note in a popover next to it, on a click, a tap, or Enter. A second click closes it, like Escape, a click outside, or Tab out of the note (`site.js`, like for footnotes).

The note is a popover at the end of the document, which the link names. Only a button can open a popover without a script, and a button does not wrap across lines. Without JavaScript, the link does nothing.
*/
struct InlineNote: ScriptedElement {
	static let script = ElementScript()

	/**
	The HTML of the text.
	*/
	let textHTML: String

	/**
	The ID of the popover with the note.
	*/
	let noteID: ElementID

	/**
	The HTML of the text of a note, for ``SiteKit/MarkdownDocument/Options/inlineNote``.
	*/
	@Sendable
	static func render(textHTML: String, noteID: ElementID) -> String {
		Self(textHTML: textHTML, noteID: noteID).render()
	}

	var content: some HTML {
		// The text as it is, with a dotted underline, which is solid under the pointer and while the note is open.
		a(.href(.fragment(noteID)), .ariaExpanded(false)) {
			HTMLRaw(textHTML)
		}
		.style {
			$0
				.inherits(.color)
				.underline(
					style: .dotted,
					color: .secondaryText,
					thickness: .pixels(1.5),
					offset: .em(0.2)
				)
				.hoverOrFocusVisible(Self.solidUnderline)
				.expanded(Self.solidUnderline)
		}
	}

	/**
	The underline of the text under the pointer and while the note is open: solid, in the color of the text.
	*/
	private static func solidUnderline(_ style: Style) -> Style {
		style
			.underlineStyle(.solid)
			.underlineColor(.currentColor)
	}

	enum Styles: String, ElementStyleSet {
		case root

		var style: Style {
			// The element only adds the behavior, so the link is laid out as if it were not there.
			Style().display(.contents)
		}
	}
}
