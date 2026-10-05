import Foundation
import RSS
import SiteKit

extension Feed {
	/**
	The releases of an app, except `v1.0.0`, the launch, with the release notes as HTML. The app icon is the image of the channel and of each release.
	*/
	static func releaseNotes(of app: App, at releaseNotes: App.ReleaseNotes, releases: [GitHubRelease]) -> Self {
		// Unlike the other feeds, the old site linked these to the URL with a trailing slash.
		Feed(title: releaseNotes.feed.title, link: RoutePath.root.absoluteURL, description: "Latest releases of \(app.title)", selfLink: releaseNotes.feed.path.absoluteURL, image: app.iconURL) {
			for release in releases where release.tagName != "v1.0.0" {
				Item(
					title: release.version,
					link: releaseNotes.destination(of: release).absoluteURL,
					// As written, like on the page, as the notes come from the app's own repository. Feed readers sanitize the HTML of feeds themselves.
					content: release.notesHTML,
					publicationDate: release.publishedAt,
					enclosure: app.iconEnclosure
				)
			}
		}
	}
}

extension Route {
	/**
	A feed of the site. The feeds are in English, and were last built when the newest item was published, so two builds of the same content give the same file.
	*/
	static func feed(_ path: RoutePath, _ feed: @autoclosure @escaping @Sendable () -> Feed) -> Self {
		.text(path) {
			var feed = feed()
			feed.language = "en"
			feed.lastBuildDate = feed.items.compactMap(\.publicationDate).max()
			return try feed.xmlString()
		}
	}
}
