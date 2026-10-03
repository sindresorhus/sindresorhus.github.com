import Elementary
import Foundation
import SiteKit

/**
The bar in the site header that replaces the site navigation when the app header scrolls away, with a scroll-driven animation. `app.js` marks the link of the visible section with `aria-current`.
*/
struct AppSecondaryNavigation: HTML {
	let app: App

	var body: some HTML {
		div(.id(.appNavigation)) {
			a(.href(app.url), .ariaLabel(app.title)) {
				AppIcon(app, size: 32, isNamedNearby: true)
					.style(Styles.icon)

				span {
					app.title
				}
				.style(Styles.name)
			}
			.style(Styles.identity)

			nav(.ariaLabel("\(app.title) sections")) {
				for link in app.links {
					a(.href(link.href)) {
						link.title
					}
					.style(Styles.link)
				}

				div {
					OverflowMenu.appPage(app, id: "app-navigation-menu")
				}
				.style(Styles.overflow)

				// With one download option, “Get” links to it. With more, it goes up to the download options.
				if !app.isArchived, !app.downloadOptions.isEmpty {
					Button("Get", destination: app.downloadOptions.count == 1 ? app.downloadOptions[0].url : "#\(AppHero.id)", size: .small)
						.style(Styles.getButton)
				}
			}
			.style(Styles.links)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case identity
		case icon
		case name
		case links
		case link
		case overflow
		case getButton

		var style: Style {
			switch self {
			case .root:
				// Only shown on larger screens, in browsers with scroll-driven animations.
				Style()
					.position(.absolute)
					.inset(0)
					.hidden()
					.supports("(animation-timeline: view())") {
						$0.breakpoint(.md) {
							$0
								.display(.flex)
								.animation(SiteHeader.Animations.showNavigation, timeline: AppHero.timeline, range: AppHero.scrolledAwayRange)
						}
					}
					.alignItems(.center)
					.justifyContent(.spaceBetween)
					.frame(width: .percent(100))
					.pageWidth()
					.padding(.rem(0.75))
					.color(.gray(600), dark: .slate(200))
					.breakpoint(.md) {
						$0.padding(vertical: .rem(0.75), horizontal: .rem(1))
					}
			case .identity:
				Style()
					.hstack(alignment: .center, spacing: .rem(0.75))
					.flexShrink(0)
			case .icon:
				Style().cornerRadius(.rem(0.5))
			case .name:
				Style()
					.display(.inline)
					.font(.lg, weight: .bold)
					.noWrap()
					.color(.primaryText)
					.hidden(below: .lg)
			case .links:
				Style().hstack(alignment: .center)
			case .link:
				Style()
					.display(.flex)
					.alignItems(.center)
					.padding(vertical: .rem(0.75), horizontal: .rem(1))
					.fontWeight(.medium)
					.noWrap()
					.currentPageUnderline()
					.hover {
						$0.color(.gray(900))
					}
					.hidden(below: .md)
					.dark {
						$0.hover {
							$0.color(.white)
						}
					}
			case .overflow:
				Style()
					.display(.flex)
					.padding(.horizontal, .rem(1))
					.setting(OverflowMenu.color, to: CSSValue(Color.lightDark(.gray(600), .slate(200))))
					.hidden(below: .md)
			case .getButton:
				Style()
					.position(.relative)
					.zIndex(10)
					.margin(.leading, .rem(1))
			}
		}
	}
}
