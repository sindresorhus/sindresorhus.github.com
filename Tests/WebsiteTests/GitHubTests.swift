import Foundation
import RSS
@testable import SiteKit
import SOML
import Subprocess
import TestSupport
import Testing
@testable import Website

struct GitHubTests {
	@Test
	func `an environment token takes precedence without launching the CLI`() async {
		#expect(await GitHub.defaultToken(environment: ["GITHUB_TOKEN": "configured", "PATH": "/missing"]) == "configured")
		#expect(await GitHub.defaultToken(environment: ["PATH": "/missing"]) == nil)
	}

	@Test(.temporaryDirectory, arguments: [
		(script: "printf '  fixture-token \\n'", expected: Optional("fixture-token")),
		(script: "printf '  \\n'", expected: Optional<String>.none),
		(script: "printf 'rejected-token'; exit 1", expected: Optional<String>.none),
	])
	func `CLI token resolution trims successful output and ignores failed commands`(script: String, expected: String?) async throws {
		let directory = try URL.temporaryDirectory()
		let executable = directory.appending(path: "gh")
		try Data("#!/bin/sh\n\(script)\n".utf8).write(to: executable)
		#expect(try await run(.name("chmod"), arguments: ["+x", executable.path(percentEncoded: false)], output: .discarded).terminationStatus.isSuccess)

		#expect(await GitHub.defaultToken(environment: ["PATH": directory.path(percentEncoded: false)]) == expected)
	}

	@Test(.temporaryDirectory)
	func `contribution requests encode typed year boundaries and omit the current end date`() async throws {
		struct Request: Encodable {
			let query: String
			let variables: [String: String]
		}

		let fields = "contributionCalendar { totalContributions weeks { contributionDays { date contributionCount } } } totalCommitContributions totalPullRequestContributions totalPullRequestReviewContributions totalRepositoryContributions totalRepositoriesWithContributedCommits commitContributionsByRepository(maxRepositories: 5) { repository { nameWithOwner url isPrivate } contributions { totalCount } }"
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys
		var responses = [(body: String, response: String)]()

		for year in 2010...2026 {
			let query: String
			var variables = ["from": "\(year)-01-01T00:00:00Z"]

			if year == 2026 {
				query = "query($from: DateTime!) { user(login: \"sindresorhus\") { contributionsCollection(from: $from) { \(fields) } } }"
			} else {
				query = "query($from: DateTime!, $to: DateTime!) { user(login: \"sindresorhus\") { contributionsCollection(from: $from, to: $to) { \(fields) } } }"
				variables["to"] = "\(year)-12-31T23:59:59Z"
			}

			let body = String(decoding: try encoder.encode(Request(query: query, variables: variables)), as: UTF8.self)
			let response = #"{"data":{"user":{"contributionsCollection":{"contributionCalendar":{"totalContributions":1,"weeks":[{"contributionDays":[{"date":"\#(year)-01-01","contributionCount":1}]}]},"totalCommitContributions":2,"totalPullRequestContributions":3,"totalPullRequestReviewContributions":4,"totalRepositoryContributions":5,"totalRepositoriesWithContributedCommits":6,"commitContributionsByRepository":[{"repository":{"nameWithOwner":"chalk/chalk","url":"https://github.com/chalk/chalk","isPrivate":false},"contributions":{"totalCount":7}}]}}}}"#
			responses.append((body, response))
		}

		let cache = try Self.graphQLCache(responses)
		let years = try await ContributionYear.load(github: GitHub(token: "fixture", cache: cache), until: Date(year: 2026, month: 10, day: 1))
		#expect(years.map(\.year) == Array(2010...2026))
		#expect(years.map(\.totals.repositoryCommits.first?.count) == Array(repeating: Optional(7), count: 17))
		#expect(years.first?.days.first?.date.description == "2010-01-01")
		#expect(years.last?.days.first?.date.description == "2026-01-01")
		#expect(cache.warnings.isEmpty)
	}

	@Test(.temporaryDirectory)
	func `release loading sorts by publication date and keeps ties in endpoint order`() async throws {
		let response = #"[{"tag_name":"v1.1.0","published_at":"2026-01-01T00:00:00Z","draft":false,"prerelease":false,"body":"Old"},{"tag_name":"v3.0.0","published_at":"2026-10-01T00:00:00Z","draft":false,"prerelease":false,"body":"Newest first tie"},{"tag_name":"v2.0.0","published_at":"2026-10-01T00:00:00Z","draft":false,"prerelease":false,"body":"Newest second tie"}]"#
		let cache = try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": response])
		let releases = try await GitHub(token: nil, cache: cache).releases(repository: #repository("sindresorhus/test"))
		let app = try await App(publicationDate: "2025-01-01", frontmatter: "releasesRepository: 'sindresorhus/test'")
		let page = ReleaseNotesPage(app: app, releaseNotes: try #require(app.releaseNotes), releases: releases)

		#expect(releases.map(\.version) == ["3.0.0", "2.0.0", "1.1.0"])
		#expect(releases.map(\.notesHTML) == ["<p>Newest first tie</p>\n", "<p>Newest second tie</p>\n", "<p>Old</p>\n"])
		#expect(page.metadata.description?.contains("The latest is 3.0.0") == true)
		#expect(page.sitemapEntry.lastModified == SOML.Date(Date(year: 2026, month: 10, day: 1)))
		#expect(AppListing(app: app, releases: releases).currentVersionDate?.description == "2026-10-01")
	}

	@Test
	func `feed routes share feed identity while retaining the distinct channel website`() async throws {
		let content = SiteContent.test()

		for source in SiteFeed.allCases {
			let route = Route.feed(source.link, source.feed(content: content))
			let xml = String(decoding: try await route.renderedFile(), as: UTF8.self)
			#expect(route.path == source.link.path)
			#expect(xml.contains("<title>\(source.link.title)</title>"))
			#expect(xml.contains("<link>https://sindresorhus.com</link>"))
			#expect(xml.contains("href=\"\(source.link.path.absoluteURL.absoluteString)\""))
			#expect(xml.contains("<language>en</language>"))
		}
	}

	/**
	Caches exact GraphQL POST bodies, so query-variable encoding is exercised without network requests.
	*/
	private static func graphQLCache(_ responses: [(body: String, response: String)]) throws -> ResponseCache {
		let directory = try URL.temporaryDirectory()

		for response in responses {
			var request = URLRequest(url: #URL("https://api.github.com/graphql"))
			request.httpMethod = "POST"
			request.httpBody = Data(response.body.utf8)
			try ResponseCache.writeFixture(for: request, body: Data(response.response.utf8), directory: directory)
		}

		return ResponseCache(directory: directory, maximumAge: .seconds(3600))
	}

	@Test(.temporaryDirectory)
	func `query owned variables preserve optional omission and exact request encoding`() async throws {
		struct Variables: Encodable, Sendable {
			let from: String
			let after: String?
		}

		struct User: Decodable, Sendable {
			let count: Int
		}

		let cache = try Self.graphQLCache([
			(body: #"{"query":"without"}"#, response: #"{"data":{"user":{"count":1}}}"#),
			(body: #"{"query":"with","variables":{"from":"start"}}"#, response: #"{"data":{"user":{"count":2}}}"#),
			(body: #"{"query":"with","variables":{"after":"cursor","from":"start"}}"#, response: #"{"data":{"user":{"count":3}}}"#),
		])
		let graphQL = try #require(GitHub(token: "fixture", cache: cache).graphQL)
		let without = try await graphQL.data(GitHub.GraphQL.UserResponse<User>.self, query: "without")
		let first = try await graphQL.data(GitHub.GraphQL.UserResponse<User>.self, query: "with", variables: Variables(from: "start", after: nil))
		let next = try await graphQL.data(GitHub.GraphQL.UserResponse<User>.self, query: "with", variables: Variables(from: "start", after: "cursor"))

		#expect(without.user.count == 1)
		#expect(first.user.count == 2)
		#expect(next.user.count == 3)
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(GitHub.GraphQL.UserResponse<User>.self, from: Data(#"{"user":null}"#.utf8))
		}
	}

	@Test(.temporaryDirectory)
	func `activity hands off the cursor and stops at old updates despite another page`() async throws {
		struct Request: Encodable {
			let query: String
			let variables: [String: String]
		}

		let query = "query($from: DateTime!, $after: String) { user(login: \"\(GitHub.account)\") { contributionsCollection(from: $from) { totalCommitContributions contributionCalendar { totalContributions } } issueComments(first: 100, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) { nodes { createdAt updatedAt } pageInfo { hasNextPage endCursor } } } }"
		let start = Date(year: 2026, month: 10, day: 1)
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys

		/**
		The expected request body uses wire-key dictionaries independently of the production variables structure.
		*/
		func body(after cursor: String?) throws -> String {
			var variables = ["from": "2026-10-01T00:00:00Z"]
			variables["after"] = cursor
			return String(decoding: try encoder.encode(Request(query: query, variables: variables)), as: UTF8.self)
		}

		// A comment created before the interval but updated in it does not stop pagination.
		let first = #"{"data":{"user":{"contributionsCollection":{"totalCommitContributions":7,"contributionCalendar":{"totalContributions":11}},"issueComments":{"nodes":[{"createdAt":"2026-10-02T00:00:00Z","updatedAt":"2026-10-03T00:00:00Z"},{"createdAt":"2026-09-01T00:00:00Z","updatedAt":"2026-10-02T00:00:00Z"}],"pageInfo":{"hasNextPage":true,"endCursor":"second"}}}}}"#
		// A genuinely old update stops pagination even though the server has another cursor.
		let second = #"{"data":{"user":{"contributionsCollection":{"totalCommitContributions":7,"contributionCalendar":{"totalContributions":11}},"issueComments":{"nodes":[{"createdAt":"2026-10-01T00:00:00Z","updatedAt":"2026-10-01T00:00:00Z"},{"createdAt":"2026-09-01T00:00:00Z","updatedAt":"2026-09-30T00:00:00Z"}],"pageInfo":{"hasNextPage":true,"endCursor":"unused"}}}}}"#
		let cache = try Self.graphQLCache([
			(body: body(after: nil), response: first),
			(body: body(after: "second"), response: second),
			// An unintended third request fails from its fresh fixture instead of reaching the network.
			(body: body(after: "unused"), response: #"{"data":{"user":null}}"#),
		])
		let activity = try #require(try await GitHub(token: "fixture", cache: cache).activity(since: start))

		#expect(activity.commentCount == 2)
		#expect(activity.commitCount == 7)
		#expect(activity.contributionCount == 11)
	}

	@Test
	func `a GraphQL next page requires its cursor and preserves invalid field failures`() throws {
		let decoder = JSONDecoder()
		let end = try decoder.decode(GitHub.GraphQL.Continuation.self, from: Data(#"{"hasNextPage":false,"endCursor":null}"#.utf8))
		let next = try decoder.decode(GitHub.GraphQL.Continuation.self, from: Data(#"{"hasNextPage":true,"endCursor":"next"}"#.utf8))

		guard
			case .end = end,
			case .after("next") = next
		else {
			Issue.record("The continuation did not retain its required cursor.")
			return
		}

		for json in [#"{"hasNextPage":true,"endCursor":null}"#, #"{"hasNextPage":true}"#, #"{"hasNextPage":false,"endCursor":12}"#] {
			#expect(throws: DecodingError.self) {
				try decoder.decode(GitHub.GraphQL.Continuation.self, from: Data(json.utf8))
			}
		}
	}

	@Test
	func `the REST repository identity comes from full name rather than navigation topology`() throws {
		let repository = try GitHubRepository(json: #"{"name":"short-name","full_name":"Chalk/Canonical","html_url":"https://example.com/navigation/alias","created_at":"2026-01-01T00:00:00Z","archived":false,"fork":false,"stargazers_count":1}"#)

		#expect(repository.nameWithOwner == #repository("chalk/canonical"))
		#expect(repository.displayName == "Chalk/Canonical")
		#expect(repository.url.absoluteString == "https://example.com/navigation/alias")
		let error = try #require(throws: DecodingError.self) {
			try GitHubRepository(json: #"{"name":"short-name","full_name":"invalid","html_url":"https://example.com/navigation/alias","created_at":"2026-01-01T00:00:00Z","archived":false,"fork":false,"stargazers_count":1}"#)
		}

		guard case .dataCorrupted(let context) = error else {
			Issue.record("An invalid repository must be a value decoding error.")
			return
		}

		#expect(context.codingPath.map(\.stringValue) == ["full_name"])
		#expect(context.debugDescription.contains("A GitHub repo is an owner and a name"))
		#expect(try GitHubRepositoryName(validating: "Chalk/Canonical").description == "Chalk/Canonical")
	}

	@Test(.temporaryDirectory)
	func `the GitHub release event variants retain published payloads and ignore incomplete alternatives`() async throws {
		let release = #"{"tag_name":"v1.2.3","html_url":"https://github.com/chalk/chalk/releases/v1.2.3","draft":false,"prerelease":false}"#
		let events = #"[{"type":"UnknownEvent","repo":{"name":"chalk/chalk"},"created_at":"2026-01-01T00:00:00Z","payload":{"action":null,"release":null}},{"type":"ReleaseEvent","repo":{"name":"chalk/chalk"},"created_at":"2026-01-02T00:00:00Z","payload":{"action":"published","release":\#(release)}},{"type":"ReleaseEvent","repo":{"name":"chalk/chalk"},"created_at":"2026-01-03T00:00:00Z","payload":{"action":"published"}}]"#
		let cache = try ResponseCache(responses: ["https://api.github.com/users/sindresorhus/events/public?per_page=100": events])
		let releases = try await GitHub(token: nil, cache: cache).latestReleases()

		#expect(releases.count == 1)
		#expect(releases.first?.repository == #repository("chalk/chalk"))
		#expect(releases.first?.version == "1.2.3")
		#expect(releases.first?.date.isoDay == "2026-01-02")
	}

	@Test(.temporaryDirectory, arguments: [#"{"action":12}"#, #"{"release":12}"#])
	func `wrongly typed known release event fields fail even on an ignored event`(payload: String) async throws {
		let events = #"[{"type":"UnknownEvent","repo":{"name":"chalk/chalk"},"created_at":"2026-01-01T00:00:00Z","payload":\#(payload)}]"#
		let cache = try ResponseCache(responses: ["https://api.github.com/users/sindresorhus/events/public?per_page=100": events])

		await #expect(throws: DecodingError.self) {
			try await GitHub(token: nil, cache: cache).latestReleases()
		}
	}

	@Test(.temporaryDirectory)
	func `the GitHub profile keeps its jointly returned contributions and counts together`() async throws {
		let directory = try URL.temporaryDirectory()
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys
		var request = URLRequest(url: #URL("https://api.github.com/graphql"))
		request.httpMethod = "POST"
		request.httpBody = try encoder.encode(["query": "{ user(login: \"sindresorhus\") { sponsors { totalCount } issueComments { totalCount } contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount } } } } } }"])
		let response = #"{"data":{"user":{"sponsors":{"totalCount":12},"issueComments":{"totalCount":34},"contributionsCollection":{"contributionCalendar":{"totalContributions":56,"weeks":[]}}}}}"#
		try ResponseCache.writeFixture(for: request, body: Data(response.utf8), directory: directory)
		let cache = ResponseCache(directory: directory, maximumAge: .seconds(3600))
		let profile = try #require(try await GitHub(token: "fixture", cache: cache).profile())

		#expect(profile.contributions.totalCount == 56)
		#expect(profile.sponsorCount == 12)
		#expect(profile.commentCount == 34)
		#expect(try await GitHub(token: nil, cache: cache).profile() == nil)
	}

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
	private static func repositoryJSON(
		_ nameWithOwner: String,
		createdAt: String = "2014-07-11",
		stars: Int = 1,
		isArchived: Bool = false,
		isFork: Bool = false
	) -> String {
		#"{"name": "\#(nameWithOwner.split(separator: "/")[1])", "description": null, "full_name": "\#(nameWithOwner)", "html_url": "https://github.com/\#(nameWithOwner)", "created_at": "\#(createdAt)T00:00:00Z", "archived": \#(isArchived), "fork": \#(isFork), "stargazers_count": \#(stars)}"#
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
		let releases = try await github.releases(repository: #repository("sindresorhus/test"))

		#expect(releases.count == 103)
		#expect(releases.allSatisfy { $0.notesHTML.isEmpty })
		#expect(releases.last?.version == "2.2")
	}

	/**
	A class without a rule would fail the check of the release notes page.
	*/
	@Test(.temporaryDirectory)
	func `a table in release notes has the container of the prose`() async throws {
		let releases = #"[{"tag_name": "v1.0.0", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false, "body": "| A |\n| - |\n| 1 |"}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": releases]))
		let notesHTML = try #require(try await github.releases(repository: #repository("sindresorhus/test")).first?.notesHTML)

		#expect(notesHTML.hasPrefix(#"<div class="\#(ProseStyles.tableContainer.className)""#))
	}

	/**
	A relative link of a release note would be a broken link of the site, which fails a scheduled build with no commit that caused it.
	*/
	@Test(.temporaryDirectory)
	func `a relative link in release notes goes where it goes on GitHub`() async throws {
		let releases = #"[{"tag_name": "v1.0.0", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false, "body": "See [the docs](docs/usage.md), [#12](../issues/12), [usage](#usage), and [Dato](https://sindresorhus.com/dato)."}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": releases]))
		let notesHTML = try #require(try await github.releases(repository: #repository("sindresorhus/test")).first?.notesHTML)

		#expect(notesHTML.contains(#"href="https://github.com/sindresorhus/test/releases/tag/docs/usage.md""#))
		#expect(notesHTML.contains(#"href="https://github.com/sindresorhus/test/releases/issues/12""#))
		#expect(notesHTML.contains(##"href="#usage""##))
		#expect(notesHTML.contains(#"href="https://sindresorhus.com/dato""#))
	}

	@Test(.temporaryDirectory)
	func `drafts without a publication date are left out`() async throws {
		let releases = #"[{"tag_name": "v2.0.0", "published_at": null, "draft": true, "prerelease": false}, {"tag_name": "v1.0.0", "published_at": "2026-01-01T00:00:00Z", "draft": false, "prerelease": false}]"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100&page=1": releases]))
		let versions = try await github.releases(repository: #repository("sindresorhus/test")).map(\.version)

		#expect(versions == ["1.0.0"])
	}

	@Test(.temporaryDirectory)
	func `popular repositories are read from the search result, without repos without code or hidden repos, and with descriptions without emoji and notes`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "awesome", "description": "Awesome lists about all kinds of interesting topics", "full_name": "sindresorhus/awesome", "html_url": "https://github.com/sindresorhus/awesome", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 515161, "language": null}, {"name": "ky", "description": "😎 Tiny :zap: HTTP client based on `fetch` [NOTE: Pull requests are disabled] ❤️", "full_name": "sindresorhus/ky", "html_url": "https://github.com/sindresorhus/ky", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 17000, "language": "TypeScript"}, {"name": "awesome-nodejs", "description": "Delightful Node.js packages", "full_name": "sindresorhus/awesome-nodejs", "html_url": "https://github.com/sindresorhus/awesome-nodejs", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 67000, "language": null}, {"name": "chalk", "description": "🖍 Terminal string styling done right, 2 colors #1", "full_name": "chalk/chalk", "html_url": "https://github.com/chalk/chalk", "created_at": "2013-08-03T00:20:36Z", "archived": false, "fork": false, "stargazers_count": 23000, "language": "JavaScript"}, {"name": "ava", "description": "Node.js test runner that lets you develop with confidence", "full_name": "avajs/ava", "html_url": "https://github.com/avajs/ava", "created_at": "2014-11-13T19:50:51Z", "archived": false, "fork": false, "stargazers_count": 20000, "language": "JavaScript"}]}"#
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
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "parse-time", "description": ":unicorn::sparkles: Parse a time like 12:30:45 into seconds :zap:", "full_name": "sindresorhus/parse-time", "html_url": "https://github.com/sindresorhus/parse-time", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [Self.popularRepositoriesURL: result]))

		#expect(try await github.popularRepositories().first?.summary == "Parse a time like 12:30:45 into seconds")
	}

	/**
	A note in double brackets, like the one of `ama`, is removed whole, without a bracket left over.
	*/
	@Test(.temporaryDirectory)
	func `the summary of a repository removes a note in double brackets`() async throws {
		let result = #"{"total_count": 1, "incomplete_results": false, "items": [{"name": "ama", "description": "[[I'm slow at replying these days]] Ask me anything!", "full_name": "sindresorhus/ama", "html_url": "https://github.com/sindresorhus/ama", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10, "language": "JavaScript"}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: [Self.popularRepositoriesURL: result]))

		#expect(try await github.popularRepositories().first?.summary == "Ask me anything!")
	}

	/**
	The searches of a year count from its start, and the searches of all time have no date.
	*/
	@Test(.temporaryDirectory)
	func `the maintenance since a date searches from the date`() async throws {
		let github = GitHub(
			token: nil,
			cache: try ResponseCache(
				responses: [
					"https://api.github.com/search/issues?q=is:issue%20is:closed%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20closed:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 1234, "incomplete_results": false, "items": []}"#,
					"https://api.github.com/search/issues?q=is:pr%20is:merged%20user:sindresorhus%20user:chalk%20user:avajs%20user:xojs%20user:soml-lang%20user:simple-color-palette%20-author:sindresorhus%20merged:%3E%3D2026-01-01T00:00:00Z&per_page=1": #"{"total_count": 56, "incomplete_results": false, "items": []}"#,
				]
			)
		)
		let maintenance = try await github.maintenance(since: Date(year: 2026, month: 1, day: 1))

		#expect(maintenance.closedIssueCount == 1234)
		#expect(maintenance.mergedPullRequestCount == 56)
	}

	/**
	GitHub stops a search that takes too long, and its count is then too low, so it is an error instead of a wrong number.
	*/
	@Test(.temporaryDirectory)
	func `an incomplete search result is an error`() async throws {
		let github = GitHub(
			token: nil,
			cache: try ResponseCache(
				responses: [
					"https://api.github.com/search/issues?q=is:issue%20is:closed&per_page=1": #"{"total_count": 12, "incomplete_results": true, "items": [{"number": 1}]}"#,
					"https://api.github.com/search/issues?q=is:pr%20is:merged&per_page=1": #"{"total_count": 34, "incomplete_results": false, "items": [{"number": 2}]}"#,
				]
			)
		)

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
		let github = GitHub(
			token: nil,
			cache: try ResponseCache(
				responses: Self.ownerResponses(repositories, accountFollowers: 84_740).merging(
					[
						Self.closedIssuesURL: #"{"total_count": 26249, "incomplete_results": false, "items": []}"#,
						Self.mergedPullRequestsURL: #"{"total_count": 15974, "incomplete_results": false, "items": []}"#,
					]
				) { $1 }
			)
		)
		let account = try await github.account()

		#expect(account.repositoryCount == 5)
		#expect(account.followerCount == 84_740)
		#expect(account.starCount == 547_000)
		#expect(account.repositories.map(\.nameWithOwner) == [#repository("sindresorhus/awesome"), #repository("sindresorhus/ky"), #repository("sindresorhus/node"), #repository("chalk/chalk"), #repository("xojs/xo")])
		#expect(account.maintenance.closedIssueCount == 26_249)
		#expect(account.maintenance.mergedPullRequestCount == 15_974)
	}

	/**
	The pages of the repos that the user has are asked for at the same time, so the repos are in the order of the pages, and a repo made since adds a page.
	*/
	@Test(.temporaryDirectory)
	func `the repos of the account are read from every page, in order`() async throws {
		func repositories(page: Int, count: Int) -> String {
			let repositories = (0..<count).map { #"{"name": "\#(page)-\#($0)", "description": null, "full_name": "sindresorhus/\#(page)-\#($0)", "html_url": "https://github.com/sindresorhus/\#(page)-\#($0)", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 1}"# }
			return "[\(repositories.joined(separator: ","))]"
		}

		let github = GitHub(
			token: nil,
			cache: try ResponseCache(
				responses: Self.ownerResponses([:]).merging(
					[
						"https://api.github.com/users/sindresorhus": #"{"public_repos": 200, "followers": 1}"#,
						"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=1": repositories(page: 1, count: 100),
						"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=2": repositories(page: 2, count: 100),
						"https://api.github.com/users/sindresorhus/repos?type=owner&per_page=100&page=3": repositories(page: 3, count: 1),
						Self.closedIssuesURL: #"{"total_count": 1, "incomplete_results": false, "items": []}"#,
						Self.mergedPullRequestsURL: #"{"total_count": 1, "incomplete_results": false, "items": []}"#,
					]
				) { $1 }
			)
		)
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
		let github = GitHub(
			token: nil,
			cache: try ResponseCache(
				responses: Self.ownerResponses(
					[
						"sindresorhus": [Self.repositoryJSON("sindresorhus/ky", createdAt: "2026-03-01"), Self.repositoryJSON("sindresorhus/node", createdAt: "2026-02-01", isFork: true), Self.repositoryJSON("sindresorhus/awesome", createdAt: "2026-01-01")],
						"soml-lang": [Self.repositoryJSON("soml-lang/soml", createdAt: "2026-10-09")],
						"xojs": [Self.repositoryJSON("xojs/xo", createdAt: "2026-05-01", isArchived: true)],
					]
				)
			)
		)

		#expect(try await github.recentRepositories().map(\.nameWithOwner) == [#repository("soml-lang/soml"), #repository("sindresorhus/ky"), #repository("sindresorhus/awesome")])
	}

	@Test
	func `a repository name ignores case, and shows the owner only when it is not the account`() {
		let name = #repository("SindreSorhus/Ky")

		#expect(name == #repository("sindresorhus/ky"))
		#expect(Set([#repository("sindresorhus/ky"), #repository("chalk/chalk")]).contains(name))
		#expect(name.displayName == "Ky")
		#expect(GitHubRepositoryName(nameWithOwner: "chalk/chalk")?.displayName == "chalk/chalk")
		#expect(GitHubRepositoryName(npmRepositoryLink: "git+ssh://git@github.com:chalk/chalk.git#main") == #repository("chalk/chalk"))
		#expect(GitHubRepositoryName(npmRepositoryLink: "addyosmani/critical") == #repository("addyosmani/critical"))
		#expect(GitHubRepositoryName(npmRepositoryLink: "gitlab:owner/name") == nil)
		#expect(GitHubRepositoryName(nameWithOwner: "sindresorhus") == nil)
		#expect(GitHubRepositoryName(nameWithOwner: "sindresorhus/ky/issues") == nil)
	}

	/**
	A repo of an organization has the owner in its title, so it does not look like a repo of the account.
	*/
	@Test
	func `the new repositories feed describes a repository with its summary, like the now page`() throws {
		let repository = try GitHubRepository(json: #"{"name": "which-path", "description": ":zap: Find the path of a command, like the Unix `which` command", "full_name": "sindresorhus/which-path", "html_url": "https://github.com/sindresorhus/which-path", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#)
		let organizationRepository = try GitHubRepository(json: #"{"name": "soml", "description": "A config language", "full_name": "soml-lang/soml", "html_url": "https://github.com/soml-lang/soml", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#)
		let content = SiteContent.test(recentRepositories: [repository, organizationRepository])
		let xml = try SiteFeed.newRepositories.feed(content: content).xmlString()

		#expect(xml.contains("<description>Find the path of a command, like the Unix which command</description>"))
		#expect(xml.contains("<title>which-path</title>"))
		#expect(xml.contains("<title>soml-lang/soml</title>"))
	}

	@Test
	func `the release notes feed links to its page, leaves out the launch, and links each release with the app name to its heading`() async throws {
		let app = try await App(frontmatter: "releasesRepository: 'sindresorhus/test'", slug: "test")
		let releaseNotes = try #require(app.releaseNotes)
		let releases = [
			GitHubRelease(
				tagName: "v1.1.0",
				publishedAt: Date(timeIntervalSince1970: 1_780_000_000),
				notesHTML: "<p>Fixed a bug.</p>"
			),
			GitHubRelease(
				tagName: "v1.0.0",
				publishedAt: Date(timeIntervalSince1970: 1_770_000_000),
				notesHTML: ""
			),
		]

		let xml = try Feed.releaseNotes(of: app, at: releaseNotes, releases: releases).xmlString()

		#expect(xml.contains("<link>https://sindresorhus.com/test/release-notes</link>"))
		#expect(xml.contains("<title>\(app.title) 1.1.0</title>"))
		#expect(xml.contains("<link>https://sindresorhus.com/test/release-notes#1.1.0</link>"))
		#expect(xml.contains("Fixed a bug."))
		#expect(!xml.contains("1.0.0</title>"))
	}
}
