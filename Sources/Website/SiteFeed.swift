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
			"New writing"
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

	var metadata: PageMetadata.Feed {
		PageMetadata.Feed(title: title, path: path)
	}

	func feed(content: SiteContent) -> Feed {
		switch self {
		case .blog:
			.blog(posts: content.listedPosts, apps: content.activeApps)
		case .newApps:
			.newApps(content.activeApps)
		case .newRepositories:
			.newRepositories(content.recentRepositories)
		}
	}
}
