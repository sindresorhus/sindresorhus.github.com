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
	enum IconPosition {
		case leading

		/**
		After the title, like an arrow that points forward.
		*/
		case trailing
	}

	let title: String
	let icon: Icon
	let iconPosition: IconPosition

	init(_ title: String, icon: Icon, iconPosition: IconPosition = .leading) {
		self.title = title
		self.icon = icon
		self.iconPosition = iconPosition
	}

	var body: some HTML {
		switch iconPosition {
		case .leading:
			icon.size(.rootEm(1.25))
			title
		case .trailing:
			title
			icon.size(.rootEm(1.25))
		}
	}
}
