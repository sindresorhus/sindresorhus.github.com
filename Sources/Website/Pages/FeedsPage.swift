import Elementary
import Foundation
import SiteKit

struct FeedsPage: Page {
	let apps: [App]

	var path: RoutePath {
		.feeds
	}

	var metadata: PageMetadata {
		PageMetadata(title: "RSS Feeds", description: "RSS feeds for the blog, new apps, new guides, new repos, and app release notes by Sindre Sorhus.")
	}

	var body: some HTML {
		ProsePage(title: "RSS Feeds") {
			div {
				for feed in SiteFeed.allCases {
					FeedCard(feed: feed)
				}
			}
			.style(Styles.primaryGrid)

			Section("App Release Notes") {
				div {
					for app in apps.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard)) {
						if let feed = app.releaseNotes?.feed {
							a(.href(feed.path)) {
								AppIcon(decorative: app, size: 40)
									.style(Styles.appIcon)

								span {
									app.title
								}
								.style(Styles.appTitle)
							}
							.style(Styles.appCard)
						}
					}
				}
				.style(Styles.appGrid)
			}
		}
	}

	private struct FeedCard: HTML {
		let feed: SiteFeed

		var body: some HTML {
			a(.href(feed.path)) {
				feed.icon.size(.rootEm(1.5))

				span {
					feed.shortTitle
				}
				.style(Styles.cardTitle)

				span {
					feed.subtitle
				}
				.style(Styles.cardSubtitle)
			}
			.style(Styles.card)
		}
	}
}

extension FeedsPage {
	enum Styles: String, StyleSet {
		case primaryGrid
		case appGrid
		case card
		case cardTitle
		case cardSubtitle
		case appCard
		case appIcon
		case appTitle

		var style: Style {
			switch self {
			case .primaryGrid, .appGrid:
				Style()
					.display(.grid)
					.gap(.rootEm(1))
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
			case .card:
				// The cards are links in prose, but do not look like text links. The icon is next to the title and the subtitle, like the icon of the app cards below. It is in the middle of a column with the width of an app icon, and the padding at the sides is the one of an app card, so the icons and the text of the two kinds of cards are in line.
				Style()
					.cardSurface()
					.grid(columns: .fixed(.rootEm(2.5)), .flexible())
					.gap(column: .rootEm(0.75))
					.alignItems(.center)
					.fontWeight(.regular)
					.padding(vertical: .rootEm(1), horizontal: .rootEm(0.75))
					.nested(Icon.selector) {
						$0
							.gridRowSpan(2)
							.justifySelf(.center)
							.color(.primary(500))
					}
			case .cardTitle:
				// Like the titles of the app cards below.
				Style()
					.display(.block)
					.textStyle(.headline)
					.color(.primaryText)
			case .cardSubtitle:
				// Like the subtitle of an app card, it does not end with one word on its last line.
				Style()
					.display(.block)
					.margin(.top, .rootEm(0.25))
					.secondaryText()
					.textWrap(.pretty)
			case .appCard:
				Style()
					.cardSurface()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(0.75))
			case .appIcon:
				// The size of the icon in the card.
				Style()
					.frame(size: .rootEm(2.5))
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			}
		}
	}
}
