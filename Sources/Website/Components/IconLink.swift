import Elementary
import SiteKit

/**
A link with only an icon, like the contact link in the header. The label is for screen readers.

```swift
IconLink("RSS Feeds", icon: .rss, destination: .path(.feeds))
	.help("All the feeds")
```
*/
struct IconLink: HTML {
	let label: String
	let icon: Icon
	let destination: LinkDestination
	let iconSize: Length

	init(_ label: String, icon: Icon, destination: LinkDestination, iconSize: Length = .rootEm(1.25)) {
		self.label = label
		self.icon = icon
		self.destination = destination
		self.iconSize = iconSize
	}

	var body: some HTML<HTMLTag.a> {
		a(.href(destination)) {
			icon.size(iconSize)
		}
		.accessibilityLabel(label)
		.style(Styles.root)
	}

	/**
	The look of an icon link, for other controls that look the same, like the menu button. A control reuses the style value instead of the class, as the order of rules from different style sets is not defined.
	*/
	static let look = Style()
		.display(.inlineFlex)
		.alignItems(.center)
		// As high as the pills of the navigation next to it.
		.padding(.rootEm(0.375))
		// A larger target for fingers, without moving the layout.
		.media(.coarsePointer) {
			$0
				.padding(.rootEm(0.75))
				.margin(.rootEm(-0.125))
		}
		// Round, like the pills of the navigation next to it.
		.cornerRadius(.capsule)
		.color(.secondaryText)
		.transition(.backgroundColor, .color, animation: .stateChange)
		.hover {
			$0
				.background(.card)
				.color(.primaryText)
		}
		// Like the current page in the navigation.
		.current {
			$0
				.background(.cardHover)
				.color(.primaryText)
		}

	enum Styles: StyleSet {
		case root

		var style: Style {
			IconLink.look
		}
	}
}
