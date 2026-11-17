import Elementary
import Foundation
import SiteKit

/**
The list of how-to guides, grouped by topic (``Guide/Topic``), with the look of the blog index, and the icon of the app of each guide. Each topic also has a page of its own (``GuideTopicPage``), and the list ends with the apps that the guides are about.
*/
struct GuidesPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.guides
	}

	var sitemapEntry: SitemapEntry {
		content.guides.map(\.guide).listSitemapEntry
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Guides",
			description: Self.intro,
			feeds: [SiteFeed.newGuides.link]
		)
	}

	private static let intro = "Short how-to guides for tasks on the Mac and iPhone, with an app for the task and the built-in way."

	/**
	The most guides of a topic that all show on phones. A topic with more shows the first 4 (``Styles/shortOnPhones``) and a link to its page, as a row of 1 or 2 more guides saves almost no space.
	*/
	private static let phoneGuideLimit = 6

	/**
	The icons of the apps with the most guides, and the introduction of the page.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(ofMostCommon: content.guides.map(\.app), project: content.project)))
	}

	var body: some HTML {
		let topics = Guide.Topic.allCases.map { topic in
			(topic: topic, guides: content.guides(of: topic))
		}
		.filter { !$0.guides.isEmpty }

		return section {
			PageHeader(title: "Guides", intro: Self.intro)

			// A link to each topic, as the page is long, and then the pages with the guides for an audience, like for people who come from Windows, that have guides, and a random guide, like the random app, so a visitor can find a useful trick by chance.
			let topicLinks = topics.map { LabeledLink($0.topic.title, destination: .fragment($0.topic.id)) }
			let audienceLinks = content.audiencesWithGuides.map { ChipNavigation.PageLink(link: LabeledLink($0.chipTitle, destination: .path($0.path))) }
			let randomLink = ChipNavigation.PageLink(link: LabeledLink("Random Guide", destination: .path(.randomGuide)), icon: .shuffle)

			ChipNavigation(
				label: "Topics",
				links: topicLinks,
				lastChip: .pageLinks(audienceLinks + [randomLink]),
				scrollsOnPhones: true
			)
				.style {
					$0.textAlign(.leading)
				}

			// The guides with the most visits of the last 30 days, which answer the most common questions, so they are the best start. Only with the visits from GoatCounter (``SiteContent/mostReadGuides``).
			if !content.mostReadGuides.isEmpty {
				Section("Most Read This Month", id: ElementID("most-read")) {
					GuideList(guides: content.mostReadGuides, headingLevel: .h3, isAboveFold: true)
				}
			}

			for (topic, guides) in topics {
				// The title links to the page of the topic (``GuideTopicPage``).
				Section(topic.title, id: topic.id, link: topic.path) {
					// The first rows of the first section are in view when the page opens, also on phones.
					GuideList(guides: guides, headingLevel: .h3, isAboveFold: content.mostReadGuides.isEmpty && topic == topics.first?.topic)
						.style(Styles.shortOnPhones, when: guides.count > Self.phoneGuideLimit)

					// On phones, a topic with many guides shows its first guides and a link to the page of the topic, so the page is not many screens tall for each topic. The other guides stay in the HTML.
					if guides.count > Self.phoneGuideLimit {
						p {
							a(.href(.path(topic.path))) {
								topic.allGuidesTitle(count: guides.count)
							}
							.style {
								$0.guideEndLink()
							}
						}
						.style {
							$0
								.margin(top: .rootEm(2), horizontal: .zero, bottom: .zero)
								.textStyle(.body)
								.hstack(justification: .center)
								.hidden(from: .tablet)
						}
					}
				}
			}

			// The apps that 2 or more guides are about, the app with the most guides first, so a user of an app finds its guides, which the end of its page lists by topic. The numbers are left out, like on the other lists.
			let appLinks = content.guides.flatMap(\.apps).mostCommonFirst
				.filter { $0.count >= 2 }
				.map { LabeledLink($0.app.title, destination: .path($0.app.path, fragment: App.Section.guides.id), iconOf: $0.app) }

			if !appLinks.isEmpty {
				Section("Guides by App", id: ElementID("apps")) {
					ChipNavigation(label: "Guides by app", links: appLinks)
						.style {
							$0.textAlign(.leading)
						}
				}
			}
		}
		// The column of the blog index, and on laptops, the wide column of the open-source page, for the two columns of guides.
		.style(BlogIndexPage.Styles.root)
		.style {
			$0
				.from(.laptop) {
					$0.frame(maxWidth: .length(Style.ColumnWidth.page.maximum))
				}
				// Twice the space between the guides, so a new topic reads as a new group, not as one more row. The first topic keeps the space below the chips.
				.children("section + section") {
					$0.margin(.top, .rootEm(5))
				}
				// The title of a topic stays at the top of the screen, below the header of the site, while its guides scroll, so a visitor in the middle of the long list sees which topic it is. It is in the section of its topic, so the title of the next topic pushes it away. It is opaque and as wide as the screen, so the guides scroll under it, with a line below it that keeps it apart from them.
				.children("section") {
					// On phones, one step smaller, like the years of the app timeline, so the long titles, like “Lock Screen and Home Screen”, are one line, and the title that stays takes less of the screen.
					$0.children(SectionStyles.title.selector) {
						$0
							.stickySectionTitle()
							.below(.smallTablet) {
								$0.textStyle(.title3)
							}
					}
					// A guide that the keyboard focuses scrolls into view below the title, also a title on two lines on a small phone, not under it.
					.descendants("a") {
						$0.scrollMargin(top: .rootEm(4.5))
					}
				}
		}
	}

	enum Styles: String, StyleSet {
		/**
		The list of guides of a topic with many guides, which shows only its first 4 guides on phones, about a screen, and all from tablets, where the page shows no link to the page of the topic.
		*/
		case shortOnPhones

		var style: Style {
			switch self {
			case .shortOnPhones:
				Style().below(.tablet) {
					$0.children("li:nth-child(n + 5)") {
						$0.hidden()
					}
				}
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

/**
A page with a part of the list of guides (``GuidesPage``), like the guides of a topic (``GuideTopicPage``) or of an audience (``AudienceGuidesPage``): a link back to all guides, the title, and the content below it, in the column of the list of guides, for the two columns, or in the column of prose for a page without the two columns (`isWide`), like the table of the keyboard shortcuts.
*/
struct GuideListPage<Content: HTML>: HTML {
	let title: String
	var intro: String?
	var isWide = true
	@ContentBuilder let content: Content

	var body: some HTML<HTMLTag.section> {
		section {
			// A visitor from a search result or a shared link can get to the other guides, like from a category page to the other apps (``AppCategoryPage``).
			div {
				BackLink(title: "All Guides", path: .guides)
			}
			.style {
				$0.margin(.bottom, .rootEm(1.5))
			}

			PageHeader(title: title, intro: intro)

			content
		}
		// The column of the blog index, and on laptops, the wide column of the list of guides, for the two columns.
		.style(BlogIndexPage.Styles.root)
		.style {
			$0.from(.laptop) {
				$0.frame(maxWidth: .length((isWide ? Style.ColumnWidth.page : .prose).maximum))
			}
		}
	}
}

extension Style {
	/**
	The title of a section of a long list, which stays at the top of the screen, below the header of the site, while the items of its section scroll, like the topics of the guides and the years of the app timeline, so a visitor in the middle of the list sees which section it is. It is in the element of its section, so the title of the next section pushes it away. It is opaque, so the items scroll under it, with a line below it that keeps it apart from them.
	*/
	func stickySectionTitle() -> Self {
		stickyBelowSiteHeader()
			.padding(.vertical, .rootEm(0.5))
			// The width of the items, so its line is the edge of the list, like a rule between sections.
			.border(.bottom, .separator)
	}

	/**
	An element that stays at the top of the screen, below the header of the site, while the rest of its parent scrolls under it, like the title of a section of a long list (``stickySectionTitle()``) or the filter field of a long list. It is opaque, with the background of the page, so the items scroll under it. It stops at the end of its parent.
	*/
	func stickyBelowSiteHeader() -> Self {
		position(.sticky)
			.top(.length(SiteHeader.height))
			// Above the items, like their icons, which scroll under it.
			.zIndex(1)
			.background(.pageBackground)
			// The header scrolls with the page on short screens (``SiteHeader``), so the element stays at the top of the screen there.
			.media(.shortScreen) {
				$0.top(.zero)
			}
	}
}
