import Elementary
import Foundation
import SiteKit

/**
The app grid, with stats and links to the app categories.
*/
struct AppsPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.apps
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Apps", description: "Quality crafted apps by Sindre Sorhus")
	}

	var headerBackground: SiteHeader.Background {
		.transparentAtTop
	}

	var body: some HTML {
		div {
			section {
				// The main page of the apps keeps its own centered title, unlike the other pages (``PageHeader``).
				header {
					// `apps-glass.js` draws liquid glass on it in the colors of the featured apps. Without WebGL, and until it draws, the colors are a still gradient.
					canvas(.id(Hooks.glass)) {}
						// The colors are data of the build, like the accent of an app card, so they are custom properties in the `style` attribute.
						.attributes(.style(glassColorDeclarations))
						.accessibilityHidden()
						.style(Styles.glass)

					// On phones, “Apps” is larger on its own line, below “Quality Crafted”.
					h1(.id(Hooks.title)) {
						span {
							"Quality Crafted"
						}
						.style(Styles.titleText)

						// A space for copied text and screen readers. The flex layout does not show it.
						" "

						span {
							"Apps"
						}
						.style(Styles.titleText, Styles.titleApps)
					}
					.style(Styles.title)

					StatList(stats: stats, isCentered: true)

					// The menu is the last chip, so the heading is only the title.
					nav {
						for category in AppCategory.browsable {
							a(.href(category.path)) {
								category.name
							}
							.style(Styles.categoryLink)
						}

						OverflowMenu(label: "More app pages", groups: Self.linkGroups, variant: .chip)
					}
					.accessibilityLabel("App categories")
					.style(Styles.categories)
				}
				.style(Styles.hero)

				// `apps.js` shows it with the count when the URL has an `exclude` parameter, like from the “More apps” menu of an app.
				p(.id(Hooks.filterNotice), .hidden) {
					span(.id(Hooks.filterCount)) {}
					" "
					a(.href(.apps)) {
						"Show All"
					}
					.style(Styles.showAllLink)
				}
				.style(Styles.filterNotice)

				if !content.featuredApps.isEmpty {
					section {
						h2 {
							"Featured"
						}
						.style(SectionStyles.label)

						AppGrid(apps: content.featuredApps, content: content, isAtTop: true)
					}
					.hiddenFromSearchSnippets()
					.style(Styles.grid)
				}

				section {
					if !content.featuredApps.isEmpty {
						h2 {
							"More Apps"
						}
						.style(SectionStyles.label)
					}

					AppGrid(apps: otherApps, content: content, isAtTop: content.featuredApps.isEmpty)
				}
				.hiddenFromSearchSnippets()
				.style(Styles.grid)

				section {
					Prose {
						for group in Self.linkGroups {
							Section(group.title) {
								ul {
									for link in group.links {
										LinkRow(link: link)
									}
								}
							}
						}
					}
				}
				.hiddenFromSearchSnippets()
				.style(Styles.extra)
			}
			.style(Styles.container)
		}

		JSONScript(schema: Schema.ItemList(
			name: "Sindre Sorhus Apps",
			description: "Quality crafted apps by Sindre Sorhus",
			url: path.absoluteURL,
			items: content.activeApps.map { app in
				Schema.SoftwareApplication(app: app, info: content.appStoreInfo(of: app))
			}
		))

		ModuleScript("/scripts/apps.js")
		// A page script, not imported by `apps.js`, so it gets the content hash in its URL, and a browser does not keep an old copy after a deploy.
		ModuleScript("/scripts/apps-glass.js")
	}

	/**
	The app categories and more pages about the apps, in the menu next to the title and at the end of the page.
	*/
	private static let linkGroups = [
		LinkGroup(
			title: "Categories",
			links: AppCategory.browsable.map(\.link) + [
				LabeledLink("Open Source", destination: .url(#URL("https://github.com/search?q=user%3Asindresorhus+language%3Aswift+topic%3Aapp+archived%3Afalse&type=repositories")), description: "Apps with the source code available"),
				LabeledLink("Random", destination: .path(.randomApp), description: "Show a random app"),
			]
		),
		LinkGroup(
			title: "More",
			links: [
				.faq,
				LabeledLink("Tiny Apps", destination: .path("/tiny-apps"), description: "Smaller utilities"),
				.appTimeline,
				.wallOfLove,
				.olderVersions,
				LabeledLink("RSS Feed for New Apps", destination: .path(.feeds), description: "Get notified about new apps I publish"),
				.discounts,
				.termsOfUse,
				LabeledLink(AppCategory.archived.title, destination: .path(AppCategory.archived.path), description: AppCategory.archived.summary),
			]
		),
	]

	/**
	The apps below the featured apps, newest first.
	*/
	private var otherApps: [App] {
		let featuredSlugs = Set(content.featuredApps.map(\.slug))
		return content.activeApps.filter { !featuredSlugs.contains($0.slug) }
	}

	/**
	The colors of the glass behind the title, as custom properties: the accent colors of the featured apps, between the violet and the pink of the brand gradient, so the glass matches “Apps”. A missing accent color is the blue of the brand.
	*/
	private var glassColorDeclarations: String {
		let accentColors = content.featuredApps.compactMap(\.accentColor).map { Color($0) }

		func accentColor(_ index: Int) -> Color {
			accentColors.indices.contains(index) ? accentColors[index] : .primary(500)
		}

		return zip(Self.glassColors, [accentColor(0), .violet(500), accentColor(1), .secondary(500), accentColor(2)])
			.map { "\($0.name): \($1)" }
			.joined(separator: "; ")
	}

	private var stats: [String] {

		return [
			content.activeApps.count.formatted(counting: "app"),
			"\((content.yearsOfCraft ?? 0).formatted(counting: "year")) of craft",
			"\(Site.appUserCount.approximateCount) users",
			"10K answered support emails",
		]
	}
}

extension AppsPage {
	/**
	The colors of the glass behind the title, from left to right. `apps-glass.js` reads them.
	*/
	fileprivate static let glassColors = (1...5).map { StyleVariable<Color>("--glass-color-\($0)") }

	/**
	How strong the light on the title is. It is registered, so it fades in and out.
	*/
	fileprivate static let titleLight = RegisteredProperty<CSSValue>("--title-light", syntax: "<percentage>", initialValue: .percent(0))

	/**
	Where the pointer is on a part of the title, for the light. `apps.js` sets them.
	*/
	fileprivate static let lightX = StyleVariable<Length>("--light-x")
	fileprivate static let lightY = StyleVariable<Length>("--light-y")

	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case filterCount = "apps-filter-count"
		case filterNotice = "apps-filter-notice"
		case glass = "apps-glass"
		case title = "apps-title"
	}

	enum Styles: StyleSet {
		case container
		case hero
		case glass
		case title
		case titleText
		case titleApps
		case categories
		case categoryLink
		case grid
		case extra
		case filterNotice
		case showAllLink

		var style: Style {
			switch self {
			case .container:
				Style()
					.padding(.vertical, .rootEm(4))
					.from(.laptop) {
						$0.padding(.vertical, .rootEm(5))
					}
			case .hero:
				// A stacking context, so the glass is behind the title, but not behind the page. A container, so the size of the title on phones follows the width of its content (`cqi`), which `vw` would not, as it includes a classic scroll bar.
				Style()
					.position(.relative)
					.zIndex(0)
					.containerType(.inlineSize)
					.margin(.bottom, .rootEm(1.25))
					.padding(.horizontal, .pageGutter)
					.textAlign(.center)
					// The stats are on the glass, so they are stronger than secondary text, with a contrast of at least 5:1 on its brightest color.
					.nested(StatList.Styles.root.selector) {
						$0.color(.gray(700), dark: .gray(200))
					}
					.from(.tablet) {
						$0.margin(.bottom, .rootEm(4))
					}
			case .glass:
				// It starts at the top of the page, behind the site header and the space above the title, and ends above the app grid. The glass and the still gradient fade out before its sides and its bottom.
				Style()
					.position(.absolute)
					.top(-Self.topPadding - SiteHeader.height)
					.leading(0)
					.trailing(0)
					.zIndex(-1)
					.frame(width: .percent(100), height: .percent(100) + Self.topPadding + SiteHeader.height, maxWidth: .rootEm(110))
					.margin(.horizontal, .auto)
					.allowsHitTesting(false)
					.backgroundImage(
						Self.glassField(0, x: 24, y: 54),
						Self.glassField(1, x: 37, y: 46),
						Self.glassField(2, x: 50, y: 52),
						Self.glassField(3, x: 63, y: 48),
						Self.glassField(4, x: 76, y: 54)
					)
					.when(.state, is: "drawing") {
						$0.backgroundImage(.none)
					}
					.from(.laptop) {
						$0
							.top(-Self.laptopTopPadding - SiteHeader.height)
							.frame(height: .percent(100) + Self.laptopTopPadding + SiteHeader.height)
					}
			case .title:
				// The expanded width of SF Pro on Apple platforms, like the name on the home page. On phones, the size makes “Quality Crafted” fill the line.
				Style()
					.vstack(alignment: .center, spacing: .em(0.12))
					.margin(.bottom, .rootEm(1.5))
					.fontFamily(.expandable)
					.fontWidth(.expanded)
					.font(size: .min(.rootEm(2.5), .containerInlineSize(100) * (1 / 7.8)))
					.lineHeight(1)
					.bold()
					.letterSpacing(.em(-0.05))
					// A soft shadow of a few faint layers, each with a larger offset and blur than the one before, so it fades smoothly. It is a filter, not a text shadow, as a text shadow draws over the background that colors the letters of the lit title.
					.filter(
						.dropShadow(Shadow(y: .pixels(1), blur: .pixels(1), color: .lightDark(.black.opacity(0.07), .black.opacity(0.3)))),
						.dropShadow(Shadow(y: .pixels(2), blur: .pixels(3), color: .lightDark(.black.opacity(0.07), .black.opacity(0.3)))),
						.dropShadow(Shadow(y: .pixels(5), blur: .pixels(10), color: .lightDark(.black.opacity(0.07), .black.opacity(0.3))))
					)
					.setting(AppsPage.titleLight, to: .percent(0))
					.transition(TransitionProperty(Property(AppsPage.titleLight.name)), animation: .default(duration: .milliseconds(500)))
					.media(Self.litTitle) {
						$0.hover {
							$0.setting(AppsPage.titleLight, to: .percent(35))
						}
					}
					.media(Self.litTitle && .dark) {
						$0.hover {
							$0.setting(AppsPage.titleLight, to: .percent(60))
						}
					}
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.justifyContent(.center)
							.gap(.em(0.22))
							.fluidFontSize(fromRem: 3.25, toRem: 4.5, between: .smallTablet, and: .laptop)
					}
			case .titleText:
				// One plain color, so the color comes from the glass behind it.
				Style()
					.textWrap(.nowrap)
					.color(.primaryText)
					.media(Self.litTitle) {
						$0
							.color(.transparent)
							// The letters are the text color, as a background layer below the light. The light is tinted, like light through the glass, as a white light would not show on the white letters of dark mode.
							.backgroundImage(Self.light(.lightDark(.primary(500).mix(with: .secondary(500), amount: .percent(30)), .primary(300).mix(with: .secondary(400), amount: .percent(40)))), .linearGradient("to right", .primaryText, .primaryText))
							.backgroundClip(.text)
							// The background only fills the box, and with the tight lines and letters, the descenders and the last letter of some fonts, like Segoe UI on Windows, reach out of it and would be cut off. The padding makes the box larger, and the negative margin keeps the layout.
							.padding(vertical: .em(0.2), horizontal: .em(0.1))
							.margin(vertical: -.em(0.2), horizontal: -.em(0.1))
					}
			case .titleApps:
				Style()
					.font(size: .em(2.1))
					.letterSpacing(.em(-0.05))
					.from(.smallTablet) {
						$0.font(size: .em(1))
					}
			case .categories:
				// The categories as chips below the stats, so visitors find the kind of app they want without opening the menu.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.margin(.top, .rootEm(2))
			case .categoryLink:
				Style().chip()
			case .grid:
				// The cards line up with the content of the header and the footer, like on the other pages with app cards.
				Style()
					.contentColumn(.page)
					.margin(top: .rootEm(2.5), horizontal: .auto, bottom: .rootEm(3))
			case .extra:
				Style()
					.margin(top: .pixels(120), horizontal: .auto, bottom: .pixels(60))
			case .filterNotice:
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.horizontal, .pageGutter)
					.secondaryText()
					.textAlign(.center)
			case .showAllLink:
				Style().textLink()
			}
		}

		/**
		The space above the title, which the glass extends into.
		*/
		private static let topPadding = Length.rootEm(4)
		private static let laptopTopPadding = Length.rootEm(5)

		/**
		Devices where a light follows the pointer over the title: a mouse or a trackpad, for visitors who allow motion.
		*/
		private static let litTitle = MediaQuery.hover && .finePointer && .allowsMotion

		/**
		A soft light at the pointer, like light on glass, as the top background layer of the letters. It is as strong as ``AppsPage/titleLight``.
		*/
		private static func light(_ color: Color) -> CSSValue {
			.radialGradient("circle 2.5em at \(AppsPage.lightX.value(default: .percent(50))) \(AppsPage.lightY.value(default: .percent(50)))", Color.transparent.mix(with: color, amount: AppsPage.titleLight.value), .transparent)
		}

		/**
		A soft field in one of the colors of the glass, for the still gradient.
		*/
		private static func glassField(_ index: Int, x: Double, y: Double) -> CSSValue {
			let color = AppsPage.glassColors[index].value(default: .primary(500))
			return .radialGradient("ellipse 24% 46% at \(CSSValue.percent(x)) \(CSSValue.percent(y))", .lightDark(color.opacity(0.28), color.opacity(0.4)), .transparent)
		}
	}
}

extension SiteContent {
	/**
	The most apps that the apps page features.
	*/
	static let maximumFeaturedAppCount = 4

	/**
	The active apps with `isFeatured`, which the apps page shows first, in an order that changes every day. When more apps are featured than ``maximumFeaturedAppCount``, the first ones by title are kept, so the same apps are left out on every build, and `website check` warns about the others (``extraFeaturedApps``).
	*/
	var featuredApps: [App] {
		var generator = SeededRandomNumberGenerator.daily("featured-apps", on: buildDate)
		return Array(featuredAppsByTitle.prefix(Self.maximumFeaturedAppCount)).shuffled(using: &generator)
	}

	/**
	The apps with `isFeatured` that the apps page leaves out, as more than ``maximumFeaturedAppCount`` apps are featured. They are in the list of the other apps.
	*/
	var extraFeaturedApps: [App] {
		Array(featuredAppsByTitle.dropFirst(Self.maximumFeaturedAppCount))
	}

	private var featuredAppsByTitle: [App] {
		activeApps
			.filter(\.isFeatured)
			.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard))
	}
}
