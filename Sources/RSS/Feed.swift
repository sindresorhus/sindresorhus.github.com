import Foundation

/**
An RSS 2.0 feed: a channel with its items.

```swift
let feed = Feed(
	title: "My Blog",
	link: URL(string: "https://example.com")!,
	description: "Posts about Swift"
) {
	for post in posts {
		Item(title: post.title, link: post.url, publicationDate: post.date)
	}
}

let xml = try feed.xmlString()
```
*/
public struct Feed: Hashable, Sendable {
	/**
	The name of the channel.
	*/
	public var title: String

	/**
	The absolute URL of the website the channel corresponds to.
	*/
	public var link: URL

	/**
	A phrase or sentence describing the channel.
	*/
	public var description: String

	/**
	The language of the channel, for example, `en-us`.
	*/
	public var language: String?

	/**
	The last time the content of the channel changed.
	*/
	public var lastBuildDate: Date?

	/**
	The absolute URL of the feed itself, written as `atom:link` with `rel="self"`, which feed validators recommend.
	*/
	public var selfLink: URL?

	/**
	A picture for the channel, like a logo, that feed readers show next to it.
	*/
	public var image: URL?

	public var items: [Item]

	public init(
		title: String,
		link: URL,
		description: String,
		language: String? = nil,
		lastBuildDate: Date? = nil,
		selfLink: URL? = nil,
		image: URL? = nil,
		items: [Item]
	) {
		self.title = title
		self.link = link
		self.description = description
		self.language = language
		self.lastBuildDate = lastBuildDate
		self.selfLink = selfLink
		self.image = image
		self.items = items
	}

	public init(
		title: String,
		link: URL,
		description: String,
		language: String? = nil,
		lastBuildDate: Date? = nil,
		selfLink: URL? = nil,
		image: URL? = nil,
		@ItemBuilder items: () -> [Item]
	) {
		self.init(
			title: title,
			link: link,
			description: description,
			language: language,
			lastBuildDate: lastBuildDate,
			selfLink: selfLink,
			image: image,
			items: items()
		)
	}
}

extension Feed {
	/**
	Checks the requirements of the RSS 2.0 specification that the type system cannot express, and that each item has its own GUID, which feed readers need to tell items apart. Errors name the item by its title, or else by its link, its GUID, or its position.
	*/
	public func validate() throws(FeedValidationError) {
		guard !title.isEmpty else {
			throw .emptyChannelTitle
		}

		guard !description.isEmpty else {
			throw .emptyChannelDescription
		}

		for url in [link, selfLink, image].compactMap(\.self) {
			guard url.isAbsolute else {
				throw .relativeURL(url, item: nil)
			}
		}

		var guids = Set<String>()

		for (index, item) in items.enumerated() {
			try item.validate(index: index)

			if
				let guid = item.resolvedGUID,
				!guids.insert(guid.value).inserted
			{
				throw .duplicateGUID(guid.value, item: item.name(index: index))
			}
		}
	}

	/**
	Validates the feed and renders it as an RSS 2.0 XML document.

	The `content` namespace is only declared when an item has HTML content.
	*/
	public func xmlString() throws(FeedValidationError) -> String {
		try validate()

		var writer = XMLWriter()
		writer.declaration()

		var rssAttributes = [("version", "2.0")]
		if items.contains(where: { $0.content != nil }) {
			rssAttributes.append(("xmlns:content", Namespace.content))
		}

		if selfLink != nil {
			rssAttributes.append(("xmlns:atom", Namespace.atom))
		}

		writer.element("rss", attributes: rssAttributes) { writer in
			writer.element("channel") { writer in
				writer.element("title", text: title)
				writer.element("link", text: link.absoluteString)
				writer.element("description", text: description)

				if let language {
					writer.element("language", text: language)
				}

				if let lastBuildDate {
					writer.element("lastBuildDate", text: lastBuildDate.rfc822String)
				}

				if let selfLink {
					writer.element("atom:link", attributes: [("href", selfLink.absoluteString), ("rel", "self"), ("type", "application/rss+xml")])
				}

				// The title and link of the image must be the same as the channel's.
				if let image {
					writer.element("image") { writer in
						writer.element("url", text: image.absoluteString)
						writer.element("title", text: title)
						writer.element("link", text: link.absoluteString)
					}
				}

				for item in items {
					item.write(to: &writer)
				}
			}
		}

		return writer.output
	}
}

enum Namespace {
	static let content = "http://purl.org/rss/1.0/modules/content/"
	static let atom = "http://www.w3.org/2005/Atom"
}

extension URL {
	var isAbsolute: Bool {
		scheme?.isEmpty == false
	}
}

extension Date {
	/**
	The date in the RFC 822 format that RSS requires, always in GMT, like `Sat, 04 Oct 2026 09:00:00 GMT`.
	*/
	var rfc822String: String {
		// The HTTP date format is this format.
		formatted(.http)
	}
}
