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
			let url = "https://api.github.com/repos/sindresorhus/test/releases?per_page=100\(page == 1 ? "" : "&page=\(page)")"
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
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/repos/sindresorhus/test/releases?per_page=100": releases]))
		let versions = try await github.releases(repository: "test").map(\.version)

		#expect(versions == ["1.0.0"])
	}

	@Test(.temporaryDirectory)
	func `popular repositories are read from the search result, with descriptions without emoji and notes`() async throws {
		let result = #"{"total_count": 1, "items": [{"name": "awesome", "description": "😎 Awesome lists :zap: about all kinds of `topics` [NOTE: Pull requests are disabled] ❤️", "html_url": "https://github.com/sindresorhus/awesome", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 515161}, {"name": "chalk", "description": "🖍 Terminal string styling done right, 2 colors #1", "html_url": "https://github.com/chalk/chalk", "created_at": "2013-08-03T00:20:36Z", "archived": false, "fork": false, "stargazers_count": 23000}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/search/repositories?q=user:sindresorhus+user:chalk+user:avajs+user:xojs+fork:false+archived:false&sort=stars&order=desc&per_page=12": result]))
		let repositories = try await github.popularRepositories()

		#expect(repositories.map(\.name) == ["awesome", "chalk"])
		#expect(repositories.first?.stars == 515_161)
		#expect(repositories.first?.summary == "Awesome lists about all kinds of topics")

		// An emoji without the emoji variation selector is removed too, but digits and `#` stay, although Unicode counts them as emoji.
		#expect(repositories.last?.summary == "Terminal string styling done right, 2 colors #1")
	}

	/**
	An emoji code is a whole word, like `:zap:`, so the `:30:` in a time stays.
	*/
	@Test(.temporaryDirectory)
	func `the summary of a repository keeps times and removes emoji codes next to each other`() async throws {
		let result = #"{"total_count": 1, "items": [{"name": "parse-time", "description": ":unicorn::sparkles: Parse a time like 12:30:45 into seconds :zap:", "html_url": "https://github.com/sindresorhus/parse-time", "created_at": "2014-07-11T13:42:37Z", "archived": false, "fork": false, "stargazers_count": 10}]}"#
		let github = GitHub(token: nil, cache: try ResponseCache(responses: ["https://api.github.com/search/repositories?q=user:sindresorhus+user:chalk+user:avajs+user:xojs+fork:false+archived:false&sort=stars&order=desc&per_page=12": result]))

		#expect(try await github.popularRepositories().first?.summary == "Parse a time like 12:30:45 into seconds")
	}

	@Test
	func `the new repositories feed describes a repository with its summary, like the now page`() throws {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let repository = try decoder.decode(GitHubRepository.self, from: Data(#"{"name": "which-path", "description": ":zap: Find the path of a command, like the Unix `which` command", "html_url": "https://github.com/sindresorhus/which-path", "created_at": "2026-01-01T00:00:00Z", "archived": false, "fork": false, "stargazers_count": 1}"#.utf8))
		let content = SiteContent(apps: [], posts: [], pages: [], recentRepositories: [repository], buildDate: .now, project: .empty)

		#expect(try SiteFeed.newRepositories.feed(content: content).xmlString().contains("<description>Find the path of a command, like the Unix which command</description>"))
	}
}
