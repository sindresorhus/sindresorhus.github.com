import Elementary
import SiteKit

/**
Links as quiet chips, with an optional link to another page or an overflow menu as the last chip (``LastChip``), like the section links of an app page and the app categories of the apps page. The menu has the chip variant. The chips are centered rows of about the same length, and a page aligns them to the start with `textAlign(.leading)`. With `scrollsOnPhones`, the chips are one row that scrolls sideways on phones, like the many groups of a long page, and the link to another page is the first chip of the row.

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
	The chip after the links.
	*/
	enum LastChip {
		/**
		A link to another page, with an arrow, as the other chips jump to the sections of the page, like the guides for Windows users after the topics of the guides.
		*/
		case pageLink(LabeledLink)

		/**
		An overflow menu with more links, like the other app pages after the app categories.
		*/
		case menu(OverflowMenu)
	}

	var body: some HTML<HTMLTag.nav> {
		nav {
			for link in links {
				Link(link)
				.style(Styles.link)
			}

			switch lastChip {
			case .pageLink(let pageLink):
				Link(destination: pageLink.destination) {
					Label(pageLink.title, icon: .arrowRight, iconPosition: .trailing)
				}
				.style(Styles.pageLink)
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
							// The link to another page is first, as it would be screens of scrolling away at the end, and its arrow shows that it is not like the other chips. Screen readers and the Tab key keep the order of the HTML.
							.children(Styles.pageLink.selector) {
								$0.order(-1)
							}
					}
			case .link:
				Style().chip()
			case .pageLink:
				Style().chip(hasIcon: true)
			}
		}
	}
}
