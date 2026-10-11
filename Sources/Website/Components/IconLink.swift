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

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style().iconButton()
		}
	}
}
