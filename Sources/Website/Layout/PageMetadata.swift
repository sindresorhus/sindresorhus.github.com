import Foundation
import SiteKit
import SOML

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

		/**
		A blog post or a guide. The page writes the dates as days, like the sitemap, as a publication date is a day, and midnight UTC would be the day before in the Americas.
		*/
		case article(publishedOn: SOML.Date, modifiedOn: SOML.Date, tags: [BlogPost.Tag])

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
			socialTitle: title,
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
