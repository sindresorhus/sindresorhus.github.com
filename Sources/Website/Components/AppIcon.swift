import Elementary
import SiteKit

/**
The icon of an app. It loads when it is about to scroll into view, unless it is at the top of the page. The parent can add styles and attributes, like an ID.

```swift
AppIcon(app, size: 64)
	.style(Styles.icon)
```
*/
struct AppIcon: HTML {
	let app: App
	let size: Int

	/**
	Whether the name of the app is next to the icon, so screen readers skip the icon.
	*/
	var isNamedNearby = false

	/**
	Whether the icon is at the top of the page, so it loads at once, before other images.
	*/
	var isAboveFold = false

	/**
	Whether the icon morphs into the icon on the next page, like from the app list into the app page, with a cross-document view transition. A page must have only one such icon of an app.
	*/
	var morphsAcrossPages = false

	init(_ app: App, size: Int, isNamedNearby: Bool = false, isAboveFold: Bool = false, morphsAcrossPages: Bool = false) {
		self.app = app
		self.size = size
		self.isNamedNearby = isNamedNearby
		self.isAboveFold = isAboveFold
		self.morphsAcrossPages = morphsAcrossPages
	}

	var body: some HTML<HTMLTag.img> {
		img(.src(app.iconPath), .width(size), .height(size), .alt(isNamedNearby ? "" : "\(app.title) app icon"))
			.attributes(.fetchPriority(.high), when: isAboveFold)
			.attributes(.lazyLoading, when: !isAboveFold)
			.attributes(.style("view-transition-name: app-icon-\(app.slug); view-transition-class: app-icon"), when: morphsAcrossPages)
	}
}
