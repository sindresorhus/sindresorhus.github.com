import Elementary
import Foundation
import SiteKit

/**
The wall of love: the press quotes and the recent five-star reviews on the App Store and Gumroad of all active apps, each with a link to its app.

The reviews are in a random order on each visit, and the press quotes are spread through them at even steps, in the order of the apps, so each column of the wall has some. A press quote is first. The order stays with the history entry, so the visitor who goes back to the page, or reloads it, returns to the same reviews. Without JavaScript, the press quotes come first, and then the reviews, newest first. `?app=velja` shows only the quotes and reviews of one app, like from the reviews on an app page. Then the introduction names the app with its icon and links to it, so the cards do not repeat its icon and name.
*/
struct ReviewsPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.reviews
	}

	/**
	The icons of the apps with the most quotes and reviews on the wall.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(ofMostCommon: (pressQuotes + reviews).map(\.app), project: content.project)))
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Wall of Love", description: "What the press and users say about the apps by Sindre Sorhus.")
	}

	var body: some HTML {
		let quotes = pressQuotes + reviews

		section {
			// The script names the one app in place of “my apps” when the page shows its quotes, with its icon and a link to it, and shows the link to all the apps.
			PageHeader(title: "Wall of Love") {
				"What the press and users say about "

				span(.id(IDs.allApps)) {
					"my apps"
				}

				a(.id(IDs.filterApp), .hidden) {}
					// The script puts the icon of the app before its name. The icon is a little larger than the text, and is clipped like in ``AppIcon``, so the cut rim of the image does not show. The icon and the first word of the name are in a `span` that does not wrap, so the icon is not alone at the end of a line, like the icons of app links in prose. A long app name can wrap after its first word, also with enlarged text.
					.style {
						$0.children("span") {
							$0
								.textWrap(.nowrap)
								.children("img") {
									$0
										.display(.inlineBlock)
										.frame(size: .em(1.5))
										.margin(.trailing, .em(0.3))
										.verticalAlign(.em(-0.4))
										.clipShape(inset: .percent(1.2), cornerRadius: .percent(22.5))
								}
						}
					}

				"."

				span(.id(IDs.showAll), .hidden) {
					" "

					a(.href(.reviews)) {
						"Show all apps"
					}
				}
			}

			// Identify the selected reviews without repeating a rating on every testimonial.
			p {
				VisuallyHidden("Selected reviews from the App Store and Gumroad.")
			}

			div(.id(IDs.wall)) {
				for quote in quotes {
					// The space below each card is padding of a wrapper, not a margin, as Safari moves the bottom margin of the last card in a column to the top of the next column, so the columns would not line up.
					div(.hook(Hooks.app, value: quote.app.slug.value)) {
						QuoteFigure(kind: quote.kind, app: quote.app)
					}
					.style(Styles.cardWrapper)
				}
			}
			.style(Styles.wall)

			// The script is right after the wall, so it puts the reviews in a random order and hides the quotes of other apps before the page shows, and the cards do not move.
			script {
				HTMLRaw(#"""
				{
					const wall = document.querySelector('#\#(IDs.wall.id)');
					const app = new URLSearchParams(location.search).get('\#(Parameters.app.rawValue)');
					const isOneApp = [...wall.children].some(card => card.dataset.app === app);
					// The cards of the one app, before they are spread, so its press quotes go at even steps through its reviews, and not all in one column.
					const isShown = card => !isOneApp || card.dataset.app === app;
					const pressQuotes = [...wall.children].slice(0, \#(pressQuotes.count)).filter(isShown);
					const reviews = [...wall.children].slice(\#(pressQuotes.count)).filter(isShown);

					// The seed of the order stays with the history entry, so Back and a reload show the same reviews at the scroll position that the browser restores. A new visit has no seed, so it gets a new order.
					const seed = history.state?.reviewsSeed ?? Math.floor(Math.random() * (2 ** 32));

					// A small random number generator with a seed (mulberry32).
					let randomState = seed;
					const random = () => {
						randomState = (randomState + 0x6D2B79F5) | 0;
						let value = Math.imul(randomState ^ (randomState >>> 15), randomState | 1);
						value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
						return ((value ^ (value >>> 14)) >>> 0) / (2 ** 32);
					};

					// The reviews of each app go at even steps through the wall, from a random start for each app, so the cards of one app are not near each other: the k-th of the n reviews of an app goes at (k + start) / n.
					const spread = [...Map.groupBy(reviews, card => card.dataset.app).values()].flatMap(group => {
						const start = random();
						return group.map((card, index) => ({card, position: (index + start) / group.length}));
					});

					spread.sort((first, second) => first.position - second.position);

					// The columns of the wall fill in the order of the cards, so the press quotes go at even steps through the reviews, and not all in the first column.
					const order = spread.map(({card}) => card);

					for (const [index, quote] of pressQuotes.entries()) {
						order.splice(Math.round(index * (pressQuotes.length + reviews.length) / pressQuotes.length), 0, quote);
					}

					wall.append(...order);

					if (isOneApp) {
						for (const card of wall.children) {
							card.hidden = !isShown(card);
						}

						const {title, url, icon, reviewURL} = \#(Self.appsJSON(quotes))[app];
						const appLink = document.querySelector('#\#(IDs.filterApp.id)');
						// The icon and the first word of the name stay on one line.
						const [, firstWord, rest] = title.match(/^(\S*)(.*)$/s);
						const start = document.createElement('span');
						start.append(Object.assign(new Image(), {src: icon, alt: ''}), firstWord);
						appLink.replaceChildren(start, rest);
						appLink.href = url;
						appLink.hidden = false;
						document.querySelector('#\#(IDs.allApps.id)').hidden = true;
						document.querySelector('#\#(IDs.showAll.id)').hidden = false;

						// The introduction names the app and links to it, so the cards do not repeat it.
						wall.dataset.state = 'one-app';

						// The words of the introduction, so the tabs and the history entries of the walls of different apps have different names.
						document.title = `What People Say About ${title} — \#(Site.name)`;

						// The button at the end of the page rates the app that the page shows, without the menu of all the apps. An app that is not on the App Store keeps the menu.
						if (reviewURL) {
							// The button is after this script, so it is not on the page yet.
							document.addEventListener('DOMContentLoaded', () => {
								const link = document.querySelector('#\#(IDs.reviewLink.id)');
								link.href = reviewURL;
								link.textContent = `Rate or Review ${title}`;
								link.hidden = false;
								document.querySelector('#\#(IDs.reviewPrompt.id)').textContent = `Like ${title}?`;
								document.querySelector('#\#(IDs.reviewPicker.id)').hidden = true;
							});
						}
					}

					// Last, so the wall still works where the browser refuses the state, like in a sandboxed frame.
					history.replaceState({...history.state, reviewsSeed: seed}, '');
				}
				"""#)
			}

			// The visitors of the page are the happy users, so it invites them to help others find the apps. It asks for a rating or a review, as a rating is enough.
			div {
				p {
					// The script names the app when the page shows the quotes of one app that is on the App Store, like the button below.
					strong(.id(IDs.reviewPrompt)) {
						"Like one of the apps?"
					}

					" A rating or a review on the App Store helps other people find it."
				}
				.style {
					$0.secondaryText()
				}

				// The script hides the menu and shows the link when the page shows the quotes of one app that is on the App Store, so the visitor does not pick the app again.
				div(.id(IDs.reviewPicker)) {
					OverflowMenu(label: "Rate or review an app on the App Store", links: reviewLinks, variant: .picker(title: "Rate or Review…"))
				}

				a(.id(IDs.reviewLink), .hidden) {
					"Rate or Review"
				}
				.style {
					$0.chip()
				}
			}
			.style {
				$0
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.textAlign(.center)
					.margin(.top, .rootEm(3))
			}
		}
		.style(Styles.root)
	}

	/**
	The links that open the sheet to rate or review each app on the App Store, by title.
	*/
	private var reviewLinks: [LabeledLink] {
		content.activeApps
			.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard))
			.compactMap { app in
				app.reviewURL.map { LabeledLink(app.title, url: $0) }
			}
	}

	/**
	A wall entry always belongs to the app that its filter and title identify.
	*/
	private struct Entry {
		let app: App
		let kind: QuoteFigure.Kind
	}

	/**
	The title, the page, and the icon of each app with quotes, for the introduction, and its link to rate or review it on the App Store, when it has one, by slug.
	*/
	private static func appsJSON(_ quotes: [Entry]) -> String {
		struct FilteredApp: Encodable {
			let title: String
			let url: LinkDestination
			let icon: RoutePath
			let reviewURL: URL?
		}

		return JSONEncoder.pageJSON(quotes.map(\.app).keyed(by: \.slug.value).mapValues { app in
			FilteredApp(
				title: app.title,
				url: app.url,
				icon: app.iconPath,
				reviewURL: app.reviewURL
			)
		})
	}

	/**
	The press quotes in the order of the apps. They are before the reviews.
	*/
	private var pressQuotes: [Entry] {
		content.activeApps.flatMap { app in
			// The wall of love has the quotes of many apps and years, and each shows its year, when it has one (``QuoteFigure``).
			app.pressQuotes.map { Entry(app: app, kind: .press($0)) }
		}
	}

	/**
	The reviews, newest first. Reviews of the same date are in the order of the app titles and the review titles.
	*/
	private var reviews: [Entry] {
		content.activeAppReviews.map { Entry(app: $0.app, kind: .review($0.review)) }
	}
}

extension ReviewsPage {
	/**
	The parameters of the URL of the page that its script reads.
	*/
	enum Parameters: String {
		/**
		The slug of the one app whose quotes and reviews the page shows, like `?app=velja`.
		*/
		case app
	}

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		/**
		“my apps” in the introduction, which the script hides when the page shows the quotes of one app.
		*/
		case allApps = "reviews-all-apps"

		/**
		The icon and the name of the one app that the page shows, in the introduction, which link to the app.
		*/
		case filterApp = "reviews-filter-app"

		/**
		The link to the quotes of all the apps, in the introduction, which the script shows when the page shows the quotes of one app.
		*/
		case showAll = "reviews-show-all"

		case wall = "reviews-wall"

		/**
		The menu of the apps to rate or review, at the end of the page.
		*/
		case reviewPicker = "reviews-review-picker"

		/**
		The link to rate or review the one app that the page shows, in place of the menu.
		*/
		case reviewLink = "reviews-review-link"

		/**
		The question above the menu or the link to rate or review, which names the one app that the page shows.
		*/
		case reviewPrompt = "reviews-review-prompt"
	}

	/**
	The states that the script of the page sets.
	*/
	enum States: String, ElementStateSet {
		/**
		The wall while it shows the quotes of one app.
		*/
		case oneApp = "one-app"
	}

	/**
	The data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		/**
		The app of a card on the wall of love, by its slug, so the page can show only the reviews of one app with `?app=velja`.
		*/
		case app
	}

	enum Styles: String, StyleSet {
		case root
		case wall
		case cardWrapper

		var style: Style {
			switch self {
			case .root:
				// The width of the header, like the pages of the app categories, so the title is at the same place on the pages about the apps.
				Style()
					.pageColumn(.page)
			case .wall:
				// Columns that the cards flow through, so cards of different heights fit together. On phones, the cards are one plain column, as a multi-column box of one very tall column can put the last card in a second column at the side, with large text.
				Style()
					.from(.tablet) {
						$0
							.columns(3, minimumWidth: .rootEm(18))
							.gap(column: .rootEm(1.25))
					}
					// The introduction names the one app and links to it, so the cards start with the quote.
					.when(States.oneApp) {
						$0.nested(QuoteFigure.Styles.appLink.selector) {
							$0.hidden()
						}
					}
			case .cardWrapper:
				// On phones, the hundreds of cards are one column, so the browser lays out only the cards near the screen. The height is the average height of a card on a phone, without the padding of the wrapper, which the browser adds to it. Not from tablets, where the columns would move cards while the page scrolls.
				Style()
					.padding(.bottom, .rootEm(1.25))
					.keepsTogether()
					.below(.tablet) {
						$0.rendersOnlyNearScreen(estimatedHeight: .pixels(268))
					}
			}
		}
	}
}
