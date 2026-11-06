import Elementary
import Foundation
import SiteKit

/**
The apps of a category, like the free apps, as cards like on the apps page.
*/
struct AppCategoryPage: Page {
	let category: AppCategory
	let content: SiteContent

	var path: RoutePath {
		category.path
	}

	var sitemapEntry: SitemapEntry {
		category.apps(in: content).listSitemapEntry
	}

	private var description: MarkdownDocument {
		MarkdownDocument(parsing: category.description, options: .site)
	}

	/**
	The description of the page says how many apps it has and names the best known ones, as the text at the top of the page is short, like “I love making menu bar apps.”
	*/
	var metadata: PageMetadata {
		PageMetadata(title: category.title, description: category.searchDescription(apps: category.apps(in: content), featuredApps: content.featuredApps))
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(category: category, apps: category.apps(in: content), featuredApps: content.featuredApps, project: content.project))
	}

	var body: some HTML {
		section {
			let apps = category.apps(in: content)

			// The icons of the first apps, so the page starts with the family of apps. Screen readers skip them, as the cards below have the same apps.
			if !apps.isEmpty {
				let iconApps = apps.prefix(7)

				div {
					for (index, app) in iconApps.enumerated() {
						let arc = IconArc(index: index, count: iconApps.count)

						AppIcon(decorative: app, size: 64, isAboveFold: true)
							.style(Styles.icon)
							.style {
								$0
									.rotationEffect(.degrees(arc.turnInDegrees))
									.offset(y: .percent(arc.drop * 100))
									.scaleEffect(CSSNumber(arc.scale))
									.zIndex(arc.zIndex)
							}
					}
				}
				.accessibilityHidden()
				.style(Styles.icons)
			}

			PageHeader(title: category.title) {
				description.inlineContent
			}

			if apps.isEmpty {
				p {
					"No apps found."
				}
			} else if category.isGroupedByPlatform {
				let groups = Platform.allCases
					.map { platform in (platform: platform, apps: apps.filter { $0.platforms.contains(platform) }) }
					.filter { !$0.apps.isEmpty }

				for (index, group) in groups.enumerated() {
					Section(group.platform.rawValue, id: ElementID(group.platform.rawValue.lowercased())) {
						// The icons of the first section are at the top, so they load first.
						AppGrid(apps: group.apps, buildDate: content.buildDate, isAtTop: index == 0)
					}
				}
			} else {
				// Right below the title of the page, so the names of the apps are level 2 headings.
				AppGrid(
					apps: apps,
					buildDate: content.buildDate,
					isAtTop: true,
					headingLevel: .h2
				)
			}

			if let footer = category.footer {
				div {
					Prose(markdown: MarkdownDocument(parsing: footer, options: .site).content)
				}
				.style(Styles.footer)
			}
		}
		.style(Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case icons
		case icon
		case footer

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.page)
			case .icons:
				// The space below has room for the lower icons at the ends of the arc, which are up to 15px lower (``icon``).
				Style()
					.display(.flex)
					.alignItems(.start)
					.margin(.bottom, .length(.rootEm(1.5) + .pixels(15)))
			case .icon:
				// Slightly overlapped, and smaller on narrow screens, so all seven fit, also with large text. Each icon is on a slight arc (``IconArc``).
				Style()
					.frame(size: .length(.min(.pixels(64), .viewportWidth(13))))
					.margin(.leading, .length(.max(.pixels(-12), .viewportWidth(-2.5))))
					.firstChild {
						$0.margin(.leading, .zero)
					}
					.filter(AppCard.iconShadow)
			case .footer:
				Style()
					.margin(.top, .rootEm(4))
					.textAlign(.center)
			}
		}
	}
}

/**
The place of an app icon on the slight arc of a row of icons, like a fanned hand of cards: each icon is turned, lowered, and made a little smaller by its distance from the middle of the row, and the icons nearer the middle are in front. The top of a category page (``AppCategoryPage``) and its social card (``OpenGraphCard``) have it.
*/
struct IconArc {
	/**
	How far the icon is from the middle of the row, in icons, like -3 for the first of seven, and 0.5 for the fourth of six.
	*/
	let distance: Double

	init(index: Int, count: Int) {
		self.distance = Double(index) - Double(count - 1) / 2
	}

	/**
	The turn, clockwise for the icons after the middle.
	*/
	var turnInDegrees: Double {
		distance * 3.5
	}

	/**
	How much lower the icon is than the middle, as a part of its size, so the row follows a curve.
	*/
	var drop: Double {
		0.025 * distance * distance
	}

	var scale: Double {
		1 - abs(distance) * 0.03
	}

	/**
	The order of the icons in front of each other, highest in the middle.
	*/
	var zIndex: Int {
		10 - Int((abs(distance) * 2).rounded())
	}
}
