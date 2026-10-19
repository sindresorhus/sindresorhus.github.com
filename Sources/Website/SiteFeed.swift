import Foundation
import RSS
import SiteKit

/**
The site-wide feeds, which every page links to, and the feeds page lists.
*/
enum SiteFeed: CaseIterable {
	case blog
	case newApps
	case newRepositories

	var path: RoutePath {
		switch self {
		case .blog:
			"/rss.xml"
		case .newApps:
			"/rss-apps.xml"
		case .newRepositories:
			"/rss-repos.xml"
		}
	}

	/**
	The name on the feeds page, like “Blog”.
	*/
	var shortTitle: String {
		switch self {
		case .blog:
			"Blog"
		case .newApps:
			"New Apps"
		case .newRepositories:
			"New Repos"
		}
	}

	/**
	The title of the feed, for feed readers, like “Sindre Sorhus — Blog”.
	*/
	var title: String {
		"\(Site.name) — \(shortTitle)"
	}

	var subtitle: String {
		switch self {
		case .blog:
			"New writing and app launches"
		case .newApps:
			"New app launches"
		case .newRepositories:
			"New open-source projects"
		}
	}

	var icon: Icon {
		switch self {
		case .blog:
			.rss
		case .newApps:
			.apps
		case .newRepositories:
			.github
		}
	}

	var link: FeedLink {
		FeedLink(title: title, path: path)
	}

	/**
	The description of the channel, for feed readers.
	*/
	private var channelDescription: String {
		switch self {
		case .blog:
			Site.description
		case .newApps:
			"New apps by Sindre Sorhus"
		case .newRepositories:
			"Recently created GitHub repos by Sindre Sorhus"
		}
	}

	func feed(content: SiteContent) -> Feed {
		Feed(title: title, link: Site.url, description: channelDescription, selfLink: path.absoluteURL, image: Site.feedImage, items: items(content: content))
	}

	private func items(content: SiteContent) -> [Item] {
		switch self {
		case .blog:
			// New blog posts and new apps.
			let posts = content.listedPosts.map { post in
				Item(title: post.title, link: post.absoluteURL, description: post.description, guid: post.isRedirect ? GUID.original(post.slug) : nil, publicationDate: post.publicationDate)
			}

			let apps = content.activeApps.map { app in
				Item(title: "New App: \(app.title)", link: app.absoluteURL, description: app.subtitle, guid: app.isRedirect ? GUID.original(app.slug) : app.launchGUID, publicationDate: app.publicationDate)
			}

			return (posts + apps).sorted(using: KeyPathComparator(\.publicationDate, order: .reverse))
		case .newApps:
			// The new apps, each with its icon.
			return content.activeApps.map { app in
				Item(title: app.title, link: app.absoluteURL, description: app.subtitle, guid: app.launchGUID, publicationDate: app.publicationDate, enclosure: app.iconEnclosure)
			}
		case .newRepositories:
			return content.recentRepositories.map { repository in
				// The summary, like on the now page, without emoji codes and notes.
				Item(title: repository.displayName, link: repository.url, description: repository.summary ?? "", publicationDate: repository.createdAt)
			}
		}
	}
}

extension GUID {
	/**
	For redirect posts and apps: identifies the item by a URL under `/blog`, like the old site did for both, so the item does not clash with the page it redirects to. Feed readers know the items by these GUIDs, so they stay.
	*/
	fileprivate static func original(_ slug: String) -> Self {
		.identifier(BlogPost.path(slug: slug).absoluteURL.absoluteString)
	}
}

extension App {
	/**
	The GUID of the item of the app in the feeds, instead of its link. Super Menu was in the feeds by mistake in October 2026, before its launch, so the readers that fetched it then know its link. Its own GUID makes its launch a new item for them. It must never change, or readers show the app again.
	*/
	fileprivate var launchGUID: GUID? {
		guard slug == "super-menu" else {
			return nil
		}

		return .identifier("\(absoluteURL.absoluteString)#launch")
	}
}
