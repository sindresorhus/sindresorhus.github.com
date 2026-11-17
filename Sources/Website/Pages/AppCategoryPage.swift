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
		PageMetadata(
			title: category.title,
			description: category.searchDescription(apps: category.apps(in: content), featuredApps: content.featuredApps),
			feeds: [SiteFeed.newApps.link]
		)
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(category: category, apps: category.apps(in: content), featuredApps: content.featuredApps, project: content.project))
	}

	var body: some HTML {
		section {
			// The featured apps first, in the order of the apps page today, like the description of the page, which names them first.
			let apps = category.apps(in: content).startingWith(content.dailyFeaturedApps)

			// A visitor from a search result can get to the other apps without the menu of the header. The space below is the space below the back link of the pages about an app (``ProsePage``).
			div {
				BackLink(title: "All Apps", path: .apps)
			}
			.style {
				$0.margin(.bottom, .rootEm(1.5))
			}

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
				.style {
					$0.before {
						$0.backgroundImage(Self.glow(of: iconApps))
					}
				}
			}

			PageHeader(title: category.title) {
				description.inlineContent
			}

			if apps.isEmpty {
				p {
					"No apps found."
				}
			} else {
				// Right below the title of the page, so the names of the apps are level 2 headings. The title of the free and the paid apps already says the price, and the introduction of the Setapp apps says that each is a purchase too.
				AppGrid(
					apps: apps,
					buildDate: content.buildDate,
					isAtTop: true,
					headingLevel: .h2,
					showsPrice: ![.free, .paid, .setapp].contains(category)
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

	/**
	A soft, still glow below each icon of the row in the color of its icon (``App/glowColor``), like the glow below the icon of an app page, so the page starts with the colors of its apps. The color is also found for a white icon with a colored glyph and for a colorful icon, so most icons of a row have a glow. An icon without color has none. In dark mode, a dark accent is lighter, like the glow of the app page, so it still shows.
	*/
	private static func glow(of apps: some Collection<App>) -> [CSSImage] {
		// Each icon covers 12px of the 64px of the icon before it (``Styles/icon``).
		let step = 52.0 / 64

		return apps.enumerated().compactMap { index, app in
			app.glowColor.map { tint -> CSSImage in
				// The middle of the icon, as a part of the row, in the layer, which is 50px wider than the row at each side (``Styles/icons``).
				let middle = (0.5 + Double(index) * step) / (1 + Double(apps.count - 1) * step)
				let x = LengthPercentage.pixels(50) + (.percent(100) - .pixels(100)) * middle

				return .radialGradient(
					.ellipse(radiusX: .pixels(75), radiusY: .pixels(65), at: CSSPosition(x: x, y: .percent(60))),
					.lightDark(tint.opacity(0.3), tint.withMinimumLightness(0.6).opacity(0.3)),
					.transparent
				)
			}
		}
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
				// The glow of the accents (``AppCategoryPage/glow(of:)``) is one layer behind the whole row, not one on each icon, as each icon has its own turn and order, so the glow of an icon would cover its neighbors. The row is as wide as its icons, and its own stacking context, so the layer is behind the icons and in front of the page.
				Style()
					.display(.flex)
					.alignItems(.start)
					.frame(width: .fitContent)
					.margin(.bottom, .length(.rootEm(1.5) + .pixels(15)))
					.position(.relative)
					.zIndex(0)
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.pixels(-40))
							.leading(.pixels(-50))
							.trailing(.pixels(-50))
							.frame(height: .pixels(150))
							.zIndex(-1)
							.filter(.blur(radius: .pixels(14)))
							.allowsHitTesting(false)
					}
			case .icon:
				// Slightly overlapped, and smaller on narrow screens, so all seven fit, also with large text. Each icon is on a slight arc (``IconArc``).
				Style()
					.frame(size: .length(.min(.pixels(64), .viewportWidth(13))))
					.margin(.leading, .length(.max(.pixels(-12), .viewportWidth(-2.5))))
					.firstChild {
						$0.margin(.leading, .zero)
					}
			case .footer:
				// Balanced lines, as the note is short and centered, so its last word is not alone on a line. The paragraphs have `pretty` of the page (``SiteStylesheet``), so the rule is on them.
				Style()
					.margin(.top, .rootEm(4))
					.textAlign(.center)
					.descendants("p") {
						$0.textWrap(.balance)
					}
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
