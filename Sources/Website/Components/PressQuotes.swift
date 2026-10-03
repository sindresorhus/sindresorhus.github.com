import Elementary
import Foundation
import SiteKit

/**
Quotes from reviews, or a five-star rating.
*/
struct PressQuotes: HTML {
	let quotes: [App.PressQuote]

	var body: some HTML {
		aside {
			div {
				for quote in quotes {
					blockquote {
						if quote.isStarRating {
							div(.ariaLabel("5 out of 5 stars")) {
								for _ in 0..<5 {
									HTMLRaw(#"<svg viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>"#)
								}
							}
							.style(Styles.stars)
						} else {
							span {
								"“"
							}
							.accessibilityHidden()
							.style(Styles.quoteMark)
						}

						p {
							quote.quote.value
						}
						.style(Styles.text)

						footer {
							if let url = quote.url {
								a(.href(url.absoluteString)) {
									quote.source.value
								}
								.style(Styles.sourceLink)
							} else {
								span {
									quote.source.value
								}
							}
						}
						.style(Styles.source)
					}
					.style(Styles.quote)
				}
			}
			.style(Styles.grid)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case grid
		case quote
		case text
		case source
		case sourceLink
		case stars
		case quoteMark

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.margin(top: .rem(7), horizontal: .auto, bottom: .rem(6))
			case .grid:
				// Two columns when there are two or more quotes. An odd last quote is centered below the others.
				Style()
					.display(.grid)
					.gap(row: .rem(5), column: .rem(4))
					.breakpoint(.sm) {
						$0
							.nested("&:has(> :nth-child(2))") {
								$0.gridColumns(2)
							}
							.children(":last-child:nth-child(odd):not(:first-child)") {
								$0
									.gridColumnSpan(2)
									.frame(maxWidth: .rem(28))
									.margin(.horizontal, .auto)
							}
					}
			case .quote:
				Style()
					.vstack(alignment: .center, justification: .spaceBetween)
					.frame(height: .percent(100))
					.textAlign(.center)
			case .text:
				Style()
					.font(size: .rem(1.125), lineHeight: 1.625)
					.italic()
					.color(.gray(600), dark: .gray(300))
			case .source:
				Style()
					.margin(.top, .rem(1))
					.font(.sm, weight: .semibold)
					.letterSpacing(.em(0.025))
					.textCase(.uppercase)
					.color(.gray(400), dark: .gray(500))
			case .sourceLink:
				Style()
					.transition(.color, duration: .milliseconds(150))
					.hover {
						$0.color(.primary(500))
					}
			case .stars:
				Style()
					.hstack(spacing: .rem(0.125))
					.margin(.bottom, .rem(1))
					.nested("svg") {
						$0
							.frame(width: .rem(1.25), height: .rem(1.25))
							.color("#ff9500")
					}
			case .quoteMark:
				Style()
					.font(size: .rem(4.5), lineHeight: 1)
					.color(.primary(400), dark: .primary(500))
					.textSelection(.disabled)
			}
		}
	}
}
