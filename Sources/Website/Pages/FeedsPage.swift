import Elementary
import Foundation
import SiteKit

struct FeedsPage: Page {
	let apps: [App]

	var path: RoutePath {
		.feeds
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("RSS Feeds"), description: "RSS feeds for the blog, new apps, new repos, and app release notes by Sindre Sorhus.")
	}

	var body: some HTML {
		ProsePage(isSpacious: true) {
			h1 {
				"RSS Feeds"
			}

			div {
				for feed in SiteFeed.allCases {
					FeedCard(feed: feed)
				}
			}
			.style(ProseStyles.excluded, Styles.primaryGrid)

			h2 {
				"App Release Notes"
			}

			div {
				for app in apps.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard)) {
					if let feed = app.releaseNotes?.feed {
						a(.href(feed.path)) {
							AppIcon(app, size: 40)
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
			.style(ProseStyles.excluded, Styles.appGrid)
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
					.gap(.rem(0.75))
					.margin(.top, .rem(2))
					.breakpoint(.sm) {
						$0.gridColumns(3)
					}
			case .appGrid:
				Style()
					.display(.grid)
					.gap(.rem(0.5))
					.margin(.top, .rem(1.5))
					.breakpoint(.sm) {
						$0.gridColumns(2)
					}
			case .card:
				Style()
					.cardSurface()
					.display(.block)
					.padding(.rem(1))
					.nested(Icon.selector) {
						$0
							.margin(.bottom, .rem(0.75))
							.color(.primary(500))
					}
			case .cardTitle:
				Style()
					.display(.block)
					.bold()
					.color(.slate(950), dark: .white)
			case .cardSubtitle:
				Style()
					.display(.block)
					.margin(.top, .rem(0.25))
					.font(.sm)
					.color(.slate(600), dark: .slate(300))
			case .appCard:
				Style()
					.cardSurface()
					.hstack(alignment: .center, spacing: .rem(0.75))
					.padding(.rem(0.75))
			case .appIcon:
				Style()
					.frame(width: .rem(2.5), height: .rem(2.5))
					.cornerRadius(.rem(0.75))
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.slate(900), dark: .white)
			}
		}
	}

}
