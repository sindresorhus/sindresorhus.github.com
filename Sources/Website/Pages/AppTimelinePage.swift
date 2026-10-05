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
		PageMetadata(title: "App Timeline", description: "Every app by Sindre Sorhus, by the year it came out.")
	}

	var body: some HTML {
		section {
			PageHeader(title: "App Timeline", intro: years.last.map { "\(content.listedApps.count) apps since \($0.number), newest first." })

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
										AppIcon(decorative: app, size: 48)
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
										.vstack()
									}
									.style(Styles.app)
								}
							}
						}
						.vstack(spacing: .rootEm(0.25))
					}
					.style(Styles.yearItem)
				}
			}
			.style(Styles.timeline)

			p {
				"Guess the app of the day in "
				a(.href(.appdle)) {
					"Appdle"
				}

				// The quilt is only built with a GitHub token.
				if !content.contributionYears.isEmpty {
					", or see every year on GitHub in the "
					a(.href(.careerQuilt)) {
						"Career Quilt"
					}
				}

				"."
			}
			.style(Styles.moreLinks)
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
		var years = [Year]()

		for app in content.listedApps {
			let year = app.publicationDate.siteYear

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
		case timeline
		case yearItem
		case year
		case app
		case icon
		case appTitle
		case subtitle
		case moreLinks

		var style: Style {
			switch self {
			case .root:
				// The column of prose pages, so the title lines up with theirs.
				Style()
					.pageColumn(.prose)
			case .timeline:
				// A line down the side, with a dot at each year.
				Style()
					.margin(.leading, .rootEm(0.375))
					.border(.leading, .separator, width: .pixels(2))
			case .yearItem:
				Style()
					.position(.relative)
					.padding(.leading, .rootEm(1.75))
					.padding(.bottom, .rootEm(2.5))
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rootEm(0.625))
							.leading(.rootEm(-0.4375))
							.frame(width: .rootEm(0.75), height: .rootEm(0.75))
							.cornerRadius(.circle)
							.backgroundImage(.brandGradient)
					}
			case .year:
				Style()
					.margin(.bottom, .rootEm(1))
					.font(.extraLarge2, weight: .bold)
					.monospacedDigit()
					.color(.primaryText)
			case .app:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.875))
					.margin(.horizontal, .rootEm(-0.5))
					.padding(.rootEm(0.5))
					.cornerRadius(.rootEm(0.75))
					.transition(.backgroundColor, animation: .stateChange)
					.hover {
						$0.background(.gray(100), dark: .white.opacity(0.05))
					}
			case .icon:
				Style()
					.flexShrink(0)
					.cornerRadius(.rootEm(0.625))
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .subtitle:
				Style()
					.secondaryText()
			case .moreLinks:
				Style()
					.secondaryText()
					.textLinks()
			}
		}
	}
}
