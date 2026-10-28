import Foundation
import SiteKit

/**
The GitHub API for the `sindresorhus` account and the organizations of its projects. A token raises the rate limit.
*/
struct GitHub {
	let token: String?
	let cache: ResponseCache

	init(token: String?, cache: ResponseCache) {
		self.token = token
		self.cache = cache
	}

	/**
	The token of `GITHUB_TOKEN`, or else the token of the GitHub CLI (`gh auth token`) when it is logged in, so a local build has the rate limit of a token (5,000 requests an hour instead of 60) without setting it. It is resolved once for the process, as `website serve` builds repeatedly.
	*/
	static func defaultToken() async -> String? {
		await defaultTokenTask.value
	}

	private static let defaultTokenTask = Task {
		await defaultToken(environment: ProcessInfo.processInfo.environment)
	}

	/**
	The token of an environment, which a test supplies instead of the one of the process.
	*/
	static func defaultToken(environment: [String: String]) async -> String? {
		if let token = environment["GITHUB_TOKEN"] {
			return token
		}

		return await gitHubCLIToken(environment: environment)
	}

	/**
	The token of the GitHub CLI, or `nil` when it is not installed or not logged in.
	*/
	private static func gitHubCLIToken(environment: [String: String]) async -> String? {
		let process = Process()
		let output = Pipe()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["gh", "auth", "token"]
		process.environment = environment
		process.standardOutput = output
		process.standardError = FileHandle.nullDevice

		var data = Data()

		let termination = try? await process.runUntilExit {
			data = try await output.fileHandleForReading.readDataToEnd()
		}

		guard termination == .exit(0) else {
			return nil
		}

		let token = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
		return token.nilIfEmpty
	}

	/**
	The published releases of a repo, newest publication date first, from all the pages (``allPages(_:query:expectedCount:)``).
	*/
	func releases(repository: GitHubRepositoryName) async throws -> [GitHubRelease] {
		let entries: [GitHubRelease.Response] = try await allPages("repos/\(repository)/releases")

		return entries.compactMap { release -> GitHubRelease? in
			guard
				let publishedAt = release.publishedAt,
				!release.isDraft,
				!release.isPrerelease
			else {
				return nil
			}

			// The site's classes, so a table is in the scrolling container of the prose.
			var options = MarkdownDocument.Options.site
			let page = repository.url.appending(path: "releases/tag/\(release.tagName)")

			// A relative link is resolved against the page of the release on GitHub, like a browser there would, so a link that is written for GitHub, like `../../issues/12`, is not a broken link of the site, which would fail a scheduled build. A link to a section, like `#usage`, stays.
			options.resolveLink = { destination in
				guard
					!destination.hasPrefix("#"),
					let url = URL(string: destination, relativeTo: page)
				else {
					return destination
				}

				return url.absoluteString
			}

			let notesHTML = release.body.map { MarkdownDocument(parsing: $0, style: .releaseNotes, options: options).html } ?? ""
			return GitHubRelease(tagName: release.tagName, publishedAt: publishedAt, notesHTML: notesHTML)
		}
		.sorted(using: KeyPathComparator(\.publishedAt, order: .reverse))
	}

	/**
	The repos that are not archived or forks among the 20 most recently created repos of the ``owners``, newest first, so there can be fewer than 20, like 18 when two are forks. The search cannot sort by the creation date, so it asks for the 20 newest repos of each owner at the same time.
	*/
	func recentRepositories() async throws -> [GitHubRepository] {
		let repositories: [[GitHubRepository]] = try await Self.owners.concurrentMap { owner in
			try await get("users/\(owner)/repos", query: [URLQueryItem(name: "type", value: "owner"), URLQueryItem(name: "sort", value: "created"), URLQueryItem(name: "per_page", value: "20")])
		}

		return repositories
			.joined()
			.sorted(using: KeyPathComparator(\.createdAt, order: .reverse))
			.prefix(20)
			.filter { !$0.isArchived && !$0.isFork }
	}

	/**
	The eight repos with code that have the most stars and are not archived or forks, most stars first. The organizations of his projects (``owners``) are included, as the about page links to the same search. Some repos are left out by their owner and name (``hiddenPopularRepositories``). Repos without code, like the Awesome lists, are left out, as the about page is about the projects that he made.
	*/
	func popularRepositories() async throws -> [GitHubRepository] {
		// More than eight, as some of the most popular repos are lists or hidden.
		let result: SearchResult<GitHubRepository> = try await get("search/repositories", query: [URLQueryItem(name: "q", value: "\(Self.ownerQualifiers) fork:false archived:false"), URLQueryItem(name: "sort", value: "stars"), URLQueryItem(name: "order", value: "desc"), URLQueryItem(name: "per_page", value: "30")])

		return Array(
			result.items
				.filter { $0.language != nil && !Self.hiddenPopularRepositories.contains($0.nameWithOwner) }
				.prefix(8)
		)
	}

	/**
	The popular repos that the about page does not show, with their owners.
	*/
	private static let hiddenPopularRepositories: Set<GitHubRepositoryName> = [#repository("avajs/ava"), #repository("sindresorhus/pageres"), #repository("sindresorhus/github-markdown-css")]

	/**
	The account of the site, in lowercase, whose repos, contributions, and releases the pages show. It is the account of the GitHub profile of the author, so the links and the data are of one account.
	*/
	static let account = Site.author.gitHubURL.lastPathComponent.lowercased()

	/**
	The account and the organizations of the projects that he made (Chalk, AVA, XO, SOML, Simple Color Palette), in lowercase, whose repos the pages show and count as his, like the new projects, the repo of the day, the repos and their stars, the popular repos, the issues closed, and the latest releases.
	*/
	static let owners = [account, "chalk", "avajs", "xojs", "soml-lang", "simple-color-palette"]

	/**
	The search qualifiers of the repos of the ``owners``, like `user:sindresorhus user:chalk`.
	*/
	static let ownerQualifiers = owners.lazy.map { "user:\($0)" }.joined(separator: " ")

	/**
	The numbers of the account, for the about page, and the repos of the account and the organizations (``owners``), for the about page and the now page.
	*/
	struct Account {
		/**
		The public repos of the ``owners``, like 1,144, also the forks and the archived ones.
		*/
		let repositoryCount: Int

		let followerCount: Int

		/**
		The stars of the repos of the ``owners`` that are not forks, like 1,099,747.
		*/
		let starCount: Int

		/**
		The issues closed and the pull requests by other people merged, of all time.
		*/
		let maintenance: Maintenance

		/**
		All the public repos of the ``owners``, also the forks and the archived ones, in the order of the owners, so the now page can find the repos that were made this year.
		*/
		let repositories: [GitHubRepository]
	}

	/**
	The work of a maintainer in the repos of the account and of the organizations of his projects (``owners``), like 26,249 issues closed and 15,974 pull requests by other people merged.
	*/
	struct Maintenance {
		/**
		The closed issues, by anyone.
		*/
		let closedIssueCount: Int

		/**
		The merged pull requests by other people, not by Sindre.
		*/
		let mergedPullRequestCount: Int
	}

	/**
	The issues closed and the pull requests by other people merged since the date, like the start of the week or of the year, or of all time without a date. The date is a whole timestamp, like the `from` of the contributions, so the searches count the same days as the contributions and the npm releases. Each is a search, and they run at the same time.
	*/
	func maintenance(since start: Date? = nil) async throws -> Maintenance {
		// Like ` closed:>=2026-01-01T00:00:00Z`, or nothing for all time.
		func dateQualifier(_ qualifier: String) -> String {
			start.map { " \(qualifier):>=\($0.formatted(.iso8601))" } ?? ""
		}

		async let closedIssueCount = issueCount(matching: "is:issue is:closed \(Self.ownerQualifiers)\(dateQualifier("closed"))")
		async let mergedPullRequestCount = issueCount(matching: "is:pr is:merged \(Self.ownerQualifiers) -author:\(Self.account)\(dateQualifier("merged"))")
		return Maintenance(closedIssueCount: try await closedIssueCount, mergedPullRequestCount: try await mergedPullRequestCount)
	}

	/**
	The numbers of the account. The stars are the sum of the stars of each repo, so it asks for all the pages of repos of each of the ``owners``. The closed issues and the merged pull requests are searches.

	That is about 23 requests, and two searches. Without a token, GitHub allows 60 requests an hour and 10 searches a minute.
	*/
	func account() async throws -> Account {
		struct User: Decodable {
			let publicRepositoryCount: Int
			let followerCount: Int

			enum CodingKeys: String, CodingKey {
				case publicRepositoryCount = "public_repos"
				case followerCount = "followers"
			}
		}

		// All at the same time, and the pages of repos of each owner once its user gives their number.
		async let allTimeMaintenance = maintenance()

		let owners = try await Self.owners.concurrentMap { owner in
			let user: User = try await get("users/\(owner)")
			let repositories: [GitHubRepository] = try await allPages("users/\(owner)/repos", query: [URLQueryItem(name: "type", value: "owner")], expectedCount: user.publicRepositoryCount)
			return (owner: owner, user: user, repositories: repositories)
		}

		let repositories = owners.flatMap(\.repositories)

		return Account(
			repositoryCount: owners.map(\.user.publicRepositoryCount).sum,
			// Select the personal account by identity while keeping the repositories in owner order.
			followerCount: owners.first { $0.owner == Self.account }?.user.followerCount ?? 0,
			starCount: repositories.filter { !$0.isFork }.map(\.stars).sum,
			maintenance: try await allTimeMaintenance,
			repositories: repositories
		)
	}

	/**
	The number of issues and pull requests that match a search, like `is:pr is:merged author:sindresorhus`.
	*/
	func issueCount(matching query: String) async throws -> Int {
		// Only the count is read.
		struct Issue: Decodable, Sendable {}

		let result: SearchResult<Issue> = try await get("search/issues", query: [URLQueryItem(name: "q", value: query), URLQueryItem(name: "per_page", value: "1")])
		return result.totalCount
	}

	/**
	The result of a search. GitHub stops a search that takes too long and returns what it found until then, like too low a count. So an incomplete result cannot be read: it is not saved, and the cached result is used.
	*/
	private struct SearchResult<Item: Decodable & Sendable>: Decodable, Sendable {
		let totalCount: Int
		let items: [Item]

		enum CodingKeys: String, CodingKey {
			case totalCount = "total_count"
			case isIncomplete = "incomplete_results"
			case items
		}

		init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			guard try !container.decode(Bool.self, forKey: .isIncomplete) else {
				throw DecodingError.dataCorruptedError(forKey: .isIncomplete, in: container, debugDescription: "The search took too long, so its result is incomplete.")
			}

			self.totalCount = try container.decode(Int.self, forKey: .totalCount)
			self.items = try container.decode([Item].self, forKey: .items)
		}
	}

	/**
	The published releases in the latest 100 public events of the account, newest first. The events cover a few days.
	*/
	func latestReleases() async throws -> [OpenSourceRelease] {
		enum Event: Decodable {
			struct Repository: Decodable {
				let name: GitHubRepositoryName
			}

			struct Payload: Decodable {
				struct Release: Decodable {
					let tagName: String
					let url: URL
					let isDraft: Bool
					let isPrerelease: Bool

					enum CodingKeys: String, CodingKey {
						case tagName = "tag_name"
						case url = "html_url"
						case isDraft = "draft"
						case isPrerelease = "prerelease"
					}
				}

				let action: String?
				let release: Release?
			}

			case publishedRelease(OpenSourceRelease)
			case ignored

			enum CodingKeys: String, CodingKey {
				case type
				case repository = "repo"
				case createdAt = "created_at"
				case payload
			}

			init(from decoder: any Decoder) throws {
				let container = try decoder.container(keyedBy: CodingKeys.self)
				let type = try container.decode(String.self, forKey: .type)
				let repository = try container.decode(Repository.self, forKey: .repository)
				let date = try container.decode(Date.self, forKey: .createdAt)
				// Decode known fields before filtering, so malformed payloads remain decoding failures even for ignored events.
				let payload = try container.decode(Payload.self, forKey: .payload)

				guard
					type == "ReleaseEvent",
					payload.action == "published",
					let release = payload.release,
					!release.isDraft,
					!release.isPrerelease
				else {
					self = .ignored
					return
				}

				self = .publishedRelease(
					OpenSourceRelease(
						repository: repository.name,
						tagName: release.tagName,
						url: release.url,
						date: date
					)
				)
			}

			/**
			The complete published release carried by this event, if supported.
			*/
			var release: OpenSourceRelease? {
				guard case .publishedRelease(let release) = self else {
					return nil
				}

				return release
			}
		}

		let events: [Event] = try await get("users/\(Self.account)/events/public", query: [URLQueryItem(name: "per_page", value: "100")])
		return events.compactMap(\.release).sorted(using: KeyPathComparator(\.date, order: .reverse))
	}

	/**
	The contributions of the last year and the all-time counts returned together by the profile request.
	*/
	struct Profile {
		let contributions: ContributionCalendar
		let sponsorCount: Int

		/**
		The comments on issues and pull requests of all time, for the about page.
		*/
		let commentCount: Int
	}

	/**
	The contributions of the last year, the number of sponsors, and the number of comments on issues and pull requests of all time, from the GraphQL API, which needs a token. `nil` without a token.
	*/
	func profile() async throws -> Profile? {
		struct User: Decodable {
			struct Contributions: Decodable {
				let contributionCalendar: ContributionCalendar
			}

			let sponsors: GraphQL.Count
			let issueComments: GraphQL.Count
			let contributionsCollection: Contributions
		}

		guard let graphQL else {
			return nil
		}

		let user = try await graphQL.data(GraphQL.UserResponse<User>.self, query: "{ user(login: \"\(Self.account)\") { sponsors { totalCount } issueComments { totalCount } contributionsCollection { \(ContributionCalendar.selection) } } }").user
		return Profile(contributions: user.contributionsCollection.contributionCalendar, sponsorCount: user.sponsors.totalCount, commentCount: user.issueComments.totalCount)
	}

	/**
	The contributions, commits, and comments since a date, like the start of the week of the now page.
	*/
	struct Activity {
		let contributionCount: Int
		let commitCount: Int

		/**
		The comments on issues and pull requests, not the comments in code reviews.
		*/
		let commentCount: Int
	}

	/**
	The activity since the date, from the GraphQL API, which needs a token. `nil` without a token.

	The comments are newest updated first, 100 at a time, so it asks for pages until a page has a comment that was last updated before the date, as the comments on the next pages were last updated even earlier, so they were also made before the date. Usually one page has a week of comments.
	*/
	func activity(since start: Date) async throws -> Activity? {
		struct User: Decodable {
			struct Contributions: Decodable {
				struct Calendar: Decodable {
					let totalContributions: Int
				}

				let totalCommitContributions: Int
				let contributionCalendar: Calendar
			}

			struct Comments: Decodable {
				struct Comment: Decodable {
					let createdAt: Date
					let updatedAt: Date
				}

				let nodes: [Comment]
				let pageInfo: GraphQL.Continuation
			}

			let contributionsCollection: Contributions
			let issueComments: Comments
		}

		struct Variables: Encodable, Sendable {
			let from: Date
			var after: String?
		}

		guard let graphQL else {
			return nil
		}

		let query = "query($from: DateTime!, $after: String) { user(login: \"\(Self.account)\") { contributionsCollection(from: $from) { totalCommitContributions contributionCalendar { totalContributions } } issueComments(first: 100, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) { nodes { createdAt updatedAt } pageInfo { hasNextPage endCursor } } } }"
		var variables = Variables(from: start)
		var commentCount = 0

		while true {
			let user = try await graphQL.data(GraphQL.UserResponse<User>.self, query: query, variables: variables).user
			let comments = user.issueComments
			commentCount += comments.nodes.count { $0.createdAt >= start }

			guard
				case .after(let cursor) = comments.pageInfo,
				comments.nodes.allSatisfy({ $0.updatedAt >= start })
			else {
				// Each page has the same contributions.
				let contributions = user.contributionsCollection
				return Activity(contributionCount: contributions.contributionCalendar.totalContributions, commitCount: contributions.totalCommitContributions, commentCount: commentCount)
			}

			variables.after = cursor
		}
	}

	/**
	The GraphQL API, which needs a token, so it is `nil` without one, and a query without a token does not compile.
	*/
	var graphQL: GraphQL? {
		token.map { GraphQL(token: $0, cache: cache) }
	}

	/**
	The GraphQL API, with the token that it needs (``GitHub/graphQL``).
	*/
	struct GraphQL {
		/**
		The exact count envelope shared by GraphQL nodes, such as sponsors, comments, and contributions to a repository.
		*/
		struct Count: Decodable, Sendable {
			let totalCount: Int
		}

		fileprivate let token: String
		fileprivate let cache: ResponseCache

		/**
		The required user envelope shared by account queries. Query-specific fields stay on their local user type.
		*/
		struct UserResponse<User: Decodable & Sendable>: Decodable, Sendable {
			let user: User
		}

		/**
		The continuation of a connection. A next page must have the cursor needed to request it.
		*/
		enum Continuation: Decodable, Sendable {
			case end
			case after(String)

			enum CodingKeys: CodingKey {
				case hasNextPage
				case endCursor
			}

			init(from decoder: any Decoder) throws {
				let container = try decoder.container(keyedBy: CodingKeys.self)
				let hasNextPage = try container.decode(Bool.self, forKey: .hasNextPage)
				let cursor = try container.decodeIfPresent(String.self, forKey: .endCursor)

				guard hasNextPage else {
					self = .end
					return
				}

				guard let cursor else {
					throw DecodingError.dataCorruptedError(forKey: .endCursor, in: container, debugDescription: "A next page needs an end cursor.")
				}

				self = .after(cursor)
			}
		}

		/**
		The `data` of a query without variables. The absent variables field is omitted from the request body.
		*/
		func data<Value: Decodable & Sendable>(_ type: Value.Type, query: String, maximumAge: Duration? = nil) async throws -> Value {
			try await data(type, query: query, variables: Optional<Never>.none, maximumAge: maximumAge)
		}

		/**
		The `data` of a query, with its query-owned variables.

		- Parameter maximumAge: How long the cached response is used, like a long time for data that never changes.
		*/
		func data<Value: Decodable & Sendable, Variables: Encodable & Sendable>(
			_ type: Value.Type,
			query: String,
			variables: Variables?,
			maximumAge: Duration? = nil
		) async throws -> Value {
			// Sorted keys, so the body, which is part of the cache key, is the same each time.
			let encoder = JSONEncoder()
			encoder.outputFormatting = .sortedKeys
			encoder.dateEncodingStrategy = .iso8601

			var request = URLRequest(url: #URL("https://api.github.com/graphql"), timeoutInterval: 30)
			request.httpMethod = "POST"
			request.httpBody = try encoder.encode(Request(query: query, variables: variables))
			request = request.forGitHub(token: token)
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			return try await cache.decoded(Response<Value>.self, from: request, maximumAge: maximumAge).data
		}

		private struct Request<Variables: Encodable & Sendable>: Encodable {
			let query: String
			let variables: Variables?
		}

		private struct Response<Value: Decodable & Sendable>: Decodable, Sendable {
			let data: Value
		}
	}

	/**
	All the items of a list that the API returns in pages, like the releases of a repo. The API returns at most 100 items per request, so it asks for pages until one is not full.

	The pages of the expected items are asked for at the same time, as a request can take a second, like each of the 12 pages of repos of the account. The later pages are asked for one at a time.

	- Parameters:
		- query: The query items without the page, like `URLQueryItem(name: "type", value: "owner")`.
		- expectedCount: The number of items, when another response has it, like the repos of the user.
	*/
	private func allPages<Element: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = [], expectedCount: Int = 0) async throws -> [Element] {
		let pageSize = 100
		let expectedPageCount = max(1, (expectedCount + pageSize - 1) / pageSize)

		@Sendable func entries(page: Int) async throws -> [Element] {
			try await get(path, query: query + [URLQueryItem(name: "per_page", value: String(pageSize)), URLQueryItem(name: "page", value: String(page))])
		}

		let expectedPages = try await (1...expectedPageCount).concurrentMap { page in
			try await entries(page: page)
		}

		var elements = [Element]()

		for page in 1... {
			let pageEntries = try await (page <= expectedPageCount ? expectedPages[page - 1] : entries(page: page))
			elements += pageEntries

			guard pageEntries.count == pageSize else {
				break
			}
		}

		return elements
	}

	private func get<Value: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> Value {
		let url = #URL("https://api.github.com").appending(path: path).appending(formQueryItems: query)
		let request = URLRequest(url: url, timeoutInterval: 20).forGitHub(token: token)
		return try await cache.decoded(from: request)
	}
}

/**
A release of an open-source project, from the public events of the account.
*/
struct OpenSourceRelease {
	/**
	The repo, like `sindresorhus/execa`. Its name is usually also the name of its npm package.
	*/
	let repository: GitHubRepositoryName

	let tagName: String
	let url: URL
	let date: Date

	/**
	The version, without the `v` of the tag, like `10.1.0`.
	*/
	var version: String {
		String(tagName.trimmingPrefix("v"))
	}
}

extension URLRequest {
	/**
	The shared GitHub API headers for REST and GraphQL, including the versioned media type and optional authentication.
	*/
	fileprivate func forGitHub(token: String?) -> Self {
		var request = self
		request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		request.setValue("sindresorhus.com", forHTTPHeaderField: "User-Agent")

		if let token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		return request
	}
}
