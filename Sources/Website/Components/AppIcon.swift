import Elementary
import SiteKit

/**
The icon of an app. It loads when it is about to scroll into view, unless it is at the top of the page. The parent can add styles, like a size or a shadow, to the box around the image.

The icon images fill their square, so the soft rim of the icon is cut flat at the sides of the image. The image is clipped to the icon shape, a little inside its edges, so the cut rim does not show. A shadow from the parent is on the box, as the clip would also cut a shadow on the image.

```swift
AppIcon(app, size: 64)
	.style(Styles.icon)

// Next to the name of the app.
AppIcon(decorative: app, size: 32)
```
*/
struct AppIcon: HTML {
	let app: App
	let size: Int

	/**
	Whether screen readers skip the icon, as the name of the app is next to it.
	*/
	private let isDecorative: Bool

	/**
	Whether the icon is at the top of the page, so it loads at once, before other images.
	*/
	var isAboveFold = false

	/**
	The ID of the image, for a script that changes the image, like the googly eyes of the Googly Eyes page.
	*/
	var imageID: String?

	init(_ app: App, size: Int, isAboveFold: Bool = false, imageID: String? = nil) {
		self.app = app
		self.size = size
		self.isDecorative = false
		self.isAboveFold = isAboveFold
		self.imageID = imageID
	}

	/**
	An icon that screen readers skip, because the name of the app is next to it, like `Image(decorative:)` in SwiftUI.
	*/
	init(decorative app: App, size: Int, isAboveFold: Bool = false) {
		self.app = app
		self.size = size
		self.isDecorative = true
		self.isAboveFold = isAboveFold
	}

	var body: some HTML<HTMLTag.span> {
		span {
			img(.src(app.iconPath), .width(size), .height(size), .alt(isDecorative ? "" : "\(app.title) app icon"))
				.attributes(.fetchPriority(.high), when: isAboveFold)
				.attributes(.lazyLoading, when: !isAboveFold)
				.attributes(.id(imageID ?? ""), when: imageID != nil)
				.style(Styles.image)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case image

		var style: Style {
			switch self {
			case .root:
				// As large as the image, unless the parent sets a size.
				Style()
					.display(.inlineBlock)
					.verticalAlign(.top)
			case .image:
				// The size of the image, or smaller when the parent sets a smaller box, like a hero icon. The corner radius is the one of an icon on the grid of Apple, about 22.5% of its size. The margin is zero, as an image in prose has a margin.
				Style()
					.display(.block)
					.frame(height: .auto, maxWidth: .percent(100))
					.margin(0)
					.clipShape(inset: .percent(1.2), cornerRadius: .percent(22.5))
			}
		}
	}
}
