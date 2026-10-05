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
	With the icon and the screenshots.
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
			appStoreID: app.showsAppStoreBanner ? app.appStoreID : nil,
			appStoreCampaign: app.appStoreBannerCampaign,
			favicon: app.iconPath,
			feeds: app.releaseNotes.map { [$0.feed] } ?? []
		)
	}

	var body: some HTML {
		section {
			// The random app page links to `#another-random-app`, which shows the “Another Random App” button. The ID is at the top, so the page does not scroll.
			article(.id(AppHero.anotherRandomAppID)) {
				let separatedContent = app.markdown.contentSeparatingIntroduction

				AppHero(app: app, info: appStoreInfo, introduction: separatedContent?.introduction)

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
					PressQuotes(quotes: app.pressQuotes)
						.style {
							$0
								.margin(.top, .rootEm(7))
								.margin(.bottom, .rootEm(6))
						}
				}

				// The rating is in the structured data, so it is shown without reviews too.
				if !reviews.isEmpty || appStoreInfo?.rating != nil {
					// The wall of love only has the reviews of the active apps, so another app, or an app without reviews, has no link to it.
					AppReviews(reviews: reviews, rating: appStoreInfo?.rating, app: app.isActive && !reviews.isEmpty ? app : nil)
						.style {
							$0.margin(.bottom, .rootEm(6))
						}
				}

				Prose(markdown: separatedContent?.remainder ?? app.markdown.content)

				// The end of the page is set apart from the text above it, like the FAQ.
				if app.isDownloadable {
					AppCallToAction(app: app, info: appStoreInfo)
						.style {
							$0.margin(.top, .rootEm(9))
						}
				}

				// The links about the app belong to the app, so they come before the other apps.
				AppFooterLinks(app: app)
					.style {
						$0.margin(.top, .rootEm(5))
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
	The three newest reviews. The wall of love has more.
	*/
	private var reviews: [AppStoreReview] {
		Array(content.appStoreReviews(of: app).prefix(3))
	}

	/**
	The color of the icon as the accent of the page, for the buttons and the links, also in the header.
	*/
	var tint: Color? {
		app.tint
	}

	private var structuredData: Schema.SoftwareApplication {
		Schema.SoftwareApplication(app: app, info: appStoreInfo, reviews: reviews)
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
