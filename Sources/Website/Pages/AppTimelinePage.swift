import Elementary
import Foundation
import SiteKit

/**
Every listed app by the year it came out, newest first.
*/
struct AppTimelinePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.appTimeline
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("App Timeline"), description: "Every app by Sindre Sorhus, by the year it came out.")
	}

	var body: some HTML {
		section {
			h1 {
				"App Timeline"
			}
			.style(Styles.title)

			if let firstYear = years.last?.number {
				p {
					"\(content.listedApps.count) apps since \(firstYear), newest first."
				}
				.style(Styles.intro)
			}

			ol {
				for year in years {
					li {
						h2(.id(String(year.number))) {
							String(year.number)
						}
						.style(Styles.year)

						ul {
							for app in year.apps {
								li {
									a(.href(app.url)) {
										AppIcon(app, size: 48, isNamedNearby: true, morphsAcrossPages: true)
											.style(Styles.icon)

										span {
											span {
												app.title
											}
											.style(Styles.appTitle)

											span {
												app.subtitle
											}
											.style(Styles.subtitle)
										}
										.style(Styles.text)
									}
									.style(Styles.app)
								}
							}
						}
						.style(Styles.apps)
					}
					.style(Styles.yearItem)
				}
			}
			.style(Styles.timeline)
		}
		.style(Styles.root)
	}

	private struct Year {
		let number: Int
		var apps: [App]
	}

	/**
	The apps of each year, newest year first. The apps are newest first too.
	*/
	private var years: [Year] {
		let calendar = Calendar(identifier: .gregorian)
		var years = [Year]()

		for app in content.listedApps {
			let year = calendar.dateComponents(in: .gmt, from: app.publicationDate).year ?? 0

			if years.last?.number == year {
				years[years.count - 1].apps.append(app)
			} else {
				years.append(Year(number: year, apps: [app]))
			}
		}

		return years
	}
}

extension AppTimelinePage {
	enum Styles: StyleSet {
		case root
		case title
		case intro
		case timeline
		case yearItem
		case year
		case apps
		case app
		case icon
		case text
		case appTitle
		case subtitle

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.pagePadding()
			case .title:
				Style()
					.font(.xl4, weight: .bold)
					.letterSpacing(.em(-0.025))
					.color(.primaryText)
			case .intro:
				Style()
					.margin(top: .rem(0.5), horizontal: 0, bottom: .rem(3))
					.font(.lg)
					.color(.secondaryText)
			case .timeline:
				// A line down the side, with a dot at each year.
				Style()
					.margin(.leading, .rem(0.375))
					.border(.leading, .separator, width: .px(2))
			case .yearItem:
				Style()
					.position(.relative)
					.padding(.leading, .rem(1.75))
					.padding(.bottom, .rem(2.5))
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rem(0.625))
							.leading(.rem(-0.4375))
							.frame(width: .rem(0.75), height: .rem(0.75))
							.cornerRadius(.circle)
							.backgroundImage(.brandGradient)
					}
			case .year:
				Style()
					.margin(.bottom, .rem(1))
					.font(.xl2, weight: .bold)
					.declaration(.fontVariantNumeric, "tabular-nums")
					.color(.primaryText)
			case .apps:
				Style().vstack(spacing: .rem(0.25))
			case .app:
				Style()
					.hstack(alignment: .center, spacing: .rem(0.875))
					.margin(.horizontal, .rem(-0.5))
					.padding(.rem(0.5))
					.cornerRadius(.rem(0.75))
					.transition(.backgroundColor, duration: .milliseconds(150))
					.hover {
						$0.background(.gray(100), dark: .white.opacity(0.05))
					}
			case .icon:
				Style()
					.flexShrink(0)
					.cornerRadius(.rem(0.625))
			case .text:
				Style().vstack()
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .subtitle:
				Style()
					.font(.sm)
					.color(.secondaryText)
			}
		}
	}
}
