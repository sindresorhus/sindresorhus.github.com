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
	Whether guides are about the app, which the end of the page lists, and the “…” menus link to.
	*/
	private var hasGuides: Bool {
		!content.guides(about: app).isEmpty
	}

	/**
	With the icon and the screenshots. An unlisted app is left out, as it is not indexed, like it is left out of the app lists, and like an unlisted post.
	*/
	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: app.lastModified, images: ([app.iconURL] + app.screenshotURLs).map { AbsoluteURL($0) })
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
			feeds: app.releaseNotes.map { [$0.feed] } ?? []
		)
	}

	var body: some HTML {
		section {
			// The random app page links to `#another-random-app`, which shows the “Another Random App” button. The ID is at the top, so the page does not scroll.
			article(.id(AppHero.anotherRandomAppID)) {
				let separatedContent = app.markdown.contentSeparatingIntroduction

				AppHero(
					listing: listing,
					introduction: separatedContent?.introduction,
					buildDate: content.buildDate,
					hasGuides: hasGuides
				)

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

				if !description.html.allSatisfy(\.isWhitespace) {
					Prose(markdown: description)
				}

				// Testimonials stand alone; eligible store and Setapp ratings are shown in the app information, even without reviews.
				if let reviews = AppReviews(listing: listing) {
					// The wall of love only has the reviews of the active apps, so another app, or an app without reviews, has no link to it.
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
					AppCallToAction(listing: listing, buildDate: content.buildDate)
						.style {
							// Until there is space at its sides (``Breakpoint/proseWithGutters``), the panel is as wide as the screen, so it has no corners and no edges at its sides.
							$0
								.margin(.top, .length(.partSpacing(rootEm: 9)))
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
							$0.margin(.vertical, .length(.partSpacing(rootEm: 9)))
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
					.margin(.bottom, .rootEm(2.5))
					.pagePadding()
					.from(.laptop) {
						$0.margin(.top, .rootEm(-2.5))
					}
			case .article:
				// The parts of the page have no outer margins, so the page spaces them here. Some parts get more space around them, which the body sets where it shows them. The margins collapse, so the space between two parts is the larger of the bottom margin of the first and the top margin of the second, and the margins of the Markdown inside collapse into it too.
				Style()
					.flowSpacing(.rootEm(5))
			}
		}
	}
}
