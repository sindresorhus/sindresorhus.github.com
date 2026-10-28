import Foundation
import SOML

/**
An item of a feed, like a blog post or a release.
*/
public struct Item: Hashable, Sendable {
	public var title: String

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

	public var publicationDate: PublicationDate?

	/**
	The email address of the author, optionally followed by the name, like `jane@example.com (Jane Doe)`.
	*/
	public var author: Author?

	public var categories: [String]

	public var enclosure: Enclosure?

	/**
	- Note: An item must have a title. RSS also allows an item with only a description, but feed readers show the title in their lists of items, and errors name the item by it.
	*/
	public init(
		title: String,
		link: URL? = nil,
		description: String? = nil,
		content: String? = nil,
		guid: GUID? = nil,
		publicationDate: PublicationDate? = nil,
		author: Author? = nil,
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
	/**
	A calendar date or an exact publication instant, kept in its original representation until RSS formatting requires a time. A calendar date is written at midnight UTC.
	*/
	public enum PublicationDate: Hashable, Sendable, Comparable {
		case date(SOML.Date)
		case instant(Foundation.Date)

		/**
		Orders dates chronologically. A calendar date precedes an instant at the same UTC midnight, so the order preserves their distinct identities.
		*/
		public static func < (lhs: Self, rhs: Self) -> Bool {
			switch (lhs, rhs) {
			case (.date(let lhs), .date(let rhs)):
				lhs < rhs
			case (.instant(let lhs), .instant(let rhs)):
				lhs < rhs
			case (.date, .instant):
				lhs.foundationDate <= rhs.foundationDate
			case (.instant, .date):
				lhs.foundationDate < rhs.foundationDate
			}
		}

		/**
		The date in the RFC 822 format that RSS requires, always in GMT.
		*/
		var rfc822String: String {
			foundationDate.rfc822String
		}

		/**
		Interprets a calendar date as midnight UTC when formatting or comparing it with an instant.
		*/
		private var foundationDate: Foundation.Date {
			switch self {
			case .date(let date):
				// Every SOML date has valid Gregorian components for an instant.
				SOML.Instant(year: date.year, month: date.month, day: date.day)!.date
			case .instant(let date):
				date
			}
		}
	}

	var resolvedGUID: GUID? {
		guid ?? link.map(GUID.permalink)
	}

	/**
	Errors name the item by its title, so it can be found.
	*/
	func validate() throws(FeedValidationError) {
		guard !title.isEmpty else {
			throw .emptyItemTitle
		}

		for url in [link, guid?.permalink].compactMap(\.self) {
			guard url.isAbsolute else {
				throw .relativeURL(url, item: title)
			}
		}
	}

	func write(to writer: inout XMLWriter) {
		writer.element("item") { writer in
			writer.element("title", text: title)

			writer.element("link", optionalText: link?.absoluteString)
			resolvedGUID?.write(to: &writer)
			writer.element("pubDate", optionalText: publicationDate?.rfc822String)
			writer.element("description", optionalText: description)

			if let content {
				writer.element("content:encoded", characterData: content)
			}

			writer.element("author", optionalText: author?.value)

			for category in categories {
				writer.element("category", text: category)
			}

			enclosure?.write(to: &writer)
		}
	}
}

/**
A string that uniquely identifies an item.
*/
public enum GUID: Hashable, Sendable {
	/**
	The URL of the item, which feed readers may open, written with `isPermaLink="true"`.
	*/
	case permalink(URL)

	/**
	Any other string that only this item has, like a URL that does not point to the item, written with `isPermaLink="false"`.
	*/
	case identifier(String)

	public var value: String {
		switch self {
		case .permalink(let url):
			url.absoluteString
		case .identifier(let value):
			value
		}
	}

	/**
	The URL of a permalink GUID, or else `nil`.
	*/
	var permalink: URL? {
		guard case .permalink(let url) = self else {
			return nil
		}

		return url
	}

	/**
	Writes the discriminator with the value it describes, so an identifier can never accidentally be declared a permalink.
	*/
	func write(to writer: inout XMLWriter) {
		switch self {
		case .permalink(let url):
			writer.element("guid", attributes: [("isPermaLink", "true")], text: url.absoluteString)
		case .identifier(let identifier):
			writer.element("guid", attributes: [("isPermaLink", "false")], text: identifier)
		}
	}
}

/**
A feed item's author, with an email address and an optional display name.
*/
public struct Author: Hashable, Sendable {
	public let email: String
	public let name: String?

	/**
	Creates an author whose email contains `@`, matching the feed's supported email check.
	*/
	public init?(email: String, name: String? = nil) {
		guard email.contains("@") else {
			return nil
		}

		self.email = email
		self.name = name
	}

	/**
	The RSS author text.
	*/
	var value: String {
		// The specification requires an email address, optionally followed by the name, like `jane@example.com (Jane Doe)`.
		email + (name.map { " (\($0))" } ?? "")
	}
}

/**
A media object attached to an item, like a podcast episode.
*/
public struct Enclosure: Hashable, Sendable {
	public let url: URL

	/**
	The size in bytes.
	*/
	public let length: Int

	public let mimeType: String

	/**
	Creates an enclosure with an absolute URL, a length of zero or more bytes, and a nonempty MIME type. Returns `nil` when the URL is relative, or when the enclosure has a negative length or no MIME type.
	*/
	public init?(url: URL, length: Int, mimeType: String) {
		guard
			length >= 0,
			!mimeType.isEmpty,
			url.isAbsolute
		else {
			return nil
		}

		self.url = url
		self.length = length
		self.mimeType = mimeType
	}

	/**
	Writes the validated media facts together in the RSS enclosure form.
	*/
	func write(to writer: inout XMLWriter) {
		writer.element(
			"enclosure",
			attributes: [
				("url", url.absoluteString),
				("length", String(length)),
				("type", mimeType),
			]
		)
	}
}

public enum FeedValidationError: Error, Hashable, CustomStringConvertible {
	case emptyChannelTitle
	case emptyChannelDescription
	case emptyItemTitle

	/**
	A URL of the channel (`item` is `nil`) or of the named item is relative.
	*/
	case relativeURL(URL, item: String?)

	/**
	Two items have the same GUID, so feed readers would show only one of them.
	*/
	case duplicateGUID(String, item: String)

	public var description: String {
		switch self {
		case .emptyChannelTitle:
			"The channel title must not be empty."
		case .emptyChannelDescription:
			"The channel description must not be empty."
		case .emptyItemTitle:
			"The item title must not be empty."
		case .relativeURL(let url, let item):
			"The URL “\(url)”\(item.map { " of the item “\($0)”" } ?? " of the channel") must be absolute."
		case .duplicateGUID(let value, let item):
			"The GUID “\(value)” of the item “\(item)” is also used by an earlier item. Each item needs its own GUID."
		}
	}
}
