import Elementary
import SiteKit

/**
Links as quiet chips, with optional links to other pages or an overflow menu as the last chips (``LastChip``), like the section links of an app page and the app categories of the apps page. The menu has the chip variant. A link with the icon of an app (``LabeledLink/iconPath``) shows the icon before its title. The chips are centered rows of about the same length, and a page aligns them to the start with `textAlign(.leading)`. With `scrollsOnPhones`, the chips are one row that scrolls sideways on phones, like the many groups of a long page, and the links to other pages are the first chips of the row.

```swift
ChipNavigation(label: "App categories", links: AppCategory.chips.map(\.link), lastChip: .menu(OverflowMenu(label: "More app pages", groups: groups, variant: .chip)))
```
*/
struct ChipNavigation: HTML {
	let label: String
	let links: [LabeledLink]
	var lastChip: LastChip?
	var scrollsOnPhones = false

	/**
	The chips after the links.
	*/
	enum LastChip {
		/**
		Links to other pages, each with an icon at its end (``PageLink``), as the other chips jump to the sections of the page, like the guides for Windows users after the topics of the guides.
		*/
		case pageLinks([PageLink])

		/**
		An overflow menu with more links, like the other app pages after the app categories.
		*/
		case menu(OverflowMenu)
	}

	/**
	A link to another page as a chip (``LastChip/pageLinks(_:)``), with an arrow at its end, or another icon that says what the page does, like the shuffle icon of “Random Guide”.
	*/
	struct PageLink {
		let link: LabeledLink
		var icon = Icon.arrowRight
	}

	var body: some HTML<HTMLTag.nav> {
		nav {
			for link in links {
				// The icon of one of my apps is before its name, like the social links. It is decorative, so the name of the link stays the title.
				if let iconPath = link.iconPath {
					Link(destination: link.destination) {
						AppIcon(decorative: iconPath, jpegXL: link.iconJPEGXL, size: 20)
							.style(Styles.appIcon)

						link.title
					}
					.style(Styles.appLink)
				} else {
					Link(link)
					.style(Styles.link)
				}
			}

			switch lastChip {
			case .pageLinks(let pageLinks):
				// The icon is as large as the icons of the other chips, like the social links, so it is not heavier than the text.
				for pageLink in pageLinks {
					Link(destination: pageLink.link.destination) {
						pageLink.link.title
						pageLink.icon.size(.rootEm(1))
					}
					.style(Styles.pageLink)
				}
			case .menu(let menu):
				menu
			case nil:
				EmptyHTML()
			}
		}
		.accessibilityLabel(label)
		.style(Styles.root)
		.style(Styles.scrollingOnPhones, when: scrollsOnPhones)
	}

	enum Styles: String, StyleSet {
		case root
		case scrollingOnPhones
		case link
		case appLink
		case appIcon
		case pageLink

		/**
		The chips: the links, and the chip of the overflow menu, which is inside the element of the menu.
		*/
		private static let chips: CSSSelector = "& > a, & \(OverflowMenu.Styles.chip.selector)"

		var style: Style {
			switch self {
			case .root:
				// Quiet chips, so the main actions above them stay the main actions. They wrap on phones, so every link is visible.
				// Inline chips in a balanced block, so the rows have about the same number of chips, as flex wrapping fills the first row and puts the rest on the last row. A page aligns them to the start with `textAlign(.leading)`.
				// The space between the chips is a margin after each chip and below it. The negative margins of the block remove it after the last chip of a row and below the last row, so the chips line up with the content around them.
				Style()
					.textAlign(.center)
					.textWrap(.balance)
					.margin([.trailing, .bottom], .rootEm(-0.5))
					.nested(Self.chips) {
						$0
							.display(.inlineFlex)
							.verticalAlign(.middle)
							.margin([.trailing, .bottom], .rootEm(0.5))
					}
			case .scrollingOnPhones:
				// On phones, one row that scrolls sideways, as many chips would fill the screen with large text. The row reaches the edges of the screen, so a chip that is cut off at the edge shows that it scrolls.
				Style()
					.below(.smallTablet) {
						$0
							// A flex row, with a gap between the chips in place of their margins.
							.hstack(alignment: .center, spacing: .rootEm(0.5))
							.margin(.bottom, .zero)
							.nested(Self.chips) {
								$0.margin(.zero)
							}
							// From the start, as the start of a centered row that overflows cannot be scrolled to.
							.justifyContent(.start)
							.flexWrap(.nowrap)
							.overflow(horizontal: .auto)
							// A horizontal swipe on a trackpad at the end does not go back in the history.
							.overscrollBehavior(horizontal: .contain)
							.fullBleed()
							// The chip at the edge fades out, so it reads as more to scroll to, not as a word that is cut. At the end of the row, the fade is mostly in the space of the page, so the last chip is only a little faint.
							.maskImage(.linearGradient(.toLeft, Color.transparent.at(.zero), Color.black.at(.rootEm(2.5))))
							// The links to other pages are first, as they would be screens of scrolling away at the end, and their arrows show that they are not like the other chips. Screen readers and the Tab key keep the order of the HTML.
							.children(Styles.pageLink.selector) {
								$0.order(-1)
							}
					}
			case .link:
				Style().chip()
			case .appLink:
				// The icon is in the round end of the chip, as far from the start as from the top and the bottom.
				Style()
					.chip(hasIcon: true)
					.padding(.leading, .rootEm(0.375))
			case .appIcon:
				// The size of a small app icon, in pixels, like the other small app icons. The icon has its own shadow.
				Style().frame(size: .pixels(20))
			case .pageLink:
				// The arrow is at the end, so the text side has the padding of a chip without an icon, like the chips next to it, and the arrow side the smaller padding, as the arrow has empty space in its box.
				Style()
					.chip(hasIcon: true)
					.padding(.leading, .rootEm(0.875))
			}
		}
	}
}
