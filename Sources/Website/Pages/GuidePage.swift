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
	All the apps of the guide, in the order of its `apps`, which its structured data and its Markdown copy are about.
	*/
	let apps: [App]

	private let parts: (before: MarkdownContent, after: MarkdownContent)

	private let withoutAppHeadingID: ElementID

	/**
	Uses the guide whose required app and optional screenshot were resolved when the content loaded.
	*/
	init(guide: Guide.Resolved, content: SiteContent) {
		self.guide = guide.guide
		self.content = content
		self.app = guide.app
		self.apps = guide.apps
		self.parts = guide.parts
		self.withoutAppHeadingID = guide.withoutAppHeadingID
		self.screenshot = guide.app.isDownloadable ? guide.screenshot : nil
	}

	var path: RoutePath {
		guide.path
	}

	var feedbackApp: App? {
		app
	}

	/**
	The color of the first app, like on the other pages of the app, so the steps, the links, and the box to get the app have its color.
	*/
	var tint: Color? {
		app.tint
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
			// The “Updated” date of the byline.
			modifiedOn: guide.lastModified,
			// The banner of the app in Safari on iPhone, like on the app page, as many readers of a guide about an iPhone app are on their iPhone.
			appStoreID: app.showsAppStoreBanner ? app.appStoreID : nil,
			feeds: [SiteFeed.newGuides.link]
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
				// The caption names the app, as the section above the screenshot is not always about it, like “With Dato” above the menu of Zone Bar, but not when the description already names it, like “Velja asks which browser…”.
				// The caption is the text of the image for screen readers, so the image has no alternative text of its own, and they read the description once.
				if let (screenshot, description) = screenshot {
					figure {
						ScreenshotImage(asset: screenshot, alternativeText: "") {
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
									// No space below it from the prose, so the caption is close to the image.
									.margin(vertical: .zero, horizontal: .auto)
									.windowSurface()
							}
						}

						figcaption {
							description.contains(app.title) ? description : "\(app.title): \(description)"
						}
						.style {
							$0
								.textAlign(.center)
								.textWrap(.balance)
						}
					}
					// The space above the box to get the app, so the blocks at the end of the guide have the same space between them.
					.style {
						$0
							.margin(.top, .rootEm(3))
							.widerThanProse()
					}
				}

				// A trial that is a download is the Mac app, so a guide about the app on the iPhone only leaves it out, and its requirement names only the platforms of the iPhone and the Apple Watch, like “iOS 26 or later” (``Guide/isAboutIPhoneOnly``).
				AppCallToAction(
					listing: content.listing(of: app),
					buildDate: content.buildDate,
					appStorePlacement: .guide(guide.slug),
					hasCompactFacts: true,
					showsTrial: !guide.isAboutIPhoneOnly || app.frontmatter.trial?.isMacOnly != true,
					platforms: guide.isAboutIPhoneOnly ? app.platforms.filter { [Platform.iOS, .watchOS].contains($0) }.nilIfEmpty : nil
				)
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
					.style {
						$0.guideEndLink()
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
			$0
				.nested(PageHeaderStyles.title.selector) {
					$0.font(size: .clamp(.rootEm(2.25), .viewportWidth(4.5), .rootEm(3)))
				}
				// The numbers, the lines, and the step links of the built-in way are gray, not in the color of the app, as they need no app. Only these, as the links and the selection in the text of the steps read the same accent, and they keep the color of the app.
				.nested("#\(raw: withoutAppHeadingID.rawValue) ~ \(StepListStyles.root.selector)") {
					let gray = { (style: Style) in
						style.setting(Color.accent, to: .secondaryText)
					}

					return $0
						.children("ol > li") {
							$0
								.before(gray)
								.after(gray)
						}
						.nested(StepListStyles.link.selector, gray)
				}
		}

		// After the guide, like the footer, so “Without an app” stays the last word of the guide. The rows of the guides at the end of an app page.
		let moreGuides = self.moreGuides

		if !moreGuides.isEmpty {
			section {
				h2 {
					"More Guides"
				}
				// Like the title of the guides at the end of an app page (``AppFooterLinks``), as both are extra content at the end of the page.
				.style(SectionStyles.label)

				GuideLinks(guides: moreGuides)

				// The guides of the app at the end of its page, when it has more than “More Guides” and the box to get the app show, as the reader of one task often wants the next task with the same app, and the guides of an app are in many topics. For an app with many guides, the link opens the row with the guides that do not show at first (``AppFooterLinks/allGuidesID(count:)``).
				// The page of the topic, so the reader sees the related guides first, like “All Posts” below the more posts of a blog post, and the page of each audience that lists the guide, like the guides for Windows users, so a reader from a search finds the other guides for the same situation.
				// A centered row that wraps, with space between the links, so their tap areas do not overlap.
				p {
					let appGuideCount = content.guides(about: app).count

					if appGuideCount >= 3 {
						a(.href(.path(app.path, fragment: AppFooterLinks.allGuidesID(count: appGuideCount)))) {
							"All \(appGuideCount.formatted(.siteNumber)) \(app.title) Guides"
						}
						.style {
							$0.guideEndLink()
						}
					}

					let topic = guide.frontmatter.topic

					a(.href(.path(topic.path))) {
						topic.allGuidesTitle(count: content.guides(of: topic).count)
					}
					.style {
						$0.guideEndLink()
					}

					for audience in Guide.Audience.allCases where audience.includes(guide.frontmatter) {
						a(.href(.path(audience.path))) {
							audience.linkTitle
						}
						.style {
							$0.guideEndLink()
						}
					}
				}
				.style {
					$0
						.margin(top: .rootEm(1.5), horizontal: .zero, bottom: .zero)
						// The size of the rows above it and of the link to the app in the guide, not the smaller text of the footer links.
						.textStyle(.body)
						.hstack(justification: .center)
						.flexWrap()
						.gap(row: .rootEm(1.25), column: .rootEm(2))
				}
			}
			.style(AppFooterLinks.Styles.root, AppFooterLinks.Styles.guides)
			// The space below the guide, and a little more, so the list reads as navigation after the guide, not as a part of it. From small tablets, as wide as the box to get the app in the guide, not as narrow as the guides at the end of an app page, so each title is one line on a tablet, and not as wide as the parts of an app page. The guides stay in one column until laptops.
			.style {
				$0
					.margin(top: .rootEm(1), horizontal: .auto, bottom: .length(.partSpacing(rootEm: 5)))
					.from(.smallTablet) {
						$0.frame(maxWidth: .length(Style.ColumnWidth.prose.maximum + .boxInset * 2))
					}
			}
		}

		JSONScript(schema: structuredData)
		// The “Back to …” link above the title (``BackLink``), so search results can show the app of the guide.
		JSONScript(schema: Schema.BreadcrumbList(parents: [(name: app.title, url: app.path.absoluteURL)], name: guide.title))
	}

	/**
	Who wrote the guide, below the title, like “By Sindre Sorhus, who makes the Folder Peek app”, with the small photo of the about page. The guide recommends the apps of its author, so the line says it openly and names all of them, like “who makes the Menu Bar Calendar and Dato apps”, and the maker of the apps knows how they work.
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
				// One unit, so a narrow screen moves the whole clause to the next line, and only a list of several apps that is wider than the screen wraps inside it.
				span {
					"who makes the \(apps.map(\.title).formattedList(.and)) \(apps.count == 1 ? "app" : "apps")"
				}
				// Balanced, so a list of apps that wraps does not leave “Dato apps” alone on the last line.
				.style {
					$0
						.display(.inlineBlock)
						.textWrap(.balance)
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
	Up to 4 other guides of the topic of the guide, the guides about the same task first, like the other screenshot guides below “How to Find Your Screenshots on Mac”: each word of the title of another guide that the title or the description of this guide also has counts 2, and each such word of its description counts 1. The words are the words of the suggestions of the feedback page, without stopwords, and other forms of a word count too (``SuggestedQuestion/words(in:)``, ``SuggestedQuestion/isForm(_:of:)``). For the same score, the guides after this one in the list of guides come first, and then the guides from the start of the topic, so a guide that shares no words shows its neighbors. A guide that the text of this guide links to is left out, as the reader already saw the link, so the place goes to a guide that the reader does not know yet.
	*/
	private var moreGuides: [Guide] {
		let topicGuides = content.guides(of: guide.frontmatter.topic).map(\.guide)

		guard let position = topicGuides.firstIndex(where: { $0.path == guide.path }) else {
			return []
		}

		let words = SuggestedQuestion.words(in: "\(guide.task) \(guide.description)")
		// The links are resolved, like `/guides/find-screenshots-mac#steps` for `guide:find-screenshots-mac#steps`.
		let linkedPaths = Set(guide.markdown.links.compactMap { (try? LinkDestination(validating: $0.destination))?.sitePath })

		func sharedWordCount(_ text: String) -> Int {
			Set(SuggestedQuestion.words(in: text)).count { word in
				words.contains { SuggestedQuestion.isForm(word, of: $0) }
			}
		}

		let otherGuides = Array(topicGuides[(position + 1)...] + topicGuides[..<position])

		return otherGuides
			.filter { !linkedPaths.contains($0.path) }
			.map { (guide: $0, score: sharedWordCount($0.task) * 2 + sharedWordCount($0.description)) }
			// The sort is stable, so the same score keeps the order after this guide.
			.sorted(using: KeyPathComparator(\.score, order: .reverse))
			.prefix(4)
			.map(\.guide)
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
			dateModified: guide.lastModified,
			images: [socialImageURL, app.iconURL, screenshot?.asset.path.absoluteURL].compactMap(\.self)
		)

		article.about = apps.map { Schema.Reference(id: $0.structuredDataID) }
		return article
	}
}

extension Style {
	/**
	A link at the end of a guide, like “More about Gifski” and “All 25 Mac Menu Bar Guides”, in the accent of the app of the guide, or at the end of a list of guides, like “Settings to Change on a New Mac” (``AudienceGuidesPage``). The arrow is only on the screen, so the name of the link is its text. The row of the link keeps space around it, so its tap area takes no taps from another link.
	*/
	func guideEndLink() -> Self {
		moreLink()
			.color(.accentText)
			.trailingArrow()
			.minimumTapArea()
	}
}
