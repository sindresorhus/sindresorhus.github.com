import Foundation
import SiteKit

/**
The GitHub API for the `sindresorhus` account. A token raises the rate limit.
*/
struct GitHub: Sendable {
	let token: String?
	let cache: ResponseCache

	init(token: String? = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], cache: ResponseCache) {
		self.token = token
		self.cache = cache
	}

	/**
	The published releases of a repo, newest first, from all the pages (``allPages(_:query:)``).
	*/
	func releases(repository: String) async throws -> [GitHubRelease] {
		let entries: [GitHubRelease.Entry] = try await allPages("repos/sindresorhus/\(repository)/releases")

		return entries
			.compactMap(\.release)
			.filter { !$0.isDraft && !$0.isPrerelease }
			.map { release in
				var release = release
				release.notesHTML = release.body.map { MarkdownDocument(parsing: $0, style: .releaseNotes).html } ?? ""
				return release
			}
	}

	/**
	The 20 most recently created repos that are not archived or forks.
	*/
	func recentRepositories() async throws -> [GitHubRepository] {
		let repositories: [GitHubRepository] = try await get("users/sindresorhus/repos?type=owner&sort=created&per_page=20")
		return repositories.filter { !$0.isArchived && !$0.isFork }
	}

	/**
	The eight repos with code that have the most stars and are not archived or forks, most stars first. The organizations of the bigger projects (``owners``) are included, as the about page links to the same search. Some repos are left out by their owner and name (``hiddenPopularRepositories``). Repos without code, like the Awesome lists, are left out, as the about page is about the projects that he made.
	*/
	func popularRepositories() async throws -> [GitHubRepository] {
		// More than eight, as some of the most popular repos are lists or hidden.
		let result: SearchResult<GitHubRepository> = try await get("search/repositories?q=\(Self.ownerQualifiers.replacing(" ", with: "+"))+fork:false+archived:false&sort=stars&order=desc&per_page=30")

		return Array(
			result.items
				.filter { $0.language != nil && !Self.hiddenPopularRepositories.contains($0.nameWithOwner) }
				.prefix(8)
		)
	}

	/**
	The popular repos that the about page does not show, with their owners.
	*/
	private static let hiddenPopularRepositories: Set = ["avajs/ava", "sindresorhus/pageres", "sindresorhus/github-markdown-css"]

	/**
	The account and the organizations of the bigger projects (Chalk, AVA, XO, SOML), whose repos the pages count, like the issues closed and the latest releases.
	*/
	static let owners = ["sindresorhus", "chalk", "avajs", "xojs", "soml-lang"]

	/**
	The search qualifiers of the repos of the ``owners``, like `user:sindresorhus user:chalk`.
	*/
	static var ownerQualifiers: String {
		owners.map { "user:\($0)" }.joined(separator: " ")
	}

	/**
	The numbers of the account, for the about page, and its repos, for the now page.
	*/
	struct Account: Sendable {
		/**
		The public repos, like 1,144, also the forks and the archived ones.
		*/
		let repositoryCount: Int

		let followerCount: Int

		/**
		The stars of the repos of the account that are not forks, like 1,099,747. Not the repos of the organizations, like Chalk.
		*/
		let starCount: Int

		/**
		The issues closed and the pull requests by other people merged, of all time.
		*/
		let maintenance: Maintenance

		/**
		All the public repos of the account, also the forks and the archived ones, so the now page can find the repos that were made this year. Not the repos of the organizations.
		*/
		let repositories: [GitHubRepository]
	}

	/**
	The work of a maintainer in the repos of the account and of the organizations of the bigger projects (``owners``), like 26,249 issues closed and 15,974 pull requests by other people merged.
	*/
	struct Maintenance: Sendable {
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
		async let mergedPullRequestCount = issueCount(matching: "is:pr is:merged \(Self.ownerQualifiers) -author:sindresorhus\(dateQualifier("merged"))")
		return Maintenance(closedIssueCount: try await closedIssueCount, mergedPullRequestCount: try await mergedPullRequestCount)
	}

	/**
	The numbers of the account. The stars are the sum of the stars of each repo, so it asks for all the pages of repos. The closed issues and the merged pull requests are searches.

	That is about 13 requests, and two searches. Without a token, GitHub allows 60 requests an hour and 10 searches a minute.
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

		// All at the same time.
		async let allTimeMaintenance = maintenance()
		async let user: User = get("users/sindresorhus")
		let repositories: [GitHubRepository] = try await allPages("users/sindresorhus/repos", query: "type=owner")

		return Account(
			repositoryCount: try await user.publicRepositoryCount,
			followerCount: try await user.followerCount,
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
		struct Issue: Decodable {}

		let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=>"))) ?? query
		let result: SearchResult<Issue> = try await get("search/issues?q=\(encodedQuery)&per_page=1")
		return result.totalCount
	}

	/**
	The result of a search. GitHub stops a search that takes too long and returns what it found until then, like too low a count. So an incomplete result cannot be read: it is not saved, and the cached result is used.
	*/
	private struct SearchResult<Item: Decodable>: Decodable {
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
		struct Event: Decodable {
			struct Repository: Decodable {
				let name: String
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

			let type: String
			let repository: Repository
			let createdAt: Date
			let payload: Payload

			enum CodingKeys: String, CodingKey {
				case type
				case repository = "repo"
				case createdAt = "created_at"
				case payload
			}
		}

		let events: [Event] = try await get("users/sindresorhus/events/public?per_page=100")

		return events
			.filter { $0.type == "ReleaseEvent" && $0.payload.action == "published" }
			.compactMap { event in
				guard
					let release = event.payload.release,
					!release.isDraft,
					!release.isPrerelease
				else {
					return nil
				}

				return OpenSourceRelease(repository: event.repository.name, tagName: release.tagName, url: release.url, date: event.createdAt)
			}
			.sorted(using: KeyPathComparator(\.date, order: .reverse))
	}

	/**
	The contributions of the last year, the number of sponsors, and the number of comments on issues and pull requests of all time, from the GraphQL API, which needs a token. `nil` without a token.
	*/
	func profile() async throws -> (contributions: ContributionCalendar, sponsorCount: Int, commentCount: Int)? {
		struct Content: Decodable {
			struct User: Decodable {
				struct Count: Decodable {
					let totalCount: Int
				}

				struct Contributions: Decodable {
					let contributionCalendar: ContributionCalendar
				}

				let sponsors: Count
				let issueComments: Count
				let contributionsCollection: Contributions
			}

			let user: User
		}

		guard token != nil else {
			return nil
		}

		let user = try await graphQL(Content.self, query: "{ user(login: \"sindresorhus\") { sponsors { totalCount } issueComments { totalCount } contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount contributionLevel } } } } } }").user
		return (user.contributionsCollection.contributionCalendar, user.sponsors.totalCount, user.issueComments.totalCount)
	}

	/**
	The contributions, commits, and comments since a date, like the start of the week of the now page.
	*/
	struct Activity: Sendable {
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
		struct Content: Decodable {
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

					struct PageInfo: Decodable {
						let hasNextPage: Bool
						let endCursor: String?
					}

					let nodes: [Comment]
					let pageInfo: PageInfo
				}

				let contributionsCollection: Contributions
				let issueComments: Comments
			}

			let user: User
		}

		guard token != nil else {
			return nil
		}

		let query = "query($from: DateTime!, $after: String) { user(login: \"sindresorhus\") { contributionsCollection(from: $from) { totalCommitContributions contributionCalendar { totalContributions } } issueComments(first: 100, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) { nodes { createdAt updatedAt } pageInfo { hasNextPage endCursor } } } }"
		var variables = ["from": start.formatted(.iso8601)]
		var commentCount = 0

		while true {
			let user = try await graphQL(Content.self, query: query, variables: variables).user
			let comments = user.issueComments
			commentCount += comments.nodes.count { $0.createdAt >= start }

			guard
				comments.pageInfo.hasNextPage,
				let cursor = comments.pageInfo.endCursor,
				comments.nodes.allSatisfy({ $0.updatedAt >= start })
			else {
				// Each page has the same contributions.
				let contributions = user.contributionsCollection
				return Activity(contributionCount: contributions.contributionCalendar.totalContributions, commitCount: contributions.totalCommitContributions, commentCount: commentCount)
			}

			variables["after"] = cursor
		}
	}

	/**
	The `data` of a GraphQL query. The GraphQL API needs a token, so it throws without one.

	- Parameter maximumAge: How long the cached response is used, like a long time for data that never changes.
	*/
	func graphQL<Value: Decodable>(_ type: Value.Type, query: String, variables: [String: String]? = nil, maximumAge: Duration? = nil) async throws -> Value {
		guard let token else {
			throw URLError(.userAuthenticationRequired)
		}

		// Sorted keys, so the body, which is part of the cache key, is the same each time.
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys

		var request = URLRequest(url: #URL("https://api.github.com/graphql"), timeoutInterval: 30)
		request.httpMethod = "POST"
		request.httpBody = try encoder.encode(GraphQLRequest(query: query, variables: variables))
		request.setValue("sindresorhus.com", forHTTPHeaderField: "User-Agent")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		return try await cache.decoded(GraphQLResponse<Value>.self, from: request, maximumAge: maximumAge).data
	}

	private struct GraphQLRequest: Encodable {
		let query: String
		let variables: [String: String]?
	}

	private struct GraphQLResponse<Value: Decodable>: Decodable {
		let data: Value
	}

	/**
	All the items of a list that the API returns in pages, like the releases of a repo. The API returns at most 100 items per request, so it asks for pages until one is not full.

	- Parameters:
		- query: The query of the URL without the page, like `type=owner`.
	*/
	private func allPages<Element: Decodable>(_ path: String, query: String? = nil) async throws -> [Element] {
		let pageSize = 100
		var elements = [Element]()

		for page in 1... {
			let parameters = [query, "per_page=\(pageSize)", "page=\(page)"].compactMap(\.self).joined(separator: "&")
			let entries: [Element] = try await get("\(path)?\(parameters)")
			elements += entries

			guard entries.count == pageSize else {
				break
			}
		}

		return elements
	}

	private func get<Value: Decodable>(_ path: String) async throws -> Value {
		guard let url = URL(string: "https://api.github.com/\(path)") else {
			throw URLError(.badURL)
		}

		var request = URLRequest(url: url, timeoutInterval: 20)
		request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		request.setValue("sindresorhus.com", forHTTPHeaderField: "User-Agent")

		if let token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		return try await cache.decoded(from: request)
	}
}

/**
A release of an open-source project, from the public events of the account.
*/
struct OpenSourceRelease: Sendable {
	/**
	The repo with its owner, like `sindresorhus/execa`.
	*/
	let repository: String

	let tagName: String
	let url: URL
	let date: Date

	/**
	The repo name without the owner, like `execa`, which is usually also the name of its npm package.
	*/
	var name: String {
		String(repository.split(separator: "/").last ?? "")
	}

	/**
	The repo name, with the owner only when it is not `sindresorhus`, like `execa` or `chalk/chalk`.
	*/
	var displayName: String {
		repository.repositoryDisplayName
	}

	/**
	The version, without the `v` of the tag, like `10.1.0`.
	*/
	var version: String {
		String(tagName.trimmingPrefix("v"))
	}
}

extension String {
	/**
	The name of a repo to show, with the owner only when it is not `sindresorhus`, like `execa` for `sindresorhus/execa`, or `chalk/chalk`.
	*/
	var repositoryDisplayName: String {
		String(trimmingPrefix("sindresorhus/"))
	}

	/**
	The owner of a repo, like `chalk` for `chalk/chalk`.
	*/
	var repositoryOwner: String {
		String(prefix { $0 != "/" })
	}
}
