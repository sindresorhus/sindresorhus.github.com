import Foundation
import RSS
import SiteKit

extension Feed {
	/**
	A feed whose title and self-link come from the same identity as its route, with a separate channel website URL.
	*/
	init(_ identity: FeedLink, link: URL, description: String, image: URL, items: [Item]) {
		self.init(title: identity.title, link: link, description: description, selfLink: identity.path.absoluteURL, image: image, items: items)
	}

	/**
	The releases of an app, except `v1.0.0`, the launch, with the release notes as HTML. The app icon is the image of the channel, not an enclosure of each release, as feed readers show an enclosure as an attachment of the item, like the file of a podcast episode.
	*/
	static func releaseNotes(of app: App, at releaseNotes: App.ReleaseNotes, releases: [GitHubRelease]) -> Self {
		// The channel links to the release notes page, which feed readers show as the website of the feed. Readers follow the self link, not this one.
		Feed(
			releaseNotes.feed,
			link: releaseNotes.path.absoluteURL,
			description: "Latest releases of \(app.title)",
			image: app.iconURL,
			items: releases.filter { $0.tagName != "v1.0.0" }.map { release in
				Item(
					// With the app, as a reader can show the item without its feed, like in a list of the items of all feeds.
					title: "\(app.title) \(release.version)",
					link: releaseNotes.destination(of: release).absoluteURL(on: releaseNotes.path),
					// As written, like on the page, as the notes come from the app's own repository. Feed readers sanitize the HTML of feeds themselves.
					content: release.notesHTML,
					publicationDate: .instant(release.publishedAt)
				)
			}
		)
	}
}

extension Route {
	/**
	A feed of the site. The feeds are in English, and were last built when the newest item was published, so two builds of the same content give the same file.
	*/
	static func feed(_ identity: FeedLink, _ feed: @autoclosure @escaping @Sendable () -> Feed) -> Self {
		.text(identity.path) {
			var feed = feed()
			feed.language = "en"
			feed.lastBuildDate = feed.items.compactMap(\.publicationDate).max()
			return try feed.xmlString()
		}
	}
}
