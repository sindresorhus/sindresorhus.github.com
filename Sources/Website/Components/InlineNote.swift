import Elementary
import SiteKit

/**
The text of an inline note in Markdown, like `^[Spotlight](note: "The search of macOS.")` (``SiteKit/MarkdownDocument/Options/inlineNote``): a link that wraps like the text around it and opens the note in a popover next to it, on a click, a tap, or Enter. A second click closes it, like Escape, a click outside, or Tab out of the note (`site.js`, like for footnotes).

The note is a popover at the end of the document, which the link names. Only a button can open a popover without a script, and a button does not wrap across lines. Without JavaScript, the link does nothing.
*/
struct InlineNote: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		// Whether the note was open when the pointer last went down on the link. The browser can close the note on the press, as the link is outside the note, so the click must not open it again.
		#wasOpen = false;

		connectedCallback() {
			// The same functions, so connecting the element again does not add second listeners.
			this.addEventListener('pointerdown', this.#rememberState);
			this.addEventListener('click', this.#toggle);
			this.#note.addEventListener('toggle', this.#updateExpanded);
		}

		get #link() {
			return this.firstElementChild;
		}

		// The note is at the end of the document, as it can have paragraphs, so the link names it, like `popovertarget` of a button.
		get #note() {
			return document.getElementById(this.#link.hash.slice(1));
		}

		#rememberState = () => {
			this.#wasOpen = this.#note.matches(':popover-open');
		};

		#toggle = event => {
			event.preventDefault();

			// A click from the keyboard has no pointer press (its `detail` is 0), so a press that did not end in a click, like a right-click, does not count. The note is closed here too, for browsers that do not close it on the press.
			if (event.detail > 0 && this.#wasOpen) {
				this.#note.hidePopover();
				return;
			}

			// The link is the source, so the note is placed next to it.
			this.#note.togglePopover({source: this.#link});
		};

		#updateExpanded = event => {
			this.#link.ariaExpanded = event.newState === 'open';
		};
	}
	"""#)

	/**
	The HTML of the text.
	*/
	let textHTML: String

	/**
	The ID of the popover with the note.
	*/
	let noteID: String

	/**
	The HTML of the text of a note, for ``SiteKit/MarkdownDocument/Options/inlineNote``.
	*/
	@Sendable
	static func render(textHTML: String, noteID: String) -> String {
		Self(textHTML: textHTML, noteID: noteID).render()
	}

	var content: some HTML {
		// The text as it is, with a dotted underline, which is solid under the pointer and while the note is open.
		a(.href("#\(noteID)"), .ariaExpanded(false)) {
			HTMLRaw(textHTML)
		}
		.style {
			$0
				.color(.inherit)
				.underline(style: .dotted, color: .secondaryText, thickness: .pixels(1.5), offset: .em(0.2))
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

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			// The element only adds the behavior, so the link is laid out as if it were not there.
			Style().display(.contents)
		}
	}
}
