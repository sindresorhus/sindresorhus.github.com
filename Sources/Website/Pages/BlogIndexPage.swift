import Elementary
import Foundation
import SiteKit

/**
The list of blog posts.
*/
struct BlogIndexPage: Page {
	let posts: [BlogPost]

	var path: RoutePath {
		.blog
	}

	var sitemapEntry: SitemapEntry {
		posts.listSitemapEntry
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Blog",
			description: "Articles by Sindre Sorhus about open source and programming."
		)
	}

	var body: some HTML {
		section {
			PageHeader(title: "Blog", intro: "Posts about open source, programming, and making apps.")

			// Keep the list semantics in Safari, as the styles remove its bullets.
			ul(.role(.list)) {
				for post in posts {
					li {
						ArticleRow(.post(post))
					}
				}
			}
			.style(Styles.list)
		}
		.style(Styles.root)
	}
}

extension BlogIndexPage {
	enum Styles: String, StyleSet {
		case root
		case list

		var style: Style {
			switch self {
			case .root:
				// The column of prose pages, so the title lines up with theirs, and the space below the title of prose pages.
				Style()
					.pageColumn(.prose)
			case .list:
				// A gap, not a margin below each post, so the last post adds no space above the footer. From tablets, the space below the introduction is larger than the space between the posts, so the first post does not look like a part of the introduction.
				Style()
					.vstack(spacing: .rootEm(2.5))
					.from(.tablet) {
						$0
							.gap(.rootEm(4))
							.margin(.top, .rootEm(5))
					}
			}
		}
	}
}
