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

			// A link to each topic, as the page is long.
			ChipNavigation(label: "Topics", links: topics.map { LabeledLink($0.topic.title, destination: .fragment($0.topic.rawValue)) }, scrollsOnPhones: true)
				.style {
					$0.justifyContent(.start)
				}

			for (topic, guides) in topics {
				Section(topic.title, id: ElementID(topic.rawValue)) {
					ul {
						for (index, guide) in guides.enumerated() {
							li {
								// The first rows of the first topic are in view when the page opens, also on phones.
								ArticleRow(.guide(guide), headingLevel: .h3, isAboveFold: topic == topics.first?.topic && index < 3)
							}
						}
					}
					// Less space than between posts, as the titles of the guides are smaller.
					.style {
						$0
							.vstack(spacing: .rootEm(2))
							.from(.tablet) {
								$0.gap(.rootEm(2.5))
							}
					}
				}
			}
		}
		.style(BlogIndexPage.Styles.root)
	}
}
