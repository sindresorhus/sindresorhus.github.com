import Foundation
import SiteKit

/**
A post on Bluesky, with the links in its text, for the now page. Sindre posts the same text to X, Mastodon, and Bluesky, and only Bluesky has a free API.
*/
struct BlueskyPost: Sendable {
	/**
	A part of the text, with its link, like a shortened URL with the whole URL.
	*/
	struct Segment: Hashable, Sendable {
		let text: String
		let link: URL?
	}

	/**
	The page of the post on Bluesky.
	*/
	let url: URL

	let date: Date
	let segments: [Segment]

	/**
	The text of the post, without links.
	*/
	var text: String {
		segments.map(\.text).joined()
	}

	static let handle = "sindresorhus.com"

	/**
	The newest post with text, without replies and reposts, from the five newest posts. `nil` when none of them has text, like posts with only an image.
	*/
	static func latest(cache: ResponseCache) async throws -> Self? {
		let url = URL(string: "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=\(handle)&limit=5&filter=posts_no_replies")!
		return try await cache.decoded(AuthorFeed.self, from: URLRequest(url: url, timeoutInterval: 15)).posts.first
	}
}

/**
The posts of an account, newest first. Reposts and the pinned post are in the feed with a `reason`.
*/
private struct AuthorFeed: Decodable {
	private struct Item: Decodable {
		/**
		Any reason, like a repost, as only its presence matters.
		*/
		struct Reason: Decodable {}

		let post: Post
		let reason: Reason?
	}

	private struct Post: Decodable {
		struct Record: Decodable {
			let text: String
			let createdAt: String
			let facets: [Facet]?
		}

		let uri: String
		let record: Record
	}

	/**
	A link in the text, by the byte range of its UTF-8 text.
	*/
	private struct Facet: Decodable {
		struct Index: Decodable {
			let byteStart: Int
			let byteEnd: Int
		}

		struct Feature: Decodable {
			let type: String
			let uri: String?
			let did: String?
			let tag: String?

			enum CodingKeys: String, CodingKey {
				case type = "$type"
				case uri
				case did
				case tag
			}

			/**
			Where the feature links to: a URL, the profile of a mention, or the posts of a hashtag.
			*/
			var link: URL? {
				switch type {
				case "app.bsky.richtext.facet#link":
					uri.flatMap(URL.init(string:)).flatMap { ["http", "https"].contains($0.scheme) ? $0 : nil }
				case "app.bsky.richtext.facet#mention":
					did.flatMap { URL(string: "https://bsky.app/profile/\($0)") }
				case "app.bsky.richtext.facet#tag":
					tag.flatMap { URL(string: "https://bsky.app/hashtag/")?.appending(path: $0) }
				default:
					nil
				}
			}
		}

		let index: Index
		let features: [Feature]
	}

	private let items: [Item]

	enum CodingKeys: String, CodingKey {
		case items = "feed"
	}

	/**
	The posts with text, newest first, without reposts and the pinned post. Posts with a date that cannot be read are left out.
	*/
	var posts: [BlueskyPost] {
		items.compactMap { item in
			guard
				item.reason == nil,
				!item.post.record.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
				let date = Self.date(item.post.record.createdAt),
				let key = item.post.uri.split(separator: "/").last,
				let url = URL(string: "https://bsky.app/profile/\(BlueskyPost.handle)/post/\(key)")
			else {
				return nil
			}

			return BlueskyPost(url: url, date: date, segments: Self.segments(of: item.post.record.text, facets: item.post.record.facets ?? []))
		}
	}

	/**
	The text split into the parts with and without links. Facets that overlap an earlier one or are outside the text are ignored.
	*/
	private static func segments(of text: String, facets: [Facet]) -> [BlueskyPost.Segment] {
		let bytes = Array(text.utf8)
		var segments = [BlueskyPost.Segment]()
		var position = 0

		func slice(_ range: Range<Int>) -> String {
			String(decoding: bytes[range], as: UTF8.self)
		}

		for facet in facets.sorted(using: KeyPathComparator(\.index.byteStart)) {
			guard
				facet.index.byteStart >= position,
				facet.index.byteStart < facet.index.byteEnd,
				facet.index.byteEnd <= bytes.count,
				let link = facet.features.lazy.compactMap(\.link).first
			else {
				continue
			}

			if facet.index.byteStart > position {
				segments.append(.init(text: slice(position..<facet.index.byteStart), link: nil))
			}

			segments.append(.init(text: slice(facet.index.byteStart..<facet.index.byteEnd), link: link))
			position = facet.index.byteEnd
		}

		if position < bytes.count {
			segments.append(.init(text: slice(position..<bytes.count), link: nil))
		}

		return segments
	}

	/**
	The date of a post, with or without fractional seconds, which Bluesky dates have.
	*/
	private static func date(_ text: String) -> Date? {
		try? Date(text, strategy: .iso8601)
	}
}
