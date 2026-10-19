import Elementary
import Foundation
import SiteKit

/**
The month a post was published and its reading time, like “May 2023 — 4 min read”. A post that redirects to another site only has the month, as its text is not here.
*/
struct PublicationInfo: HTML {
	let post: BlogPost

	var body: some HTML {
		DateText(post.publicationDate, format: .siteMonth)

		if !post.isRedirect {
			" — \(post.readingTime) min read"
		}
	}
}
