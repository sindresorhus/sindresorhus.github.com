import Elementary
import Foundation
import SiteKit

struct AppPage: Page {
	let app: App
	let content: SiteContent

	var path: RoutePath {
		app.path
	}

	var navigation: SiteHeader.Variant {
		.app(app, hasGuides: hasGuides)
	}

	/**
	An archived app is below the list of archived apps, where the apps page lists it, so a visitor from an old link sees what “archived” means and the other archived apps, like “Apps › Archived Apps › Jiffy”.
	*/
	var parents: [LabeledLink] {
		app.isArchived ? [.apps, LabeledLink(AppCategory.archived.title, path: AppCategory.archived.path)] : [.apps]
	}

	/**
	Whether guides are about the app, which the end of the page lists, and the “…” menus link to.
	*/
	private var hasGuides: Bool {
		!content.guides(about: app).isEmpty
	}

	/**
	With the icon, the screenshots, and the demo videos, like in the structured data. An unlisted app is left out, as it is not indexed, like it is left out of the app lists, and like an unlisted post.
	*/
	var sitemapEntry: SitemapEntry {
		let videos = app.media.compactMap(\.video).map { video in
			SitemapEntry.Video(
				title: app.demoVideoTitle,
				description: app.subtitle,
				thumbnail: AbsoluteURL(video.poster.absoluteURL),
				content: AbsoluteURL(video.path.absoluteURL)
			)
		}

		return SitemapEntry(
			lastModified: app.lastModified,
			images: ([app.iconURL] + app.screenshotURLs).map { AbsoluteURL($0) },
			videos: videos
		)
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(app: app, project: content.project))
	}

	var linkTitle: String {
		app.title
	}

	var metadata: PageMetadata {
		let title = "\(app.title): \(app.subtitle)"

		return PageMetadata(
			title: title,
			description: app.description,
			// With the subtitle, as compact link previews, like in Messages, show only the title and the domain, but without the site name, which is already in `og:site_name`, and which search results show above the title.
			isTitleStandalone: true,
			// Search engines do not index an unlisted app, like it is not in the sitemap.
			isIndexed: app.isListed,
			appStoreID: app.showsAppStoreBanner ? app.appStoreID : nil,
			favicon: app.iconPath,
			video: app.media.lazy.compactMap(\.video).first,
			feeds: app.releaseNotes.map { [$0.feed] } ?? [],
			discordEmbed: discordEmbed
		)
	}

	/**
	The link preview of the page in Discord, like a small store page: the name with a link to the page, the description, and the icon, the first three screenshots, and the places to get the app as buttons, in the order of the buttons of the page.
	*/
	private var discordEmbed: DiscordEmbed {
		let screenshots = app.screenshots.prefix(3).map(\.path.absoluteURL)
		let buttons = app.downloadOptions.map { (title: $0.title, url: $0.url.absoluteURL(on: app.path)) }

		let components: [DiscordEmbed.Component?] = [
			.text("## [\(app.title)](\(app.absoluteURL.absoluteString))\n\(app.description)", thumbnail: app.iconURL),
			screenshots.isEmpty ? nil : .gallery(screenshots),
			buttons.isEmpty ? nil : .separator,
			buttons.isEmpty ? nil : .linkButtons(buttons),
		]

		return DiscordEmbed(components: components.compactMap(\.self))
	}

	var body: some HTML {
		section {
			// The random app page links to `#another-random-app`, which shows the “Another Random App” button. The ID is at the top, and its scroll margin is taller than the screen, so the page does not scroll, not even by the space that the sticky header keeps above a target.
			article(.id(AppHero.anotherRandomAppID)) {
				let separatedContent = app.markdown.contentSeparatingIntroduction

				AppHero(listing: listing, introduction: separatedContent?.introduction, hasGuides: hasGuides)

				// A sale that the app is in today comes before the announcement of the app, like a bundle, as it ends soon, and one banner is enough.
				let banner = content.sale(of: app).map { AnnouncementBanner(sale: $0, app: app) } ?? app.announcement.map(AnnouncementBanner.init(announcement:))

				// The space below is the space between the parts, so the screenshots are not far from it.
				if let banner {
					banner
						.style {
							$0.margin(.top, .length(.partSpacing(rootEm: 4.5)))
						}
				}

				if !app.media.isEmpty {
					AppMedia(app: app)
				}

				if !app.pressQuotes.isEmpty {
					PressQuotes(quotes: app.pressQuotes)
						.style {
							$0
								.margin(.top, .length(.partSpacing(rootEm: 7)))
								.margin(.bottom, .length(.partSpacing(rootEm: 6)))
						}
				}

				// The reviews come after the description of the app and before its first section, like the trial or the FAQ, so visitors know what the app does before they read what others think of it.
				let remainder = separatedContent?.remainder ?? app.markdown.content
				let sections = remainder.separatedBeforeFirstSection
				let description = sections?.before ?? remainder

				if !description.html.rawValue.allSatisfy(\.isWhitespace) {
					Prose(markdown: description)
				}

				// After the features, a visitor who already uses another app asks how this one is different, and the answers are far down in the FAQ. The label and the chips are one row, like “Compared with Clock widget”, and the chips go below the label when they do not fit next to it.
				if !comparisonLinks.isEmpty {
					div {
						p {
							"Compared with"
						}
						.style {
							$0
								.margin(.zero)
								.textStyle(.headline)
						}

						ChipNavigation(label: "Compared with", links: comparisonLinks)
							.style {
								$0.textAlign(.leading)
							}
					}
					.style {
						$0
							.contentColumn(.prose)
							.hstack(alignment: .center)
							.flexWrap()
							.gap(row: .rootEm(0.5), column: .rootEm(0.75))
					}
				}

				// Testimonials stand alone; eligible store and Setapp ratings are shown in the app information, even without reviews.
				if let reviews = AppReviews(listing: listing) {
					// The wall of love only has the reviews of the active apps, so another app, or an app without reviews, has no link to it. An app with no more reviews than the page shows has no link either, as the wall would show the same quotes.
					reviews
						.style {
							$0.margin(.vertical, .length(.partSpacing(rootEm: 6)))
						}
				}

				if let sections {
					Prose(markdown: sections.after)
				}

				// The end of the page is set apart from the text above it, like the FAQ.
				if app.isDownloadable {
					// The announcement again, right above the box, so a visitor who reads the whole page and gets the app at its end sees it too, like a bundle or a sale. It has the space above the box.
					if let banner {
						banner
							.style {
								$0.margin(.top, .length(.partSpacing(rootEm: 9)))
							}
					}

					AppCallToAction(listing: listing, buildDate: content.buildDate, trialDialogID: AppHero.trialDialogID)
						.style {
							// Until there is space at its sides (``Breakpoint/proseWithGutters``), the panel is as wide as the screen, so it has no corners and no edges at its sides.
							$0
								.margin(.top, .length(.partSpacing(rootEm: 9)))
								.directlyAfter(AnnouncementBanner.Styles.root.selector) {
									$0.margin(.top, .rootEm(1.5))
								}
								.below(.proseWithGutters) {
									$0
										.cornerRadius(.zero)
										.border(.horizontal, width: .zero)
								}
						}
				}

				// The box to get the app has the facts, so an app that cannot be downloaded yet shows them alone.
				if
					!app.isDownloadable,
					!app.isArchived
				{
					AppFacts(listing: listing, buildDate: content.buildDate)
						.style {
							// Until there is space at its sides (``Breakpoint/proseWithGutters``), it has the space of the page at its sides, like the text above it, as it has no box around it.
							$0
								.margin(.vertical, .length(.partSpacing(rootEm: 9)))
								.below(.proseWithGutters) {
									$0.padding(.horizontal, .pageGutter)
								}
						}
				}

				// The links about the app belong to the app, so they come before the other apps. An archived app can have none.
				let footerLinks = AppFooterLinks(app: app, guides: content.guides(about: app))

				if !footerLinks.isEmpty {
					footerLinks
						.style {
							$0.margin(.top, .length(.partSpacing(rootEm: 5)))
						}
				}

				let relatedApps = app.relatedApps(from: content.activeApps, on: content.buildDate)

				if !relatedApps.isEmpty {
					RelatedApps(relatedApps: relatedApps, content: content)
						.style {
							$0.margin(.top, .length(.partSpacing(rootEm: 8)))
						}
				}
			}
			.style(Styles.article)
		}
		.style(Styles.root)

		JSONScript(schema: Schema.SoftwareApplication(listing: listing, buildDate: content.buildDate))

		if let script = app.script {
			ModuleScript(script)
		}
	}

	private var listing: AppListing {
		content.listing(of: app)
	}

	/**
	The questions of the FAQ that compare the app with another app or feature (`@faq.compares`), as links to their answers, with the name of the other app, like “MeetingBar”. The page opens the question that a link points to.

	Then the questions of my other apps that compare them with this app, as links to the answers on their pages, like “Menu Bar Calendar” on the page of Dato for “What does Dato add?”, so a comparison of two of my apps shows on both pages. An app that the page already compares with gets no second chip.

	A link about one of my other apps has its icon, unless the app has only the placeholder icon, so a visitor sees that the comparison is with an app of mine.
	*/
	private var comparisonLinks: [LabeledLink] {
		let links: [LabeledLink] = app.faqHeadings.compactMap { heading in
			heading[FAQDirectives.Compares.self].map { name in
				LabeledLink(name, destination: .fragment(heading.id), iconOf: content.activeAppsWithPages.first { $0.title == name })
			}
		}

		let linksOfOtherApps: [LabeledLink] = content.activeAppsWithPages.flatMap { other in
			other.faqHeadings
				.filter { $0[FAQDirectives.Compares.self] == app.title }
				.map { LabeledLink(other.title, destination: .path(other.path, fragment: $0.id), iconOf: other) }
		}

		return links + linksOfOtherApps.filter { link in
			!links.contains { $0.title == link.title }
		}
	}
}

extension AppPage {
	enum Styles: String, StyleSet {
		case root
		case article

		var style: Style {
			switch self {
			case .root:
				// Each part has its own width, like the app cards (``RelatedApps``), which are as wide as the content of the header.
				Style()
					.pagePadding()
					.from(.laptop) {
						$0.margin(.top, .rootEm(-2.5))
					}
			case .article:
				// The parts of the page have no outer margins, so the page spaces them here. Some parts get more space around them, which the body sets where it shows them. The margins collapse, so the space between two parts is the larger of the bottom margin of the first and the top margin of the second, and the margins of the Markdown inside collapse into it too.
				Style()
					.flowSpacing(.rootEm(5))
					// The random app page links to the article (``AppHero/anotherRandomAppID``), and the page must stay at the top.
					.scrollMargin(top: .viewportHeight(100))
			}
		}
	}
}

/**
Links that open ChatGPT or Claude with a prompt to answer questions about an app from the Markdown copy of its page (``RoutePath/markdownCopy``), below the heading of the FAQ section of the page (``MarkdownDocument/Options/appPage(_:project:frontmatter:sharedQuestions:shortcuts:appIconCopies:)``). The assistant reads the page and asks the visitor for the question (``Assistant/url(prompt:)``). The Markdown copy does not have the links, as the assistant reads it.
*/
struct AssistantLinks: HTML {
	enum Assistant {
		case chatGPT
		case claude

		var title: String {
			switch self {
			case .chatGPT:
				"ChatGPT"
			case .claude:
				"Claude"
			}
		}

		/**
		A new chat with the prompt. ChatGPT sends the prompt at once, and Claude can put it in the message field, so the prompt ends with a request that works in both cases. ChatGPT gets `hints=search`, so it reads the page from the web.
		*/
		func url(prompt: String) -> AbsoluteURL {
			let url = switch self {
			case .chatGPT:
				#URL("https://chatgpt.com/").appending(queryItems: [
					URLQueryItem(name: "q", value: prompt),
					URLQueryItem(name: "hints", value: "search"),
				])
			case .claude:
				#URL("https://claude.ai/new").appending(queryItems: [
					URLQueryItem(name: "q", value: prompt),
				])
			}

			return AbsoluteURL(url)
		}

		/**
		A link to a new chat with the prompt (``url(prompt:)``), with the name of the assistant.
		*/
		func link(prompt: String) -> some HTML<HTMLTag.a> {
			a(.href(.url(self.url(prompt: prompt)))) {
				title
			}
		}
	}

	let appTitle: String
	let markdownCopyURL: URL

	var body: some HTML<HTMLTag.p> {
		let prompt = "Read \(markdownCopyURL.absoluteString), the page of the \(appTitle) app. Answer my questions about the app only from this page, and say when the page does not have the answer. Then ask me what I want to know."

		p {
			"You can also ask "

			Assistant.chatGPT.link(prompt: prompt)

			" or "

			Assistant.claude.link(prompt: prompt)

			" about \(appTitle). They get this page as text."
		}
		.style {
			$0.secondaryText()
		}
	}
}
