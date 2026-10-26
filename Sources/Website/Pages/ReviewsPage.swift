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
		let quotes = pressQuotes + reviews

		section {
			PageHeader(title: "Wall of Love", intro: "What the press and App Store reviewers say about my apps.")

			// The stars of the reviews are decorative, so the page says their rating once.
			p {
				VisuallyHidden("The App Store reviews all have five stars.")
			}

			// The script shows it when the page shows the quotes of one app.
			p(.id(Hooks.filterNotice), .hidden) {
				"Showing what people say about "
				strong(.id(Hooks.filterApp)) {}
				". "
				a(.href(.reviews)) {
					"Show All"
				}
			}
			.style(Styles.filterNotice)

			div(.id(Hooks.wall)) {
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
					const wall = document.querySelector('#\#(Hooks.wall.id)');
					const reviews = [...wall.children].slice(\#(pressQuotes.count));

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

						const notice = document.querySelector('#\#(Hooks.filterNotice.id)');
						document.querySelector('#\#(Hooks.filterApp.id)').textContent = \#(Self.appTitlesJSON(quotes))[app];
						notice.hidden = false;
					}
				}
				"""#)
			}
		}
		.style(Styles.root)
	}

	/**
	The titles of the apps with quotes, by slug, for the filter notice.
	*/
	private static func appTitlesJSON(_ quotes: [QuoteFigure]) -> String {
		JSONEncoder.pageJSON(Dictionary(quotes.compactMap(\.app).map { ($0.slug, $0.title) }) { first, _ in first })
	}

	/**
	The press quotes in the order of the apps. They are before the reviews.
	*/
	private var pressQuotes: [QuoteFigure] {
		content.activeApps.flatMap { app in
			// The wall of love has the quotes of many apps and years, so each shows its year, when it has one.
			app.pressQuotes.map { QuoteFigure(kind: .press($0), app: app, showsYear: true) }
		}
	}

	/**
	The reviews, newest first. Reviews of the same date are in the order of the app titles and the review titles.
	*/
	private var reviews: [QuoteFigure] {
		content.activeAppReviews.map { QuoteFigure(kind: .review($0.review), app: $0.app) }
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

		/**
		The name of the app in the filter notice.
		*/
		case filterApp = "reviews-filter-app"

		case wall = "reviews-wall"
	}

	enum Styles: StyleSet {
		case root
		case wall
		case cardWrapper
		case filterNotice

		var style: Style {
			switch self {
			case .root:
				// The width of the header, like the pages of the app categories, so the title is at the same place on the pages about the apps.
				Style()
					.pageColumn(.page)
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
