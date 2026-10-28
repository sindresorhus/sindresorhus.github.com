import Elementary
import Foundation
import SiteKit
import SOML

/**
Quotes from the press, or five-star ratings from people, on an app page. Each quote is a pull quote, with a large quotation mark and its source below it, and has no card (``QuoteFigure/hasCard``). The App Store reviews (``AppReviews``) keep their cards, so the two kinds of praise look different.

From small tablets, the quotes are in two columns, with an odd last quote centered below the others, and from laptops, three and five or more quotes are in three columns, with the quotes of a last row that is not full centered below the others, like the last two of five quotes. Four quotes stay in two columns, so they are two full rows (``QuoteLayout``). From laptops, more than two quotes are wider, with the edge of the reviews and the box to get the app (``Style/wideAppPartColumn()``). On phones, two or more quotes are a row that the visitor swipes, so they do not push the features far down the page (``Style/swipeRow(spacing:)``).
*/
struct PressQuotes: HTML {
	let quotes: [App.PressQuote.Resolved]

	var body: some HTML<HTMLTag.section> {
		let layout = QuoteLayout(count: quotes.count)

		// The row is a Tab stop with a name, so keyboard users can scroll it on phones, also to a quote without a link. It is a stop on larger screens too, where nothing scrolls, as only a script could know when the row scrolls.
		section {
			for quote in quotes {
				QuoteFigure(kind: .press(quote, presentation: .pullQuote))
			}
		}
		.attributes(.tabindex(0), .ariaLabel("Press quotes"), when: quotes.count > 1)
		.style(Styles.root)
		.style(Styles.row, when: layout != .single)
		.style(layout, when: layout != .single)
		.style(Styles.wide, when: layout.isWide)
	}

	enum Styles: StyleSet {
		case root
		case row
		case wide

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.display(.grid)
					.gap(row: .rootEm(3), column: .rootEm(2.5))
			case .row:
				Style().swipeRow(spacing: .rootEm(1.5))
			case .wide:
				// As wide as the screenshots, so the columns are not narrow, and as wide as the content of the header on large screens.
				Style()
					.wideAppPartColumn()
					.from(.laptop) {
						$0.padding(.horizontal, .zero)
					}
			}
		}
	}
}

/**
The layout of a grid of quotes from small tablets, from the number of quotes, so the press quotes (``PressQuotes``), the grid of reviews (``QuoteGrid``), and the parent that makes the reviews wider (``AppReviews``) agree.
*/
enum QuoteLayout: StyleSet {
	/**
	One quote, which is as wide as the column of the page.
	*/
	case single

	/**
	Two quotes, in two columns.
	*/
	case twoColumns

	/**
	Four quotes, in two columns as wide as three, so they are two full rows, not a row of three and one quote alone.
	*/
	case wideTwoColumns

	/**
	Three, or five or more quotes, in three columns from laptops, with the quotes of a last row that is not full centered below the others, and in two columns before.
	*/
	case threeColumns

	init(count: Int) {
		switch count {
		case ...1:
			self = .single
		case 2:
			self = .twoColumns
		case 4:
			self = .wideTwoColumns
		default:
			self = .threeColumns
		}
	}

	/**
	The shared responsive column rules, leaving spacing and presentation to each quote component.
	*/
	var style: Style {
		let style = Style()
		guard self != .single else {
			return style
		}

		// The odd last quote is centered below the others.
		let columns = style.from(.smallTablet) {
			$0.balancedColumns(2)
		}

		guard self == .threeColumns else {
			return columns
		}

		// The quotes of a last row that is not full are centered below the others.
		return columns.from(.laptop) {
			$0.balancedColumns(3)
		}
	}

	/**
	Whether the quotes are wider than the column of the page from laptops (``Style/wideAppPartColumn()``), so the columns are not narrow.
	*/
	var isWide: Bool {
		switch self {
		case .single, .twoColumns:
			false
		case .wideTwoColumns, .threeColumns:
			true
		}
	}
}

/**
A grid of the App Store reviews of an app as quote cards, in the columns of the press quotes (``QuoteLayout``), and like them, a row that the visitor swipes on phones (``Style/swipeRow(spacing:)``). The parent makes the grid wider (``QuoteLayout/isWide``).
*/
struct QuoteGrid: HTML {
	let reviews: [AppStoreReview]

	var body: some HTML<HTMLTag.section> {
		let layout = QuoteLayout(count: reviews.count)

		// A `section`, as a `div` cannot have a name.
		section {
			for review in reviews {
				// The grid is on the accent band of the app page (``AppReviews``), so its cards have the page background, which stands out from the band.
				QuoteFigure(kind: .review(review))
					.style {
						$0.background(.pageBackground)
					}
			}
		}
		.attributes(.tabindex(0), .ariaLabel("Reviews"), when: layout != .single)
		.style(Styles.root)
		.style(Styles.row, when: layout != .single)
		.style(layout, when: layout != .single)
	}

	enum Styles: StyleSet {
		case root
		case row

		var style: Style {
			switch self {
			case .root:
				// On phones, one review is one column that is not wider than the page, also with large text.
				Style()
					.display(.grid)
					.gap(.rootEm(1.25))
			case .row:
				// On phones, more reviews are a row that the visitor swipes, like the press quotes, so they do not fill several screens. The row reaches the edges of the screen, out of the space of the page around the grid.
				Style()
					.swipeRow(spacing: .rootEm(1.25))
					.below(.smallTablet) {
						$0.fullBleed()
					}
			}
		}
	}
}

/**
A quote from the press or an App Store review, as a card: the stars, the quote, and the source. The reviews of the app pages and the wall of love use it, so the cards look the same everywhere. The press quotes of an app page are pull quotes instead, without a card (``hasCard``).
*/
struct QuoteFigure: HTML {
	enum Kind {
		case press(App.PressQuote.Resolved, presentation: PressPresentation = .card)
		case review(AppStoreReview)
	}

	/**
	Only press quotes have a pull-quote presentation. Reviews always keep their card.
	*/
	enum PressPresentation {
		case card
		case pullQuote
	}

	let kind: Kind

	/**
	The app the quote is about, shown above it, for pages with quotes of many apps.
	*/
	var app: App?

	/**
	Whether the quote is a card. Without a card, a press quote is a pull quote: a large quotation mark in the accent of the page, the quote, and the source below it, so it reads as a quote from the press, also when it is long. The wall of love keeps the cards, as its press quotes are in one wall with the reviews. With or without a card, the name of the source is in a serif font, so a press quote is not like a review.
	*/
	private var hasCard: Bool {
		switch kind {
		case .press(_, let presentation):
			presentation == .card
		case .review:
			true
		}
	}

	var body: some HTML<HTMLTag.figure> {
		figure {
			if let app {
				a(.href(app.url)) {
					AppIcon(decorative: app, size: 32)

					app.title
				}
				.style(Styles.appLink)
			}

			switch kind {
			case .press(let resolved, _):
				let quote = resolved.quote
				if quote.isStarRating {
					StarRating(stars: .five)
				}

				blockquote {
					p {
						if
							let highlight = quote.highlight,
							let range = quote.quote.firstRange(of: highlight)
						{
							String(quote.quote[..<range.lowerBound])

							mark {
								highlight
							}
							.style(Styles.highlight)

							String(quote.quote[range.upperBound...])
						} else {
							quote.quote
						}
					}
				}
				.attributes(optional: resolved.attribution.citationURL.map { .custom(name: "cite", value: $0.absoluteString) })
				.style(Styles.text)
				// The stars of a rating already show that it is praise.
				.style(Styles.quotationMark, when: !hasCard && !quote.isStarRating)

				// The source is outside the quote, as the HTML spec requires. The year and the language of the article are below the name.
				figcaption {
					span {
						resolved.attribution.sourceContent
					}
					.style(Styles.attributionName)

					let details = [resolved.attribution.yearText, quote.translatedFrom.map { "Translated from \($0.rawValue)" }].compactMap(\.self)

					if !details.isEmpty {
						FactLine(facts: details) {}
						.style(Styles.sourceDetails)
					}
				}
				.style(Styles.source)
				.style(Styles.attribution, when: !hasCard)
			case .review(let review):
				// The reviews are the five-star reviews, which the heading of the reviews says once, so screen readers do not read “5 out of 5 stars” for each.
				StarRating(stars: review.rating, isDecorative: true)

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
					DateText(day: SOML.Date(review.date), format: .siteMonth)
				}
				.style(Styles.source)
			}
		}
		.style(Styles.root)
		.style(Styles.card, when: hasCard)
	}

	enum Styles: StyleSet {
		case root
		case card
		case appLink
		case text
		case reviewTitle
		case reviewText
		case quotationMark
		case source
		case sourceLink
		case sourceDetails
		case attribution
		case attributionName
		case highlight

		var style: Style {
			switch self {
			case .root:
				// Long words, like in the title of a review, break instead of overflowing.
				// The margins of prose are reset, so it looks the same in prose, like on the now page.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.75))
					.margin(.zero)
					.overflowWrap(.anywhere)
					.nested("p, img, figcaption") {
						$0.margin(.zero)
					}
			case .card:
				Style()
					.padding(.cardPadding)
					.cardSurface(isInteractive: false)
			case .appLink:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.625))
					.underline(false)
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
					.hoverColor(.link)
			case .text:
				// Without the look of a quote in prose, like on the now page. The title of a review is a little apart from its text. It is a gap, as the root resets the margins of the paragraphs.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(.zero)
					.padding(.zero)
					.declaration(.border, "none")
					.italic(false)
					.declaration(.quotes, "none")
					.textStyle(.body)
					.color(.primaryText)
			case .reviewTitle:
				Style().fontWeight(.semibold)
			case .reviewText:
				// Keeps the line breaks of the review.
				Style().preservesLineBreaks()
			case .quotationMark:
				// A large opening quotation mark above the quote, which screen readers skip, as the quote is a `blockquote`. Its box is lower than the mark, so the quote is close to it.
				Style()
					.before {
						$0
							.content("“", alternativeText: "")
							.display(.block)
							.frame(height: .rootEm(1.75))
							.fontFamily(.serif)
							.font(size: .rootEm(4), lineHeight: 1)
							.fontWeight(.bold)
							.color(.pageAccent)
					}
			case .source:
				Style()
					.font(size: .rootEm(0.8125), lineHeight: 1.5)
					.fontWeight(.medium)
					.color(.secondaryText)
			case .sourceLink:
				// The arrow shows that the source is a link to the article.
				Style()
					.quietLink()
					.after {
						$0
							.content(" ↗", alternativeText: "")
							.fontFamily(.system)
							.fontWeight(.regular)
							.color(.secondaryText)
					}
			case .sourceDetails:
				// Below the name of the source.
				Style().display(.block)
			case .attribution:
				// A little more space above the source than between the other parts, so it reads as the end of the quote.
				Style()
					.padding(.top, .rootEm(0.25))
			case .attributionName:
				// The name of the publication is the proof, so it stands out.
				Style()
					.fontFamily(.serif)
					.font(size: .rootEm(1.1875), lineHeight: 1.3)
					.fontWeight(.semibold)
					.color(.primaryText)
			case .highlight:
				// A soft marker in the accent of the page below the lower part of the text, which keeps its color.
				Style()
					.background(.transparent)
					.backgroundImage(.linearGradient(.toBottom, Color.transparent.at(.percent(55)), Color.lightDark(Color.pageAccent.opacity(0.28), Color.pageAccent.opacity(0.4)).at(.percent(55))))
					.inherits(.color)
			}
		}
	}
}

extension App.PressQuote.Attribution {
	/**
	The cited article or buyer review; an unlinked person's quote has no citation URL.
	*/
	fileprivate var citationURL: URL? {
		switch self {
		case .article(_, let url, _), .buyer(_, let url, _):
			url
		case .person:
			nil
		}
	}

	/**
	The source markup follows the resolved attribution rather than checking an optional URL again.
	*/
	@HTMLBuilder
	fileprivate var sourceContent: some HTML {
		switch self {
		case .article(let source, let url, _), .buyer(let source, let url, _):
			a(.href(.url(url))) {
				source
			}
			.style(QuoteFigure.Styles.sourceLink)
		case .person(let source, _):
			source
		}
	}

	/**
	The article's required year or the optional year of a personal attribution, ready for its fact line.
	*/
	fileprivate var yearText: String? {
		switch self {
		case .article(_, _, let year):
			String(year)
		case .buyer(_, _, let year), .person(_, let year):
			year.map(String.init)
		}
	}
}
