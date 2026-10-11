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

	var metadata: PageMetadata {
		PageMetadata(
			title: "Blog",
			description: "Articles by Sindre Sorhus about open source and programming."
		)
	}

	var body: some HTML {
		section {
			PageHeader(title: "Blog")

			ul {
				for post in posts {
					li {
						BlogPostRow(post: post)
					}
				}
			}
			.style(Styles.list)
		}
		.style(Styles.root)
	}
}

extension BlogIndexPage {
	enum Styles: StyleSet {
		case root
		case list

		var style: Style {
			switch self {
			case .root:
				// The column of prose pages, so the title lines up with theirs, and the space below the title of prose pages.
				Style()
					.pageColumn(.prose)
			case .list:
				// A gap, not a margin below each post, so the last post adds no space above the footer.
				Style()
					.vstack(spacing: .rootEm(2.5))
					.from(.tablet) {
						$0.gap(.rootEm(4))
					}
			}
		}
	}
}
