import Elementary
import Foundation
import SiteKit

struct FeedsPage: Page {
	let apps: [App]

	var path: RoutePath {
		.feeds
	}

	var metadata: PageMetadata {
		PageMetadata(title: "RSS Feeds", description: "RSS feeds for the blog, new apps, new repos, and app release notes by Sindre Sorhus.")
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
				feed.icon

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
	enum Styles: StyleSet {
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
			case .primaryGrid:
				Style()
					.display(.grid)
					.gap(.rootEm(1))
					.from(.smallTablet) {
						$0.gridColumns(3)
					}
			case .appGrid:
				Style()
					.display(.grid)
					.gap(.rootEm(1))
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
			case .card:
				// The cards are links in prose, but do not look like text links.
				Style()
					.cardSurface()
					.display(.block)
					.fontWeight(.regular)
					.padding(.rootEm(1))
					.nested(Icon.selector) {
						$0
							.margin(.bottom, .rootEm(0.75))
							.color(.primary(500))
					}
			case .cardTitle:
				Style()
					.display(.block)
					.bold()
					.color(.primaryText)
			case .cardSubtitle:
				Style()
					.display(.block)
					.margin(.top, .rootEm(0.25))
					.textStyle(.caption)
					.color(.secondaryText)
			case .appCard:
				Style()
					.cardSurface()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(0.75))
			case .appIcon:
				// Not like an image in prose.
				Style()
					.plainImage()
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.cornerRadius(.rootEm(0.75))
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			}
		}
	}

}
