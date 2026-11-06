import Foundation
import SiteKit
import SOML

/**
What the head says about a page: title, description, social previews, and robots rules.
*/
struct PageMetadata {
	enum Kind {
		case website

		/**
		A blog post or a guide. The page writes the dates as days, like the sitemap, as a publication date is a day, and midnight UTC would be the day before in the Americas.
		*/
		case article(publishedOn: SOML.Date, modifiedOn: SOML.Date, tags: [BlogPost.Tag])

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
	The title of the page, like “Apps” or “Older Versions”. The document title adds the site name, unless the title names the page alone (`isTitleStandalone`).
	*/
	let title: String

	var description: String?

	/**
	Whether the title names the page without the site name, like the title of an app page, a guide, or a post, or the home page, whose title is the name of the site. Then the browser tab, the search results, and the social previews show the title alone, so search engines show the whole title, as they cut a long one, and they show the site name above each result anyway. A title like “Apps” gets the site name.
	*/
	var isTitleStandalone = false

	var kind = Kind.website

	/**
	Whether search engines may index the page.
	*/
	var isIndexed = true

	/**
	Shows the App Store banner in Safari on iOS.
	*/
	var appStoreID: AppStoreID?

	var favicon: RoutePath = #path("/favicon.png")

	/**
	A video for link previews, like the demo of an app, which some apps play in the preview.
	*/
	var video: VideoAsset?

	/**
	Feeds in addition to the site-wide feeds.
	*/
	var feeds = [FeedLink]()

	/**
	Origins the page will connect to soon, like a form endpoint.
	*/
	var preconnectOrigins = [SiteOrigin]()

	/**
	The data of the page as a JSON file, like `/apps.json` for the apps page, which the head links to for tools.
	*/
	var dataFile: RoutePath?

	/**
	The title with the site name, like “Apps — Sindre Sorhus”, for the browser tab, search results, and social previews. A title that names the page alone has no site name (`isTitleStandalone`), like the home page, which has only the site name.
	*/
	var documentTitle: String {
		isTitleStandalone ? title : "\(title) — \(Site.name)"
	}
}

/**
Builds article projections from the document's publication facts while leaving page presentation explicit.
*/
extension PageMetadata {
	/**
	Creates article metadata using the same publication and modification days as the sitemap and structured data.
	*/
	init<Document: ContentDocument>(
		article document: Document,
		title: String,
		description: String?,
		tags: [BlogPost.Tag] = [],
		isIndexed: Bool = true,
		appStoreID: AppStoreID? = nil
	) where Document.Frontmatter: PublishedFrontmatter {
		self.init(
			title: title,
			description: description,
			isTitleStandalone: true,
			kind: .article(publishedOn: document.frontmatter.publicationDate, modifiedOn: document.lastModified, tags: tags),
			isIndexed: isIndexed,
			appStoreID: appStoreID
		)
	}
}

/**
Builds an article's structured data from its document's publication facts.
*/
extension Schema.Article {
	/**
	Creates structured data with document-owned canonical and publication facts and caller-owned presentation fields.
	*/
	init<Document: ContentDocument>(
		document: Document,
		type: Kind,
		title: String,
		description: String?,
		images: [URL],
		keywords: [String]? = nil
	) where Document.Frontmatter: PublishedFrontmatter {
		self.init(
			type: type,
			headline: title,
			description: description,
			url: document.path.absoluteURL,
			datePublished: document.frontmatter.publicationDate,
			dateModified: document.lastModified,
			author: .author,
			image: images,
			keywords: keywords
		)
	}
}
