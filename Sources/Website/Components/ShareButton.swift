import Foundation
import Elementary
import SiteKit

/**
A “Share…” button that shows the share sheet of the browser for a page, and closes the popover it is in, as the share sheet replaces it.

The page is in the attributes of the element (``SharedPage/attributes()``), which the script reads on click.
*/
struct ShareButton: ScriptedElement {
	static let script = ElementScript()

	let page: SharedPage

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		page.attributes()
	}

	var content: some HTML {
		button(.type(.button)) {
			"Share…"
		}
		.buttonStyle(size: .small)
	}

	enum Styles: String, ElementStyleSet {
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

/**
A page to share with the share sheet of the browser, like an app on the App Store. The elements that share it, ``ShareButton`` and ``OverflowMenu``, have it in their attributes, which their scripts read with `sharedPage(element)` of `dom.js`.
*/
struct SharedPage {
	let title: String
	let url: URL

	/**
	The attributes of the element that shares the page.
	*/
	func attributes<Tag: HTMLTrait.Attributes.Global>() -> [HTMLAttribute<Tag>] {
		[.custom(name: "share-title", value: title), .custom(name: "share-url", value: url.absoluteString)]
	}
}
