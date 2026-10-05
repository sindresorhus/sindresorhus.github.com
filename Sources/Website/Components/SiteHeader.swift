import Elementary
import SiteKit

/**
The sticky site navigation. On small screens, the links are in a popover behind a menu button, which works without JavaScript, and closes with the Escape key or a click outside. Its script also closes it when the keyboard focus moves out of it.
*/
struct SiteHeader: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		connectedCallback() {
			// The same function, so connecting the element again does not add a second listener.
			this.querySelector('[data-part="menu"]').addEventListener('focusout', this.#closeMenu);
		}

		// The mobile menu covers the page, so it closes when keyboard focus moves out of it, like to a link behind it. Not when it moves to the menu button, which closes it itself.
		#closeMenu = event => {
			const menu = event.currentTarget;
			const destination = event.relatedTarget;
			const isLeaving = destination && !menu.contains(destination) && destination.popoverTargetElement !== menu;

			if (isLeaving && menu.matches(':popover-open')) {
				menu.hidePopover();
			}
		};
	}
	"""#)

	enum Variant {
		case standard

		/**
		Hides the “Donate” link, and shows the navigation of the app when its header scrolls away.
		*/
		case app(App)

		/**
		A page about an app, like its release notes, which is in the “Apps” section, like the page of the app. It keeps the “Donate” link, like other pages.
		*/
		case appSubpage
	}

	/**
	The background of the header, like `toolbarBackground(_:)` in SwiftUI.
	*/
	enum Background {
		/**
		A fill with a blur, which the page scrolls under.
		*/
		case standard

		/**
		See-through at the top of the page, so a background of the page, like the glass of the apps page, continues behind it without an edge. The fill and the blur fade in as the page scrolls under the header. Without scroll-driven animations, the header keeps them.
		*/
		case transparentAtTop
	}

	let variant: Variant
	var background = Background.standard

	/**
	The height of the header, without its border. Pages use it for the area that the header covers, like the scroll padding of section links.
	*/
	static let height = Length.rootEm(4)

	@Environment(requiring: RoutePath.$current) private var currentPath

	var content: some HTML {
		header {
			div {
				div {
					// On the home page, the brand is a unicorn, which screen readers would read as “unicorn face”.
					a(.href(.root)) {
						currentPath == .root ? "🦄" : Site.name
					}
					.accessibilityLabel(Site.name)
					.style(Styles.brand)

					// Shows “×” while the menu is open.
					button(.type(.button), .popoverTarget(Self.menuID)) {
						span {
							Icon.menu.size(.rootEm(1.5))
						}
						.style(Styles.menuIcon)

						span {
							Icon.close.size(.rootEm(1.5))
						}
						.style(Styles.closeIcon)
					}
					.accessibilityLabel("Menu")
					.style(Styles.menuToggle)
				}
				.style(Styles.top)

				// A popover on small screens, and a row of links on larger screens.
				nav(.id(Self.menuID), .popover, .part(Parts.menu)) {
					ul {
						link("Apps", to: .apps)
						link("About", to: .about)
						link("Blog", to: .blog)
						link("Now", to: .now)
						// On larger screens, the contact link is an icon.
						link("Contact", to: .contact, isMobileOnly: true)

						// App pages hide it, so the app gets the attention.
						if app == nil {
							li {}
								.accessibilityHidden()
								.style(Styles.separator)

							link("Donate", to: .donate)
						}
					}
					.style(Styles.links)

					// The feeds are in the footer, and feed readers find them from the `<link>` elements of the pages.
					div {
						IconLink("Contact", icon: .mail, destination: .path(.contact))
							.attributes(.ariaCurrent("page"), when: currentPath == .contact)
					}
					.style(Styles.iconLinks)
				}
				.accessibilityLabel("Primary navigation")
				.style(Styles.menu)
			}
			.style(Styles.navigation)
			.style(Styles.navigationReplacedByApp, when: app != nil)

			if let app {
				AppSecondaryNavigation(app: app)
			}
		}
		.hiddenFromSearchSnippets()
		.style(Styles.header)
		.style(Styles.transparentAtTop, when: background == .transparentAtTop)
	}

	private var app: App? {
		guard case .app(let app) = variant else {
			return nil
		}

		return app
	}

	/**
	Whether the page is in the section of the link. The pages of the apps are in “Apps”, though their paths, like `/velja`, are not below `/apps`.
	*/
	private func isInSection(_ path: RoutePath) -> Bool {
		switch variant {
		case .standard:
			currentPath.starts(with: path)
		case .app, .appSubpage:
			path == .apps
		}
	}

	private func link(_ title: String, to path: RoutePath, isMobileOnly: Bool = false) -> some HTML {
		li {
			a(.href(path)) {
				span {
					title
				}
			}
			// A parent section, like “Apps” on an app page, is the current location, but not the current page.
			.attributes(.ariaCurrent(currentPath == path ? "page" : "true"), when: isInSection(path))
			.style(Styles.link)
			.style(Styles.mobileOnly, when: isMobileOnly)
		}
	}
}

extension SiteHeader {
	/**
	The ID of the menu, which its button shows and hides.
	*/
	private static let menuID = "menu"

	enum Parts: String, ElementPartSet {
		case menu
	}

	enum Styles: ElementStyleSet {
		case root
		case header
		case transparentAtTop
		case navigation
		case navigationReplacedByApp
		case top
		case brand
		case menuToggle
		case menuIcon
		case closeIcon
		case menu
		case links
		case link
		case mobileOnly
		case separator
		case iconLinks

		/**
		The space before the site name, and at the sides of the text of the links in the menu, so the text lines up with the name.
		*/
		private static let brandMargin = Length.rootEm(0.5)

		/**
		The header, which the open menu on small screens starts below.
		*/
		private static let anchor = Anchor("--site-header")

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the header is laid out as if it were not there, and it stays sticky in the page.
				Style().display(.contents)
			case .header:
				Style()
					.anchorName(Self.anchor)
					.position(.sticky)
					.top(0)
					.zIndex(40)
					.frame(width: .percent(100))
					.border(.bottom, .separator)
					// The border fades in as the page scrolls under the header. At the top, and on pages that do not scroll, the header is part of the page.
					.supports(.scrollTimeline) {
						$0
							.borderColor(.transparent)
							.animation(Animations.showBorder, timeline: .scroll, range: "0 2rem")
					}
					.background(.pageBackground)
					.from(.tablet) {
						$0
							.background(.pageBackground.opacity(0.8))
							.backdropFilter(.blur(radius: .pixels(24)))
							.reducedTransparency {
								$0
									.background(.pageBackground)
									.backdropFilter(.none)
							}
					}
					.dark {
						$0.border(.bottom, width: 0)
					}
			case .transparentAtTop:
				// The fill and the blur are on a layer behind the header, so they can fade in, as the backdrop filter of the header itself would also blur its links.
				Style()
					.background(.transparent)
					.backdropFilter(.none)
					.before {
						$0
							.content("")
							.position(.absolute)
							.inset(0)
							.zIndex(-1)
							.background(.pageBackground.opacity(0.8))
							.backdropFilter(.blur(radius: .pixels(24)))
							.allowsHitTesting(false)
							.reducedTransparency {
								$0
									.background(.pageBackground)
									.backdropFilter(.none)
							}
							.supports(.scrollTimeline) {
								$0.animation(Animations.showFill, timeline: .scroll, range: "0 \(SiteHeader.height)")
							}
					}
					// The links are stronger than secondary text, as they are on the background of the page at the top.
					.nested(Self.menu.selector) {
						$0.color(.bodyText)
					}
			case .navigation:
				Style()
					.pageWidth()
					.vstack(justification: .center)
					.frame(height: SiteHeader.height)
					// With the margin of the site name, the name lines up with the content of the page.
					.padding(.horizontal, .pageGutter - Self.brandMargin)
					.from(.tablet) {
						$0
							.flexDirection(.row)
							.alignItems(.center)
							.justifyContent(.spaceBetween)
							.padding(.vertical, .rootEm(0.5))
					}
			case .navigationReplacedByApp:
				// Fades out when the app header scrolls away, as the navigation of the app replaces it. Scrolling starts the fade, and it then finishes on its own. Without the script, it stays.
				// On phones, it stays, so the menu button is always there.
				Style()
					.from(.tablet) {
						$0
							.transition(.filter, .visibility, animation: SiteHeader.navigationSwap)
							.when(ancestorHas: AppSecondaryNavigation.Hooks.appHeroScrolledAway) {
								$0
									.filter(.opacity(0))
									.visibility(false)
							}
					}
			case .top:
				Style()
					.hstack(justification: .spaceBetween)
			case .brand:
				Style()
					.hstack(alignment: .center)
					.margin(.leading, Self.brandMargin)
					.font(.extraLarge2, weight: .heavy)
					.textWrap(.nowrap)
					.color(.primaryText)
			case .menuToggle:
				IconLink.look
					.margin(.leading, .rootEm(0.375))
					.transition(.backgroundColor, animation: .stateChange)
					.hidden(from: .tablet)
			case .menuIcon:
				Style()
					.display(.flex)
					.nested("\(Self.navigation.selector):has(\(Self.menu.selector):popover-open) &") {
						$0.hidden()
					}
			case .closeIcon:
				Style()
					.hidden()
					.nested("\(Self.navigation.selector):has(\(Self.menu.selector):popover-open) &") {
						$0.display(.flex)
					}
			case .menu:
				// On small screens, the open popover covers the page below the header, which is its anchor. On larger screens, it is a row in the header.
				Style()
					.alignItems(.start)
					.inset(.auto)
					.margin(0)
					// The links have the padding of the site name as their padding, so their text lines up with it.
					.padding(horizontal: .pageGutter - Self.brandMargin, bottom: .rootEm(0.75))
					.color(.secondaryText)
					.background(.pageBackground)
					.popoverOpen {
						$0
							.display(.flex)
							.position(.fixed)
							.inset(0)
							.top(.anchor(Self.anchor, .bottom))
							.frame(width: .auto, height: .auto)
					}
					.from(.tablet) {
						$0
							.display(.flex)
							.alignItems(.center)
							.position(.static)
							.padding(0)
							.background(.transparent)
							.overflow(.visible)
					}
			case .links:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(.top, .rootEm(2))
					.font(.extraLarge4)
					.from(.tablet) {
						$0
							.flexDirection(.row)
							.alignSelf(.center)
							.gap(.rootEm(0.25))
							.frame(width: .auto)
							.padding(.top, 0)
							.textStyle(.caption)
					}
			case .link:
				// On small screens, in the menu, the text lines up with the site name, and the current page is in the color of headings. From tablets, the links are pills, like the chips of the site, and the current page has the stronger fill of a card under the pointer.
				Style()
					.hstack(alignment: .center)
					.padding(vertical: .rootEm(0.75), horizontal: Self.brandMargin)
					.fontWeight(.medium)
					.transition(.color, .backgroundColor, animation: .stateChange)
					.hover {
						$0.color(.primaryText)
					}
					.current {
						$0.color(.primaryText)
					}
					.from(.tablet) {
						$0.navigationPill()
					}
			case .mobileOnly:
				Style().hidden(from: .tablet)
			case .separator:
				Style()
					.display(.block)
					.alignSelf(.center)
					.frame(width: .pixels(1), height: .rootEm(1.5))
					.margin(vertical: 0, horizontal: .rootEm(0.75))
					.cornerRadius(.capsule)
					.background(.gray(200).opacity(0.6), dark: .gray(600).opacity(0.5))
					.hidden(below: .tablet)
			case .iconLinks:
				Style()
					.display(.flex)
					.alignItems(.center)
					.alignSelf(.center)
					.margin(.leading, .rootEm(0.5))
					.hidden(below: .tablet)
			}
		}
	}

	/**
	The scroll-driven animations of the header, like the border that fades in as the page scrolls under it.
	*/
	enum Animations: KeyframeSet {
		case showBorder
		case showFill

		var keyframes: [Keyframe] {
			switch self {
			case .showBorder:
				[.to(Style().borderColor(.separator))]
			case .showFill:
				[
					.from(Style().opacity(0)),
					.to(Style().opacity(1)),
				]
			}
		}
	}

	/**
	The fade between the site navigation and the navigation of the app, when the app header scrolls away or back. The script of ``AppSecondaryNavigation`` starts it.

	The fades use `filter: opacity()` instead of `opacity`, as the backdrop filter of the header blocks opacity animations of its children. `visibility` keeps the hidden links out of the keyboard focus.
	*/
	static let navigationSwap = Animation.easeInOut(duration: .milliseconds(250))
}
