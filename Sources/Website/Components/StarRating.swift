import Elementary
import SiteKit

/**
A row of stars for a rating out of five, like for a review. Screen readers read it as one image, like “5 out of 5 stars”.
*/
struct StarRating: HTML {
	let rating: Int

	var body: some HTML<HTMLTag.div> {
		div(.role("img")) {
			for _ in 0..<rating {
				Icon.star.size(.rootEm(1.25))
			}
		}
		.accessibilityLabel("\(rating) out of 5 stars")
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			// The orange of the App Store in dark mode. On light cards, it has too little contrast, so it is a darker amber there.
			Style()
				.hstack(spacing: .rootEm(0.125))
				.color(.amber(600), dark: "#ff9500")
		}
	}
}
