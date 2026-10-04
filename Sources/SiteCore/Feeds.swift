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


enum FeedHTMLSanitizer {
	private static let allowedTags: Set<String> = [
		"address", "article", "aside", "footer", "header",
		"h1", "h2", "h3", "h4", "h5", "h6", "hgroup",
		"main", "nav", "section",
		"blockquote", "dd", "div", "dl", "dt", "figcaption", "figure",
		"hr", "li", "menu", "ol", "p", "pre", "ul",
		"a", "abbr", "b", "bdi", "bdo", "br", "cite", "code", "data", "dfn",
		"em", "i", "kbd", "mark", "q", "rb", "rp", "rt", "rtc", "ruby",
		"s", "samp", "small", "span", "strong", "sub", "sup", "time", "u", "var", "wbr",
		"caption", "col", "colgroup", "table", "tbody", "td", "tfoot", "th",
		"thead", "tr",
	]

	private static let nonTextTags = ["script", "style", "textarea", "option"]
	private static let selfClosingTags: Set<String> = ["br", "hr", "wbr"]

	static func sanitize(_ html: String) -> String {
		var result = html

		result = result.replacingOccurrences(
			of: #"(?s)<!--.*?-->"#,
			with: "",
			options: .regularExpression
		)

		for tag in nonTextTags {
			result = result.replacingOccurrences(
				of: "(?is)<\\s*\(tag)\\b[^>]*>.*?<\\s*/\\s*\(tag)\\s*>",
				with: "",
				options: .regularExpression
			)
		}

		let tagRegex = try! NSRegularExpression(pattern: #"(?is)<\s*(/?)\s*([a-zA-Z0-9]+)([^>]*)>"#)
		let matches = tagRegex.matches(
			in: result,
			range: NSRange(result.startIndex..<result.endIndex, in: result)
		)

		for match in matches.reversed() {
			guard
				let fullRange = Range(match.range(at: 0), in: result),
				let closingRange = Range(match.range(at: 1), in: result),
				let nameRange = Range(match.range(at: 2), in: result),
				let attributesRange = Range(match.range(at: 3), in: result)
			else {
				continue
			}

			let isClosing = !result[closingRange].isEmpty
			let tag = result[nameRange].lowercased()
			let attributes = String(result[attributesRange])
			let replacement = sanitizedTag(
				name: tag,
				attributes: attributes,
				isClosing: isClosing
			)
			result.replaceSubrange(fullRange, with: replacement)
		}

		return result
	}

	private static func sanitizedTag(
		name: String,
		attributes: String,
		isClosing: Bool
	) -> String {
		guard allowedTags.contains(name) else {
			return ""
		}

		if isClosing {
			return selfClosingTags.contains(name) ? "" : "</\(name)>"
		}

		if selfClosingTags.contains(name) {
			return "<\(name) />"
		}

		guard name == "a" else {
			return "<\(name)>"
		}

		let attributeRegex = try! NSRegularExpression(
			pattern: #"(?i)([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>]+))"#
		)
		let matches = attributeRegex.matches(
			in: attributes,
			range: NSRange(attributes.startIndex..<attributes.endIndex, in: attributes)
		)

		var renderedAttributes: [String] = []

		for match in matches {
			guard
				let nameRange = Range(match.range(at: 1), in: attributes)
			else {
				continue
			}

			let attributeName = attributes[nameRange].lowercased()
			guard ["href", "name", "target"].contains(attributeName) else {
				continue
			}

			var value: String?
			for index in 2...4 where match.range(at: index).location != NSNotFound {
				if let range = Range(match.range(at: index), in: attributes) {
					value = String(attributes[range])
					break
				}
			}
			guard let value else {
				continue
			}

			if attributeName == "href", !isSafeURL(value) {
				continue
			}

			renderedAttributes.append(
				"\(attributeName)=\"\(TextUtilities.escapeHTML(value))\""
			)
		}

		let suffix = renderedAttributes.isEmpty
			? ""
			: " " + renderedAttributes.joined(separator: " ")
		return "<a\(suffix)>"
	}

	private static func isSafeURL(_ value: String) -> Bool {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else {
			return true
		}

		if trimmed.hasPrefix("#")
			|| trimmed.hasPrefix("/")
			|| trimmed.hasPrefix("./")
			|| trimmed.hasPrefix("../")
		{
			return true
		}

		guard let colon = trimmed.firstIndex(of: ":") else {
			return true
		}

		let slash = trimmed.firstIndex(of: "/")
		if let slash, slash < colon {
			return true
		}

		let scheme = trimmed[..<colon].lowercased()
		return ["http", "https", "ftp", "mailto", "tel"].contains(scheme)
	}
}
