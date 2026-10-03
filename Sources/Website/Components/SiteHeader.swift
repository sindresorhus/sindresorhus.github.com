import Elementary
import SiteKit

/**
The sticky site navigation. On small screens, the links are in a popover behind a menu button, which works without JavaScript, and closes with the Escape key or a click outside.
*/
struct SiteHeader: HTML {
	enum Variant: Sendable {
		case standard

		/**
		Hides the donation links, and shows the navigation of the app when its header scrolls away.
		*/
		case app(App)
	}

	let variant: Variant

	@Environment(requiring: RoutePath.$current) private var currentPath

	var body: some HTML {
		header(.id(.siteHeader), .data("nosnippet", value: "")) {
			div {
				div {
					// On the home page, the brand is a unicorn, which screen readers would read as “unicorn face”.
					a(.href("/"), .ariaLabel(Site.name)) {
						currentPath == .root ? "🦄" : Site.name
					}
					.style(Styles.brand)

					button(.type(.button), .custom(name: "popovertarget", value: "menu"), .ariaLabel("Menu")) {
						Icon.menu.size(.rem(1.5))
					}
					.style(Styles.menuToggle)
				}
				.style(Styles.top)

				// A popover on small screens, and a row of links on larger screens.
				nav(.id("menu"), .popover, .ariaLabel("Primary navigation")) {
					ul {
						link("Apps", to: .apps)
						link("About", to: .about)
						link("Blog", to: .blog)
						// On larger screens, the contact link is an icon.
						link("Contact", to: .contact, isMobileOnly: true)

						if case .standard = variant {
							li(.ariaHidden) {}
								.style(Styles.separator)

							link("Donate", to: "/donate")
							link("Supporters", to: "/supporters")
						}
					}
					.style(Styles.links)

					div {
						IconLink(url: "/feeds", label: "RSS Feeds", icon: .rss)
						IconLink(url: RoutePath.contact.description, label: "Contact", icon: .mail)
					}
					.style(Styles.iconLinks)
				}
				.style(Styles.menu)
			}
			.style(Styles.navigation)
			.style(Styles.navigationReplacedByApp, when: app != nil)

			if let app {
				AppSecondaryNavigation(app: app)
			}
		}
		.style(Styles.root)
	}

	private var app: App? {
		guard case .app(let app) = variant else {
			return nil
		}

		return app
	}

	private func link(_ title: String, to path: RoutePath, isMobileOnly: Bool = false) -> some HTML {
		li {
			a(.href(path)) {
				span {
					title
				}
			}
			.attributes(.ariaCurrent("page"), when: currentPath.starts(with: path))
			.style(Styles.link)
			.style(Styles.mobileOnly, when: isMobileOnly)
		}
	}
}

extension SiteHeader {
	enum Styles: StyleSet {
		case root
		case navigation
		case navigationReplacedByApp
		case top
		case brand
		case menuToggle
		case menu
		case links
		case link
		case mobileOnly
		case separator
		case iconLinks

		var style: Style {
			switch self {
			case .root:
				Style()
					.declaration("anchor-name", "--site-header")
					.position(.sticky)
					.top(0)
					.zIndex(40)
					.frame(width: .percent(100))
					.border(.bottom)
					// The border fades in as the page scrolls under the header. At the top, and on pages that do not scroll, the header is part of the page.
					.supports("(animation-timeline: scroll())") {
						$0
							.borderColor(.transparent)
							.animation(Animations.showBorder, timeline: "scroll()", range: "0 2rem")
					}
					.background(.pageBackground)
					.breakpoint(.md) {
						$0
							.background(.white.opacity(0.9))
							.backdropFilter("blur(12px)")
							.reducedTransparency {
								$0
									.background(.pageBackground)
									.declaration(.backdropFilter, .none)
							}
					}
					.dark {
						$0
							.declaration(.borderBottomWidth, 0)
							.breakpoint(.md) {
								$0
									.background(.slate(950).opacity(0.9))
									.reducedTransparency {
										$0.background(.pageBackground)
									}
							}
					}
			case .navigation:
				Style()
					.pageWidth()
					.padding(.rem(0.75))
					.breakpoint(.md) {
						$0
							.hstack(justification: .spaceBetween)
							.padding(vertical: .rem(0.75), horizontal: .rem(1))
					}
			case .navigationReplacedByApp:
				// Fades out when the app header scrolls away, as the navigation of the app replaces it. Without scroll-driven animations, it stays.
				Style()
					.supports("(animation-timeline: view())") {
						$0.breakpoint(.md) {
							$0.animation(Animations.hideNavigation, timeline: AppHero.timeline, range: AppHero.scrolledAwayRange)
						}
					}
			case .top:
				Style()
					.hstack(justification: .spaceBetween)
			case .brand:
				Style()
					.hstack(alignment: .center)
					.margin(.leading, .rem(0.5))
					.font(.xl2, weight: .heavy)
					.noWrap()
					.color(.primaryText)
			case .menuToggle:
				IconLink.look
					.margin(.leading, .rem(0.375))
					.transition(.backgroundColor, duration: .milliseconds(150))
					.breakpoint(.md) {
						$0.display(.none)
					}
			case .menu:
				// On small screens, the open popover covers the page below the header, which is its anchor. Browsers without anchor positioning use the usual height of the header. On larger screens, it is a row in the header.
				Style()
					.alignItems(.start)
					.inset(.auto)
					.margin(0)
					.padding(horizontal: .rem(0.75), bottom: .rem(0.75))
					.color(.gray(600), dark: .slate(200))
					.background(.pageBackground)
					.nested("&:popover-open") {
						$0
							.display(.flex)
							.position(.fixed)
							.top(.px(69))
							.declaration(.top, "anchor(--site-header bottom)")
							.leading(0)
							.trailing(0)
							.bottom(0)
							.frame(width: .auto, height: .auto)
					}
					.breakpoint(.md) {
						$0
							.display(.flex)
							.position(.static)
							.padding(0)
							.background(.transparent)
							.overflow(.visible)
					}
			case .links:
				Style()
					.vstack(spacing: .rem(0.5))
					.frame(width: .percent(100))
					.padding(.top, .rem(2))
					.font(.xl4)
					.breakpoint(.md) {
						$0
							.flexDirection(.row)
							.alignSelf(.center)
							.gap(0)
							.frame(width: .auto)
							.padding(.top, 0)
							.font(.base)
					}
			case .link:
				Style()
					.hstack(alignment: .center)
					.padding(vertical: .rem(0.75), horizontal: .rem(1))
					.fontWeight(.medium)
					.transition(.color, duration: .milliseconds(150), curve: .easeInOut)
					.hover {
						$0.color(.gray(900))
					}
					.currentPageUnderline()
					.dark {
						$0.hover {
							$0.color(.white)
						}
					}
			case .mobileOnly:
				Style()
					.breakpoint(.md) {
						$0.display(.none)
					}
			case .separator:
				Style()
					.display(.block)
					.alignSelf(.center)
					.frame(width: .px(1), height: .rem(1.5))
					.margin(vertical: 0, horizontal: .rem(0.75))
					.cornerRadius(.capsule)
					.background(.slate(200).opacity(0.6), dark: .slate(600).opacity(0.5))
					.hidden(below: .md)
			case .iconLinks:
				Style()
					.display(.flex)
					.alignItems(.center)
					.alignSelf(.center)
					.margin(.leading, .rem(0.5))
					.hidden(below: .md)
			}
		}
	}

	/**
	The scroll-driven animations of the header.

	The site navigation and the app navigation trade places. `filter: opacity()` is used instead of `opacity`, as the backdrop filter of the header blocks opacity animations of its children. `visibility` keeps the hidden links out of the keyboard focus.
	*/
	enum Animations: KeyframeSet {
		case hideNavigation
		case showNavigation
		case showBorder

		var keyframes: [Keyframe] {
			let visible = Style()
				.filter("opacity(1)")
				.visibility(true)

			let hidden = Style()
				.filter("opacity(0)")
				.visibility(false)

			return switch self {
			case .hideNavigation:
				[.from(visible), .to(hidden)]
			case .showNavigation:
				[.from(hidden), .to(visible)]
			case .showBorder:
				[.to(Style().borderColor(.currentColor))]
			}
		}
	}
}
