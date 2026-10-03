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
		PageMetadata(title: PageMetadata.titled("Apps"), description: "Quality crafted apps by Sindre Sorhus")
	}

	var body: some HTML {
		div {
			section {
				header {
					// The menu is next to the title, not in it, so the heading is only the title. The heading gets the font of the row.
					div {
						h1 {
							span {
								"Quality Crafted"
							}

							GradientText("Apps")
						}
						.style(Styles.titleText)

						div {
							OverflowMenu(id: "app-pages-menu", label: "More app pages", groups: content.appExtras, variant: .title)
						}
						.style(Styles.moreMenu)
					}
					.style(Styles.title)

					p {
						for stat in stats {
							span {
								stat
							}
							.style(Styles.stat)
						}
					}
					.style(Styles.stats)
				}
				.style(Styles.hero)

				// `apps.js` shows it with the count when the URL has an `exclude` parameter, like from the “More apps” menu of an app.
				p(.id(.appsFilterNotice), .hidden) {
					span {}
					" "
					a(.href(.apps)) {
						"Show all"
					}
					.style(Styles.showAllLink)
				}
				.style(Styles.filterNotice)

				section(.id("apps-grid"), .data("nosnippet", value: "")) {
					for app in content.activeApps {
						AppCard(app: app, isNew: app.isNew(at: content.buildDate))
					}
				}
				.style(Styles.grid)

				section(.data("nosnippet", value: "")) {
					for group in content.appExtras {
						Section(group.title) {
							ul {
								for link in group.links {
									LinkRow(link: link)
								}
							}
						}
					}
				}
				.style(ProseStyles.root, Styles.extra)
			}
			.style(Styles.container)
		}
		.style(Styles.root)

		JSONScript(schema: Schema.ItemList(
			name: "Sindre Sorhus Apps",
			description: "Quality crafted apps by Sindre Sorhus",
			url: path.absoluteURL(site: Site.url),
			items: content.activeApps.map { app in
				Schema.SoftwareApplication(
					name: app.title,
					description: app.subtitle,
					url: app.path.absoluteURL(site: Site.url),
					applicationCategory: app.schemaCategory,
					operatingSystem: app.operatingSystems,
					author: .authorName,
					downloadUrl: app.appStoreURL
				)
			}
		))

		ModuleScript("/scripts/apps.js")
	}

	private var stats: [String] {
		let calendar = Calendar(identifier: .gregorian)
		let firstYear = content.listedApps.map(\.publicationDate).min().map { calendar.component(.year, from: $0) }
		let yearsOfCraft = firstYear.map { calendar.component(.year, from: content.buildDate) - $0 } ?? 0

		return [
			"\(content.listedApps.count) apps",
			"\(yearsOfCraft) years of craft",
			"6 million users",
			"10K answered support emails",
		]
	}
}

extension AppsPage {
	enum Styles: StyleSet {
		case root
		case container
		case hero
		case title
		case titleText
		case moreMenu
		case stats
		case stat
		case grid
		case extra
		case filterNotice
		case showAllLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.background(.slate(50))
					.dark {
						$0.background(.inherit)
					}
			case .container:
				Style()
					.frame(width: .percent(100))
					.margin(vertical: 0, horizontal: .auto)
					.padding(vertical: .rem(4), horizontal: 0)
					.breakpoint(.sm) {
						$0
							.frame(maxWidth: .rem(40))
							.padding(vertical: .rem(4), horizontal: .rem(1.5))
					}
					.breakpoint(.md) {
						$0.frame(maxWidth: .rem(48))
					}
					.breakpoint(.lg) {
						$0
							.frame(maxWidth: .rem(64))
							.padding(vertical: .rem(5), horizontal: .rem(1.5))
					}
					.breakpoint(.xl) {
						$0.frame(maxWidth: .rem(80))
					}
					.breakpoint(.xxl) {
						$0.frame(maxWidth: .rem(96))
					}
			case .hero:
				Style()
					.margin(.bottom, .rem(1.25))
					.textAlign(.center)
					.breakpoint(.md) {
						$0.margin(.bottom, .rem(4))
					}
			case .title:
				Style()
					.vstack(alignment: .center, justification: .center)
					.gap(.rem(0.75))
					.margin(.bottom, .rem(1.5))
					.font(size: .rem(2.5))
					.bold()
					.letterSpacing(.em(-0.05))
					.breakpoint(.sm) {
						$0
							.flexDirection(.row)
							.flexWrap()
							.font(.xl5)
					}
					.breakpoint(.md) {
						$0.font(size: .rem(4.5))
					}
			case .titleText:
				Style()
					.display(.flex)
					.flexWrap()
					.alignItems(.center)
					.justifyContent(.center)
					.gap(.rem(0.5))
			case .moreMenu:
				Style()
					.display(.inlineFlex)
					.margin(.top, .rem(0.25))
					.scaleEffect(1.25)
					.breakpoint(.sm) {
						$0
							.margin(.top, 0)
							.offset(x: .rem(0.5), y: .px(4))
							.scaleEffect(1.2)
					}
					.breakpoint(.md) {
						$0.offset(x: .rem(0.5), y: .px(7))
					}
			case .stats:
				Style()
					.vstack(justification: .center)
					.gap(row: .rem(0.25), column: 0)
					.fontFamily(.monospace)
					.font(.sm)
					.letterSpacing(.em(0.025))
					.declaration(.fontVariantNumeric, "oldstyle-nums tabular-nums")
					.color(.slate(500))
					.breakpoint(.md) {
						$0
							.flexDirection(.row)
							.alignItems(.center)
							.gap(row: 0)
					}
			case .stat:
				// A dot between the stats on one line. Screen readers skip it, as its alternative text is empty.
				Style()
					.breakpoint(.md) {
						$0.nested("& + &::before") {
							$0
								.content("·", alternativeText: "")
								.margin(vertical: 0, horizontal: .rem(0.5))
								.opacity(0.5)
						}
					}
			case .grid:
				Style()
					.grid(columns: 1)
					.margin(top: .rem(1.5), horizontal: .auto, bottom: .rem(3))
					.breakpoint(.sm) {
						$0
							.gap(.rem(3))
							.margin(vertical: .rem(3), horizontal: .auto)
							.padding(.rem(0.25))
					}
					.breakpoint(.lg) {
						$0.gridColumns(2)
					}
					.dark {
						$0.color(.white)
					}
			case .extra:
				Style()
					.margin(top: .px(120), horizontal: .auto, bottom: .px(60))
			case .filterNotice:
				Style()
					.margin(.bottom, .rem(1))
					.font(.sm)
					.textAlign(.center)
					.color(.slate(500), dark: .slate(400))
			case .showAllLink:
				Style()
					.underline()
					.hover {
						$0.color(.slate(700), dark: .slate(200))
					}
			}
		}
	}
}
