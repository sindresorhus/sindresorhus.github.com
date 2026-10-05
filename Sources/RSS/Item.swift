import Foundation

/**
An item of a feed, like a blog post or a release.
*/
public struct Item: Hashable, Sendable {
	public var title: String?

	/**
	The absolute URL of the item.
	*/
	public var link: URL?

	/**
	A plain-text synopsis of the item.
	*/
	public var description: String?

	/**
	The full HTML content of the item. It is written as `content:encoded`.
	*/
	public var content: String?

	/**
	Uniquely identifies the item. When `nil`, the link is used as a permalink GUID.
	*/
	public var guid: GUID?

	public var publicationDate: Date?

	/**
	The email address of the author, optionally followed by the name, like `jane@example.com (Jane Doe)`.
	*/
	public var author: String?

	public var categories: [String]

	public var enclosure: Enclosure?

	/**
	- Note: An item must have a title or a description.
	*/
	public init(
		title: String? = nil,
		link: URL? = nil,
		description: String? = nil,
		content: String? = nil,
		guid: GUID? = nil,
		publicationDate: Date? = nil,
		author: String? = nil,
		categories: [String] = [],
		enclosure: Enclosure? = nil
	) {
		self.title = title
		self.link = link
		self.description = description
		self.content = content
		self.guid = guid
		self.publicationDate = publicationDate
		self.author = author
		self.categories = categories
		self.enclosure = enclosure
	}
}

extension Item {
	var resolvedGUID: GUID? {
		guid ?? link.map(GUID.permalink)
	}

	/**
	How errors name the item, so it can be found: the title, the link, the GUID, or else the position, like `#2`.
	*/
	func name(index: Int) -> String {
		title ?? link?.absoluteString ?? guid?.value ?? "#\(index + 1)"
	}

	func validate(index: Int) throws(FeedValidationError) {
		let name = name(index: index)

		guard title != nil || description != nil else {
			throw .itemWithoutTitleOrDescription(item: name)
		}

		for url in [link, enclosure?.url].compactMap(\.self) {
			guard url.isAbsolute else {
				throw .relativeURL(url, item: name)
			}
		}

		if
			let guid = resolvedGUID,
			guid.isPermaLink,
			URL(string: guid.value)?.isAbsolute != true
		{
			throw .invalidPermaLink(guid.value, item: name)
		}

		// The specification requires an email address, optionally followed by the name, like `jane@example.com (Jane Doe)`.
		if
			let author,
			!author.contains("@")
		{
			throw .authorWithoutEmailAddress(author, item: name)
		}

		if
			let enclosure,
			enclosure.length < 0 || enclosure.mimeType.isEmpty
		{
			throw .invalidEnclosure(item: name)
		}
	}

	func write(to writer: inout XMLWriter) {
		writer.element("item") { writer in
			if let title {
				writer.element("title", text: title)
			}

			if let link {
				writer.element("link", text: link.absoluteString)
			}

			if let guid = resolvedGUID {
				writer.element("guid", attributes: [("isPermaLink", guid.isPermaLink ? "true" : "false")], text: guid.value)
			}

			if let publicationDate {
				writer.element("pubDate", text: publicationDate.rfc822String)
			}

			if let description {
				writer.element("description", text: description)
			}

			if let content {
				writer.element("content:encoded", characterData: content)
			}

			if let author {
				writer.element("author", text: author)
			}

			for category in categories {
				writer.element("category", text: category)
			}

			if let enclosure {
				writer.element("enclosure", attributes: [
					("url", enclosure.url.absoluteString),
					("length", String(enclosure.length)),
					("type", enclosure.mimeType),
				])
			}
		}
	}
}

/**
A string that uniquely identifies an item.
*/
public struct GUID: Hashable, Sendable {
	public var value: String

	/**
	Whether the value is a URL that points to the item.
	*/
	public var isPermaLink: Bool

	public init(_ value: String, isPermaLink: Bool = false) {
		self.value = value
		self.isPermaLink = isPermaLink
	}

	public static func permalink(_ url: URL) -> Self {
		Self(url.absoluteString, isPermaLink: true)
	}
}

/**
A media object attached to an item, like a podcast episode.
*/
public struct Enclosure: Hashable, Sendable {
	public var url: URL

	/**
	The size in bytes.
	*/
	public var length: Int

	public var mimeType: String

	public init(url: URL, length: Int, mimeType: String) {
		self.url = url
		self.length = length
		self.mimeType = mimeType
	}
}

public enum FeedValidationError: Error, Hashable, CustomStringConvertible {
	case emptyChannelTitle
	case emptyChannelDescription

	/**
	A URL of the channel (`item` is `nil`) or of the named item is relative.
	*/
	case relativeURL(URL, item: String?)

	case itemWithoutTitleOrDescription(item: String)
	case invalidPermaLink(String, item: String)

	/**
	Two items have the same GUID, so feed readers would show only one of them.
	*/
	case duplicateGUID(String, item: String)

	case authorWithoutEmailAddress(String, item: String)

	/**
	The enclosure has a negative length or no MIME type.
	*/
	case invalidEnclosure(item: String)

	public var description: String {
		switch self {
		case .emptyChannelTitle:
			"The channel title must not be empty."
		case .emptyChannelDescription:
			"The channel description must not be empty."
		case .relativeURL(let url, let item):
			"The URL “\(url)”\(item.map { " of the item “\($0)”" } ?? " of the channel") must be absolute."
		case .itemWithoutTitleOrDescription(let item):
			"The item “\(item)” must have a title or a description."
		case .invalidPermaLink(let value, let item):
			"The permalink GUID “\(value)” of the item “\(item)” must be an absolute URL."
		case .duplicateGUID(let value, let item):
			"The GUID “\(value)” of the item “\(item)” is also used by an earlier item. Each item needs its own GUID."
		case .authorWithoutEmailAddress(let author, let item):
			"The author “\(author)” of the item “\(item)” must have an email address, like `jane@example.com (Jane Doe)`."
		case .invalidEnclosure(let item):
			"The enclosure of the item “\(item)” must have a length of zero or more bytes and a MIME type."
		}
	}
}
