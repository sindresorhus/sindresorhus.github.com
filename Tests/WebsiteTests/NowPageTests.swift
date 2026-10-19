import Elementary
import Foundation
import SiteKit
import TestSupport
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
		#expect(post.segments == [
			BlueskyPost.Segment(text: "🦄 New: ", link: nil),
			BlueskyPost.Segment(text: "github.com/sindresorhus...", link: #URL("https://github.com/sindresorhus/eslint-cssicorn")),
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
		let json = #"{"totalContributions": \#(counts.sum), "weeks": [{"contributionDays": [\#(days.joined(separator: ","))]}]}"#
		let calendar = try ContributionCalendar(json: json)

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
		let html = try NowPage(page: page, content: content).renderedHTML()
		let section = try #require(html.firstMatch(of: /<h2 id="on-this-day".*?<\/section>/.dotMatchesNewlines())).output
		let rows = section.matches(of: /<a href="[^"]*">([^<]*)<\/a><span[^>]*>([^<]*)<\/span>/)

		#expect(rows.map(\.output.1) == ["same-day", "Test"])
		#expect(rows.map(\.output.2) == ["posted in 2021", "launched in 2019"])
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
			{"package": {"name": "pid-port", "version": "2.2.0", "date": "2026-10-04T14:57:36.835Z", "links": {"repository": "git+https://github.com/sindresorhus/pid-port.git"}}, "downloads": {"weekly": 1000}},
			{"package": {"name": "capital-owner", "version": "1.0.0", "date": "2026-10-03T14:57:36.835Z", "links": {"repository": "https://github.com/SindreSorhus/capital-owner"}}, "downloads": {"weekly": 1000}}
		], "total": 5}
		"""#
		let cache = try ResponseCache.npm(search: search)
		let statistics = await NPMStatistics.load(cache: cache, warnings: WarningCollector())
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(apps: [], posts: [], pages: [page], npmStatistics: statistics, buildDate: Date(timeIntervalSince1970: 1_791_374_400), project: .empty)

		let html = try NowPage(page: page, content: content).renderedHTML()

		#expect(html.contains("npmjs.com/package/chalk"))
		#expect(html.contains("npmjs.com/package/pid-port"))
		// The owner of a link with capitals is the same owner.
		#expect(html.contains("npmjs.com/package/capital-owner"))
		// The repo is read from a link in another form, without its `.git`.
		#expect(statistics.packages.first { $0.name == "pid-port" }?.repository == "sindresorhus/pid-port")
		#expect(!html.contains("yeoman-generator"))
		#expect(!html.contains("no-repository"))
	}

	/**
	The npm downloads while the visitor is on the page run at the average of the last week, so 604,800 downloads a week are 1 a second. They show the section, also without the other numbers. Without npm data, there is no count.
	*/
	@Test
	func `the npm downloads while the visitor is on the page run at the rate of the last week`() async throws {
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		var npmStatistics = NPMStatistics()
		npmStatistics.packages = [NPMStatistics.Package(name: "chalk", version: "6.0.0", description: nil, date: .now, weeklyDownloads: 604_800, dependentCount: nil, repository: "chalk/chalk")]

		// The section, and whether it is hidden.
		func buildingNow(npmStatistics: NPMStatistics) throws -> (html: Substring, isHidden: Bool) {
			let content = SiteContent(apps: [], posts: [], pages: [page], npmStatistics: npmStatistics, buildDate: .now, project: .empty)
			let html = try NowPage(page: page, content: content).renderedHTML()
			let section = try #require(html.firstMatch(of: /<section([^>]*)><h2 id="building-now".*?<\/section>/.dotMatchesNewlines()))
			return (section.output.0, section.output.1.contains("hidden"))
		}

		let section = try buildingNow(npmStatistics: npmStatistics)
		#expect(section.html.contains(#"<running-count class="running-count" data-config="{&quot;perSecond&quot;:1}">0</running-count>"#))
		#expect(!section.isHidden)

		let withoutNPM = try buildingNow(npmStatistics: NPMStatistics())
		#expect(!withoutNPM.html.contains("<running-count"))
		#expect(withoutNPM.isHidden)
	}

	/**
	A package version with a GitHub release is shown as the release, like `is` 7.1.0, and a newer version without a release as the package, like `got` 16.1.0.
	*/
	@Test(.temporaryDirectory)
	func `the latest releases list a project once, with its newest release`() async throws {
		let search = #"""
		{"objects": [
			{"package": {"name": "@sindresorhus/is", "version": "7.1.0", "date": "2026-10-06T14:57:36.835Z", "links": {"repository": "https://github.com/sindresorhus/is"}}, "downloads": {"weekly": 1000}},
			{"package": {"name": "got", "version": "16.1.0", "date": "2026-10-05T14:57:36.835Z", "links": {"repository": "https://github.com/sindresorhus/got"}}, "downloads": {"weekly": 1000}}
		], "total": 2}
		"""#
		let cache = try ResponseCache.npm(search: search)
		let statistics = await NPMStatistics.load(cache: cache, warnings: WarningCollector())

		func release(_ repository: GitHubRepositoryName, _ tagName: String, day: Int) throws -> OpenSourceRelease {
			OpenSourceRelease(repository: repository, tagName: tagName, url: try #require(URL(string: "https://github.com/\(repository)/releases/tag/\(tagName)")), date: Date(timeIntervalSince1970: 1_791_374_400 - Double(day * 86_400)))
		}

		var activity = RecentActivity()
		activity.releases = try [release("sindresorhus/execa", "v10.1.0", day: 1), release("sindresorhus/execa", "v10.0.0", day: 2), release("sindresorhus/is", "v7.1.0", day: 3), release("sindresorhus/got", "v16.0.0", day: 4)]

		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(apps: [], posts: [], pages: [page], npmStatistics: statistics, recentActivity: activity, buildDate: Date(timeIntervalSince1970: 1_791_374_400), project: .empty)

		let html = try NowPage(page: page, content: content).renderedHTML()

		#expect(html.contains("execa/releases/tag/v10.1.0"))
		#expect(!html.contains("execa/releases/tag/v10.0.0"))
		#expect(html.contains("is/releases/tag/v7.1.0"))
		#expect(!html.contains("npmjs.com/package/@sindresorhus/is"))
		#expect(html.contains("npmjs.com/package/got"))
		#expect(!html.contains("got/releases/tag/v16.0.0"))
	}

	@Test
	func `the page renders without the network, with the hand-written part and without the parts the build could not get`() async throws {
		let content = try await SiteContent.website
		let page = try #require(content.page(.now))

		let html = try NowPage(page: page, content: content).renderedHTML()

		#expect(html.contains("<h1"))
		#expect(html.contains(try #require(page.frontmatter.status)))
		#expect(html.contains("Newest App"))
		// The commits load in the browser, so the group is there, with placeholder rows that screen readers skip, and the hidden link to GitHub for when they cannot load.
		#expect(html.contains(#"id="latest-commits""#))
		#expect(!html.contains(#"id="latest-commits" hidden"#))
		#expect(html.components(separatedBy: #"<li aria-hidden="true" class="\#(NowPage.Styles.row.className) \#(NowPage.Styles.stackedRow.className) \#(NowPage.Styles.placeholderRow.className)""#).count - 1 == 5)
		#expect(html.contains(#"<p id="latest-commits-error" hidden"#))
		#expect(html.contains("nownownow.com"))
		#expect(!html.contains("Contributions"))
		#expect(!html.contains("On Social Media"))
		#expect(!html.contains("This Week in Open Source"))

		// The numbers of all the years are on the about page.
		#expect(!html.contains("All Time"))
		#expect(html.contains("/about#\(AboutPage.numbersID)"))
	}

	@Test
	func `the year has the days with contributions, the busiest day, and the repositories with the most commits`() async throws {
		let json = #"""
		{
			"totalContributions": 12,
			"weeks": [
				{"contributionDays": [{"date": "2026-01-01", "contributionCount": 2, "contributionLevel": "FIRST_QUARTILE"}, {"date": "2026-01-02", "contributionCount": 7, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-03", "contributionCount": 0, "contributionLevel": "NONE"}, {"date": "2026-01-04", "contributionCount": 3, "contributionLevel": "SECOND_QUARTILE"}]}
			]
		}
		"""#
		let calendar = try ContributionCalendar(json: json)
		let buildDate = try Date("2026-01-04T12:00:00Z", strategy: .iso8601)
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let totals = try ContributionYear.Totals(json: #"""
		{
			"totalCommitContributions": 12,
			"totalPullRequestContributions": 0,
			"totalPullRequestReviewContributions": 0,
			"totalRepositoryContributions": 0,
			"totalRepositoriesWithContributedCommits": 2,
			"commitContributionsByRepository": [
				{"repository": {"nameWithOwner": "sindresorhus/ky", "url": "https://github.com/sindresorhus/ky", "isPrivate": false}, "contributions": {"totalCount": 1163}},
				{"repository": {"nameWithOwner": "sindresorhus/secret", "url": "https://github.com/sindresorhus/secret", "isPrivate": true}, "contributions": {"totalCount": 500}},
				{"repository": {"nameWithOwner": "chalk/chalk", "url": "https://github.com/chalk/chalk", "isPrivate": false}, "contributions": {"totalCount": 2}},
				{"repository": {"nameWithOwner": "sindresorhus/got", "url": "https://github.com/sindresorhus/got", "isPrivate": false}, "contributions": {"totalCount": 1}}
			]
		}
		"""#)
		let content = SiteContent(apps: [], posts: [], pages: [page], contributionYears: [ContributionYear(year: 2026, calendar: calendar, totals: totals, until: buildDate)], buildDate: buildDate, project: .empty)

		let html = try NowPage(page: page, content: content).renderedHTML()

		#expect(html.contains(">3</span> <span class=\"\(StatCard.Styles.label.className)\">days with contributions</span>"))
		#expect(html.contains(">7</span> <span class=\"\(StatCard.Styles.label.className)\">busiest day, January 2</span>"))
		#expect(html.contains(">2</span> <span class=\"\(StatCard.Styles.label.className)\">repositories committed to</span>"))
		// A private repo, which a personal token can see, is left out.
		#expect(html.contains(#"Most commits went to <a href="https://github.com/sindresorhus/ky">ky</a> (1,163), <a href="https://github.com/chalk/chalk">chalk/chalk</a> (2), and <a href="https://github.com/sindresorhus/got">got</a> (1)."#))
		// The numbers of the open-source work are in their own group, so it is clear that the busiest day is of the contributions. Without apps or posts this year, the group of the apps is left out.
		#expect(html.contains("Open Source</h3>"))
		#expect(!html.contains("Apps and Blog"))
		#expect(!html.contains("secret"))
	}

	@Test
	func `only the now page can have a status`() async throws {
		let error = try await #require(throws: ContentError.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'About'\nstatus: 'Busy'\n---\n\nText.", slug: "about")
		}

		#expect(error.line == 3)
		#expect(error.reason.contains("now.md"))
	}

	/**
	The two reviews are of two different apps, so they do not say the same. The newest review is the last change of the page.
	*/
	@Test
	func `the page shows the two newest reviews of two different apps, with a link to the wall of love`() async throws {
		func app(_ title: String, id: Int) async throws -> App {
			try await App(markdown: "---\ntitle: '\(title)'\nsubtitle: 'An app'\npublicationDate: '2020-01-01'\nplatforms: ['iOS']\nappStoreID: \(id)\n---\n\nText.", slug: title.lowercased())
		}

		func review(_ title: String, date: String) throws -> AppStoreReview {
			AppStoreReview(title: title, text: "A review that is long enough to be shown on the page of the app.", author: "A reviewer", rating: 5, date: try Date(date, strategy: .iso8601))
		}

		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(
			apps: [try await app("First", id: 1), try await app("Second", id: 2)],
			posts: [],
			pages: [page],
			appStoreReviews: [
				1: [try review("Review of the first app", date: "2026-10-06T00:00:00Z"), try review("Older review of the first app", date: "2026-10-05T00:00:00Z")],
				2: [try review("Review of the second app", date: "2026-10-01T00:00:00Z")],
			],
			buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601),
			project: .empty
		)

		let nowPage = NowPage(page: page, content: content)
		let html = try nowPage.renderedHTML()
		#expect(nowPage.sitemapEntry?.lastModified == (try Date("2026-10-06T00:00:00Z", strategy: .iso8601)))
		#expect(html.contains("Recent Reviews"))
		#expect(html.contains("Review of the first app"))
		#expect(html.contains("Review of the second app"))
		#expect(!html.contains("Older review of the first app"))
		#expect(html.contains(#"More on the <a href="/apps/reviews">Wall of Love</a>"#))
	}

	/**
	The version of an app from the day of its launch is the launch, not an update, like in the numbers of the year.
	*/
	@Test
	func `the latest updates leave out the version that an app launched with`() async throws {
		func app(_ title: String, id: Int, publicationDate: String) async throws -> App {
			try await App(markdown: "---\ntitle: '\(title)'\nsubtitle: 'An app'\npublicationDate: '\(publicationDate)'\nplatforms: ['iOS']\nappStoreID: \(id)\n---\n\nText.", slug: title.lowercased())
		}

		func info(id: AppStoreID, version: String, date: String) throws -> AppStoreInfo {
			AppStoreInfo(id: id, version: version, currentVersionReleaseDate: try Date(date, strategy: .iso8601), priceAmount: nil, currencyCode: nil, averageUserRating: nil, userRatingCount: nil, kind: "software", minimumOsVersion: "26.0", supportedDevices: nil)
		}

		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		let content = SiteContent(
			apps: [try await app("Launched", id: 1, publicationDate: "2026-10-01"), try await app("Updated", id: 2, publicationDate: "2020-01-01")],
			posts: [],
			pages: [page],
			appStoreInfo: [
				1: try info(id: 1, version: "1.0", date: "2026-10-01T15:00:00Z"),
				2: try info(id: 2, version: "2.1", date: "2026-10-05T15:00:00Z"),
			],
			buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601),
			project: .empty
		)

		let html = try NowPage(page: page, content: content).renderedHTML()
		let updates = try #require(html.firstMatch(of: /Latest Updates<\/h3>.*?<\/ul>/.dotMatchesNewlines())).output

		#expect(updates.contains(">Updated</a>"))
		#expect(updates.contains(">2.1</span>"))
		#expect(!updates.contains(">Launched</a>"))
	}

	/**
	The week starts at the start of a day, as the GitHub contributions count whole days, so all the numbers of the week count the same days.
	*/
	@Test
	func `the week is the 7 days up to and with the day of the build`() throws {
		let buildDate = try Date("2026-10-13T15:42:00Z", strategy: .iso8601)
		#expect(RecentActivity.weekStart(before: buildDate) == (try Date("2026-10-07T00:00:00Z", strategy: .iso8601)))
	}

	@Test
	func `the week has the contributions, the commits, the issues closed, the pull requests merged from others, and the comments`() async throws {
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		var activity = RecentActivity()
		activity.weekMaintenance = GitHub.Maintenance(closedIssueCount: 83, mergedPullRequestCount: 61)
		activity.weekActivity = GitHub.Activity(contributionCount: 245, commitCount: 171, commentCount: 32)
		let content = SiteContent(apps: [], posts: [], pages: [page], recentActivity: activity, buildDate: try Date("2026-10-13T12:00:00Z", strategy: .iso8601), project: .empty)

		let html = try NowPage(page: page, content: content).renderedHTML()
		#expect(html.contains("This Week in Open Source"))

		for (value, label) in [("245", "contributions"), ("171", "commits"), ("83", "issues closed"), ("61", "pull requests merged from others"), ("32", "comments")] {
			#expect(html.contains(">\(value)</span> <span class=\"\(StatCard.Styles.label.className)\">\(label)</span>"))
		}
	}

	/**
	The issues and the pull requests of the year are with the other numbers of the open-source work, and npm has its own group, after it. A package of an earlier year is not counted. A new package is one in a repo of the account or of the organizations of its projects that was made this year, and it counts as updated too.
	*/
	@Test
	func `the year has the issues closed and the pull requests merged from others, and the npm packages in their own group`() async throws {
		let page = try await MarkdownPage(markdown: "---\ntitle: 'Now'\n---\n\nText.", slug: "now")
		var activity = RecentActivity()
		activity.yearMaintenance = GitHub.Maintenance(closedIssueCount: 2146, mergedPullRequestCount: 303)
		var npmStatistics = NPMStatistics()
		npmStatistics.packages = [
			NPMStatistics.Package(name: "chalk", version: "6.0.0", description: nil, date: try Date("2026-03-01T00:00:00Z", strategy: .iso8601), weeklyDownloads: 1000, dependentCount: nil, repository: "chalk/chalk"),
			NPMStatistics.Package(name: "ora", version: "9.0.0", description: nil, date: try Date("2025-12-31T00:00:00Z", strategy: .iso8601), weeklyDownloads: 5, dependentCount: nil, repository: "sindresorhus/ora"),
			NPMStatistics.Package(name: "new-thing", version: "1.0.0", description: nil, date: try Date("2026-05-01T00:00:00Z", strategy: .iso8601), weeklyDownloads: 5, dependentCount: nil, repository: "sindresorhus/New-Thing"),
		]
		let repositories = try [GitHubRepository](json: #"[{"name": "new-thing", "description": null, "html_url": "https://github.com/sindresorhus/new-thing", "created_at": "2026-04-30T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1, "language": "JavaScript"}, {"name": "ora", "description": null, "html_url": "https://github.com/sindresorhus/ora", "created_at": "2016-04-30T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1, "language": "JavaScript"}]"#)
		let account = GitHub.Account(repositoryCount: 2, followerCount: 1, starCount: 2, maintenance: GitHub.Maintenance(closedIssueCount: 1, mergedPullRequestCount: 1), repositories: repositories)
		let content = SiteContent(apps: [], posts: [], pages: [page], gitHubAccount: account, npmStatistics: npmStatistics, recentActivity: activity, buildDate: try Date("2026-10-13T12:00:00Z", strategy: .iso8601), project: .empty)

		let html = try NowPage(page: page, content: content).renderedHTML()
		let year = try #require(html.split(separator: #"id="year""#).last)
		let parts = year.split(separator: "npm</h3>")
		try #require(parts.count == 2)
		let (openSource, npm) = (parts[0], parts[1])

		#expect(openSource.contains(">2146</span> <span class=\"\(StatCard.Styles.label.className)\">issues closed</span>"))
		#expect(openSource.contains(">303</span> <span class=\"\(StatCard.Styles.label.className)\">pull requests merged from others</span>"))
		#expect(npm.contains(">1</span> <span class=\"\(StatCard.Styles.label.className)\">new package</span>"))
		#expect(npm.contains(">2</span> <span class=\"\(StatCard.Styles.label.className)\">packages updated</span>"))
	}

	/**
	Each week is 7 days up to the last day, so the last week is whole. The days before the first whole week are left out. The count of each day is its day of the month.
	*/
	@Test(arguments: [
		(dayCount: 6, weeklyCounts: []),
		(dayCount: 7, weeklyCounts: [28]),
		// 2 to 8.
		(dayCount: 8, weeklyCounts: [35]),
		// 3 to 9, and 10 to 16.
		(dayCount: 16, weeklyCounts: [42, 91]),
	])
	func `the weekly contributions are the sums of each 7 days up to the last day`(dayCount: Int, weeklyCounts: [Int]) throws {
		let days = (1...dayCount).map { #"{"date": "2026-10-\#($0.formatted(.number.precision(.integerLength(2))))", "contributionCount": \#($0), "contributionLevel": "FIRST_QUARTILE"}"# }
		let json = #"{"totalContributions": 0, "weeks": [{"contributionDays": [\#(days.joined(separator: ","))]}]}"#
		let calendar = try ContributionCalendar(json: json)

		#expect(calendar.weeklyCounts == weeklyCounts)
	}

	@Test
	func `the sparkline goes from zero at the bottom to the highest number at the top, with a dot at the last number`() {
		let html = Sparkline(values: [0, 5, 10], label: "A label").render()

		#expect(html.contains(#"aria-label="A label""#))
		#expect(html.contains(#"d="M0 100L1 50L2 0""#))
		#expect(html.contains(#"d="M2 0h0""#))
	}
}
