import Elementary
import SiteKit

/**
Links as quiet chips, with an optional overflow menu as the last chip, like the section links of an app page and the app categories of the apps page. The menu has the chip variant. With `scrollsOnPhones`, the chips are one row that scrolls sideways on phones, like the many groups of a long page.

```swift
ChipNavigation(label: "App categories", links: AppCategory.chips.map(\.link), menu: OverflowMenu(label: "More app pages", groups: groups, variant: .chip))
```
*/
struct ChipNavigation: HTML {
	let label: String
	let links: [LabeledLink]
	var menu: OverflowMenu?
	var scrollsOnPhones = false

	var body: some HTML<HTMLTag.nav> {
		nav {
			for link in links {
				Link(link)
				.style(Styles.link)
			}

			if let menu {
				menu
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

		var style: Style {
			switch self {
			case .root:
				// Quiet chips, so the main actions above them stay the main actions. They wrap on phones, so every link is visible.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .scrollingOnPhones:
				// On phones, one row that scrolls sideways, as many chips would fill the screen with large text. The row reaches the edges of the screen, so a chip that is cut off at the edge shows that it scrolls.
				Style()
					.below(.smallTablet) {
						$0
							// From the start, as the start of a centered row that overflows cannot be scrolled to.
							.justifyContent(.start)
							.flexWrap(.nowrap)
							.overflow(horizontal: .auto)
							// A horizontal swipe on a trackpad at the end does not go back in the history.
							.overscrollBehavior(horizontal: .contain)
							.fullBleed()
							// The chip at the edge fades out, so it reads as more to scroll to, not as a word that is cut. At the end of the row, the fade is mostly in the space of the page, so the last chip is only a little faint.
							.maskImage(.linearGradient(.toLeft, Color.transparent.at(.zero), Color.black.at(.rootEm(2.5))))
					}
			case .link:
				Style().chip()
			}
		}
	}
}
