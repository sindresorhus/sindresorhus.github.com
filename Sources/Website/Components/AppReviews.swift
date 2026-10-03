import Elementary
import Foundation
import SiteKit

/**
Recent five-star reviews of an app from the App Store.
*/
struct AppReviews: HTML {
	let reviews: [AppStoreReview]

	var body: some HTML {
		section {
			h2 {
				"Recent Reviews"
			}
			.style(Styles.title)

			div {
				for review in reviews {
					figure {
						div {
							"★★★★★"
						}
						.attributes(.role("img"))
						.accessibilityLabel("5 out of 5 stars")
						.style(Styles.stars)

						blockquote {
							p {
								review.title
							}
							.style(Styles.reviewTitle)

							p {
								review.text
							}
							.style(Styles.text)
						}

						figcaption {
							"\(review.author), "
							DateText(review.date, format: .site.month(.wide).year())
						}
						.style(Styles.author)
					}
					.style(Styles.review)
				}
			}
			.style(Styles.grid)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case title
		case grid
		case review
		case stars
		case reviewTitle
		case text
		case author

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.margin(top: .rem(4), horizontal: .auto, bottom: .rem(6))
			case .title:
				Style()
					.margin(.bottom, .rem(1.5))
					.font(.lg, weight: .semibold)
					.textAlign(.center)
					.color(.secondaryText)
			case .grid:
				Style()
					.display(.grid)
					.gap(.rem(1))
					.breakpoint(.md) {
						$0.declaration("grid-template-columns", "repeat(auto-fit, minmax(14rem, 1fr))")
					}
			case .review:
				Style()
					.vstack(spacing: .rem(0.5))
					.padding(.rem(1.25))
					.cornerRadius(.rem(0.75))
					.background(.black.opacity(0.025), dark: .white.opacity(0.04))
			case .stars:
				Style()
					.font(.sm)
					.letterSpacing(.em(0.1))
					.color("#ff9500")
			case .reviewTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .text:
				// Keeps the line breaks of the review.
				Style()
					.margin(.top, .rem(0.25))
					.font(.sm)
					.declaration(.whiteSpace, "pre-line")
					.color(.bodyText)
			case .author:
				Style()
					.margin(.top, .auto)
					.font(.xs)
					.color(.secondaryText)
			}
		}
	}
}
