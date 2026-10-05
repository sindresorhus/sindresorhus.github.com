import Elementary
import Foundation
import SiteKit

/**
A page written in Markdown, like `/donate`. The about page is ``AboutPage``.
*/
struct MarkdownContentPage: Page {
	let page: MarkdownPage

	var path: RoutePath {
		page.path
	}

	var sitemapEntry: SitemapEntry? {
		SitemapEntry(lastModified: page.lastCommitDate)
	}

	var metadata: PageMetadata {
		PageMetadata(title: page.title, description: page.description)
	}

	var body: some HTML {
		ProsePage(photo: page.frontmatter.photo, markdown: page.markdown.content)
	}
}
