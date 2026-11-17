import Elementary
import Foundation
import SiteKit
import SOML

/**
Every listed app by the year it came out, newest first.
*/
struct AppTimelinePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.appTimeline
	}

	/**
	The icons of the newest apps, in the order of the page.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(of: content.listedApps, project: content.project)))
	}

	var metadata: PageMetadata {
		PageMetadata(title: "App Timeline", description: "Every app by Sindre Sorhus, by the year it came out.")
	}

	var body: some HTML {
		section {
			PageHeader(title: "App Timeline", intro: years.last.map { "\(content.listedApps.count.formatted(counting: "app")) since \($0.number), newest first." })

			ol {
				for (yearIndex, year) in years.enumerated() {
					li {
						h2(.id(ElementID(String(year.number)))) {
							String(year.number)
						}
						.style(Styles.year)

						ul {
							for (index, app) in year.apps.enumerated() {
								li {
									a(.href(app.url)) {
										// The first icons are in view on a phone. Only a few, as they also load before other images.
										AppIcon(decorative: app, size: 48, isAboveFold: yearIndex == 0 && index < 3)

										span {
											span {
												app.title
											}
											.style(Styles.appTitle)

											span {
												app.displaySubtitle
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

			// The quilt is only built with a GitHub token.
			if !content.contributionYears.isEmpty {
				p {
					"See every year on GitHub in the "
					a(.href(.careerQuilt)) {
						"Career Quilt"
					}
					"."
				}
				.style(Styles.moreLinks)
			}
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
			let year = app.publicationDate.year

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
	enum Styles: String, StyleSet {
		case root
		case timeline
		case yearItem
		case year
		case app
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
				// A line down the side, with a dot at each year. The line starts at the middle of the first dot (``year``), the top of the dot plus half its size, so it does not stick out above the newest year.
				Style()
					.position(.relative)
					.margin(.leading, .rootEm(0.375))
					.padding(.leading, .pixels(2))
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rootEm(1.5))
							.bottom(.zero)
							.leading(.zero)
							.frame(width: .pixels(2))
							.background(.separator)
					}
			case .yearItem:
				Style()
					.padding(.leading, .rootEm(1.75))
					.padding(.bottom, .rootEm(2.5))
					// The line ends at the last app, like the line of the steps.
					.lastChild {
						$0.padding(.bottom, .zero)
					}
			case .year:
				// The year stays at the top of the screen while its apps scroll, like the topics of the guides, as on a phone, the apps of some years are taller than the screen. The negative margin takes back the padding above it, so the space between the years stays the same. The dot is on the title, so it stays on the line next to its year, at the place it has at rest: the padding of the year item and half the dot to the start, centered on the line of the timeline.
				Style()
					.stickySectionTitle()
					.margin(.top, .rootEm(-0.5))
					.margin(.bottom, .rootEm(0.5))
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rootEm(1.125))
							.leading(.rootEm(-2.1875))
							.frame(size: .rootEm(0.75))
							.cornerRadius(.circle)
							.backgroundImage(.brandGradient)
					}
					.textStyle(.title3)
					.monospacedDigit()
					.color(.primaryText)
			case .app:
				// The icon is at the top, next to the title, so it stays with its app when the subtitle wraps to many lines, like with large text.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.875))
					.margin(.horizontal, .rootEm(-0.5))
					.padding(.rootEm(0.5))
					// The radius of the icon plus the padding, so the corner of the fill is parallel to the corner of the icon.
					.cornerRadius(.boxRadius)
					// The fill of a card only under the pointer or with the focus of the keyboard, so a long list of years stays calm. The app picker of the feedback page, a short list of choices, has the fill at rest.
					.hoverFill(.card)
					// An app that the keyboard focuses scrolls into view below the year, not under it, like the guides below their topic.
					.scrollMargin(top: .rootEm(4.5))
			case .appTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .subtitle:
				Style()
					.secondaryText()
					.textWrap(.balance)
			case .moreLinks:
				Style()
					.secondaryText()
					.textLinks()
			}
		}
	}
}
