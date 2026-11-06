import Elementary
import Foundation
import SiteKit

/**
Selected five-star App Store reviews as testimonials. The press quotes lead with their source instead, without cards (``PressQuotes``), so the two kinds of praise look different.

The section is a band in the accent of the page across the whole width, so the praise is a chapter of its own on a long page.
*/
struct AppReviews: HTML {
	let reviews: [AppStoreReview]

	/**
	The app, for a link to all its quotes and reviews on the wall of love.
	*/
	var app: App?

	/**
	Creates the section only when there is praise to show. The listing owns which app the reviews belong to, so the link cannot identify another app.
	*/
	init?(listing: AppListing) {
		guard !listing.newestReviews.isEmpty else {
			return nil
		}

		self.init(reviews: listing.newestReviews, app: listing.app.isActive ? listing.app : nil)
	}

	/**
	Creates explicitly supplied testimonials, such as the examples in the gallery.
	*/
	init(reviews: [AppStoreReview], app: App? = nil) {
		self.reviews = reviews
		self.app = app
	}

	var body: some HTML<HTMLTag.section> {
		section {
			div {
				// Keep the US average separate from selected international reviews, which are a different sample.
				h2 {
					"What users say"
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

		var style: Style {
			switch self {
			case .band:
				// A little of the accent in the page background, with a line above and below. The cards on it have the page background in light mode and a lighter surface in dark mode (``QuoteGrid``), so they stand out from the band.
				Style()
					.padding(.vertical, .rootEm(4))
					.background(.lightDark(.pageBackground.mix(with: .pageAccent, amount: .percent(6)), .pageBackground.mix(with: .pageAccent, amount: .percent(9))))
					.border([.top, .bottom], .pageBackground.mix(with: .pageAccent, amount: .percent(18)), width: .pixels(1))
			case .content:
				Style()
					.contentColumn()
			case .wideContent:
				// More than two reviews are wider, with the edge of the press quotes, so the columns are not narrow (``QuoteLayout``).
				Style()
					.wideAppPartColumn()
					.from(.laptop) {
						$0.padding(.horizontal, .zero)
					}
			case .moreLink:
				Style()
					.margin(.top, .rootEm(1.5))
					.textAlign(.center)
			}
		}
	}
}
