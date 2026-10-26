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
		.app(app)
	}

	/**
	With the icon and the screenshots. An unlisted app is left out, as it is not indexed, like it is left out of the app lists, and like an unlisted post.
	*/
	var sitemapEntry: SitemapEntry? {
		SitemapEntry(lastModified: app.lastModified, images: [app.iconURL] + app.screenshotURLs)
	}

	var socialCard: OpenGraphCard? {
		OpenGraphCard(app: app, project: content.project)
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "\(app.title): \(app.subtitle)",
			description: app.description,
			socialTitle: app.title,
			// Search engines do not index an unlisted app, like it is not in the sitemap.
			isIndexed: app.isListed,
			appStoreID: app.showsAppStoreBanner ? app.appStoreID : nil,
			favicon: app.iconPath,
			video: app.media.first { $0.kind == .video },
			feeds: app.releaseNotes.map { [$0.feed] } ?? []
		)
	}

	var body: some HTML {
		section {
			// The random app page links to `#another-random-app`, which shows the “Another Random App” button. The ID is at the top, so the page does not scroll.
			article(.id(AppHero.anotherRandomAppID)) {
				let separatedContent = app.markdown.contentSeparatingIntroduction

				AppHero(app: app, info: appStoreInfo, introduction: separatedContent?.introduction, buildDate: content.buildDate)

				// The space below is the space between the parts, so the screenshots are not far from it.
				if let announcement = app.announcement {
					AnnouncementBanner(announcement: announcement)
						.style {
							$0.margin(.top, .rootEm(4.5))
						}
				}

				if !app.media.isEmpty {
					AppMedia(app: app)
				}

				if !app.pressQuotes.isEmpty {
					PressQuotes(quotes: app.pressQuotes, showsYears: app.showsPressQuoteYears)
						.style {
							$0
								.margin(.top, .rootEm(7))
								.margin(.bottom, .rootEm(6))
						}
				}

				// The reviews come after the description of the app and before its first section, like the trial or the FAQ, so visitors know what the app does before they read what others think of it.
				let remainder = separatedContent?.remainder ?? app.markdown.content
				let sections = app.markdown.headings.first { $0.level == 2 }.flatMap { remainder.separated(beforeHeading: $0.id) }
				let description = sections?.before ?? remainder

				if !description.html.allSatisfy(\.isWhitespace) {
					Prose(markdown: description)
				}

				// The rating is in the structured data, so it is shown without reviews too.
				if !reviews.isEmpty || content.rating(of: app) != nil {
					// The wall of love only has the reviews of the active apps, so another app, or an app without reviews, has no link to it.
					AppReviews(reviews: reviews, rating: content.rating(of: app), app: app.isActive && !reviews.isEmpty ? app : nil)
						.style {
							$0.margin(.vertical, .rootEm(6))
						}
				}

				if let sections {
					Prose(markdown: sections.after)
				}

				// The end of the page is set apart from the text above it, like the FAQ.
				if app.isDownloadable {
					AppCallToAction(app: app, info: appStoreInfo)
						.style {
							$0.margin(.top, .rootEm(9))
						}
				}

				if !app.isArchived {
					AppFacts(app: app, info: appStoreInfo)
						.style {
							$0.margin(.vertical, .rootEm(9))
						}
				}

				// The links about the app belong to the app, so they come before the other apps. An archived app can have none.
				if !app.pageOverflowLinks.isEmpty {
					AppFooterLinks(app: app)
						.style {
							$0.margin(.top, .rootEm(5))
						}
				}

				let relatedApps = app.relatedApps(from: content.activeApps, on: content.buildDate)

				if !relatedApps.isEmpty {
					RelatedApps(relatedApps: relatedApps, content: content)
						.style {
							$0.margin(.top, .rootEm(8))
						}
				}
			}
			.style(Styles.article)
		}
		.style(Styles.root)

		JSONScript(schema: structuredData)

		if let script = app.script {
			ModuleScript(script)
		}
	}

	private var appStoreInfo: AppStoreInfo? {
		content.appStoreInfo(of: app)
	}

	/**
	The four newest reviews, which fill two rows of two, so none is alone in a row. The wall of love has more.
	*/
	private var reviews: [AppStoreReview] {
		Array(content.appStoreReviews(of: app).prefix(4))
	}

	/**
	The color of the icon as the accent of the page, for the buttons and the links, also in the header.
	*/
	var tint: Color? {
		app.tint
	}

	private var structuredData: Schema.SoftwareApplication {
		Schema.SoftwareApplication(app: app, info: appStoreInfo, reviews: reviews, latestRelease: content.releases(of: app).first, gumroadRating: content.gumroadProduct(of: app)?.rating)
	}
}

extension AppPage {
	enum Styles: StyleSet {
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
