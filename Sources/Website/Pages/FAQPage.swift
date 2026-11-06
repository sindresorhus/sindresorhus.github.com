import Elementary
import Foundation
import SiteKit

/**
The general FAQ (``MarkdownPage/Kind/faq``). Below its introduction, it has a menu to the FAQ of each app, as most questions are about one app, and a link to each section, as the page is long.
*/
struct FAQPage: Page {
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

	var body: some HTML {
		ProsePage {
			if let (introduction, sections) = page.markdown.content.separatedBeforeFirstSection {
				introduction

				// After the sentence of the introduction that says that the questions about one app are on its page.
				OverflowMenu(label: "FAQ of an app", links: appFAQLinks, variant: .picker(title: "Choose an app…"))

				// The links come from the headings, so a new section gets a link.
				ChipNavigation(label: "Sections", links: page.markdown.headings.filter { $0.level == .h2 }.map { LabeledLink($0.text, destination: .fragment($0.id)) }, scrollsOnPhones: true)
					.style {
						$0
							.margin(.top, .rootEm(2))
							.justifyContent(.start)
					}

				sections
			} else {
				page.markdown.content
			}
		}
	}

	/**
	The FAQ sections of the apps that have one, by title, like on the feedback form.
	*/
	private var appFAQLinks: [LabeledLink] {
		content.activeAppsWithPages
			.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard))
			.compactMap { app in
				app.faqDestination.map { LabeledLink(app.title, destination: $0) }
			}
	}
}
