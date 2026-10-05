import Elementary
import SiteKit

/**
Text in the blue to pink gradient of the site.
*/
struct GradientText: HTML {
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
			Style()
				.backgroundImage(.brandGradient)
				.color(.transparent)
				.backgroundClip(.text)
				// Keeps the end of the last letter inside the gradient.
				.padding(.trailing, .em(0.025))
				.margin(.trailing, .em(-0.025))
		}
	}
}
