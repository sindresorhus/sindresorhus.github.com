import Elementary
import Foundation
import SiteKit

/**
A page written in Markdown, like `/donate`. The about page is ``AboutPage``.
*/
struct MarkdownContentPage: Page {
	let page: MarkdownPage
	let project: Project

	var path: RoutePath {
		page.path
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, project: project))
	}

	var sitemapEntry: SitemapEntry {
		page.sitemapEntry
	}

	var metadata: PageMetadata {
		page.metadata
	}

	var body: some HTML {
		ProsePage(photo: page.frontmatter.photo) {
			page.markdown.content
		}
	}
}
