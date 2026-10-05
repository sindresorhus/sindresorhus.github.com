import Elementary
import Foundation
import SiteKit

/**
Recent five-star reviews of an app from the App Store, as quote cards like the press quotes, below the rating of the app. Without reviews, it is only the rating.
*/
struct AppReviews: HTML {
	let reviews: [AppStoreReview]

	/**
	The App Store rating, when the app has one.
	*/
	var rating: AppStoreInfo.Rating?

	/**
	The app, for a link to all its quotes and reviews on the wall of love.
	*/
	var app: App?

	var body: some HTML<HTMLTag.section> {
		section {
			h2 {
				reviews.isEmpty ? "Rating" : "Recent Reviews"
			}
			.style(SectionStyles.label, Styles.title)

			if let rating {
				p {
					rating.text
				}
				.style(Styles.rating)
			}

			if !reviews.isEmpty {
				QuoteGrid(quotes: reviews.map { .review($0) })
			}

			if let app {
				p {
					a(.href(.path(.reviews, query: [URLQueryItem(name: "app", value: app.slug)]))) {
						"More about \(app.title) on the Wall of Love →"
					}
				}
				.style(Styles.moreLink)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case title
		case rating
		case moreLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
			case .title:
				// The rating is part of the title, so the space is below the rating.
				Style()
					.nested("&:has(+ \(Self.rating.selector))") {
						$0.margin(.bottom, .rootEm(0.25))
					}
			case .rating:
				Style()
					.margin(.bottom, .rootEm(1.5))
					.secondaryText()
					.textAlign(.center)
			case .moreLink:
				Style()
					.margin(.top, .rootEm(1.5))
					.textAlign(.center)
					.fontWeight(.semibold)
					.color(.link)
			}
		}
	}
}
