import Foundation
import SiteKit

struct GitHubRelease {
	let tagName: String
	let publishedAt: Date

	/**
	The release notes rendered as HTML, once when the releases load. Empty when there are no notes.
	*/
	let notesHTML: String

	/**
	The version without the `v` prefix, like `1.2.0`.
	*/
	var version: String {
		String(tagName.trimmingPrefix("v"))
	}

	/**
	A response of the API, before its notes are rendered. A missing publication date means it is not published, like a draft.
	*/
	struct Response: Decodable {
		let tagName: String
		let publishedAt: Date?
		let body: String?
		let isDraft: Bool
		let isPrerelease: Bool

		enum CodingKeys: String, CodingKey {
			case tagName = "tag_name"
			case publishedAt = "published_at"
			case body
			case isDraft = "draft"
			case isPrerelease = "prerelease"
		}
	}
}
