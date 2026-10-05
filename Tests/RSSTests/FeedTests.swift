import Foundation
import Testing
import RSS

@Suite
struct FeedTests {
	private let site = URL(string: "https://example.com")!

	@Test
	func `renders channel and items`() throws {
		let date = Date(timeIntervalSince1970: 1_700_000_000)
		let feed = Feed(title: "Blog & News", link: site, description: "Posts <weekly>") {
			Item(title: "First", link: site.appending(path: "first"), description: "Hello", publicationDate: date)
		}

		let xml = try feed.xmlString()

		#expect(xml.hasPrefix(#"<?xml version="1.0" encoding="UTF-8"?>"#))
		#expect(xml.contains(#"<rss version="2.0">"#))
		#expect(xml.contains("<title>Blog &amp; News</title>"))
		#expect(xml.contains("<description>Posts &lt;weekly&gt;</description>"))
		#expect(xml.contains("<link>https://example.com</link>"))
		#expect(xml.contains(#"<guid isPermaLink="true">https://example.com/first</guid>"#))
		#expect(xml.contains("<pubDate>Tue, 14 Nov 2023 22:13:20 GMT</pubDate>"))
	}

	@Test
	func `renders the whole document`() throws {
		let feed = Feed(title: "A", link: site, description: "B", language: "en") {
			Item(title: "One", link: site.appending(path: "one"))
		}

		#expect(try feed.xmlString() == """
		<?xml version="1.0" encoding="UTF-8"?>
		<rss version="2.0">
			<channel>
				<title>A</title>
				<link>https://example.com</link>
				<description>B</description>
				<language>en</language>
				<item>
					<title>One</title>
					<link>https://example.com/one</link>
					<guid isPermaLink="true">https://example.com/one</guid>
				</item>
			</channel>
		</rss>

		""")
	}

	@Test
	func `declares content namespace only when needed`() throws {
		let plain = Feed(title: "A", link: site, description: "B") {
			Item(title: "Plain")
		}
		#expect(try !plain.xmlString().contains("xmlns:content"))

		let rich = Feed(title: "A", link: site, description: "B") {
			Item(title: "Rich", content: "<p>One ]]> two</p>")
		}
		let xml = try rich.xmlString()
		#expect(xml.contains(#"xmlns:content="http://purl.org/rss/1.0/modules/content/""#))
		#expect(xml.contains("<content:encoded><![CDATA[<p>One ]]]]><![CDATA[> two</p>]]></content:encoded>"))
	}

	@Test
	func `removes characters that XML does not allow from the content`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Rich", content: "<p>One\u{0}two</p>")
		}

		#expect(try feed.xmlString().contains("<content:encoded><![CDATA[<p>Onetwo</p>]]></content:encoded>"))
	}

	@Test
	func `uses custom GUIDs`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Moved", link: URL(string: "https://elsewhere.com/post")!, guid: GUID("https://example.com/post"))
		}

		#expect(try feed.xmlString().contains(#"<guid isPermaLink="false">https://example.com/post</guid>"#))
	}

	@Test
	func `leaves out the GUID without a link or a custom GUID`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Note")
		}

		#expect(try !feed.xmlString().contains("<guid"))
	}

	@Test
	func `writes the optional item elements`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(
				title: "Episode",
				author: "jane@example.com (Jane Doe)",
				categories: ["Swift", "Tips & Tricks"],
				enclosure: Enclosure(url: site.appending(path: "episode.mp3"), length: 1234, mimeType: "audio/mpeg")
			)
		}

		let xml = try feed.xmlString()
		#expect(xml.contains("<author>jane@example.com (Jane Doe)</author>"))
		#expect(xml.contains("<category>Swift</category>\n\t\t\t<category>Tips &amp; Tricks</category>"))
		#expect(xml.contains(#"<enclosure url="https://example.com/episode.mp3" length="1234" type="audio/mpeg"/>"#))
	}

	@Test
	func `escapes attribute values`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Item", guid: GUID(#"a"b'c<d>&e"#))
		}

		#expect(try feed.xmlString().contains(#"<guid isPermaLink="false">a&quot;b&apos;c&lt;d&gt;&amp;e</guid>"#))
	}

	@Test
	func `escapes an ampersand followed by a combining mark`() throws {
		let feed = Feed(title: "A&\u{301}B", link: site, description: "C", items: [])
		#expect(try feed.xmlString().contains("<title>A&amp;\u{301}B</title>"))
	}

	@Test
	func `writes the language and the last build date`() throws {
		let date = Date(timeIntervalSince1970: 1_700_000_000)
		let xml = try Feed(title: "A", link: site, description: "B", language: "en-us", lastBuildDate: date, items: []).xmlString()
		#expect(xml.contains("<language>en-us</language>"))
		#expect(xml.contains("<lastBuildDate>Tue, 14 Nov 2023 22:13:20 GMT</lastBuildDate>"))
	}

	@Test(arguments: [
		(0, "Thu, 01 Jan 1970 00:00:00 GMT"),
		(951_782_400, "Tue, 29 Feb 2000 00:00:00 GMT"),
		(1_735_689_599, "Tue, 31 Dec 2024 23:59:59 GMT"),
	])
	func `writes dates in the RFC 822 format in GMT`(timestamp: TimeInterval, expected: String) throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Item", publicationDate: Date(timeIntervalSince1970: timestamp))
		}

		#expect(try feed.xmlString().contains("<pubDate>\(expected)</pubDate>"))
	}

	@Test
	func `builds items with control flow`() {
		let includeSecond = false
		let isLong = true
		let extra: [Item] = [Item(title: "Extra")]

		let feed = Feed(title: "A", link: site, description: "B") {
			for index in 1...3 {
				Item(title: "Item \(index)")
			}

			if includeSecond {
				Item(title: "Hidden")
			}

			if isLong {
				Item(title: "Long")
			} else {
				Item(title: "Short")
			}

			extra
		}

		#expect(feed.items.map(\.title) == ["Item 1", "Item 2", "Item 3", "Long", "Extra"])
	}

	@Test
	func `removes characters that XML does not allow`() throws {
		let feed = Feed(title: "A\u{0B}B", link: site, description: "C", items: [])
		#expect(try feed.xmlString().contains("<title>AB</title>"))
	}

	@Test
	func `validates the specification requirements`() {
		#expect(throws: FeedValidationError.emptyChannelTitle) {
			try Feed(title: "", link: site, description: "B", items: []).validate()
		}

		#expect(throws: FeedValidationError.emptyChannelDescription) {
			try Feed(title: "A", link: site, description: "", items: []).validate()
		}

		#expect(throws: FeedValidationError.relativeURL(URL(string: "/post")!, item: "Post")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Post", link: URL(string: "/post")!)]).validate()
		}

		#expect(throws: FeedValidationError.relativeURL(URL(string: "/relative")!, item: nil)) {
			try Feed(title: "A", link: URL(string: "/relative")!, description: "B", items: []).validate()
		}

		#expect(throws: FeedValidationError.relativeURL(URL(string: "logo.png")!, item: nil)) {
			try Feed(title: "A", link: site, description: "B", image: URL(string: "logo.png")!, items: []).validate()
		}

		#expect(throws: FeedValidationError.relativeURL(URL(string: "/episode.mp3")!, item: "Episode")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Episode", enclosure: Enclosure(url: URL(string: "/episode.mp3")!, length: 1, mimeType: "audio/mpeg"))]).validate()
		}

		#expect(throws: FeedValidationError.invalidPermaLink("post-1", item: "Post")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Post", guid: GUID("post-1", isPermaLink: true))]).validate()
		}
	}

	@Test
	func `names an item without a title or description by its link, GUID, or position`() {
		#expect(throws: FeedValidationError.itemWithoutTitleOrDescription(item: "https://example.com")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Fine"), Item(link: site)]).validate()
		}

		#expect(throws: FeedValidationError.itemWithoutTitleOrDescription(item: "post-1")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(guid: GUID("post-1"))]).validate()
		}

		#expect(throws: FeedValidationError.itemWithoutTitleOrDescription(item: "#2")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Fine"), Item()]).validate()
		}
	}

	@Test
	func `rejects items with the same GUID`() {
		#expect(throws: FeedValidationError.duplicateGUID("https://example.com/post", item: "Second")) {
			try Feed(title: "A", link: site, description: "B") {
				Item(title: "First", link: site.appending(path: "post"))
				Item(title: "Second", guid: GUID("https://example.com/post", isPermaLink: true))
			}
			.validate()
		}
	}

	@Test
	func `rejects an author without an email address`() {
		#expect(throws: FeedValidationError.authorWithoutEmailAddress("Jane Doe", item: "Post")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Post", author: "Jane Doe")]).validate()
		}
	}

	@Test
	func `rejects an invalid enclosure`() {
		#expect(throws: FeedValidationError.invalidEnclosure(item: "Episode")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Episode", enclosure: Enclosure(url: site, length: -1, mimeType: "audio/mpeg"))]).validate()
		}

		#expect(throws: FeedValidationError.invalidEnclosure(item: "Episode")) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Episode", enclosure: Enclosure(url: site, length: 1, mimeType: ""))]).validate()
		}
	}

	@Test
	func `renders only valid feeds`() {
		#expect(throws: FeedValidationError.emptyChannelTitle) {
			try Feed(title: "", link: site, description: "B", items: []).xmlString()
		}
	}

	@Test
	func `describes errors with the item name`() {
		#expect(FeedValidationError.relativeURL(URL(string: "/post")!, item: "Post").description == "The URL “/post” of the item “Post” must be absolute.")
		#expect(FeedValidationError.relativeURL(URL(string: "/")!, item: nil).description == "The URL “/” of the channel must be absolute.")
		#expect(FeedValidationError.itemWithoutTitleOrDescription(item: "#2").description == "The item “#2” must have a title or a description.")
	}

	@Test
	func `writes the self link and the channel image`() throws {
		let xml = try Feed(title: "A", link: site, description: "B", selfLink: site.appending(path: "rss.xml"), image: site.appending(path: "logo.png"), items: []).xmlString()
		#expect(xml.contains(#"<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">"#))
		#expect(xml.contains(#"<atom:link href="https://example.com/rss.xml" rel="self" type="application/rss+xml"/>"#))
		#expect(xml.contains("<image>\n\t\t\t<url>https://example.com/logo.png</url>\n\t\t\t<title>A</title>\n\t\t\t<link>https://example.com</link>\n\t\t</image>"))
	}

	@Test
	func `produces well-formed XML`() throws {
		let feed = Feed(title: "A & B", link: site, description: "<C>", selfLink: site.appending(path: "rss.xml")) {
			Item(title: "One \"quoted\"", link: site.appending(path: "one"), content: "<p>Unclosed <b>tag</p> ]]> &nbsp;", categories: ["x<y"])
		}

		let document = try XMLDocument(xmlString: feed.xmlString())
		#expect(document.rootElement()?.name == "rss")
		#expect(try document.nodes(forXPath: "//item/title").first?.stringValue == "One \"quoted\"")
		#expect(try document.nodes(forXPath: "//item/*[local-name()='encoded']").first?.stringValue == "<p>Unclosed <b>tag</p> ]]> &nbsp;")
	}
}
