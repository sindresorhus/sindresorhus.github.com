import Elementary
import Foundation
import SiteKit

/**
A page written in Markdown, like `/about`.
*/
struct MarkdownContentPage: Page {
	let page: MarkdownPage

	var path: RoutePath {
		page.path
	}

	var lastModified: Date? {
		page.lastCommitDate
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled(page.frontmatter.title.value), description: page.frontmatter.description?.value)
	}

	var body: some HTML {
		ProsePage(isSpacious: true, html: page.markdown.html)
	}
}
