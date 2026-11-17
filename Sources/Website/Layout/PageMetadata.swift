import Elementary
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

		/**
		A page about the author (``Site/author``), like the about page. The page has the name and the username of the author, which Open Graph has for a profile.
		*/
		case profile

		var openGraphType: String {
			switch self {
			case .website:
				"website"
			case .article:
				"article"
			case .profile:
				"profile"
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
	The feeds of the page, which the head lists before the site-wide feeds, like the release notes of an app, or the new guides on a guide, as some feed readers take the first feed. It can be a site-wide feed, which is then not listed again.
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
	The link preview of the page in Discord, in place of the preview of the Open Graph tags, like an app page as a small store page.
	*/
	var discordEmbed: DiscordEmbed?

	/**
	The title with the site name, like “Apps — Sindre Sorhus”, for the browser tab, search results, and social previews. A title that names the page alone has no site name (`isTitleStandalone`), like the home page, which has only the site name.
	*/
	var documentTitle: String {
		isTitleStandalone ? title : "\(title) — \(Site.name)"
	}
}

/**
A link preview for Discord, which Discord shows in place of the preview of the Open Graph tags (a component embed), with the parts that the site uses. Discord shows the preview of the Open Graph tags when it cannot show this one, and other services do not read it. See https://docs.discord.com/developers/link-previews/component-embeds

Limitation: the text is Discord Markdown, so a pair of `*` or `_` in a text would be formatting. The texts of the site do not have them.
*/
struct DiscordEmbed: Encodable {
	/**
	The ID and the media type of the script element that Discord reads. The media type is not the one of the data of page scripts (`application/json`), so the tests of page data leave it out.
	*/
	static let id = ElementID("discord:component-embed")
	static let scriptType: HTMLAttribute<HTMLTag.script>.ScriptType = "application/vnd.discord.component-embed+json"

	/**
	The largest size of the JSON that Discord reads, in bytes. A larger embed shows no preview.
	*/
	static let maximumSize = 3000

	/**
	Discord shows at most 5 buttons in a row.
	*/
	static let maximumButtonCount = 5

	enum Component {
		/**
		Text in Discord Markdown, like `## [Dato](https://sindresorhus.com/dato)` and the description below it, with an image at its right, like the icon of an app.
		*/
		case text(String, thumbnail: URL)

		/**
		Images in a grid, like screenshots.
		*/
		case gallery([URL])

		case separator

		/**
		Links as buttons in a row, at most ``DiscordEmbed/maximumButtonCount``.
		*/
		case linkButtons([(title: String, url: URL)])
	}

	let components: [Component]

	/**
	The components in one container, the only top-level component that Discord accepts. Discord names each kind of component by a number, like 17 for a container.
	*/
	func encode(to encoder: any Encoder) throws {
		var root = encoder.container(keyedBy: Key.self)
		var container = root.nestedContainer(keyedBy: Key.self, forKey: .component)
		try container.encode(17, forKey: .type)
		var components = container.nestedUnkeyedContainer(forKey: .components)

		for component in self.components {
			var item = components.nestedContainer(keyedBy: Key.self)

			switch component {
			case .text(let text, let thumbnail):
				// A section, with a text display and a thumbnail.
				try item.encode(9, forKey: .type)
				var texts = item.nestedUnkeyedContainer(forKey: .components)
				var textDisplay = texts.nestedContainer(keyedBy: Key.self)
				try textDisplay.encode(10, forKey: .type)
				try textDisplay.encode(text, forKey: .content)
				var accessory = item.nestedContainer(keyedBy: Key.self, forKey: .accessory)
				try accessory.encode(11, forKey: .type)
				try accessory.encode(["url": thumbnail], forKey: .media)
			case .gallery(let images):
				// A media gallery.
				try item.encode(12, forKey: .type)
				try item.encode(images.map { ["media": ["url": $0]] }, forKey: .items)
			case .separator:
				try item.encode(14, forKey: .type)
			case .linkButtons(let links):
				// An action row of buttons with the link style.
				try item.encode(1, forKey: .type)
				var buttons = item.nestedUnkeyedContainer(forKey: .components)

				for link in links.prefix(Self.maximumButtonCount) {
					var button = buttons.nestedContainer(keyedBy: Key.self)
					try button.encode(2, forKey: .type)
					try button.encode(5, forKey: .style)
					try button.encode(link.title, forKey: .label)
					try button.encode(link.url, forKey: .url)
				}
			}
		}
	}

	private enum Key: String, CodingKey {
		case component
		case components
		case type
		case content
		case accessory
		case media
		case items
		case style
		case label
		case url
	}
}

/**
Builds article projections from the document's publication facts while leaving page presentation explicit.
*/
extension PageMetadata {
	/**
	Creates article metadata with the publication day of the document, and the same modification day as the structured data.

	- Parameter modifiedOn: The day that the page says the article changed, like the “Updated” date of a guide, or the publication day of a blog post, which shows only its month, and has its updates in its text (``ContentDocument/lastModified`` is the last commit of the file, which can be only a fix of its frontmatter). Google asks for the same dates as the page.
	- Parameter feeds: The feeds of the page (``feeds``), like the new guides on a guide.
	*/
	init<Document: ContentDocument>(
		article document: Document,
		title: String,
		description: String?,
		modifiedOn: SOML.Date,
		tags: [BlogPost.Tag] = [],
		isIndexed: Bool = true,
		appStoreID: AppStoreID? = nil,
		feeds: [FeedLink] = []
	) where Document.Frontmatter: PublishedFrontmatter {
		self.init(
			title: title,
			description: description,
			isTitleStandalone: true,
			kind: .article(publishedOn: document.frontmatter.publicationDate, modifiedOn: modifiedOn, tags: tags),
			isIndexed: isIndexed,
			appStoreID: appStoreID,
			feeds: feeds
		)
	}
}

/**
Builds an article's structured data from its document's publication facts.
*/
extension Schema.Article {
	/**
	Creates structured data with document-owned canonical and publication facts and caller-owned presentation fields.

	- Parameter dateModified: The day that the page says the article changed, like for the metadata of the page (``PageMetadata/init(article:title:description:modifiedOn:tags:isIndexed:appStoreID:feeds:)``).
	*/
	init<Document: ContentDocument>(
		document: Document,
		type: Kind,
		title: String,
		description: String?,
		dateModified: SOML.Date,
		images: [URL],
		keywords: [String]? = nil
	) where Document.Frontmatter: PublishedFrontmatter {
		self.init(
			type: type,
			headline: title,
			description: description,
			url: document.path.absoluteURL,
			datePublished: document.frontmatter.publicationDate,
			dateModified: dateModified,
			author: .author,
			image: images,
			keywords: keywords
		)
	}
}
