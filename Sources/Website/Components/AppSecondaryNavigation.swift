import Elementary
import Foundation
import SiteKit

/**
The bar in the site header that replaces the site navigation with a fade when the app header scrolls away. Its script starts the fade, and marks the link of the visible section with `aria-current`.
*/
struct AppSecondaryNavigation: ScriptedElement {
	static let script = ElementScript()

	let app: App

	var content: some HTML {
		a(.href(app.url)) {
			AppIcon(decorative: app, size: 32)

			span {
				app.title
			}
			.style(Styles.name)
		}
		.accessibilityLabel(app.title)
		.style(Styles.identity)

		nav {
			for link in app.links {
				a(.href(link.destination)) {
					link.title
				}
				.attributes(.part(Parts.sectionLink), when: link.destination.isFragment)
				.style(Styles.link)
			}

			div {
				OverflowMenu.appPage(app)
			}
			.style(Styles.overflow)

			// With one download option, “Get” links to it. With more, it goes up to the download options.
			if app.isDownloadable {
				Link("Get", destination: app.downloadOptions.count == 1 ? app.downloadOptions[0].url : .fragment(AppHero.Hooks.hero.id))
					.buttonStyle(size: .small)
					.style(Styles.getButton)
			}
		}
		.accessibilityLabel("\(app.title) sections")
		.hstack(alignment: .center, spacing: .rootEm(0.25))
	}

	/**
	The data attribute that the script sets on the site header while the app header has scrolled away, so the navigation of the app replaces the site navigation.
	*/
	enum Hooks: String, ScriptHookSet {
		case appHeroScrolledAway = "data-app-hero-scrolled-away"
	}

	enum Parts: String, ElementPartSet {
		case sectionLink
	}

	enum Styles: ElementStyleSet {
		case root
		case identity
		case name
		case link
		case overflow
		case getButton

		var style: Style {
			switch self {
			case .root:
				// It fades in when the app header scrolls away (the script sets the attribute on the site header), and the fade finishes also when the scrolling stops. On phones, the site navigation stays, so the menu is always there, and the bar only adds the “Get” button next to the menu button, so buying is always one tap away on a long page.
				Style()
					.position(.absolute)
					.inset(0)
					.hstack(alignment: .center, justification: .spaceBetween)
					.filter(.opacity(0))
					.visibility(false)
					.transition(.filter, .visibility, animation: SiteHeader.navigationSwap)
					.when(ancestorHas: Hooks.appHeroScrolledAway) {
						$0
							.filter(.opacity(1))
							.visibility(true)
					}
					.pageWidth()
					.padding(.rootEm(0.75))
					.color(.gray(600), dark: .gray(200))
					// Taps go through to the site navigation below it, except on the button. The space at the end is for the menu button.
					.below(.tablet) {
						$0
							.justifyContent(.end)
							.padding(.trailing, .rootEm(4.25))
							.allowsHitTesting(false)
					}
					.from(.tablet) {
						$0.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1))
					}
			case .identity:
				// The focus of the keyboard shows as a fill around the icon and the name, like on the site name. The negative margin cancels the padding, so the layout does not change.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.flexShrink(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.margin(vertical: .rootEm(-0.25), horizontal: .rootEm(-0.5))
					.focusFill()
					.hidden(below: .tablet)
			case .name:
				Style()
					.display(.inline)
					.textStyle(.lead, weight: .bold)
					.textWrap(.nowrap)
					.color(.primaryText)
					// Between tablets and laptops, the section links need the space.
					.media(.from(.tablet) && .below(.laptop)) {
						$0.hidden()
					}
			case .link:
				// Pills like the site navigation, with the section in view in a tint of the accent of the app.
				Style()
					.hstack(alignment: .center)
					.textWrap(.nowrap)
					.navigationPill(currentFill: Color.pageAccent.opacity(0.16))
					.hidden(below: .tablet)
			case .overflow:
				Style()
					.display(.flex)
					.padding(.horizontal, .rootEm(1))
					.setting(OverflowMenu.color, to: .currentColor)
					.hidden(below: .tablet)
			case .getButton:
				Style()
					.position(.relative)
					.zIndex(10)
					.margin(.leading, .rootEm(1))
					.allowsHitTesting(true)
			}
		}
	}
}
