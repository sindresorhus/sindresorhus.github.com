import Elementary
import SiteKit

/**
A row of stars for a rating out of five, like for a review. Screen readers read it as one image, like “5 out of 5 stars”, unless it is decorative.
*/
struct StarRating: HTML {
	let rating: Int

	/**
	Whether screen readers skip the stars, as the text around them says the rating once for all, like for a list of reviews that all have five stars.
	*/
	var isDecorative = false

	var body: some HTML<HTMLTag.div> {
		div {
			for _ in 0..<rating {
				Icon.star
			}
		}
		// The icons are hidden from screen readers, so a decorative row is silent without a label.
		.attributes(.role("img"), .ariaLabel("\(rating) out of 5 stars"), when: !isDecorative)
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
