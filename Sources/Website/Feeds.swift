import Foundation
import RSS
import SiteKit

extension Feed {
	/**
	New blog posts and new apps.
	*/
	static func blog(posts: [BlogPost], apps: [App]) -> Self {
		struct Entry {
			let item: Item
			let date: Date
		}

		let posts = posts.map { post in
			Entry(item: Item(title: post.title, link: post.absoluteURL, description: post.description, guid: post.isRedirect ? GUID.original(post.slug) : nil, publicationDate: post.publicationDate), date: post.publicationDate)
		}

		let apps = apps.map { app in
			Entry(item: Item(title: "New App: \(app.title)", link: app.absoluteURL, description: app.subtitle, guid: app.isRedirect ? GUID.original(app.slug) : nil, publicationDate: app.publicationDate), date: app.publicationDate)
		}

		return Feed(
			title: SiteFeed.blog.title,
			link: Site.url,
			description: Site.description,
			selfLink: SiteFeed.blog.path.absoluteURL(site: Site.url),
			image: Site.feedImage,
			items: (posts + apps).sorted(using: KeyPathComparator(\.date, order: .reverse)).map(\.item)
		)
	}

	/**
	The new apps, each with its icon.
	*/
	static func newApps(_ apps: [App]) -> Self {
		Feed(title: SiteFeed.newApps.title, link: Site.url, description: "New apps by Sindre Sorhus", selfLink: SiteFeed.newApps.path.absoluteURL(site: Site.url), image: Site.feedImage) {
			for app in apps {
				Item(title: app.title, link: app.absoluteURL, description: app.subtitle, publicationDate: app.publicationDate, enclosure: app.iconEnclosure)
			}
		}
	}

	static func newRepositories(_ repositories: [GitHubRepository]) -> Self {
		Feed(title: SiteFeed.newRepositories.title, link: Site.url, description: "Recently created GitHub repos by Sindre Sorhus", selfLink: SiteFeed.newRepositories.path.absoluteURL(site: Site.url), image: Site.feedImage) {
			for repository in repositories {
				Item(title: repository.name, link: repository.url, description: repository.description ?? "", publicationDate: repository.createdAt)
			}
		}
	}

	/**
	The releases of an app, except the first one, with the release notes as HTML. The app icon is the image of the channel and of each release.
	*/
	static func releaseNotes(of app: App, at releaseNotes: App.ReleaseNotes, releases: [GitHubRelease]) -> Self {
		// Unlike the other feeds, the old site linked these to the URL with a trailing slash.
		Feed(title: releaseNotes.feed.title, link: RoutePath.root.absoluteURL(site: Site.url), description: "Latest releases of \(app.title)", selfLink: releaseNotes.feed.path.absoluteURL(site: Site.url), image: app.iconURL) {
			for release in releases where release.tagName != "v1.0.0" {
				Item(
					title: release.version,
					link: releaseNotes.path.absoluteURL(site: Site.url, fragment: release.version),
					// Feed readers get the notes without images, forms, and other markup they may not show safely. The page shows them as written, as the notes come from the app's own repository.
					content: release.notesHTML.sanitizedHTML,
					publicationDate: release.publishedAt,
					enclosure: app.iconEnclosure
				)
			}
		}
	}
}

extension GUID {
	/**
	For redirect posts and apps: identifies the item by a URL under `/blog`, like the old site did for both, so the item does not clash with the page it redirects to. Feed readers know the items by these GUIDs, so they stay.
	*/
	fileprivate static func original(_ slug: String) -> Self {
		GUID(Site.url.appending(path: "blog/\(slug)").absoluteString)
	}
}

extension Route {
	static func feed(_ path: RoutePath, _ feed: @autoclosure @escaping @Sendable () -> Feed) -> Self {
		.text(path) {
			try feed().xmlString()
		}
	}
}
