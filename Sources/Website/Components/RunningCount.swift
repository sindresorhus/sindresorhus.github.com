import Elementary
import Foundation
import SiteKit

/**
A count that starts at 0 when the page is opened and goes up at a rate in every frame while it is on screen, like the npm downloads while the visitor has been on the page. A ``StatCard`` shows it for a ``Stat`` with a rate.

Without JavaScript, it stays at 0, so the now page hides it, like a ``LiveFact``.

It is not a CSS animation of an `@property` integer shown with `counter()`, as Safari 27 animates the integer as a decimal, which `counter()` does not accept, so it shows 0. CSS also cannot start the count when a prerendered page is opened.
*/
struct RunningCount: ScriptedElement {
	static let script = ElementScript()

	let perSecond: Double

	var config: Config? {
		Config(perSecond: perSecond)
	}

	var content: some HTML {
		"0"
	}

	struct Config: Encodable {
		let perSecond: Double

		/**
		The count from which the number has a thousands separator (``SiteNumberFormatStyle``), like the other numbers of the site.
		*/
		let groupingThreshold = SiteNumberFormatStyle.groupingThreshold

		/**
		The language of the site, like `en-US`, for the thousands separator.
		*/
		let locale = Locale.site.identifier(.bcp47)
	}

	enum Styles: String, ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The text is laid out as if the element were not there, like the other numbers. The digits have the same width, so the number does not move while it changes.
				Style()
					.display(.contents)
					.monospacedDigit()
			}
		}
	}
}
