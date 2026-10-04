import Foundation

public struct RSSItem: Sendable {
	public let title: String
	public let link: String
	public let publicationDate: Date
	public let description: String?
	public let contentHTML: String?
	public let guid: String?

	public init(title: String, link: String, publicationDate: Date, description: String? = nil, contentHTML: String? = nil, guid: String? = nil) {
		self.title = title
		self.link = link
		self.publicationDate = publicationDate
		self.description = description
		self.contentHTML = contentHTML
		self.guid = guid
	}
}

public enum FeedRenderer {
	public static func rss(title: String, description: String, items: [RSSItem]) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
		let renderedItems = items.map { item in
			let absoluteLink = absolute(item.link)
			return """
			<item>
				<title>\(TextUtilities.escapeXML(item.title))</title>
				<link>\(TextUtilities.escapeXML(absoluteLink))</link>
				<guid isPermaLink="\(item.guid == nil ? "true" : "false")">\(TextUtilities.escapeXML(item.guid ?? absoluteLink))</guid>
				<pubDate>\(formatter.string(from: item.publicationDate))</pubDate>
				\(item.description.map { "<description>\(TextUtilities.escapeXML($0))</description>" } ?? "")
				\(item.contentHTML.map { "<content:encoded><![CDATA[\($0.replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>"))]]></content:encoded>" } ?? "")
			</item>
			"""
		}.joined(separator: "\n")

		return """
		<?xml version="1.0" encoding="UTF-8"?>
		<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
		<channel>
			<title>\(TextUtilities.escapeXML(title))</title>
			<link>\(SiteConfiguration.origin)/</link>
			<description>\(TextUtilities.escapeXML(description))</description>
			\(renderedItems)
		</channel>
		</rss>
		"""
	}

	private static func absolute(_ link: String) -> String {
		link.hasPrefix("http://") || link.hasPrefix("https://") ? link : SiteConfiguration.origin + (link.hasPrefix("/") ? link : "/\(link)")
	}
}
