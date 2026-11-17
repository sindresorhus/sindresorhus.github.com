import Elementary
import Foundation
import SiteKit
import SOML

/**
Quotes from the press, or five-star ratings from people, on an app page. Each quote is a pull quote, with a large quotation mark and its source below it, and has no card (``QuoteFigure/hasCard``). The reviews (``AppReviews``) keep their cards, so the two kinds of praise look different.

From small tablets, a quote that is alone has larger text, as it has the whole column, and more quotes are in two columns, with an odd last quote centered below the others, and from laptops, three and five or more quotes are in three columns, with the quotes of a last row that is not full centered below the others, like the last two of five quotes. Four quotes stay in two columns, so they are two full rows (``QuoteLayout``). Where there is space at the sides of the text, more than two quotes are wider, with the edge of the reviews and the box to get the app (``Style/wideAppPartColumn()``). On phones, two or more quotes are a row that the visitor swipes, so they do not push the features far down the page (``Style/swipeRow(spacing:)``). There, each quote is a card with its source at the bottom (``Style/quoteCard()``), as the row is as tall as its tallest quote, so a short quote does not end above an empty band.
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
		.style(Styles.single, when: layout == .single)
		.style(Styles.row, when: layout != .single)
		.style(layout, when: layout != .single)
		.style(Styles.wide, when: layout.isWide)
	}

	enum Styles: String, StyleSet {
		case root
		case single
		case row
		case wide

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.display(.grid)
					.gap(row: .rootEm(3), column: .rootEm(2.5))
			case .single:
				// A quote that is alone has the whole column, so its text is larger, like a pull quote: about 70 characters a line instead of 100, and not smaller than the text around it. On phones, the column is narrow, so the text stays the size of the body.
				Style()
					.from(.smallTablet) {
						$0.nested(QuoteFigure.Styles.text.selector) {
							$0.font(size: .rootEm(1.375), lineHeight: 1.45)
						}
					}
			case .row:
				Style()
					.swipeRow(spacing: .rootEm(1.5))
					.below(.smallTablet) {
						$0
							.alignItems(.stretch)
							.children(QuoteFigure.Styles.root.selector) {
								$0.quoteCard()
							}
					}
			case .wide:
				// As wide as the content of the header, so the columns are not narrow.
				Style()
					.wideAppPartColumn()
					.from(.proseWithGutters) {
						$0.padding(.horizontal, .zero)
					}
			}
		}
	}
}

/**
The layout of a grid of quotes from small tablets, from the number of quotes, so the press quotes (``PressQuotes``), the grid of reviews (``QuoteGrid``), and the parent that makes the reviews wider (``AppReviews``) agree.
*/
enum QuoteLayout: String, StyleSet {
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
	Whether the quotes are wider than the column of the page where there is space at the sides of the text (``Style/wideAppPartColumn()``), so the columns are not narrow.
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
A grid of the reviews of an app as quote cards, in the columns of the press quotes (``QuoteLayout``), and like them, a row that the visitor swipes on phones (``Style/swipeRow(spacing:)``). The parent makes the grid wider (``QuoteLayout/isWide``).
*/
struct QuoteGrid: HTML {
	let reviews: [StoreReview]

	var body: some HTML<HTMLTag.section> {
		let layout = QuoteLayout(count: reviews.count)

		// A `section`, as a `div` cannot have a name.
		section {
			for review in reviews {
				// The grid is on the accent band of the app page (``AppReviews``), so its cards have the page background, which stands out from the band. In dark mode, a raised surface is lighter, so the cards are a light overlay, like the other dark cards, not the darker page background.
				QuoteFigure(kind: .review(review))
					.style {
						$0.background(.lightDark(.pageBackground, .card))
					}
			}
		}
		.attributes(.tabindex(0), .ariaLabel("Reviews"), when: layout != .single)
		.style(Styles.root)
		.style(Styles.row, when: layout != .single)
		.style(layout, when: layout != .single)
	}

	enum Styles: String, StyleSet {
		case root
		case row

		var style: Style {
			switch self {
			case .root:
				// On phones, one review is one column that is not wider than the page, also with large text.
				Style()
					.display(.grid)
					.gap(.cardSpacing)
			case .row:
				// On phones, more reviews are a row that the visitor swipes, like the press quotes, so they do not fill several screens. The row reaches the edges of the screen, out of the space of the page around the grid.
				// The cards have the height of the row, so a short card does not end in the middle of the band next to a long one, like the press quotes on phones.
				Style()
					.swipeRow(spacing: .rootEm(1.25))
					.below(.smallTablet) {
						$0
							.fullBleed()
							.alignItems(.stretch)
					}
			}
		}
	}
}

/**
A quote from the press or a review on the App Store or Gumroad, as a card: the quote and the source, with stars only for a press rating. The reviews of the app pages and the wall of love use it, so the cards look the same everywhere. The press quotes of an app page are pull quotes instead, without a card (``hasCard``), except on phones, where their row gives them the look of a card (``PressQuotes``).
*/
struct QuoteFigure: HTML {
	enum Kind {
		case press(App.PressQuote.Resolved, presentation: PressPresentation = .card)
		case review(StoreReview)
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
	A blank line in the text of a review, also with spaces on it, which starts a new paragraph.
	*/
	nonisolated(unsafe) private static let paragraphBreak = /\n\s*\n/

	/**
	The app the quote is about, shown above it, for pages with quotes of many apps.
	*/
	var app: App?

	/**
	Whether the quote is a card. Without a card, a press quote is a pull quote: a large quotation mark in the accent of the page, the quote, and the source below it, so it reads as a quote from the press, also when it is long. The wall of love keeps the cards, as its press quotes are in one wall with the reviews. With or without a card, the name of a publication is in a serif font, so a press quote is not like a review. The name of a person, like a buyer on Gumroad, has the small style of the sources of the reviews, as it is what a user said, not a publication (``App/PressQuote/Attribution/isPerson``).
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
				// The link shows the icon and the name of the app, so it shows no preview of the app in prose, like on the now page.
				a(.href(app.url), .hook(LinkPreview.Hooks.noLinkPreview)) {
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
				.attributes(optional: resolved.attribution.citationURL.map { .custom(name: "cite", value: $0.value.absoluteString) })
				.style(Styles.text)
				// The stars of a rating already show that it is praise.
				.style(Styles.quotationMark, when: !hasCard && !quote.isStarRating)

				// The source is outside the quote, as the HTML spec requires. The award or the year, and the language of the article, are below the name.
				figcaption {
					span {
						resolved.attribution.sourceContent
					}
					.style(resolved.attribution.isPerson ? Styles.personName : Styles.attributionName)

					// The award has its year, so the year is not repeated below it.
					if let award = resolved.awardText {
						span {
							Icon.star.size(.em(1))
							award
						}
						.style(Styles.award)
					}

					let details = [resolved.awardText == nil ? resolved.attribution.yearText : nil, quote.translatedFrom.map { "Translated from \($0.rawValue)" }].compactMap(\.self)

					if !details.isEmpty {
						FactLine(facts: details) {}
						.style(Styles.sourceDetails)
					}
				}
				.style(Styles.source)
				.style(Styles.attribution, when: !hasCard)
			case .review(let review):
				// Selected reviews read as testimonials, with the quote and its source instead of repeated stars.
				blockquote {
					// A review on Gumroad has no title.
					if let title = review.displayTitle {
						p {
							title
						}
						.style(Styles.reviewTitle)
					}

					// A blank line starts a new paragraph, with a gap that is smaller than a line, like in prose.
					for paragraph in review.displayText.split(separator: Self.paragraphBreak) {
						p {
							String(paragraph)
						}
						.style(Styles.reviewText)
					}
				}
				.style(Styles.text)

				figcaption {
					"\(review.author), "

					// The store and the date stay together, so a source that does not fit breaks after the name of the reviewer.
					span {
						"\(review.store.title), "
						DateText(day: SOML.Date(review.date), format: .siteMonth)
					}
					.style {
						$0.textWrap(.nowrap)
					}
				}
				.style(Styles.source)
			}
		}
		.style(Styles.root)
		.style(Styles.card, when: hasCard)
	}

	enum Styles: String, StyleSet {
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
		case personName
		case award
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
				Style().quoteCard()
			case .appLink:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.625))
					.noUnderline()
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
					.hoverColor(.link)
			case .text:
				// Without the look of a quote in prose, like on the now page. The title of a review is a little apart from its text. It is a gap, as the root resets the margins of the paragraphs.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(.zero)
					.padding(.zero)
					.declaration(raw: .border, "none")
					.italic(false)
					.declaration(raw: .quotes, "none")
					.textStyle(.body)
					// The prose sets a medium weight on a quote.
					.fontWeight(.regular)
					.color(.primaryText)
			case .reviewTitle:
				Style().fontWeight(.semibold)
			case .reviewText:
				// Keeps the line breaks of the review. With the gap of the quote, a paragraph is 0.625 rem below the one before it.
				Style()
					.preservesLineBreaks()
					.directlyAfter("&") {
						$0.margin(.top, .rootEm(0.375))
					}
			case .quotationMark:
				// A large opening quotation mark above the quote, which screen readers skip, as the quote is a `blockquote`. Its box is lower than the mark, so the quote is close to it. In the accent for marks, like the dot of a carousel, so a light accent shows on white.
				Style()
					.before {
						$0
							.content("“", alternativeText: "")
							.display(.block)
							.frame(height: .rootEm(1.75))
							.fontFamily(.serif)
							.font(size: .rootEm(4), lineHeight: 1)
							.fontWeight(.bold)
							.color(.accentMark)
					}
			case .source:
				Style()
					.font(.footnote)
					.fontWeight(.medium)
					.color(.secondaryText)
			case .sourceLink:
				// The arrow shows that the source is a link to the article. The name already has the primary text color of a quiet link under the pointer, so the arrow gets the accent of the page there, also with the focus of the keyboard.
				Style()
					.quietLink()
					.after {
						$0
							.content(" ↗", alternativeText: "")
							.fontFamily(.system)
							.fontWeight(.regular)
							.color(.secondaryText)
							.transition(.color, timing: .stateChange)
					}
					.hoverOrFocusVisible {
						$0.after {
							$0.color(.accentMark)
						}
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
			case .personName:
				// The name of a person has the small style of the source (``source``), the style of the sources of the reviews, with a dash before it, which screen readers skip.
				Style()
					.before {
						$0.content("— ", alternativeText: "")
					}
			case .award:
				// An award of the publication, like “Best Mac App Runner-Up 2025”, is on a line of its own below the name, with a star in the accent for marks, so it stands out from the year of the other quotes.
				Style()
					.hstack(alignment: .center, spacing: .em(0.375))
					.margin(.top, .rootEm(0.125))
					.fontWeight(.semibold)
					.color(.primaryText)
					.children(Icon.selector) {
						$0
							.flexShrink(0)
							.color(.accentMark)
					}
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

extension Style {
	/**
	The look of a quote card (``QuoteFigure``), with the source at the bottom of the card, so the sources of a row of cards, which have the height of the tallest card, line up. The card is a vertical stack, so the source moves only in a card that is taller than its content.
	*/
	fileprivate func quoteCard() -> Self {
		plainCard()
			.children(QuoteFigure.Styles.source.selector) {
				$0.margin(.top, .auto)
			}
	}
}

extension App.PressQuote.Attribution {
	/**
	The cited article or buyer review; an unlinked person's quote has no citation URL.
	*/
	fileprivate var citationURL: AbsoluteURL? {
		switch self {
		case .article(_, let url, _), .buyer(_, let url, _):
			url
		case .person:
			nil
		}
	}

	/**
	Whether the source is a person, like a buyer on Gumroad or a quote without a link, not a publication, so the page shows the name in the style of the sources of the reviews, not as the name of a publication.
	*/
	fileprivate var isPerson: Bool {
		switch self {
		case .article:
			false
		case .buyer, .person:
			true
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
	The article's required year or the optional year of a personal attribution, ready for its fact line and for the Markdown copy of the page (``App/PressQuote/Resolved/markdown``).
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

extension App.PressQuote.Resolved {
	/**
	The award of the article with its year, like “Best Mac App Runner-Up 2025” (``App/PressQuote/award``), which the source shows in place of the year alone.
	*/
	fileprivate var awardText: String? {
		guard
			let award = quote.award,
			case .article(_, _, let year) = attribution
		else {
			return nil
		}

		return "\(award) \(year)"
	}

	/**
	The quote as a Markdown block quote with its source below it, like on the page (``QuoteFigure``): the name with its link, the year, and the language of a translated article, like `> Dato is a simple app …` and `> [MacStories](https://www.macstories.net/…), 2021`. For the Markdown copy of the app page.
	*/
	var markdown: String {
		let source = switch attribution {
		case .article(let source, let url, _), .buyer(let source, let url, _):
			url.value.markdownLink(source)
		case .person(let source, _):
			source
		}

		let details = [source, awardText ?? attribution.yearText, quote.translatedFrom.map { "translated from \($0.rawValue)" }].compactMap(\.self)

		return "> \(quote.quote.replacing("\n", with: "\n> "))\n>\n> \(details.joined(separator: ", "))"
	}
}
