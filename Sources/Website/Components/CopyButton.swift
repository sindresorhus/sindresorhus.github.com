import Elementary
import SiteKit

/**
A button that copies a text, like an email address or a link, and shows a checkmark instead of its title for a moment. It is hidden until its script finds that the browser can copy.

The text is the `text` attribute of the element, which the script reads on click, so another script can change it, like Appdle does with the result.
*/
struct CopyButton: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		// The pending timer that removes the copied state, so a second click restarts it.
		#copiedStateTimer;

		connectedCallback() {
			// Without clipboard access, the button stays hidden, as the visitor can still select the text.
			if (!navigator.clipboard) {
				return;
			}

			this.hidden = false;
			// The same function, so connecting the element again does not add a second listener.
			this.addEventListener('click', this.#copy);
		}

		#copy = async () => {
			try {
				await navigator.clipboard.writeText(this.getAttribute('text'));
			} catch {
				return;
			}

			this.dataset.state = 'copied';
			// On the button, as the element itself has no box. Older browsers, like Safari 26, have no `ariaNotify`. They say nothing, but the copied state still goes away.
			this.firstElementChild.ariaNotify?.('Copied');

			clearTimeout(this.#copiedStateTimer);
			this.#copiedStateTimer = setTimeout(() => {
				delete this.dataset.state;
			}, 1500);
		};
	}
	"""#)

	enum Look {
		/**
		A small secondary button, which shows a checkmark instead of its title for a moment after copying.
		*/
		case standard

		/**
		The raised gray button of the 1999 page.
		*/
		case retro
	}

	let title: String
	let text: String
	var look = Look.standard

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.hidden, .custom(name: "text", value: text)]
	}

	var content: some HTML {
		switch look {
		case .standard:
			// The title and the checkmark share one grid cell, so the button keeps its width when it shows the checkmark.
			button(.type(.button)) {
				span {
					span {
						title
					}
					.style(Styles.label)

					span {
						Icon.check.size(.rootEm(1.125))
					}
					.style(Styles.checkmark)
				}
				.style(Styles.labels)
			}
			.buttonStyle(.secondary, size: .small)
		case .retro:
			button(.type(.button)) {
				title
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
	}

	enum Styles: ElementStyleSet {
		case root
		case labels
		case label
		case checkmark

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the button is laid out as if it were not there.
				Style().display(.contents)
			case .labels:
				Style().display(.grid)
			case .label:
				// The title fades out, and the checkmark grows in, centered in the space of the title.
				Style()
					.stackedInGrid()
					.transition(.opacity, animation: .stateChange)
					.when(ancestorHas: .state, is: "copied") {
						$0.opacity(0)
					}
			case .checkmark:
				Style()
					.stackedInGrid()
					.hstack(alignment: .center, justification: .center)
					// A thicker line than other icons, so the checkmark is easy to see in the small button.
					.nested("svg") {
						$0.declaration(.strokeWidth, 2.75)
					}
					.opacity(0)
					.scaleEffect(0.5)
					.transition(.opacity, .scaleEffect, animation: .pop)
					.when(ancestorHas: .state, is: "copied") {
						$0
							.opacity(1)
							.scaleEffect(1)
					}
			}
		}
	}
}
