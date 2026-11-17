import Elementary
import Foundation
import SiteKit

/**
Selected five-star reviews on the App Store or Gumroad as testimonials. The press quotes lead with their source instead, without cards (``PressQuotes``), so the two kinds of praise look different.

The section is a band in the accent of the page across the whole width, so the praise is a chapter of its own on a long page.
*/
struct AppReviews: HTML {
	let reviews: [StoreReview]

	/**
	The app, for a link to all its quotes and reviews on the wall of love. Only when the wall of love has more than the page: the page shows all the press quotes of the app, so the wall has more only when the app has more reviews than the page shows.
	*/
	var app: App?

	/**
	Creates the section only when there is praise to show. The listing owns which app the reviews belong to, so the link cannot identify another app.
	*/
	init?(listing: AppListing) {
		let reviews = listing.newestReviews

		guard !reviews.isEmpty else {
			return nil
		}

		self.init(reviews: reviews, app: listing.app.isActive && listing.reviews.count > reviews.count ? listing.app : nil)
	}

	/**
	Creates explicitly supplied testimonials, such as the examples in the gallery.
	*/
	init(reviews: [StoreReview], app: App? = nil) {
		self.reviews = reviews
		self.app = app
	}

	var body: some HTML<HTMLTag.section> {
		section {
			div {
				// Keep the US average separate from selected international reviews, which are a different sample.
				h2 {
					"What Users Say"
				}
				.style(SectionStyles.label)

				QuoteGrid(reviews: reviews)

				if let app {
					p {
						a(.href(.path(.reviews, query: [URLQueryItem(name: ReviewsPage.Parameters.app.rawValue, value: app.slug.value)]))) {
							"More about \(app.title) on the Wall of Love"
						}
						// The arrow is only on the screen, so the name of the link is its text.
						.style {
							$0
								.moreLink()
								// The accent of the app, like the band of the reviews around it.
								.color(.accentText)
								.trailingArrow()
						}
					}
					.style(Styles.moreLink)
				}
			}
			.style(Styles.content)
			.style(Styles.wideContent, when: QuoteLayout(count: reviews.count).isWide)
		}
		.style(Styles.band)
	}

	enum Styles: String, StyleSet {
		case band
		case content
		case wideContent
		case moreLink

		/**
		The page background with a percentage of the accent. The dark page is a little blue, and a mix in OKLCH goes around the hue circle, so a little of a warm accent, like yellow, would stay blue. So in dark mode, the accent is mixed in OKLab into the page background without its blue, and the band has the hue of the accent and the lightness of the mix in OKLCH.
		*/
		private static func tint(light: Double, dark: Double) -> Color {
			.lightDark(
				.pageBackground.mix(with: .pageAccent, amount: .percent(light)),
				SemanticColor.pageBackgroundColors.dark.neutral.mix(with: .pageAccent, amount: .percent(dark), in: .oklab)
			)
		}

		var style: Style {
			switch self {
			case .band:
				// A little of the accent in the page background, with a line above and below. The cards on it have the page background in light mode and a lighter surface in dark mode (``QuoteGrid``), so they stand out from the band.
				Style()
					.padding(.vertical, .rootEm(4))
					.background(Self.tint(light: 6, dark: 9))
					.border([.top, .bottom], Self.tint(light: 18, dark: 18), width: .pixels(1))
			case .content:
				Style()
					.contentColumn()
			case .wideContent:
				// More than two reviews are wider, with the edge of the press quotes, so the columns are not narrow (``QuoteLayout``).
				Style()
					.wideAppPartColumn()
					.from(.proseWithGutters) {
						$0.padding(.horizontal, .zero)
					}
			case .moreLink:
				// Balanced, so on a phone the name of the Wall of Love does not break, and its end is not alone on the last line.
				Style()
					.margin(.top, .rootEm(1.5))
					.textAlign(.center)
					.textWrap(.balance)
			}
		}
	}
}
