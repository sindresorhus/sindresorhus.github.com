import Elementary
import SiteKit

/**
An icon with a title, like SwiftUI's `Label`. The parent lays them out.

```swift
a(.href(.apps)) {
	Label("Apps", icon: .appStore)
}
```
*/
struct Label: HTML {
	enum IconPosition: Sendable {
		case leading

		/**
		After the title, like the arrow of “Older posts →”.
		*/
		case trailing
	}

	let title: String
	let icon: Icon
	var iconPosition = IconPosition.leading
	var iconSize = Length.rem(1.25)

	init(_ title: String, icon: Icon, iconPosition: IconPosition = .leading, iconSize: Length = .rem(1.25)) {
		self.title = title
		self.icon = icon
		self.iconPosition = iconPosition
		self.iconSize = iconSize
	}

	var body: some HTML {
		switch iconPosition {
		case .leading:
			icon.size(iconSize)
			title
		case .trailing:
			title
			icon.size(iconSize)
		}
	}
}
