import Elementary
import SiteKit

/**
Text only for screen readers, like a label for an icon.

For an element that is visually hidden but still works, like a file input with a styled label, apply the style with `.style(VisuallyHidden.Styles.root)`.
*/
struct VisuallyHidden: HTML {
	let text: String

	init(_ text: String) {
		self.text = text
	}

	var body: some HTML {
		span {
			text
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style().visuallyHidden()
		}
	}
}
