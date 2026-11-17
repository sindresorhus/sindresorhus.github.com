import Elementary
import Foundation
import SiteKit

/**
The guides of one topic (``Guide/Topic``), like the menu bar guides, in one list with the rows of the list of guides (``GuideList``), like a category page of the apps (``AppCategoryPage``), so a search for the guides of a topic lands on a short list, not on the long list of all guides. It has no introduction, as the title says what the guides are about.

The site only has the page when the topic has guides (``Site/specialPages``).
*/
struct GuideTopicPage: Page {
	let topic: Guide.Topic
	let content: SiteContent

	var path: RoutePath {
		topic.path
	}

	private var guides: [Guide.Resolved] {
		content.guides(of: topic)
	}

	var sitemapEntry: SitemapEntry {
		guides.map(\.guide).listSitemapEntry
	}

	/**
	The description says what the guides do (``Guide/Topic/summary``), as the title above it names the topic, like on the social card. It does not have the number of guides, which changes.
	*/
	var metadata: PageMetadata {
		PageMetadata(
			title: topic.guidesTitle,
			description: "\(topic.summary) Each guide has an app and the built-in way.",
			feeds: [SiteFeed.newGuides.link]
		)
	}

	/**
	The list of guides, as the page is a part of it, like a category page is a part of the apps.
	*/
	var parents: [LabeledLink] {
		[.guides]
	}

	/**
	The icons of the apps with the most guides on the page, and the title of the page.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(ofMostCommon: guides.map(\.app), project: content.project)))
	}

	var body: some HTML {
		GuideListPage(title: topic.guidesTitle) {
			GuideList(guides: guides, headingLevel: .h2, isAboveFold: true)
				// From tablets, the space below the title is larger than the space between the guides, so the title does not read as one more row.
				.style {
					$0.from(.tablet) {
						$0.margin(.top, .rootEm(2.5))
					}
				}
		}
	}
}
