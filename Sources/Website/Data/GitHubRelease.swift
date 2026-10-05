import Foundation
import SiteKit

struct GitHubRelease: Decodable, Sendable {
	let tagName: String
	let publishedAt: Date
	let body: String?
	let isDraft: Bool
	let isPrerelease: Bool

	/**
	The release notes rendered as HTML, once when the releases load. Empty when there are no notes.
	*/
	var notesHTML = ""

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
	var version: String {
		String(tagName.trimmingPrefix("v"))
	}

	/**
	A release in a response of the API. The release is `nil` when it has no publication date, like a draft.
	*/
	struct Entry: Decodable {
		let release: GitHubRelease?

		init(from decoder: any Decoder) throws {
			let isPublished = try !decoder.container(keyedBy: CodingKeys.self).decodeNil(forKey: .publishedAt)
			self.release = isPublished ? try GitHubRelease(from: decoder) : nil
		}
	}
}
