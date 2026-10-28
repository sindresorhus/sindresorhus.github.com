import Elementary
import Foundation
import SiteKit

/**
Recent five-star reviews of an app from the App Store, as quote cards, below the rating of the app. The press quotes lead with their source instead, without cards (``PressQuotes``), so the two kinds of praise look different. Without reviews, it is only the rating.

The rating is a large number with stars, which is read at a glance, and screen readers read it as one sentence. With reviews, the section is a band in the accent of the page across the whole width, so the praise is a chapter of its own on a long page. Only a rating is too little for a band, so it is part of the page.
*/
struct AppReviews: HTML {
	let reviews: [AppStoreReview]

	/**
	The rating, when the app has one (``AppListing/rating``).
	*/
	var rating: AppRating?

	/**
	The app, for a link to all its quotes and reviews on the wall of love.
	*/
	var app: App?

	/**
	Creates the section only when there is praise to show. The listing owns which app the reviews belong to, so the link cannot identify another app.
	*/
	init?(listing: AppListing) {
		guard !listing.newestReviews.isEmpty || listing.rating != nil else {
			return nil
		}

		self.init(reviews: listing.newestReviews, rating: listing.rating, app: listing.app.isActive && !listing.newestReviews.isEmpty ? listing.app : nil)
	}

	/**
	Creates explicitly supplied praise, such as the independent rating examples in the gallery.
	*/
	init(reviews: [AppStoreReview], rating: AppRating? = nil, app: App? = nil) {
		self.reviews = reviews
		self.rating = rating
		self.app = app
	}

	var body: some HTML<HTMLTag.section> {
		section {
			div {
				h2 {
					reviews.isEmpty ? "Rating" : "Recent Reviews"

					// The stars of the reviews are decorative, so the heading says their rating once.
					if !reviews.isEmpty {
						VisuallyHidden(", all with five stars")
					}
				}
				.style(SectionStyles.label, Styles.title)

				if let rating {
					// Screen readers read the sentence below instead.
					div {
						p {
							rating.formattedScore
						}
						.style(Styles.average)

						if let storeRating = rating.storeRating {
							StarRating(average: storeRating, isDecorative: true)
						}

						p {
							rating.countText
						}
						.style(Styles.count)
					}
					.accessibilityHidden()
					.style(Styles.rating)

					p {
						rating.text
					}
					.style(VisuallyHidden.Styles.root)
				}

				if !reviews.isEmpty {
					QuoteGrid(reviews: reviews)
				}

				if let app {
					p {
						a(.href(.path(.reviews, query: [URLQueryItem(name: "app", value: app.slug)]))) {
							"More about \(app.title) on the Wall of Love →"
						}
						.style {
							$0.moreLink()
						}
					}
					.style(Styles.moreLink)
				}
			}
			.style(Styles.content)
			.style(Styles.wideContent, when: QuoteLayout(count: reviews.count).isWide)
		}
		.style(Styles.band, when: !reviews.isEmpty)
	}

	enum Styles: StyleSet {
		case band
		case content
		case wideContent
		case title
		case rating
		case average
		case count
		case moreLink

		var style: Style {
			switch self {
			case .band:
				// A little of the accent in the page background, with a line above and below. The cards on it have the page background (``QuoteGrid``), so they stand out from the band.
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
			case .title:
				// The rating is part of the title, so the space is below the rating.
				Style()
					.nested("&:has(+ \(Self.rating.selector))") {
						$0.margin(.bottom, .rootEm(0.25))
					}
			case .rating:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.margin(.bottom, .rootEm(2.5))
			case .average:
				Style()
					.margin(.zero)
					.font(size: .rootEm(4), lineHeight: 1)
					.fontWeight(.bold)
					.letterSpacing(.em(-0.03))
					.monospacedDigit()
					.color(.primaryText)
			case .count:
				Style()
					.margin(.zero)
					.secondaryText()
			case .moreLink:
				Style()
					.margin(.top, .rootEm(1.5))
					.textAlign(.center)
			}
		}
	}
}
