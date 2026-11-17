import Elementary
import Foundation
import SiteKit

/**
A page written in Markdown, like `/donate`. The about page is ``AboutPage``.
*/
struct MarkdownContentPage: Page {
	let page: MarkdownPage
	let content: SiteContent

	var path: RoutePath {
		page.path
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, project: content.project))
	}

	var sitemapEntry: SitemapEntry {
		page.sitemapEntry
	}

	var metadata: PageMetadata {
		page.metadata
	}

	/**
	The titles of its sections, like “Black Friday” on the discounts page.
	*/
	var searchKeywords: [String] {
		page.markdown.headings.filter { $0.level == .h2 }.map(\.text)
	}

	var body: some HTML {
		ProsePage(photo: page.frontmatter.photo) {
			page.markdown.content
		}
	}
}
