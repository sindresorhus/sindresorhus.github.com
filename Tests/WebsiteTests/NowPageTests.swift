import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct NowPageTests {
	@Test(.temporaryDirectory)
	func `the latest Bluesky post skips reposts and keeps the links of its text`() async throws {
		// The link starts after “🦄 ”, which is 5 bytes in UTF-8, so the byte offsets differ from the character offsets.
		let feed = #"""
		{"feed": [
			{"post": {"uri": "at://did:plc:test/app.bsky.feed.post/repost", "record": {"text": "A repost", "createdAt": "2026-10-07T10:00:00.000Z"}}, "reason": {"$type": "app.bsky.feed.defs#reasonRepost", "by": {"handle": "sindresorhus.com"}}},
			{"post": {"uri": "at://did:plc:test/app.bsky.feed.post/3mwxsirxlbs2y", "record": {"text": "🦄 New: github.com/sindresorhus... Enjoy", "createdAt": "2026-10-03T11:40:27.083Z", "facets": [{"index": {"byteStart": 10, "byteEnd": 36}, "features": [{"$type": "app.bsky.richtext.facet#link", "uri": "https://github.com/sindresorhus/eslint-cssicorn"}]}]}}},
			{"post": {"uri": "at://did:plc:test/app.bsky.feed.post/older", "record": {"text": "Older", "createdAt": "2026-10-01T18:04:23Z"}}}
		]}
		"""#

		let cache = try ResponseCache(responses: ["https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=sindresorhus.com&limit=5&filter=posts_no_replies": feed])
		let post = try #require(try await BlueskyPost.latest(cache: cache))

		#expect(post.url.absoluteString == "https://bsky.app/profile/sindresorhus.com/post/3mwxsirxlbs2y")
		#expect(post.date == Date(timeIntervalSince1970: 1_791_027_627.083))
		#expect(post.text == "🦄 New: github.com/sindresorhus... Enjoy")
		#expect(post.segments == [
			BlueskyPost.Segment(text: "🦄 New: ", link: nil),
			BlueskyPost.Segment(text: "github.com/sindresorhus...", link: URL(string: "https://github.com/sindresorhus/eslint-cssicorn")),
			BlueskyPost.Segment(text: " Enjoy", link: nil),
		])
	}

	@Test(arguments: [
		(counts: [3, 0, 2, 5, 1], streak: 3),
		// Today has no contributions yet, so the streak ends yesterday.
		(counts: [3, 0, 2, 5, 0], streak: 2),
		(counts: [3, 4, 0, 0], streak: 0),
		(counts: [1, 1, 1], streak: 3),
		(counts: [], streak: 0),
	])
	func `the streak counts the days in a row with contributions`(counts: [Int], streak: Int) throws {
		let days = counts.enumerated().map { #"{"date": "2026-10-0\#($0.offset + 1)", "contributionCount": \#($0.element), "contributionLevel": "\#($0.element == 0 ? "NONE" : "FIRST_QUARTILE")"}"# }
		let json = #"{"totalContributions": \#(counts.reduce(0, +)), "weeks": [{"contributionDays": [\#(days.joined(separator: ","))]}]}"#
		let calendar = try JSONDecoder().decode(ContributionCalendar.self, from: Data(json.utf8))

		#expect(calendar.currentStreak == streak)
	}

	@Test
	func `on this day lists the apps, releases, and posts of this day in earlier years`() async throws {
		func post(_ slug: String, date: String) async throws -> BlogPost {
			try await BlogPost(markdown: "---\ntitle: '\(slug)'\npublicationDate: '\(date)'\n---\n\nText.", slug: slug)
		}

		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2019-10-07'\nplatforms: ['macOS']\n---\n\nText.")
		let posts = try await [post("same-day", date: "2021-10-07"), post("other-day", date: "2021-10-08"), post("this-year", date: "2026-10-07")]
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")

		// 2026-10-07 12:00 UTC.
		let content = SiteContent(apps: [app], posts: posts, pages: [page], buildDate: Date(timeIntervalSince1970: 1_791_374_400), project: .empty)
		let anniversaries = NowPage(page: page, content: content).onThisDay

		#expect(anniversaries.map(\.title) == ["same-day", "Test"])
		#expect(anniversaries.map(\.description) == ["posted in 2021", "launched in 2019"])
	}

	/**
	The npm search also finds packages that he only helps maintain, like `yeoman-generator`, so the page only shows the packages of repositories that he or his organizations own.
	*/
	@Test(.temporaryDirectory)
	func `the latest releases only have packages from his own repositories`() async throws {
		let search = #"""
		{"objects": [
			{"package": {"name": "chalk", "version": "6.0.0", "date": "2026-10-05T14:57:36.835Z", "links": {"repository": "https://github.com/chalk/chalk"}}, "downloads": {"weekly": 1000}},
			{"package": {"name": "yeoman-generator", "version": "10.0.0", "date": "2026-10-06T14:57:36.835Z", "links": {"repository": "https://github.com/yeoman/generator"}}, "downloads": {"weekly": 1000}},
			{"package": {"name": "no-repository", "version": "1.0.0", "date": "2026-10-06T14:57:36.835Z", "links": {}}, "downloads": {"weekly": 1000}},
			{"package": {"name": "pid-port", "version": "2.2.0", "date": "2026-10-04T14:57:36.835Z", "links": {"repository": "git+https://github.com/sindresorhus/pid-port.git"}}, "downloads": {"weekly": 1000}}
		], "total": 4}
		"""#
		let cache = try ResponseCache(responses: ["https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=0": search])
		let statistics = await NPMStatistics.load(cache: cache, warnings: WarningCollector())
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(apps: [], posts: [], pages: [page], npmStatistics: statistics, buildDate: Date(timeIntervalSince1970: 1_791_374_400), project: .empty)

		guard case .page(_, let render) = NowPage(page: page, content: content).route.output else {
			Issue.record("The now page is not a page.")
			return
		}

		let html = try render()

		#expect(html.contains("npmjs.com/package/chalk"))
		#expect(html.contains("npmjs.com/package/pid-port"))
		#expect(!html.contains("yeoman-generator"))
		#expect(!html.contains("no-repository"))
	}

	@Test(.temporaryDirectory)
	func `the latest releases list a project once, with its newest release`() async throws {
		let search = #"""
		{"objects": [
			{"package": {"name": "@sindresorhus/is", "version": "7.1.0", "date": "2026-10-06T14:57:36.835Z", "links": {"repository": "https://github.com/sindresorhus/is"}}, "downloads": {"weekly": 1000}}
		], "total": 1}
		"""#
		let cache = try ResponseCache(responses: ["https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=0": search])
		let statistics = await NPMStatistics.load(cache: cache, warnings: WarningCollector())

		func release(_ repository: String, _ tagName: String, day: Int) throws -> OpenSourceRelease {
			OpenSourceRelease(repository: repository, tagName: tagName, url: try #require(URL(string: "https://github.com/\(repository)/releases/tag/\(tagName)")), date: Date(timeIntervalSince1970: 1_791_374_400 - Double(day * 86_400)))
		}

		var activity = RecentActivity()
		activity.releases = try [release("sindresorhus/execa", "v10.1.0", day: 1), release("sindresorhus/execa", "v10.0.0", day: 2), release("sindresorhus/is", "v7.1.0", day: 3)]

		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(apps: [], posts: [], pages: [page], npmStatistics: statistics, recentActivity: activity, buildDate: Date(timeIntervalSince1970: 1_791_374_400), project: .empty)

		guard case .page(_, let render) = NowPage(page: page, content: content).route.output else {
			Issue.record("The now page is not a page.")
			return
		}

		let html = try render()

		#expect(html.contains("execa/releases/tag/v10.1.0"))
		#expect(!html.contains("execa/releases/tag/v10.0.0"))
		#expect(html.contains("is/releases/tag/v7.1.0"))
		#expect(!html.contains("npmjs.com/package/@sindresorhus/is"))
	}

	@Test
	func `the page renders without the network, with the hand-written part and without the parts the build could not get`() async throws {
		let content = try await SiteContent.load(from: .website, externalData: .none, buildDate: Date(timeIntervalSince1970: 1_791_374_400))
		let page = try #require(content.page(.now))

		guard case .page(_, let render) = NowPage(page: page, content: content).route.output else {
			Issue.record("The now page is not a page.")
			return
		}

		let html = try render()

		#expect(html.contains("<h1"))
		#expect(html.contains(try #require(page.frontmatter.status)))
		#expect(html.contains("Newest App"))
		#expect(html.contains(#"id="latest-commits" hidden"#))
		#expect(html.contains("nownownow.com"))
		#expect(!html.contains("Contributions"))
		#expect(!html.contains("On Social Media"))
		#expect(!html.contains("This Week in Open Source"))

		// Every list of numbers has numbers, like the open-source totals, which are left out without npm and contribution data.
		let emptyStatList = try Regex(#"<ul class="[^"]*\b\#(NowPage.Styles.stats.className)\b[^"]*"></ul>"#)
		#expect(html.contains("All Time"))
		#expect(!html.contains(emptyStatList))
	}

	@Test
	func `only the now page can have a status`() async throws {
		await #expect {
			try await MarkdownPage(markdown: "---\ntitle: 'About'\nstatus: 'Busy'\n---\n\nText.", slug: "about")
		} throws: { error in
			let error = error as? ContentError
			return error?.line == 3 && error?.reason.contains("now.md") == true
		}
	}
}
