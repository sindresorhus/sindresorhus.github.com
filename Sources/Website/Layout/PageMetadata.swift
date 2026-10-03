import Foundation
import SiteKit

/**
What the head says about a page: title, description, social previews, and robots rules.
*/
struct PageMetadata: Sendable {
	enum Kind: Sendable {
		case website
		case blog
		case product
		case article(publishedAt: Date, tags: [BlogPost.Tag])

		var openGraphType: String {
			switch self {
			case .website:
				"website"
			case .blog:
				"blog"
			case .product:
				"product"
			case .article:
				"article"
			}
		}
	}

	/**
	The preview image for social media. Defaults to the site card.
	*/
	struct SocialImage: Sendable {
		let path: RoutePath
		let description: String

		static let site = Self(path: OpenGraphCard.site, description: Site.name)
	}

	/**
	A feed for feed readers to discover.
	*/
	struct Feed: Sendable {
		let title: String
		let path: RoutePath
	}

	var title: String
	var description: String?

	/**
	The title in social previews. Defaults to the title.
	*/
	var socialTitle: String?

	var kind = Kind.website
	var image = SocialImage.site

	/**
	Whether search engines may index the page.
	*/
	var isIndexed = true

	/**
	Shows the App Store banner in Safari on iOS.
	*/
	var appStoreID: Int?

	/**
	The campaign of the App Store banner, like `pt=123&ct=web-smart-banner`.
	*/
	var appStoreCampaign: String?

	var favicon = "/favicon.png"

	/**
	Feeds in addition to the site-wide feeds.
	*/
	var feeds = [Feed]()

	/**
	Origins the page will connect to soon, like a form endpoint.
	*/
	var preconnectOrigins = [String]()

	/**
	A title like “Apps — Sindre Sorhus” or “Older Versions — Apps — Sindre Sorhus”.
	*/
	static func titled(_ parts: String...) -> String {
		(parts + [Site.name]).joined(separator: " — ")
	}
}
