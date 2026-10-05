import Foundation
import SiteKit

/**
What the head says about a page: title, description, social previews, and robots rules.
*/
struct PageMetadata {
	enum Kind {
		case website
		case article(publishedAt: Date, tags: [BlogPost.Tag])

		var openGraphType: String {
			switch self {
			case .website:
				"website"
			case .article:
				"article"
			}
		}
	}

	/**
	The title of the page, like “Apps” or “Older Versions — Apps”. The document title adds the site name.
	*/
	var title: String

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

	/**
	The campaign of the App Store banner, like `pt=123&ct=web-smart-banner`.
	*/
	var appStoreCampaign: String?

	var favicon: RoutePath = "/favicon.png"

	/**
	Feeds in addition to the site-wide feeds.
	*/
	var feeds = [FeedLink]()

	/**
	Origins the page will connect to soon, like a form endpoint.
	*/
	var preconnectOrigins = [String]()

	/**
	The title with the site name, like “Apps — Sindre Sorhus”, for the browser tab and search results. The home page has only the site name.
	*/
	var documentTitle: String {
		title == Site.name ? title : "\(title) — \(Site.name)"
	}
}
