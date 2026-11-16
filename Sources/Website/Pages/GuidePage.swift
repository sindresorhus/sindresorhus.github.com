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

	/**
	All the apps of the guide, in the order of its `apps`, which its structured data is about.
	*/
	private let apps: [App]

	private let parts: (before: MarkdownContent, after: MarkdownContent)

	/**
	Uses the guide whose required app and optional screenshot were resolved when the content loaded.
	*/
	init(guide: Guide.Resolved, content: SiteContent) {
		self.guide = guide.guide
		self.content = content
		self.app = guide.app
		self.apps = guide.apps
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
		SitemapEntry(lastModified: guide.lastModified, images: [screenshot?.asset.path.absoluteURL].compactMap(\.self).map { AbsoluteURL($0) })
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
			byline

			// The box to get the app is after the steps, and before the built-in way, which stays the last word of the guide.
			if app.isDownloadable {
				parts.before

				// After the steps of the app, so the reader sees the result before deciding to get it. Not taller than on the app page, so a screenshot of a phone is not several screens tall.
				// The frame of the screenshots of the app page, so the same image looks the same in both places. From tablets, it hangs into the space at the sides of the text, like the boxes around it.
				if let (screenshot, description) = screenshot {
					div {
						ScreenshotImage(asset: screenshot, alternativeText: description) {
							$0.style {
								$0
									.display(.block)
									// The width before the image loads, so a lazy image that is not loaded yet has its height from the width and the size attributes, and the box below it does not move down when it loads. The height is automatic, as the height attribute is otherwise the height.
									.frame(
										width: .pixels(screenshot.maximumDisplayWidth),
										height: .auto,
										maxWidth: .percent(100),
										maxHeight: .pixels(MediaAsset.maximumDisplayHeight)
									)
									.margin(.horizontal, .auto)
									.windowSurface()
							}
						}
					}
					.style {
						$0.widerThanProse()
					}
				}

				AppCallToAction(listing: content.listing(of: app), buildDate: content.buildDate, appStorePlacement: .guide(guide.slug))
					.style {
						// Where there is space at the sides of the text (``Breakpoint/proseWithGutters``), the box hangs into it, like the other boxes of prose, like the code. Until then, from tablets, it is as wide as the text, like the other boxes. Below tablets, it is as wide as the screen, like at the end of the app page, so it goes into the space at the sides of the page. Between tablets and that width, the page has its largest width, so the space at its sides is not only the gutter.
						$0
							.margin(.top, .rootEm(3))
							.widerThanProse()
							.below(.tablet) {
								$0.margin(.horizontal, .length(-.pageGutter))
							}
					}

				// Below the box, as a reader who decides to get the app often wants the screenshots, the reviews, and the FAQ of the app first, and the link back at the top is out of view. The box above shows the app, so the link shows no preview of it.
				p(.hook(LinkPreview.Hooks.noLinkPreview)) {
					a(.href(app.path)) {
						"More about \(app.title)"
					}
					// The arrow is only on the screen, so the name of the link is its text.
					.style {
						$0
							.moreLink()
							.trailingArrow()
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
					// On one line, so it goes below the back link as a whole on a phone (``ProsePageStyles/backRow``).
					.textWrap(.nowrap)
			}
		}
		// One step smaller than the titles of the other pages, as the title of a guide is a long task, like “How to … on Mac”, which would take 4 or 5 lines on a phone and push the quick answer below the first screen.
		.style {
			$0.nested(PageHeaderStyles.title.selector) {
				$0.font(size: .clamp(.rootEm(2.25), .viewportWidth(4.5), .rootEm(3)))
			}
		}

		// After the guide, like the footer, so “Without an app” stays the last word of the guide. The rows of the guides at the end of an app page.
		let moreGuides = self.moreGuides

		if !moreGuides.isEmpty {
			section {
				h2 {
					"More Guides"
				}
				// Like the titles of the groups of the footer.
				.style {
					$0
						.margin(.bottom, .rootEm(0.75))
						.textAlign(.center)
						.textStyle(.caption, weight: .semibold)
						.color(.secondaryText)
				}

				GuideLinks(guides: moreGuides)
			}
			.style(AppFooterLinks.Styles.root, AppFooterLinks.Styles.guides)
			// The space below the guide, and a little more, so the list reads as navigation after the guide, not as a part of it.
			.style {
				$0.margin(top: .rootEm(1), horizontal: .auto, bottom: .length(.partSpacing(rootEm: 5)))
			}
		}

		JSONScript(schema: structuredData)
		// The “Back to …” link above the title (``BackLink``), so search results can show the app of the guide.
		JSONScript(schema: Schema.BreadcrumbList(parents: [(name: app.title, url: app.path.absoluteURL)], name: guide.title))
	}

	/**
	Who wrote the guide, below the title, like “By Sindre Sorhus, who makes the Folder Peek app”, with the small photo of the about page. The guide recommends the app of its author, so the line says it openly, and the maker of the app knows how it works.
	*/
	private var byline: some HTML<HTMLTag.p> {
		p {
			img(
				.src(Site.author.smallPhotoPath),
				.alt(""),
				.width(28),
				.height(28)
			)
				// It is in the prose, so it starts without the margins and the shadow of the images of prose.
				.style {
					$0
						.plainImage()
						.frame(size: .pixels(28))
						.flexShrink(0)
						.cornerRadius(.circle)
				}

			// In one element, so the text and the link are one item of the stack, without a gap between them.
			span {
				"By "
				a(.href(.about)) {
					Site.author.name
				}
				", "
				// “the … app”, as the names of some apps are common words, and “who makes Today” reads like a sentence about time.
				// One unit, so a narrow screen moves the whole clause to the next line, and never splits the name of the app.
				span {
					"who makes the \(app.title) app"
				}
				.style {
					$0.display(.inlineBlock)
				}
			}
		}
		.style {
			$0
				.hstack(alignment: .center, spacing: .rootEm(0.5))
				.secondaryText()
				// Close to the title, as it says who wrote the guide, like the author line of an article, and with the space of the title below it, so it does not read as a part of the box below. The negative margin takes most of the space below the header of the page (``ProsePage``).
				.margin(top: .rootEm(-1.75), horizontal: .zero, bottom: .rootEm(2.5))
		}
	}

	/**
	Up to 4 other guides of the topic of the guide, in the order of the list of guides. The guides of other apps come first, one for each app, and then more guides of the same apps, so a topic with many guides about one app, like Supercharge, also shows the other apps.
	*/
	private var moreGuides: [Guide] {
		// The apps that already have a guide in the list, starting with the app of this guide.
		var listedApps: Set = [app.slug]
		var firstGuidesOfApps = [Guide]()
		var otherGuides = [Guide]()

		for other in content.resolvedGuides where other.guide.frontmatter.topic == guide.frontmatter.topic && other.guide.path != guide.path {
			if listedApps.insert(other.app.slug).inserted {
				firstGuidesOfApps.append(other.guide)
			} else {
				otherGuides.append(other.guide)
			}
		}

		return Array((firstGuidesOfApps + otherGuides).prefix(4))
	}

	/**
	The images are the card, the icon of the app, and the screenshot, as Google asks for images in several aspect ratios, and the card is wide. The article is about each app of the guide, which the structured data of its app page has (``App/structuredDataID``).
	*/
	private var structuredData: Schema.Article {
		var article = Schema.Article(
			document: guide,
			type: .article,
			title: guide.title,
			description: guide.description,
			images: [socialImageURL, app.iconURL, screenshot?.asset.path.absoluteURL].compactMap(\.self)
		)

		article.about = apps.map { Schema.Reference(id: $0.structuredDataID) }
		return article
	}
}
