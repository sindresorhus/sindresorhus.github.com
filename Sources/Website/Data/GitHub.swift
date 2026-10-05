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
	The published releases of a repo, newest first. The API returns at most 100 releases per request, so it asks for pages until one is not full.
	*/
	func releases(repository: String) async throws -> [GitHubRelease] {
		let pageSize = 100
		var releases = [GitHubRelease]()

		for page in 1... {
			// The first page has no page number, so its URL is the same as before pages were read, and cached responses still work.
			let entries: [GitHubRelease.Entry] = try await get("repos/sindresorhus/\(repository)/releases?per_page=\(pageSize)\(page == 1 ? "" : "&page=\(page)")")
			releases += entries.compactMap(\.release)

			guard entries.count == pageSize else {
				break
			}
		}

		return releases
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
	The repos with the most stars that are not archived or forks, most stars first. The organizations of the bigger projects (Chalk, AVA, XO) are included, as the about page links to the same search.
	*/
	func popularRepositories() async throws -> [GitHubRepository] {
		struct SearchResult: Decodable {
			let items: [GitHubRepository]
		}

		let result: SearchResult = try await get("search/repositories?q=user:sindresorhus+user:chalk+user:avajs+user:xojs+fork:false+archived:false&sort=stars&order=desc&per_page=12")
		return result.items
	}

	/**
	The number of issues and pull requests that match a search, like `is:pr is:merged author:sindresorhus`.
	*/
	func issueCount(matching query: String) async throws -> Int {
		struct SearchResult: Decodable {
			let totalCount: Int

			enum CodingKeys: String, CodingKey {
				case totalCount = "total_count"
			}
		}

		let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=>"))) ?? query
		let result: SearchResult = try await get("search/issues?q=\(encodedQuery)&per_page=1")
		return result.totalCount
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
	The contributions of the last year and the number of sponsors, from the GraphQL API, which needs a token. `nil` without a token.
	*/
	func contributionsAndSponsors() async throws -> (contributions: ContributionCalendar, sponsorCount: Int)? {
		struct Content: Decodable {
			struct User: Decodable {
				struct Sponsors: Decodable {
					let totalCount: Int
				}

				struct Contributions: Decodable {
					let contributionCalendar: ContributionCalendar
				}

				let sponsors: Sponsors
				let contributionsCollection: Contributions
			}

			let user: User
		}

		guard token != nil else {
			return nil
		}

		let user = try await graphQL(Content.self, query: "{ user(login: \"sindresorhus\") { sponsors { totalCount } contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount contributionLevel } } } } } }").user
		return (user.contributionsCollection.contributionCalendar, user.sponsors.totalCount)
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
		String(repository.trimmingPrefix("sindresorhus/"))
	}

	/**
	The version, without the `v` of the tag, like `10.1.0`.
	*/
	var version: String {
		String(tagName.trimmingPrefix("v"))
	}
}
