import Foundation
import RSS
import SiteKit
import Testing
@testable import Website

@Suite
struct GitHubTests {
	@Test(.temporaryDirectory)
	func `releases are read from every page`() async throws {
		// Fresh cached responses, so the test does not use the network.
		func response(page: Int, releaseCount: Int) -> (url: String, body: String) {
			let url = "https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=\(page)"
			let releases = (0..<releaseCount).map { #"{"tag_name": "v\#(page).\#($0)", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false}"# }
			return (url, "[\(releases.joined(separator: ","))]")
		}

		let responses = [response(page: 1, releaseCount: 100), response(page: 2, releaseCount: 3)]
		let github = GitHub(token: nil, cache: try ResponseCache(responses: Dictionary(uniqueKeysWithValues: responses)))
		let releases = try await github.releases(repository: "test")

		#expect(releases.count == 103)
		#expect(releases.last?.version == "2.2")
	}

	@Test(.temporaryDirectory)
	func `drafts without a publication date are left out`() async throws {
		let releases = #"[{"tag_name": "v2.0.0", "published_at": null, "draft": true, "prerelease": false}, {"tag_name": "v1.0.0", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": releases]))
		let versions = try await github.releases(repository: "test").map(\.version)

		#expect(versions == ["1.0.0"])
	}

	@Test(.temporaryDirectory)
	func `popular repositories are read from the search result, without repos without code or hidden repos, and with descriptions without emoji and notes`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "awesome", "description": "Awesome lists about all kinds of interesting topics", "html_url": "https://github.com/sindresorhus/awesome", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 515161, "language": null}, {"name": "ky", "description": "😎 Tiny :zap: HTTP client based on `fetch` [NOTE: Pull requests are disabled] ❤️", "html_url": "https://github.com/sindresorhus/ky", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 17000, "language": "TypeScript"}, {"name": "awesome-nodejs", "description": "Delightful Node.js packages", "html_url": "https://github.com/sindresorhus/awesome-nodejs", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 67000, "language": null}, {"name": "chalk", "description": "🖍 Terminal string styling done right, 2 colors #1", "html_url": "https://github.com/chalk/chalk", "created_at": "2013-08-03T00:20:36Z", "archived": false, "fork": false, "stargazers_count": 23000, "language": "JavaScript"}, {"name": "ava", "description": "Node.js test runner that lets you develop with confidence", "html_url": "https://github.com/avajs/ava", "created_at": "2014-11-13T19:50:51Z", "archived": false, "fork": false, "stargazers_count": 20000, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/search/repositories?q=user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20fork:false%20archived:false&sort=stars&order=desc&per_page=30": result]))
		let repositories = try await github.popularRepositories()

		// The lists of links, without a language, and the hidden repos, like AVA, are left out.
		#expect(repositories.map(\.name) == ["ky", "chalk"])
		#expect(repositories.first?.stars == 17_000)
		#expect(repositories.first?.summary == "Tiny HTTP client based on fetch")

		// An emoji without the emoji variation selector is removed too, but digits and `#` stay, although Unicode counts them as emoji.
		#expect(repositories.last?.summary == "Terminal string styling done right, 2 colors #1")
	}

	/**
	An emoji code is a whole word, like `:zap:`, so the `:30:` in a time stays.
	*/
	@Test(.temporaryDirectory)
	func `the summary of a repository keeps times and removes emoji codes next to each other`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "parse-time", "description": ":unicorn::sparkles: Parse a time like 12:30:45 into seconds :zap:", "html_url": "https://github.com/sindresorhus/parse-time", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/search/repositories?q=user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20fork:false%20archived:false&sort=stars&order=desc&per_page=30": result]))

		#expect(try await github.popularRepositories().first?.summary == "Parse a time like 12:30:45 into seconds")
	}

	/**
	A note in double brackets, like the one of `ama`, is removed whole, without a bracket left over.
	*/
	@Test(.temporaryDirectory)
	func `the summary of a repository removes a note in double brackets`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "ama", "description": "[[I'm slow at replying these days]] Ask me anything!", "html_url": "https://github.com/sindresorhus/ama", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/search/repositories?q=user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20fork:false%20archived:false&sort=stars&order=desc&per_page=30": result]))

		#expect(try await github.popularRepositories().first?.summary == "Ask me anything!")
	}

	/**
	The searches of a year count from its start, and the searches of all time have no date.
	*/
	@Test(.temporaryDirectory)
	func `the maintenance since a date searches from the date`() async throws {
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [
			"https://api.github.com/search/issues?q=is:issue%20is:closed%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20closed:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 1234, "incomplete_results": false, "items": []}"#,
			"https://api.github.com/search/issues?q=is:pr%20is:merged%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20-author:sindresorhus%20merged:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 56, "incomplete_results": false, "items": []}"#,
		]))
		let maintenance = try await github.maintenance(since: Date(year: 2026, month: 1, day: 1))

		#expect(maintenance.closedIssueCount == 1234)
		#expect(maintenance.mergedPullRequestCount == 56)
	}

	/**
	GitHub stops a search that takes too long, and its count is then too low, so it is an error instead of a wrong number.
	*/
	@Test(.temporaryDirectory)
	func `an incomplete search result is an error`() async throws {
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [
			"https://api.github.com/search/issues?q=is:issue%20is:closed&per_page=1": #"{"total_count": 12, "incomplete_results": true, "items": [{"number": 1}]}"#,
			"https://api.github.com/search/issues?q=is:pr%20is:merged&per_page=1": #"{"total_count": 34, "incomplete_results": false, "items": [{"number": 2}]}"#,
		]))

		await #expect(throws: DecodingError.self) {
			try await github.issueCount(matching: "is:issue is:closed")
		}

		#expect(try await github.issueCount(matching: "is:pr is:merged") == 34)
	}

	/**
	The stars are of the repos that are not forks.
	*/
	@Test(.temporaryDirectory)
	func `the account has the repos, the followers, the stars of its repos, and the closed issues and merged pull requests`() async throws {
		let user = #"{"public_repos": 3, "followers": 84740}"#
		let repositories = #"[{"name": "awesome", "description": null, "html_url": "https://github.com/sindresorhus/awesome", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 500000, "language": null}, {"name": "ky", "description": null, "html_url": "https://github.com/sindresorhus/ky", "created_at": "2018-07-11T13:42:37Z", "archived": true, "fork": false, "stargazers_count": 17000, "language": "TypeScript"}, {"name": "node", "description": null, "html_url": "https://github.com/sindresorhus/node", "created_at": "2015-07-11T13:42:37Z", "archived": false, "fork": true, "stargazers_count": 2, "language": "JavaScript"}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [
			"https://api.github.com/users/sindresorhus": user,
			"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=1": repositories,
			"https://api.github.com/search/issues?q=is:issue%20is:closed%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang&per_page=1": #"{"total_count": 26249, "incomplete_results": false, "items": []}"#,
			"https://api.github.com/search/issues?q=is:pr%20is:merged%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20-author:sindresorhus&per_page=1": #"{"total_count": 15974, "incomplete_results": false, "items": []}"#,
		]))
		let account = try await github.account()

		#expect(account.repositoryCount == 3)
		#expect(account.followerCount == 84_740)
		#expect(account.starCount == 517_000)
		#expect(account.repositories.map(\.nameWithOwner) == ["sindresorhus/awesome", "sindresorhus/ky", "sindresorhus/node"])
		#expect(account.maintenance.closedIssueCount == 26_249)
		#expect(account.maintenance.mergedPullRequestCount == 15_974)
	}

	@Test
	func `the new repositories feed describes a repository with its summary, like the now page`() throws {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let repository = try decoder.decode(GitHubRepository.self, from: Data(#"{"name": "which-path", "description": ":zap: Find the path of a command, like the Unix `which` command", "html_url": "https://github.com/sindresorhus/which-path", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#.utf8))
		let content = SiteContent(apps: [], posts: [], pages: [], recentRepositories: [repository], buildDate: .now, project: .empty)

		#expect(try SiteFeed.newRepositories.feed(content: content).xmlString().contains("<description>Find the path of a command, like the Unix which command</description>"))
	}

	@Test
	func `the release notes feed leaves out the launch and links each release to its heading`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nreleasesRepository: 'test'\n---\n\nText.", slug: "test")
		let releaseNotes = try #require(app.releaseNotes)
		let releases = [
			GitHubRelease(tagName: "v1.1.0", publishedAt: Date(timeIntervalSince1970: 1_780_000_000), body: nil, isDraft: false, isPrerelease: false, notesHTML: "<p>Fixed a bug.</p>"),
			GitHubRelease(tagName: "v1.0.0", publishedAt: Date(timeIntervalSince1970: 1_770_000_000), body: nil, isDraft: false, isPrerelease: false),
		]

		let xml = try Feed.releaseNotes(of: app, at: releaseNotes, releases: releases).xmlString()

		#expect(xml.contains("<title>1.1.0</title>"))
		#expect(xml.contains("<link>https://sindresorhus.com/test/release-notes#1.1.0</link>"))
		#expect(xml.contains("Fixed a bug."))
		#expect(!xml.contains("<title>1.0.0</title>"))
	}
}
