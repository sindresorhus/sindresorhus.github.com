import Elementary
import SiteKit

/**
The sticky site navigation, with the search of the site (``SiteSearch``). On small screens, the links are in a popover behind a menu button, which works without JavaScript, and closes with the Escape key or a click outside. On an app page, the popover also has the sections of the app. Its script also closes it when the keyboard focus moves out of it, after a tap on a section of the page, or when the window becomes as wide as a tablet, like a phone that rotates, and when it opens, it marks the section that the visitor is in. The “…” menu of the app closes it after a choice (``OverflowMenu``).
*/
struct SiteHeader: ScriptedElement {
	static let script = ElementScript()

	enum Variant {
		case standard

		/**
		Hides the “Donate” link, shows the sections of the app in the menu on phones, and shows the navigation of the app when its header scrolls away. With `hasGuides`, the “…” menu of the navigation links to the guides at the end of the page.
		*/
		case app(App, hasGuides: Bool)

		/**
		A page about an app, like its release notes, which is in the “Apps” section, like the page of the app. It keeps the “Donate” link, like other pages.
		*/
		case appSubpage(App)

		/**
		The app that the page is about: the app of an app page, or of a page about the app, like its release notes.
		*/
		var app: App? {
			switch self {
			case .standard:
				nil
			case .app(let app, _), .appSubpage(let app):
				app
			}
		}
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
		See-through at the top of the page, so a background of the page, like the glass of the apps page, continues behind it without an edge. The fill and the blur fade in as the page scrolls under the header.
		*/
		case transparentAtTop
	}

	let variant: Variant
	var background = Background.standard

	/**
	The height of the header, without its border. Pages use it for the area that the header covers, like the scroll padding of section links.
	*/
	static let height = LengthPercentage.rootEm(4)

	@TaskLocalValue(requiring: RoutePath.$current) private var currentPath

	var config: Config? {
		Config()
	}

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

					// Next to the menu button on phones, and after the links from tablets, where this row is not a box of its own (``Styles/top``).
					SiteSearch()

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
						link("Blog", to: .blog)
						link("Now", to: .now)
						link("About", to: .about)
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

					// On phones, the sticky header has no room for the sections of the app, so the menu has them, below the site links, with the “…” menu of the app at the end, so its pages, like the release notes, are not only in the app header far above. From tablets, the navigation of the app has them (``AppSecondaryNavigation``).
					if case .app(let app, let hasGuides) = variant {
						div {
							// Screen readers get the name from the label of the list.
							p(.notTranslated) {
								app.title
							}
							.accessibilityHidden()
							.style(Styles.appSectionsTitle)

							// Keep the list semantics in Safari, as the styles remove its bullets.
							ul {
								for link in app.links {
									li {
										Link(link)
											.attributes(.part(Parts.appSectionLink))
											.style(Styles.appSectionLink)
									}
								}

								li {
									OverflowMenu.appPage(app, hasGuides: hasGuides, variant: .chip)
								}
							}
							.accessibilityLabel("\(app.title) sections", role: .list)
							.style(Styles.appSectionLinks)
						}
						.style(Styles.appSections)
					}

					// The feeds are in the footer, and feed readers find them from the `<link>` elements of the pages.
					div {
						IconLink("Contact", icon: .mail, destination: .path(.contact))
							.attributes(.ariaCurrent(.page), when: currentPath == .contact)
					}
					.style(Styles.iconLinks)
				}
				// Not “Primary navigation”, as screen readers add the role, so it would be “Primary navigation navigation”.
				.accessibilityLabel("Primary")
				.style(Styles.menu)
			}
			.style(Styles.navigation)
			.style(Styles.navigationReplacedByApp, when: app != nil)

			if case .app(let app, let hasGuides) = variant {
				AppSecondaryNavigation(app: app, hasGuides: hasGuides)
			}
		}
		.hiddenFromSearchSnippets()
		.style(Styles.header)
		.style(Styles.transparentAtTop, when: background == .transparentAtTop)
	}

	private var app: App? {
		guard case .app(let app, _) = variant else {
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
			.attributes(.ariaCurrent(currentPath == path ? .page : .item), when: isInSection(path))
			.style(Styles.link)
		}
		// The item, not only its link, so an empty item does not add one more gap to the row.
		.style(Styles.mobileOnly, when: isMobileOnly)
	}
}

extension SiteHeader {
	/**
	The ID of the menu, which its button shows and hides. It has a prefix, so it is not the same as the ID of a heading, like “Menu”.
	*/
	private static let menuID = ElementID("site-menu")

	struct Config: Encodable {
		/**
		The media query of the width of a tablet, from which the menu is a row in the header, so the script closes a menu that is still open.
		*/
		let tabletQuery = MediaCondition.from(.tablet).description
	}

	enum Parts: String, ElementPartSet {
		case menu
		case appSectionLink
	}

	enum Styles: String, ElementStyleSet {
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
		case appSections
		case appSectionsTitle
		case appSectionLinks
		case appSectionLink

		/**
		The space before the site name, and at the sides of the text of the links in the menu, so the text lines up with the name.
		*/
		private static let brandMargin = LengthPercentage.rootEm(0.5)

		/**
		Narrower than a phone, like a phone with the text at 200%, where the site name and the menu button only fit when the name is smaller.
		*/
		static let narrowScreen = Breakpoint(minimumWidthInRem: 22)

		/**
		The header, which the open menu on small screens starts below.
		*/
		private static let anchor = Anchor("site-header")

		/**
		The fill and the blur of the glass of the header, which the transparent header at the top of some pages fades into while the page scrolls, so the two must look the same.
		*/
		private static let glassFill = Color.pageBackground.opacity(0.8)
		private static let glassBlur = Length.pixels(24)

		/**
		The size of the chips of the app in the menu, larger than the chips of the app header, so they are easy to tap.
		*/
		private static var appChipSize: Style {
			Style()
				.padding(vertical: .rootEm(0.625), horizontal: .rootEm(1.125))
				.textStyle(.body, weight: .medium)
		}

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the header is laid out as if it were not there, and it stays sticky in the page.
				Style().display(.contents)
			case .header:
				Style()
					.anchorName(Self.anchor)
					.position(.sticky)
					.top(.zero)
					// On a short screen, like a phone in landscape, it scrolls away with the page, as it would cover a third of it. So the “Get” button of an app page is not there while scrolled, which is fine, as the download buttons are at the top and the end of the page.
					.media(.shortScreen) {
						$0.position(.relative)
					}
					.zIndex(40)
					.frame(width: .percent(100))
					.border(.bottom, .separator)
					// The border fades in as the page scrolls under the header. At the top, and on pages that do not scroll, the header is part of the page.
					.borderColor(.transparent)
					.animation(Animations.showBorder, timeline: .scroll, from: .zero, to: .rootEm(2))
					.background(.pageBackground)
					.from(.tablet) {
						$0.frostedBackground(Self.glassFill, opaque: .pageBackground, blur: Self.glassBlur)
					}
			case .transparentAtTop:
				// The fill and the blur are on a layer behind the header, so they can fade in, as the backdrop filter of the header itself would also blur its links.
				Style()
					.background(.transparent)
					.backdropFilter()
					.before {
						$0
							.content("")
							.position(.absolute)
							.inset(.zero)
							.zIndex(-1)
							.frostedBackground(Self.glassFill, opaque: .pageBackground, blur: Self.glassBlur)
							.allowsHitTesting(false)
							.animation(Animations.showFill, timeline: .scroll, from: .zero, to: SiteHeader.height)
					}
					// The links are stronger than secondary text, as they are on the background of the page at the top.
					.nested(Self.menu.selector) {
						$0.color(.bodyText)
					}
			case .navigation:
				Style()
					.pageWidth()
					.vstack(justification: .center)
					.frame(height: .length(SiteHeader.height))
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
				// Fades out when the app header scrolls away, as the navigation of the app replaces it. Without the script, it stays.
				// On phones, it stays, so the menu button is always there.
				Style()
					.from(.tablet) {
						$0.navigationSwap(isShownWhileScrolledAway: false)
					}
			case .top:
				// From tablets, the site name and the search button are items of the row of the navigation, so the search button can be after the links.
				Style()
					.hstack(justification: .spaceBetween)
					.from(.tablet) {
						$0.display(.contents)
					}
			case .brand:
				// The space before the name is padding, so the keyboard focus can show as a fill around the name, like on the links. The name already has the strongest text color, so a color change would not show.
				Style()
					.hstack(alignment: .center)
					.padding(.horizontal, Self.brandMargin)
					.font(.extraLarge2, weight: .heavy)
					.textWrap(.nowrap)
					.color(.primaryText)
					.focusFill()
					// On very narrow screens, like a phone with the text at 200%, the name is smaller, so the menu button stays on the screen. It can still be clipped, but never pushes the menu button out.
					.frame(minWidth: .zero)
					.below(Self.narrowScreen) {
						$0
							.overflow(.hidden)
							.font(.regular, weight: .heavy)
					}
					// On phones, the icon and the name of the app replace it while the app header has scrolled away (``AppSecondaryNavigation``).
					.below(.tablet) {
						$0.navigationSwap(isShownWhileScrolledAway: false)
					}
			case .menuToggle:
				// The look of an icon link, as a style value instead of the class of ``IconLink``, as the order of rules from different style sets is not defined. It never shrinks, so it stays on the screen.
				Style()
					.iconButton()
					.flexShrink(0)
					.hidden(from: .tablet)
			case .menuIcon:
				Style()
					.display(.flex)
					.inside("\(Self.navigation.selector):has(\(Self.menu.selector):popover-open)") {
						$0.hidden()
					}
			case .closeIcon:
				Style()
					.hidden()
					.inside("\(Self.navigation.selector):has(\(Self.menu.selector):popover-open)") {
						$0.display(.flex)
					}
			case .menu:
				// On small screens, the open popover covers the page below the header, which is its anchor. On larger screens, it is a row in the header.
				Style()
					.alignItems(.start)
					.inset(.auto)
					.margin(.zero)
					// The links have the padding of the site name as their padding, so their text lines up with it.
					.padding(horizontal: .pageGutter - Self.brandMargin, bottom: .rootEm(0.75))
					.color(.secondaryText)
					.background(.pageBackground)
					.popoverOpen {
						$0
							.display(.flex)
							.flexDirection(.column)
							.position(.fixed)
							.inset(.zero)
							.top(anchor: Self.anchor, side: .bottom)
							.frame(size: .auto)
							// A swipe on the menu does not scroll the page behind it, so the page is still at the same place when the menu closes.
							.overscrollBehavior(.contain)
					}
					.from(.tablet) {
						$0
							.hstack(alignment: .center)
							.position(.static)
							// At the end of the row, before the search button.
							.margin(.leading, .auto)
							.padding(.zero)
							.background(.transparent)
							.overflow(.visible)
					}
			case .links:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(.top, .rootEm(2))
					.font(.extraLarge4)
					// Large text has tighter letters, like the titles of the pages.
					.letterSpacing(.em(-0.025))
					// On a short screen, like a phone in landscape, the links are a row at the size of the site name, so the links below them, like the sections of an app, are on the screen too.
					.below(.tablet) {
						$0.media(.shortScreen) {
							$0
								.flexDirection(.row)
								.flexWrap(.wrap)
								.gap(row: .zero, column: .rootEm(1))
								.padding(.top, .rootEm(1))
								.font(.extraLarge2)
						}
					}
					.from(.tablet) {
						$0
							.flexDirection(.row)
							.alignSelf(.center)
							.gap(.rootEm(0.25))
							.frame(width: .auto)
							.padding(.top, .zero)
							.textStyle(.caption)
							.letterSpacing(.zero)
					}
			case .link:
				// On small screens, in the menu, the text lines up with the site name, and the current page is in the color of headings. From tablets, the links are pills, like the chips of the site, and the current page has the stronger fill of a card under the pointer.
				Style()
					.hstack(alignment: .center)
					.padding(vertical: .rootEm(0.75), horizontal: Self.brandMargin)
					.fontWeight(.medium)
					.hoverColor(.primaryText)
					.current {
						$0
							.color(.primaryText)
							// The current page already has the color of the focus, so in the menu, the focus of the keyboard shows as a fill, like on the site name. From tablets, the pill shows it.
							.below(.tablet) {
								$0.focusFill()
							}
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
					.margin(vertical: .zero, horizontal: .rootEm(0.75))
					.cornerRadius(.capsule)
					// As visible in light mode as in dark mode, also on the tinted glass of the apps page.
					.background(.gray(300), dark: .gray(600).opacity(0.5))
					.hidden(below: .tablet)
			case .iconLinks:
				Style()
					.hstack(alignment: .center)
					.alignSelf(.center)
					.margin(.leading, .rootEm(0.5))
					.hidden(below: .tablet)
			case .appSections:
				Style()
					.frame(width: .percent(100))
					.padding(top: .rootEm(2), horizontal: Self.brandMargin, bottom: .rootEm(1))
					.hidden(from: .tablet)
			case .appSectionsTitle:
				// Like the titles of the groups of the footer from tablets. It stays small on phones, as it is a caption above chips, not above links of body text.
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textStyle(.caption, weight: .semibold)
					.color(.secondaryText)
			case .appSectionLinks:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
					// The “…” menu at the end has the size of the section links, and their height, as it has only an icon. It is round (``OverflowMenu/Styles/roundChip``), so it is as wide as it is high.
					.nested(OverflowMenu.Styles.chip.selector) {
						$0
							.combined(with: Self.appChipSize)
							.padding(.horizontal, .zero)
							.frame(size: .length(LengthPercentage.lineHeight(1) + .rootEm(1.25)))
					}
			case .appSectionLink:
				// Larger than the chips of the app header, so they are easy to tap.
				Style()
					.chip()
					.combined(with: Self.appChipSize)
					.display(.block)
					// The section that the visitor is in has the tint of the accent of the app, like the section links of the navigation of the app.
					.currentFill(.currentSectionFill)
			}
		}
	}

	/**
	The scroll-driven animations of the header, like the border that fades in as the page scrolls under it.
	*/
	enum Animations: String, KeyframeSet {
		case showBorder
		case showFill

		var keyframes: [Keyframe] {
			switch self {
			case .showBorder:
				// Fainter than the separators in dark mode, where they are too strong on the near-black glass, but still a clear edge for the text that scrolls under it.
				[.to(Style().borderColor(.lightDark(.separator, .white.opacity(0.07))))]
			case .showFill:
				[
					.from(Style().opacity(0)),
					.to(Style().opacity(1)),
				]
			}
		}
	}

	/**
	The fade between the site navigation and the navigation of the app, when the app header scrolls away or back. The script of ``AppSecondaryNavigation`` starts it. Each row fades for this duration, one after the other (``Style/navigationSwap(isShownWhileScrolledAway:)``).

	The fades use `filter: opacity()` instead of `opacity`, as the backdrop filter of the header blocks opacity animations of its children. `visibility` keeps the hidden links out of the keyboard focus.
	*/
	static let navigationSwapDuration = Duration.milliseconds(150)
}

extension Style {
	/**
	The fade of a row of the site header that another row replaces at the same place, like the site navigation and the navigation of an app, which replaces it while the app header has scrolled away (``SiteHeader/navigationSwapDuration``). The outgoing row fades out at once, and the incoming row fades in after it, so the names and the links of the two rows never show through each other. Scrolling starts the fade, and it then finishes on its own.

	- Parameter isShownWhileScrolledAway: Whether the row shows while the app header has scrolled away, like the navigation of the app, or while it has not, like the site navigation.
	*/
	func navigationSwap(isShownWhileScrolledAway: Bool) -> Self {
		let shown = { (style: Self) in
			style
				.filter()
				.visibility(true)
				.transitionDelay(SiteHeader.navigationSwapDuration)
		}
		let hidden = { (style: Self) in
			style
				.filter(.opacity(0))
				.visibility(false)
				.transitionDelay(.zero)
		}
		let style = transition(.filter, .visibility, timing: .easeInOut(duration: SiteHeader.navigationSwapDuration))

		return isShownWhileScrolledAway
			? hidden(style).when(ancestorHas: AppSecondaryNavigation.Hooks.appHeroScrolledAway, shown)
			: shown(style).when(ancestorHas: AppSecondaryNavigation.Hooks.appHeroScrolledAway, hidden)
	}
}
