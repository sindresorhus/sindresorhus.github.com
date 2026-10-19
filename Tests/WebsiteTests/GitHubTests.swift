import Foundation
import RSS
import SiteKit
import TestSupport
import Testing
@testable import Website

@Suite
struct GitHubTests {
	/**
	The search of the popular repos.
	*/
	private static let popularRepositoriesURL = "https://api.github.com/search/repositories?q=user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20fork:false%20archived:false&sort=stars&order=desc&per_page=30"

	/**
	The search of the closed issues of all time.
	*/
	private static let closedIssuesURL = "https://api.github.com/search/issues?q=is:issue%20is:closed%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette&per_page=1"

	/**
	The search of the pull requests from others that were merged, of all time.
	*/
	private static let mergedPullRequestsURL = "https://api.github.com/search/issues?q=is:pr%20is:merged%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20-author:sindresorhus&per_page=1"

	/**
	The user and the repos of each of the owners, for the account and the recent repos, so the tests do not use the network. An owner that is not given has no repos, and each organization has one follower, so a sum of the followers would show.

	- Parameter repositoriesByOwner: The repos of each owner, from ``repositoryJSON(_:createdAt:stars:isArchived:isFork:)``, newest first for the recent repos.
	*/
	private static func ownerResponses(_ repositoriesByOwner: [String: [String]], accountFollowers: Int = 1) -> [String: String] {
		var responses = [String: String]()

		for owner in GitHub.owners {
			let repositories = repositoriesByOwner[owner] ?? []
			let followers = owner == GitHub.account ? accountFollowers : 1
			responses["https://api.github.com/users/\(owner)"] = #"{"public_repos": \#(repositories.count), "followers": \#(followers)}"#
			responses["https://api.github.com/users/\(owner)/repos?type=owner&per_page=100&page=1"] = "[\(repositories.joined(separator: ", "))]"
			responses["https://api.github.com/users/\(owner)/repos?type=owner&sort=created&per_page=20"] = "[\(repositories.joined(separator: ", "))]"
		}

		return responses
	}

	/**
	A repo in the JSON of the API, like `sindresorhus/ky`.
	*/
	private static func repositoryJSON(_ nameWithOwner: String, createdAt: String = "2014-07-11", stars: Int = 1, isArchived: Bool = false, isFork: Bool = false) -> String {
		#"{"name": "\#(nameWithOwner.split(separator: "/")[1])", "description": null, "html_url": "https://github.com/\#(nameWithOwner)", "created_at": "\#(createdAt)T00:00:00Z", "archived": \#(isArchived), "fork": \#(isFork), "stargazers_count": \#(stars)}"#
	}

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

	/**
	A class without a rule would fail the check of the release notes page.
	*/
	@Test(.temporaryDirectory)
	func `a table in release notes has the container of the prose`() async throws {
		let releases = #"[{"tag_name": "v1.0.0", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false, "body": "| A |\n| - |\n| 1 |"}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": releases]))
		let notesHTML = try #require(try await github.releases(repository: "test").first?.notesHTML)

		#expect(notesHTML.hasPrefix(#"<div class="\#(ProseStyles.tableContainer.className)""#))
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
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [Self.popularRepositoriesURL: result]))
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
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [Self.popularRepositoriesURL: result]))

		#expect(try await github.popularRepositories().first?.summary == "Parse a time like 12:30:45 into seconds")
	}

	/**
	A note in double brackets, like the one of `ama`, is removed whole, without a bracket left over.
	*/
	@Test(.temporaryDirectory)
	func `the summary of a repository removes a note in double brackets`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "ama", "description": "[[I'm slow at replying these days]] Ask me anything!", "html_url": "https://github.com/sindresorhus/ama", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [Self.popularRepositoriesURL: result]))

		#expect(try await github.popularRepositories().first?.summary == "Ask me anything!")
	}

	/**
	The searches of a year count from its start, and the searches of all time have no date.
	*/
	@Test(.temporaryDirectory)
	func `the maintenance since a date searches from the date`() async throws {
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [
			"https://api.github.com/search/issues?q=is:issue%20is:closed%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20closed:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 1234, "incomplete_results": false, "items": []}"#,
			"https://api.github.com/search/issues?q=is:pr%20is:merged%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20-author:sindresorhus%20merged:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 56, "incomplete_results": false, "items": []}"#,
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
	The repos and the stars are of the account and the organizations of the projects, in the order of the owners, and the stars are of the repos that are not forks. The followers are of the account.
	*/
	@Test(.temporaryDirectory)
	func `the account has the repos, the followers, the stars of its repos, and the closed issues and merged pull requests`() async throws {
		let repositories = [
			"sindresorhus": [Self.repositoryJSON("sindresorhus/awesome", stars: 500_000), Self.repositoryJSON("sindresorhus/ky", stars: 17_000, isArchived: true), Self.repositoryJSON("sindresorhus/node", stars: 2, isFork: true)],
			"chalk": [Self.repositoryJSON("chalk/chalk", stars: 23_000)],
			"xojs": [Self.repositoryJSON("xojs/xo", stars: 7000)],
		]
		let github = GitHub(token: nil, cache: try ResponseCache(responses: Self.ownerResponses(repositories, accountFollowers: 84_740).merging([
			Self.closedIssuesURL: #"{"total_count": 26249, "incomplete_results": false, "items": []}"#,
			Self.mergedPullRequestsURL: #"{"total_count": 15974, "incomplete_results": false, "items": []}"#,
		]) { $1 }))
		let account = try await github.account()

		#expect(account.repositoryCount == 5)
		#expect(account.followerCount == 84_740)
		#expect(account.starCount == 547_000)
		#expect(account.repositories.map(\.nameWithOwner) == ["sindresorhus/awesome", "sindresorhus/ky", "sindresorhus/node", "chalk/chalk", "xojs/xo"])
		#expect(account.maintenance.closedIssueCount == 26_249)
		#expect(account.maintenance.mergedPullRequestCount == 15_974)
	}

	/**
	The pages of the repos that the user has are asked for at the same time, so the repos are in the order of the pages, and a repo made since adds a page.
	*/
	@Test(.temporaryDirectory)
	func `the repos of the account are read from every page, in order`() async throws {
		func repositories(page: Int, count: Int) -> String {
			let repositories = (0..<count).map { #"{"name": "\#(page)-\#($0)", "description": null, "html_url": "https://github.com/sindresorhus/\#(page)-\#($0)", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 1}"# }
			return "[\(repositories.joined(separator: ","))]"
		}

		let github = GitHub(token: nil, cache: try ResponseCache(responses: Self.ownerResponses([:]).merging([
			"https://api.github.com/users/sindresorhus": #"{"public_repos": 200, "followers": 1}"#,
			"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=1": repositories(page: 1, count: 100),
			"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=2": repositories(page: 2, count: 100),
			"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=3": repositories(page: 3, count: 1),
			Self.closedIssuesURL: #"{"total_count": 1, "incomplete_results": false, "items": []}"#,
			Self.mergedPullRequestsURL: #"{"total_count": 1, "incomplete_results": false, "items": []}"#,
		]) { $1 }))
		let names = try await github.account().repositories.map(\.name)

		#expect(names.count == 201)
		#expect(names.prefix(2) == ["1-0", "1-1"])
		#expect(names[100] == "2-0")
		#expect(names.last == "3-0")
	}

	/**
	Each owner gives its newest repos, so the newest of all of them come first, also when an organization made one after the account.
	*/
	@Test(.temporaryDirectory)
	func `the recent repositories are the newest of the account and the organizations, without forks and archived repos`() async throws {
		let github = GitHub(token: nil, cache: try ResponseCache(responses: Self.ownerResponses([
			"sindresorhus": [Self.repositoryJSON("sindresorhus/ky", createdAt: "2026-03-01"), Self.repositoryJSON("sindresorhus/node", createdAt: "2026-02-01", isFork: true), Self.repositoryJSON("sindresorhus/awesome", createdAt: "2026-01-01")],
			"soml-lang": [Self.repositoryJSON("soml-lang/soml", createdAt: "2026-10-09")],
			"xojs": [Self.repositoryJSON("xojs/xo", createdAt: "2026-05-01", isArchived: true)],
		])))

		#expect(try await github.recentRepositories().map(\.nameWithOwner) == ["soml-lang/soml", "sindresorhus/ky", "sindresorhus/awesome"])
	}

	@Test
	func `a repository name ignores case, and shows the owner only when it is not the account`() {
		let name: GitHubRepositoryName = "SindreSorhus/Ky"

		#expect(name == "sindresorhus/ky")
		#expect(Set<GitHubRepositoryName>(["sindresorhus/ky", "chalk/chalk"]).contains(name))
		#expect(name.displayName == "Ky")
		#expect(GitHubRepositoryName(nameWithOwner: "chalk/chalk")?.displayName == "chalk/chalk")
		#expect(GitHubRepositoryName(npmRepositoryLink: "git+ssh://git@github.com:chalk/chalk.git#main") == "chalk/chalk")
		#expect(GitHubRepositoryName(nameWithOwner: "sindresorhus") == nil)
		#expect(GitHubRepositoryName(nameWithOwner: "sindresorhus/ky/issues") == nil)
	}

	/**
	A repo of an organization has the owner in its title, so it does not look like a repo of the account.
	*/
	@Test
	func `the new repositories feed describes a repository with its summary, like the now page`() throws {
		let repository = try GitHubRepository(json: #"{"name": "which-path", "description": ":zap: Find the path of a command, like the Unix `which` command", "html_url": "https://github.com/sindresorhus/which-path", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#)
		let organizationRepository = try GitHubRepository(json: #"{"name": "soml", "description": "A config language", "html_url": "https://github.com/soml-lang/soml", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#)
		let content = SiteContent(apps: [], posts: [], pages: [], recentRepositories: [repository, organizationRepository], buildDate: .now, project: .empty)
		let xml = try SiteFeed.newRepositories.feed(content: content).xmlString()

		#expect(xml.contains("<description>Find the path of a command, like the Unix which command</description>"))
		#expect(xml.contains("<title>which-path</title>"))
		#expect(xml.contains("<title>soml-lang/soml</title>"))
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
