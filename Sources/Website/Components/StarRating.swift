import Elementary
import Foundation
import SiteKit

/**
A row of five stars for a rating out of five, like for a review, or the average of an app, like 4.7, where the last star is filled in part. The stars above the rating are faint. Screen readers read it as one image, like “5 out of 5 stars”, unless it is decorative.
*/
struct StarRating: HTML {
	private let rating: Double

	/**
	Whether screen readers skip the stars, as the text around them says the rating once for all, like for a list of reviews that all have five stars.
	*/
	private let isDecorative: Bool

	/**
	A whole number of stars from a validated review.
	*/
	init(stars: ReviewStars, isDecorative: Bool = false) {
		self.rating = Double(stars.rawValue)
		self.isDecorative = isDecorative
	}

	/**
	The rounded average shown with the rating on the page.
	*/
	init(average: StoreRating, isDecorative: Bool = false) {
		self.rating = average.roundedAverage
		self.isDecorative = isDecorative
	}

	/**
	Where the filled part of the row ends, which the row sets.
	*/
	private static let fillWidth = StyleVariable<LengthPercentage>("star-fill")

	/**
	The size of a star, in rem.
	*/
	private static let starSize = 1.25

	/**
	The gap between the stars, in rem.
	*/
	private static let spacing = 0.125

	var body: some HTML<HTMLTag.div> {
		// One element for the five stars, as a list of reviews has hundreds of rows: the filled color, up to the rating, and the faint color, in the shapes of the stars. A partly filled star, like the last one of 4.7, is filled up to the part.
		let wholeStars = rating.rounded(.down)
		let filledEnd = wholeStars * (Self.starSize + Self.spacing) + (rating - wholeStars) * Self.starSize

		div {}
			// The stars are a mask, so screen readers do not see them, and a decorative row is silent without a label.
			.attributes(.role("img"), .ariaLabel("\(rating.formatted(.number.locale(.site))) out of 5 stars"), when: !isDecorative)
			.style(Styles.root)
			.style {
				$0.setting(Self.fillWidth, to: .rootEm(filledEnd))
			}
	}

	enum Styles: StyleSet {
		case root

		/**
		The orange of the App Store in dark mode. On light cards, it has too little contrast, so it is a darker amber there.
		*/
		private static let starColor = Color.lightDark(.amber(600), "#ff9500")

		/**
		The shape of the stars, written once.
		*/
		private static let mask = CSSImage.url(svg: Icon.star.standaloneSVG)

		var style: Style {
			switch self {
			case .root:
				// Five stars, with a gap between them. Limitation: the row does not wrap, like on a phone with very large text, but it is narrow enough for the smallest phones.
				Style()
					.frame(
						width: .rootEm(5 * StarRating.starSize + 4 * StarRating.spacing),
						height: .rootEm(StarRating.starSize)
					)
					.flexShrink(0)
					.backgroundImage(.linearGradient(.toRight, Self.starColor.at(StarRating.fillWidth.value), Color.secondaryText.opacity(0.35).at(StarRating.fillWidth.value)))
					.maskImage(Self.mask)
					.maskSize(width: .rootEm(StarRating.starSize), height: .rootEm(StarRating.starSize))
					.maskRepeat(.space)
					// Forced colors would remove the gradient, which is the stars.
					.forcedColorAdjust(.none)
			}
		}
	}
}
