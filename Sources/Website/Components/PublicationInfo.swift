import Elementary
import Foundation
import SiteKit

/**
The month a post was published and its reading time, like “May 2023 — 4 min read”.
*/
struct PublicationInfo: HTML {
	let post: BlogPost
	let showsReadingTime: Bool

	var body: some HTML {
		DateText(post.publicationDate, format: .siteMonth)

		if showsReadingTime {
			" — \(post.readingTime) min read"
		}
	}
}
