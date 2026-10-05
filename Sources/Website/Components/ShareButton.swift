import Foundation
import Elementary
import SiteKit

/**
A “Share…” button that shows the share sheet of the browser for a page, and closes the popover it is in, as the share sheet replaces it.

The page is the `share-title` and `share-url` attributes of the element, which the script reads on click.
*/
struct ShareButton: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		connectedCallback() {
			// The same function, so connecting the element again does not add a second listener.
			this.addEventListener('click', this.#share);
		}

		#share = async () => {
			this.closest('[popover]')?.hidePopover();

			try {
				await navigator.share({title: this.getAttribute('share-title'), url: this.getAttribute('share-url')});
			} catch (error) {
				if (error.name !== 'AbortError') {
					console.error('Share failed:', error.message);
				}
			}
		};
	}
	"""#)

	/**
	The title of the shared page.
	*/
	let pageTitle: String

	let url: URL

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.custom(name: "share-title", value: pageTitle), .custom(name: "share-url", value: url.absoluteString)]
	}

	var content: some HTML {
		button(.type(.button)) {
			"Share…"
		}
		.buttonStyle(size: .small)
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the button is laid out as if it were not there.
				Style().display(.contents)
			}
		}
	}
}
