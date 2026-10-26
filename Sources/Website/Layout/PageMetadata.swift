import Foundation
import SiteKit

/**
What the head says about a page: title, description, social previews, and robots rules.
*/
struct PageMetadata {
	enum Kind {
		/**
		The home page, whose title is the name of the site alone.
		*/
		case home
		case website
		case article(publishedAt: Date, tags: [BlogPost.Tag])

		var openGraphType: String {
			switch self {
			case .home, .website:
				"website"
			case .article:
				"article"
			}
		}
	}

	/**
	The title of the page, like “Apps” or “Older Versions — Apps”. The document title adds the site name.
	*/
	let title: String

	var description: String?

	/**
	The title in social previews. Defaults to the document title.
	*/
	var socialTitle: String?

	var kind = Kind.website

	/**
	Whether search engines may index the page.
	*/
	var isIndexed = true

	/**
	Shows the App Store banner in Safari on iOS.
	*/
	var appStoreID: AppStoreID?

	var favicon: RoutePath = "/favicon.png"

	/**
	A video for link previews, like the demo of an app, which some apps play in the preview.
	*/
	var video: MediaAsset?

	/**
	Feeds in addition to the site-wide feeds.
	*/
	var feeds = [FeedLink]()

	/**
	Origins the page will connect to soon, like a form endpoint.
	*/
	var preconnectOrigins = [URL]()

	/**
	The title with the site name, like “Apps — Sindre Sorhus”, for the browser tab and search results. The home page has only the site name.
	*/
	var documentTitle: String {
		switch kind {
		case .home:
			title
		case .website, .article:
			"\(title) — \(Site.name)"
		}
	}
}
