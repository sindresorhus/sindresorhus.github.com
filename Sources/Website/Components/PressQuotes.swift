import Elementary
import Foundation
import SiteKit

/**
Quotes from reviews, or a five-star rating, as cards. ``AppReviews`` uses the same look.
*/
struct PressQuotes: HTML {
	let quotes: [App.PressQuote]

	var body: some HTML<HTMLTag.section> {
		section {
			QuoteGrid(quotes: quotes.map { .press($0) })
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style().contentColumn()
		}
	}
}

/**
A grid of quote cards: two columns when there are two or more quotes, and an odd last quote centered below the others.
*/
struct QuoteGrid: HTML {
	let quotes: [QuoteFigure.Kind]

	var body: some HTML {
		div {
			for quote in quotes {
				QuoteFigure(kind: quote)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			let spacing = Length.rootEm(1.25)

			// The odd last quote spans both columns, and is as wide as one column, so it is centered.
			return Style()
				.display(.grid)
				.gap(spacing)
				.from(.smallTablet) {
					$0
						.nested("&:has(> :nth-child(2))") {
							$0.gridColumns(2)
						}
						.children(":last-child:nth-child(odd):not(:first-child)") {
							$0
								.gridColumnSpan(2)
								.frame(width: (.percent(100) - spacing) * 0.5)
								.margin(.horizontal, .auto)
						}
				}
		}
	}
}

/**
A quote from the press or an App Store review, as a card: the stars, the quote, and the source. The app pages, the wall of love, and the press quotes use it, so quotes look the same everywhere.
*/
struct QuoteFigure: HTML {
	enum Kind {
		case press(App.PressQuote)
		case review(AppStoreReview)
	}

	let kind: Kind

	/**
	The app the quote is about, shown above it, for pages with quotes of many apps.
	*/
	var app: App?

	var body: some HTML {
		figure {
			if let app {
				a(.href(app.url)) {
					AppIcon(decorative: app, size: 32)
						.style(Styles.appIcon)

					app.title
				}
				.style(Styles.appLink)
			}

			switch kind {
			case .press(let quote):
				if quote.isStarRating {
					StarRating(rating: 5)
				}

				// The source is outside the quote, as the HTML spec requires.
				blockquote {
					p {
						quote.quote
					}
				}
				.attributes(.custom(name: "cite", value: quote.url?.absoluteString ?? ""), when: quote.url != nil)
				.style(Styles.text)

				figcaption {
					if let url = quote.url {
						a(.href(.url(url))) {
							quote.source
						}
						.style(Styles.sourceLink)
					} else {
						quote.source
					}
				}
				.style(Styles.source)
			case .review(let review):
				StarRating(rating: review.rating)

				blockquote {
					p {
						review.title
					}
					.style(Styles.reviewTitle)

					p {
						review.text
					}
					.style(Styles.reviewText)
				}
				.style(Styles.text)

				figcaption {
					"\(review.author), App Store, "
					DateText(review.date, format: .siteMonth)
				}
				.style(Styles.source)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case appLink
		case appIcon
		case text
		case reviewTitle
		case reviewText
		case source
		case sourceLink

		var style: Style {
			switch self {
			case .root:
				// Long words, like in the title of a review, break instead of overflowing.
				// The margins of prose are reset, so it looks the same in prose, like on the now page.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.75))
					.margin(0)
					.padding(.rootEm(1.5))
					.cardSurface(isInteractive: false)
					.overflowWrap(.anywhere)
					.nested("p, img, figcaption") {
						$0.margin(0)
					}
			case .appLink:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.625))
					.underline(false)
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
					.hoverColor(.link)
			case .appIcon:
				Style().flexShrink(0)
			case .text:
				// Without the look of a quote in prose, like on the now page.
				Style()
					.margin(0)
					.padding(0)
					.declaration(.border, "none")
					.declaration(.fontStyle, "normal")
					.declaration(.quotes, "none")
					.textStyle(.body)
					.color(.primaryText)
			case .reviewTitle:
				Style()
					.margin(.bottom, .rootEm(0.25))
					.fontWeight(.semibold)
			case .reviewText:
				// Keeps the line breaks of the review.
				Style().preservesLineBreaks()
			case .source:
				Style()
					.font(size: .rootEm(0.8125), lineHeight: 1.5)
					.fontWeight(.medium)
					.color(.secondaryText)
			case .sourceLink:
				Style()
					.hoverColor(.primaryText)
			}
		}
	}
}
