import Elementary
import Foundation
import SiteKit

/**
The wall of love: the press quotes and the recent five-star App Store reviews of all active apps, each with a link to its app.

The press quotes come first, in the order of the apps, and then the reviews in a random order on each visit. Without JavaScript, the reviews are newest first. `?app=velja` shows only the quotes and reviews of one app, like from the reviews on an app page.
*/
struct ReviewsPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.reviews
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Wall of Love", description: "What the press and App Store reviewers say about the apps by Sindre Sorhus.")
	}

	var body: some HTML {
		section {
			PageHeader(title: "Wall of Love", intro: "What the press and App Store reviewers say about my apps.")

			// The script shows it when the page shows the quotes of one app.
			p(.id(Hooks.filterNotice), .hidden) {
				"Showing what people say about "
				strong {}
				". "
				a(.href(.reviews)) {
					"Show All"
				}
			}
			.style(Styles.filterNotice)

			div {
				for quote in quotes {
					// The space below each card is padding of a wrapper, not a margin, as Safari moves the bottom margin of the last card in a column to the top of the next column, so the columns would not line up.
					div(.hook(Hooks.app, value: quote.app?.slug ?? "")) {
						quote
					}
					.style(Styles.cardWrapper)
				}
			}
			.style(Styles.wall)

			// The script is right after the wall, so it shuffles the reviews and hides the quotes of other apps before the page shows, and the cards do not move.
			script {
				HTMLRaw(#"""
				{
					const wall = document.currentScript.previousElementSibling;
					const reviews = [...wall.children].slice(\#(pressQuoteCount));

					for (let index = reviews.length - 1; index > 0; index--) {
						const other = Math.floor(Math.random() * (index + 1));
						[reviews[index], reviews[other]] = [reviews[other], reviews[index]];
					}

					wall.append(...reviews);

					const app = new URLSearchParams(location.search).get('app');
					const cards = [...wall.children].filter(card => card.dataset.app === app);

					if (cards.length > 0) {
						for (const card of wall.children) {
							card.hidden = !cards.includes(card);
						}

						const notice = document.querySelector('#\#(Hooks.filterNotice.rawValue)');
						notice.querySelector('strong').textContent = cards[0].querySelector('a').textContent.trim();
						notice.hidden = false;
					}
				}
				"""#)
			}
		}
		.style(Styles.root)
	}

	private var pressQuoteCount: Int {
		content.activeApps.map(\.pressQuotes.count).reduce(0, +)
	}

	/**
	The press quotes in the order of the apps, and then the reviews, newest first. Reviews of the same date are in the order of the app titles and the review titles.
	*/
	private var quotes: [QuoteFigure] {
		let pressQuotes = content.activeApps.flatMap { app in
			app.pressQuotes.map { QuoteFigure(kind: .press($0), app: app) }
		}

		let reviews = content.activeAppReviews.map { QuoteFigure(kind: .review($0.review), app: $0.app) }

		return pressQuotes + reviews
	}
}

extension ReviewsPage {
	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		The app of a card on the wall of love, by its slug, so the page can show only the reviews of one app with `?app=velja`.
		*/
		case app = "data-app"

		case filterNotice = "reviews-filter-notice"
	}

	enum Styles: StyleSet {
		case root
		case wall
		case cardWrapper
		case filterNotice

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.wide)
			case .wall:
				// Columns that the cards flow through, so cards of different heights fit together.
				Style()
					.columns(3, minimumWidth: .rootEm(18))
					.gap(column: .rootEm(1.25))
			case .cardWrapper:
				Style()
					.padding(.bottom, .rootEm(1.25))
					.keepsTogether()
			case .filterNotice:
				Style()
					.secondaryText()
					.textLinks()
			}
		}
	}
}
