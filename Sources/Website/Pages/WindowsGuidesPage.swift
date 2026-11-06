import Elementary
import Foundation
import SiteKit

/**
The guides for people who come from Windows, like how to cut and paste files or delete a file with the Delete key: the guides with `isForWindowsUsers: true` in their frontmatter, in one list, with the rows of the list of guides (``GuideList``). The guides stay in their topics on ``GuidesPage``, which links to this page.

The site only has the page when a guide is for it (``Site/specialPages``).
*/
struct WindowsGuidesPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.guidesForWindowsUsers
	}

	var sitemapEntry: SitemapEntry {
		content.guidesForWindowsUsers.map(\.guide).listSitemapEntry
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: Self.title,
			description: Self.intro
		)
	}

	private static let title = "Mac Guides for Windows Users"
	private static let intro = "New on the Mac? These short guides show how to do the things that you did on Windows, like cut and paste files, with an app for the task and the built-in way."

	var body: some HTML {
		section {
			PageHeader(title: Self.title) {
				Self.intro
				" See also "
				a(.href(.path(.guides))) {
					"all guides"
				}
				"."
			}

			GuideList(guides: content.guidesForWindowsUsers, headingLevel: .h2, isAboveFold: true)
				// From tablets, the space below the introduction is larger than the space between the guides, like on the blog index.
				.style {
					$0.from(.tablet) {
						$0.margin(.top, .rootEm(5))
					}
				}
		}
		// The column of the blog index, and on laptops, the wide column of the list of guides, for the two columns.
		.style(BlogIndexPage.Styles.root)
		.style {
			$0.from(.laptop) {
				$0.frame(maxWidth: .length(Style.ColumnWidth.page.maximum))
			}
		}
	}
}
