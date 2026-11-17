import Elementary
import Foundation
import SiteKit

/**
The general FAQ (``MarkdownPage/Kind/faq``). At the end of its introduction, it has a menu to the FAQ of each app, as most questions are about one app, and a link to each section, as the page is long. It ends with the line of the FAQ of an app page, which links to the feedback form.
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

	var searchKeywords: [String] {
		["FAQ", "help"]
	}

	var body: some HTML {
		ProsePage {
			if let (introduction, sections) = page.markdown.content.separatedBeforeFirstSection {
				// The menu is at the end of the sentence of the introduction that says that the questions about one app are on its page, so it reads as the answer to the sentence. The title, the sentence, and the menu are rows that wrap, with the space of the introduction between the rows, so on a phone, the menu goes below the sentence with the same space as below the title.
				div {
					introduction

					OverflowMenu(label: "FAQ of an app", links: appFAQLinks, variant: .picker(title: "Choose an app…"))
				}
				.style {
					$0
						.hstack(alignment: .center)
						.flexWrap()
						.gap(row: PageHeaderStyles.introSpacing, column: .rootEm(0.5))
						// The space below the introduction, which the gaps replace for the title and the sentence.
						.margin(.bottom, .rootEm(2.5))
						.children("h1") {
							$0
								.frame(width: .percent(100))
								.margin(.zero)
						}
						.children("p") {
							$0.margin(.zero)
						}
				}

				// The links come from the headings, so a new section gets a link.
				ChipNavigation(label: "Sections", links: page.markdown.headings.filter { $0.level == .h2 }.map { LabeledLink($0.text, destination: .fragment($0.id)) }, scrollsOnPhones: true)
					.style {
						$0
							.margin(.top, .rootEm(2))
							.textAlign(.leading)
					}

				sections
			} else {
				page.markdown.content
			}

			// The same open line as the end of the FAQ of an app page, after all the sections, so the way to ask is not hidden in a closed question.
			UnansweredQuestionNote(feedback: .path(.feedback)) {
				" You could also try to "

				a(.href("https://chatgpt.com/g/g-df0ZoBF9N-sindregpt")) {
					"ask my AI bot"
				}

				"."
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

/**
The line at the end of a list of questions, where a visitor who did not find the answer gives up, so it says that a message is welcome, like at the end of the FAQ of an app page. The extra content follows it, like another way to ask.
*/
struct UnansweredQuestionNote<Extra: HTML>: HTML {
	let feedback: LinkDestination
	@HTMLBuilder let extra: Extra

	var body: some HTML<HTMLTag.p> {
		p {
			"Did not find the answer? "

			a(.href(feedback)) {
				"Send me a message"
			}

			". I read and reply to all messages."

			extra
		}
		.style {
			$0.secondaryText()
		}
	}
}

extension UnansweredQuestionNote<EmptyHTML> {
	init(feedback: LinkDestination) {
		self.init(feedback: feedback) {}
	}
}
