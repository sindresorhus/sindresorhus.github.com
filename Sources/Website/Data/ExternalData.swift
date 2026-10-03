import Foundation
import SiteKit

/**
The App Store info of an app, like the price and rating, from the US App Store.

Mac App Store apps always have a rating count of 0.
*/
public struct AppStoreInfo: Decodable, Sendable {
	public let trackId: Int
	public let version: String?
	public let price: Double?
	public let currency: String?
	public let averageUserRating: Double?
	public let userRatingCount: Int?

	/**
	The price for the app page, like “$4.99, one-time purchase” or “Free”. A paid app that is free to download has an in-app purchase.
	*/
	func priceText(isPaid: Bool) -> String? {
		guard
			let price,
			let currency
		else {
			return nil
		}

		guard price > 0 else {
			return isPaid ? "Free to download, with an in-app purchase" : "Free"
		}

		return "\(price.formatted(.currency(code: currency).locale(Locale(identifier: "en_US")).precision(.fractionLength(price.rounded() == price ? 0 : 2)))), one-time purchase"
	}

	/**
	Looks up the apps with one request.

	The info only adds structured data to the app pages, so a failed request returns no info instead of failing the build.
	*/
	static func lookup(ids: [Int], cache: ResponseCache) async -> [Int: Self] {
		struct Response: Decodable {
			let results: [AppStoreInfo]
		}

		guard
			!ids.isEmpty,
			let url = URL(string: "https://itunes.apple.com/lookup?id=\(ids.map(String.init).joined(separator: ","))")
		else {
			return [:]
		}

		do {
			let response = try await cache.decoded(Response.self, from: URLRequest(url: url, timeoutInterval: 15))
			return Dictionary(response.results.map { ($0.trackId, $0) }) { first, _ in first }
		} catch {
			print("Warning: Could not get App Store info, so app pages have less structured data: \(error)")
			return [:]
		}
	}
}

/**
A review of an app on the US App Store.
*/
public struct AppStoreReview: Hashable, Sendable {
	public let title: String
	public let text: String
	public let author: String
	public let rating: Int
	public let date: Date

	/**
	The most recent five-star reviews of each app, at most three, from the public reviews feed of the US App Store. Reviews that are very short or long are left out, so they fit the page.

	The reviews are extra, so a failed request leaves out the reviews of that app instead of failing the build.
	*/
	static func recentFiveStar(appIDs: [Int], cache: ResponseCache) async -> [Int: [Self]] {
		await withTaskGroup(of: (Int, [Self]).self) { group in
			for id in Set(appIDs) {
				group.addTask {
					guard let url = URL(string: "https://itunes.apple.com/us/rss/customerreviews/id=\(id)/sortBy=mostRecent/json") else {
						return (id, [])
					}

					do {
						let feed = try await cache.decoded(ReviewFeed.self, from: URLRequest(url: url, timeoutInterval: 15))
						return (id, Array(feed.reviews.filter(\.isShowable).prefix(3)))
					} catch {
						print("Warning: Could not get the App Store reviews of app \(id): \(error)")
						return (id, [])
					}
				}
			}

			return await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
		}
	}

	private var isShowable: Bool {
		rating == 5 && (40...360).contains(text.count) && !title.isEmpty
	}
}

/**
The reviews feed of the App Store. Its `entry` is a list, one object for one review, or missing without reviews.
*/
private struct ReviewFeed: Decodable {
	private struct Label: Decodable {
		let label: String
	}

	private struct Entry: Decodable {
		struct Author: Decodable {
			let name: Label
		}

		let author: Author
		let title: Label
		let content: Label
		let rating: Label
		let updated: Label

		enum CodingKeys: String, CodingKey {
			case author
			case title
			case content
			case rating = "im:rating"
			case updated
		}
	}

	private enum CodingKeys: String, CodingKey {
		case feed
		case entry
	}

	let reviews: [AppStoreReview]

	init(from decoder: any Decoder) throws {
		let feed = try decoder.container(keyedBy: CodingKeys.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .feed)

		let entries: [Entry] = if let list = try? feed.decode([Entry].self, forKey: .entry) {
			list
		} else if let entry = try? feed.decode(Entry.self, forKey: .entry) {
			[entry]
		} else {
			[]
		}

		self.reviews = try entries.map { entry in
			AppStoreReview(
				title: entry.title.label.trimmingCharacters(in: .whitespacesAndNewlines),
				text: entry.content.label.trimmingCharacters(in: .whitespacesAndNewlines),
				author: entry.author.name.label,
				rating: Int(entry.rating.label) ?? 0,
				date: try Date(entry.updated.label, strategy: .iso8601)
			)
		}
	}
}

public struct GitHubRelease: Decodable, Sendable {
	public let tagName: String
	public let publishedAt: Date
	public let body: String?
	public let isDraft: Bool
	public let isPrerelease: Bool

	/**
	The release notes rendered as HTML, once when the releases load. Empty when there are no notes.
	*/
	public internal(set) var notesHTML = ""

	enum CodingKeys: String, CodingKey {
		case tagName = "tag_name"
		case publishedAt = "published_at"
		case body
		case isDraft = "draft"
		case isPrerelease = "prerelease"
	}

	/**
	The version without the `v` prefix, like `1.2.0`.
	*/
	public var version: String {
		tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
	}
}

public struct GitHubRepository: Decodable, Sendable {
	public let name: String
	public let description: String?
	public let url: URL
	public let createdAt: Date
	public let isArchived: Bool
	public let isFork: Bool

	enum CodingKeys: String, CodingKey {
		case name
		case description
		case url = "html_url"
		case createdAt = "created_at"
		case isArchived = "archived"
		case isFork = "fork"
	}
}

/**
The GitHub API for the `sindresorhus` account. A token raises the rate limit.
*/
public struct GitHub: Sendable {
	let token: String?
	let cache: ResponseCache

	public init(token: String? = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], cache: ResponseCache) {
		self.token = token
		self.cache = cache
	}

	/**
	The published releases of a repo, newest first.
	*/
	func releases(repository: String) async throws -> [GitHubRelease] {
		let releases: [GitHubRelease] = try await get("repos/sindresorhus/\(repository)/releases?per_page=100")

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
