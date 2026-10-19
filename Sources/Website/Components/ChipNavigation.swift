import Elementary
import SiteKit

/**
Links as quiet chips, with an overflow menu as the last chip, like the section links of an app page and the app categories of the apps page. The menu has the chip variant.

```swift
ChipNavigation(label: "App categories", links: AppCategory.browsable.map(\.link), menu: OverflowMenu(label: "More app pages", groups: groups, variant: .chip))
```
*/
struct ChipNavigation: HTML {
	let label: String
	let links: [LabeledLink]
	let menu: OverflowMenu

	var body: some HTML<HTMLTag.nav> {
		nav {
			for link in links {
				a(.href(link.destination)) {
					link.title
				}
				.style(Styles.link)
			}

			menu
		}
		.accessibilityLabel(label)
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case link

		var style: Style {
			switch self {
			case .root:
				// Quiet chips, so the main actions above them stay the main actions. They wrap on phones, so every link is visible.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .link:
				Style().chip()
			}
		}
	}
}
