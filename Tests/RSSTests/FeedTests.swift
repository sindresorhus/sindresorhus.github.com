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
	func `uses custom GUIDs`() throws {
		let feed = Feed(title: "A", link: site, description: "B") {
			Item(title: "Moved", link: URL(string: "https://elsewhere.com/post")!, guid: GUID("https://example.com/post"))
		}

		#expect(try feed.xmlString().contains(#"<guid isPermaLink="false">https://example.com/post</guid>"#))
	}

	@Test
	func `builds items with control flow`() {
		let includeSecond = false
		let feed = Feed(title: "A", link: site, description: "B") {
			for index in 1...3 {
				Item(title: "Item \(index)")
			}

			if includeSecond {
				Item(title: "Hidden")
			}
		}

		#expect(feed.items.map(\.title) == ["Item 1", "Item 2", "Item 3"])
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

		#expect(throws: FeedValidationError.itemWithoutTitleOrDescription(index: 1)) {
			try Feed(title: "A", link: site, description: "B", items: [Item(title: "Fine"), Item(link: site)]).validate()
		}
	}

	@Test
	func `writes the self link and the channel image`() throws {
		let xml = try Feed(title: "A", link: site, description: "B", selfLink: site.appending(path: "rss.xml"), image: site.appending(path: "logo.png"), items: []).xmlString()
		#expect(xml.contains(#"<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">"#))
		#expect(xml.contains(#"<atom:link href="https://example.com/rss.xml" rel="self" type="application/rss+xml"/>"#))
		#expect(xml.contains("<image>\n\t\t\t<url>https://example.com/logo.png</url>\n\t\t\t<title>A</title>\n\t\t\t<link>https://example.com</link>\n\t\t</image>"))
	}
}
