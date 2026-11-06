import Elementary
import Foundation
import SiteKit

/**
The list of how-to guides, grouped by topic (``Guide/Topic``), with the look of the blog index, and the icon of the app of each guide.
*/
struct GuidesPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.guides
	}

	var sitemapEntry: SitemapEntry {
		content.guides.listSitemapEntry
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Guides",
			description: Self.intro
		)
	}

	private static let intro = "Short how-to guides for tasks on the Mac and iPhone, with an app for the task and the built-in way."

	var body: some HTML {
		let topics = Guide.Topic.allCases.map { topic in
			(topic: topic, guides: content.resolvedGuides.filter { $0.guide.frontmatter.topic == topic })
		}
		.filter { !$0.guides.isEmpty }

		return section {
			PageHeader(title: "Guides", intro: Self.intro)

			// A link to each topic, as the page is long, and then the page with the guides for people who come from Windows, when it has guides.
			let topicLinks = topics.map { LabeledLink($0.topic.title, destination: .fragment($0.topic.rawValue)) }
			let windowsLinks = content.guidesForWindowsUsers.isEmpty ? [] : [LabeledLink("For Windows Users", destination: .path(.guidesForWindowsUsers))]

			ChipNavigation(label: "Topics", links: topicLinks + windowsLinks, scrollsOnPhones: true)
				.style {
					$0.justifyContent(.start)
				}

			for (topic, guides) in topics {
				Section(topic.title, id: ElementID(topic.rawValue)) {
					// The first rows of the first topic are in view when the page opens, also on phones.
					GuideList(guides: guides, headingLevel: .h3, isAboveFold: topic == topics.first?.topic)
				}
			}
		}
		// The column of the blog index, and on laptops, the wide column of the open-source page, for the two columns of guides.
		.style(BlogIndexPage.Styles.root)
		.style {
			$0.from(.laptop) {
				$0.frame(maxWidth: .length(Style.ColumnWidth.page.maximum))
			}
		}
	}
}

/**
A list of guides as rows with the icon of the app of each guide, like the guides of a topic: one column, and two columns on laptops.
*/
struct GuideList: HTML {
	let guides: [Guide.Resolved]

	/**
	The level of the titles: 3 below the heading of a topic, or 2 right below the title of the page.
	*/
	let headingLevel: ItemHeadingLevel

	/**
	Whether the first rows are in view when the page opens, so their icons load at once.
	*/
	let isAboveFold: Bool

	var body: some HTML<HTMLTag.ul> {
		// Keep the list semantics in Safari, as the styles remove its bullets.
		ul(.role(.list)) {
			for (index, guide) in guides.enumerated() {
				li {
					ArticleRow(.guide(guide), headingLevel: headingLevel, isAboveFold: isAboveFold && index < 3)
				}
			}
		}
		// Less space than between posts, as the titles of the guides are smaller. Two columns on laptops, so a whole topic fits on about one screen.
		.style {
			$0
				.vstack(spacing: .rootEm(2))
				.from(.tablet) {
					$0.gap(.rootEm(2.5))
				}
				.from(.laptop) {
					$0
						.grid(columns: 2)
						.gap(row: .rootEm(2.5), column: .rootEm(3))
				}
		}
	}
}
