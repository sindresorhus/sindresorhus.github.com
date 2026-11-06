import Elementary
import Foundation
import SiteKit

/**
The bar in the site header that replaces the site navigation with a fade when the app header scrolls away. Its script starts the fade, and marks the link of the visible section with `aria-current`.
*/
struct AppSecondaryNavigation: ScriptedElement {
	static let script = ElementScript()

	let app: App

	/**
	Whether the page has guides about the app, which the “…” menu links to.
	*/
	let hasGuides: Bool

	var content: some HTML {
		a(.href(app.url)) {
			AppIcon(decorative: app, size: 32)

			span(.notTranslated) {
				app.title
			}
			.style(Styles.name)
		}
		.accessibilityLabel(app.title)
		.style(Styles.identity)

		nav {
			for link in app.links {
				Link(link)
				.attributes(.part(Parts.sectionLink), when: link.destination.isFragment)
				.style(Styles.link)
			}

			div {
				OverflowMenu.appPage(app, hasGuides: hasGuides)
			}
			.style(Styles.overflow)

			// With one place to get the app, “Get” links to it, also when the app has a trial. With more, it goes up to the download options.
			if app.isDownloadable {
				// The name of the app is only for screen readers, so the link says what it gets in a list of the links of the page.
				Link(destination: app.placesToGet.count == 1 ? app.placesToGet[0].url : .fragment(AppHero.IDs.hero.id)) {
					"Get"
					VisuallyHidden(" \(app.title)")
				}
				.buttonStyle(size: .small)
				.style(Styles.getButton)
			}
		}
		.accessibilityLabel("\(app.title) sections")
		.hstack(alignment: .center, spacing: .rootEm(0.25))
	}

	/**
	The data attributes that the script sets on the site header: one while the app header has scrolled away, so the navigation of the app replaces the site navigation, and the fragment of the section that the visitor is in, like `#faq`, so the menu of the site header marks it on phones.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case appHeroScrolledAway = "app-hero-scrolled-away"
		case currentSection = "current-section"
	}

	enum Parts: String, ElementPartSet {
		case sectionLink
	}

	enum Styles: String, ElementStyleSet {
		case root
		case identity
		case name
		case link
		case overflow
		case getButton

		var style: Style {
			switch self {
			case .root:
				// It fades in when the app header scrolls away (the script sets the attribute on the site header), and the fade finishes also when the scrolling stops. On phones, the site navigation stays, so the menu is always there, and the bar only adds the icon and the name of the app in place of the site name, and the “Get” button next to the menu button, so a visitor who came from a link to a section sees which app it is, and buying is always one tap away on a long page.
				Style()
					.position(.absolute)
					.inset(.zero)
					.hstack(alignment: .center, justification: .spaceBetween)
					.filter(.opacity(0))
					.visibility(false)
					.transition(.filter, .visibility, timing: SiteHeader.navigationSwap)
					.when(ancestorHas: Hooks.appHeroScrolledAway) {
						$0
							.filter(.opacity(1))
							.visibility(true)
					}
					.pageWidth()
					.padding(.rootEm(0.75))
					.color(.gray(600), dark: .gray(200))
					// Taps go through to the site navigation below it, except on the app and the button. The space at the end is for the menu button. The icon lines up with the site name, which it replaces.
					.below(.tablet) {
						$0
							.padding(.leading, .pageGutter)
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
					// On phones, the name can be cut off, but never pushes the “Get” button out.
					.below(.tablet) {
						$0
							.flexShrink(1)
							.frame(minWidth: .zero)
							.allowsHitTesting(true)
					}
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
					.below(.tablet) {
						$0
							.overflow(.hidden)
							.textOverflow(.ellipsis)
					}
					// Where the name would be cut off, like on narrow phones or with large text, only the icon shows. The link keeps the name as its label.
					.below(Self.nameWidth) {
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

		/**
		The width from which the bar shows the name of the app next to its icon. A rem breakpoint, so it follows the text size. At 100% text, the longest names, like “System Color Picker”, fit from a 390 px wide phone (24.375 rem).
		*/
		static let nameWidth = Breakpoint(minimumWidthInRem: 24.375)
	}
}
