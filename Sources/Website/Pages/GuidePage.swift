import Elementary
import Foundation
import SiteKit

/**
A how-to guide, like `/guides/convert-video-to-gif-mac`, with a link back to its app.
*/
struct GuidePage: Page {
	let guide: Guide
	let content: SiteContent

	/**
	The first app of the guide, which the guide links back to.
	*/
	private let app: App
	private let parts: (before: MarkdownContent, after: MarkdownContent)

	/**
	Uses the guide whose required app and optional screenshot were resolved when the content loaded.
	*/
	init(guide: Guide.Resolved, content: SiteContent) {
		self.guide = guide.guide
		self.content = content
		self.app = guide.app
		self.parts = guide.parts
		self.screenshot = guide.app.isDownloadable ? guide.screenshot : nil
	}

	var path: RoutePath {
		guide.path
	}

	var feedbackApp: App? {
		app
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(guide: guide, app: app, project: content.project))
	}

	/**
	The screenshot of the first app that shows the result, which the guide picks (`screenshot`). The page shows it above the box to get the app, so a guide about an app that cannot be downloaded has none, also in the sitemap and the structured data.
	*/
	private let screenshot: (asset: ScreenshotAsset, description: String)?

	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: guide.lastModified, images: [screenshot?.asset.path.absoluteURL].compactMap(\.self))
	}

	var metadata: PageMetadata {
		PageMetadata(
			article: guide,
			title: guide.title,
			description: guide.description,
			// The banner of the app in Safari on iPhone, like on the app page, as many readers of a guide about an iPhone app are on their iPhone.
			appStoreID: app.showsAppStoreBanner ? app.appStoreID : nil
		)
	}

	var body: some HTML {
		ProsePage(title: .plain(guide.title), backTo: app) {
			// The box to get the app is after the steps, and before the built-in way, which stays the last word of the guide.
			if app.isDownloadable {
				parts.before

				// After the steps of the app, so the reader sees the result before deciding to get it. Not taller than on the app page, so a screenshot of a phone is not several screens tall.
				if let (screenshot, description) = screenshot {
					ScreenshotImage(asset: screenshot, alternativeText: description) {
						$0.style {
							$0
								.display(.block)
								.frame(width: .auto, maxHeight: .pixels(MediaAsset.maximumDisplayHeight))
								.margin(.horizontal, .auto)
						}
					}
				}

				AppCallToAction(listing: content.listing(of: app))
					.style {
						// From tablets, the box hangs into the space at the sides of the text, like the other boxes of prose, like the code. Below tablets, it is as wide as the screen, like at the end of the app page, so it goes into the space at the sides of the page.
						$0
							.margin(.top, .rootEm(3))
							.widerThanProse()
							.below(.tablet) {
								$0.margin(.horizontal, .length(-.pageGutter))
							}
					}

				// Below the box, as a reader who decides to get the app often wants the screenshots, the reviews, and the FAQ of the app first, and the link back at the top is out of view.
				p {
					a(.href(app.path)) {
						"More about \(app.title) →"
					}
					.style {
						$0.moreLink()
					}
				}
				.style {
					$0
						.margin(top: .rootEm(1), horizontal: .zero, bottom: .rootEm(3))
						.textAlign(.center)
				}

				parts.after
			} else {
				guide.markdown.content
			}
		} accessory: {
			// The date of the last change, as a guide is only useful while its steps are right.
			p {
				if guide.lastModified == guide.publicationDate {
					DateText(day: guide.publicationDate, format: .siteDay)
				} else {
					"Updated "
					DateText(day: guide.lastModified, format: .siteDay)
				}
			}
			.style {
				$0
					.textStyle(.caption)
					.secondaryText()
					.monospacedDigit()
			}
		}

		JSONScript(schema: structuredData)
	}

	/**
	The images are the card, the icon of the app, and the screenshot, as Google asks for images in several aspect ratios, and the card is wide.
	*/
	private var structuredData: Schema.Article {
		Schema.Article(
			document: guide,
			type: .article,
			title: guide.title,
			description: guide.description,
			images: [socialImageURL, app.iconURL, screenshot?.asset.path.absoluteURL].compactMap(\.self)
		)
	}
}
