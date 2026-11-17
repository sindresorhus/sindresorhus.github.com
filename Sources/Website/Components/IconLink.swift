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
	let iconSize: LengthPercentage

	/**
	Whether the fill goes beyond the icon, so the icon lines up with the edge of the text, like at the end of a row (``Style/iconButton(hoverFill:isOutset:)``).
	*/
	let isOutset: Bool

	init(
		_ label: String,
		icon: Icon,
		destination: LinkDestination,
		iconSize: LengthPercentage = .rootEm(1.25),
		isOutset: Bool = false
	) {
		self.label = label
		self.icon = icon
		self.destination = destination
		self.iconSize = iconSize
		self.isOutset = isOutset
	}

	var body: some HTML<HTMLTag.a> {
		a(.href(destination)) {
			icon.size(iconSize)
		}
		.accessibilityLabel(label)
		.style(isOutset ? Styles.outset : Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case outset

		var style: Style {
			switch self {
			case .root:
				Style().iconButton()
			case .outset:
				Style().iconButton(isOutset: true)
			}
		}
	}
}
