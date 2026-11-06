import Elementary
import Foundation
import SiteKit
import SOML

/**
The document every page is rendered in: the head with metadata, and the body with the header, the page content, and the footer.
*/
struct SiteLayout<Content: Page>: HTMLDocument {
	let page: Content

	/**
	The rendered ``SiteBody``.
	*/
	let bodyHTML: RenderedHTML

	/**
	The styles and scripts that stay with the rendered body.
	*/
	private var resources: PageResources.Snapshot {
		bodyHTML.resources
	}

	/**
	The scripts of the elements with an inline script that the body shows (``ScriptedElement/generatedScript()``).
	*/
	let inlineScripts: [String]

	@TaskLocalValue(requiring: Site.Scripts.$published) private var publishedScripts

	/**
	The scripts that the page loads: the script of the site, and the scripts that the body uses.
	*/
	private var scripts: [RoutePath] {
		[#path("/scripts/site.js")] + resources.scripts
	}

	var title: String {
		page.metadata.documentTitle
	}

	var lang: String {
		"en"
	}

	var head: some HTML {
		// First, as an import map must come before any module script. Browsers other than Chrome and Safari only use one import map.
		if let importMap = publishedScripts.importMap(loading: scripts) {
			script(.type(.importmap)) {
				HTMLRaw(importMap)
			}
		}

		// The scripts that the scripts of the page import, so the browser loads them at once, not only when the script that imports them has arrived. After the import map, which a module preload uses too.
		for path in publishedScripts.modulePreloads(loading: scripts) {
			link(.rel("modulepreload"), .href(path))
		}

		page.head

		if let tint = page.tint {
			Elementary.style {
				HTMLRaw(Stylesheet.accent(tint).css)
			}
		}

		MetadataHead(
			path: page.path,
			metadata: page.metadata,
			socialImage: page.socialImage
		)

		// The styles of the components on the page. The shared styles are in the stylesheet that every page links to.
		Elementary.style {
			HTMLRaw(
				Stylesheet {
					Layer(.components) {
						resources.styleNodes
					}

					Layer(.elements) {
						resources.elementStyleNodes
					}
				}.css
			)
		}

		// The counter counts a page when it is visible. A page that the speculation rules prerender is hidden until the visitor opens it, so a prerendered page that nobody opens is not counted.
		script(.src("https://gc.zgo.at/count.js"), .async, .data("goatcounter", value: "https://sindresorhus.goatcounter.com/count")) {}
	}

	var body: some HTML {
		bodyHTML

		for path in scripts {
			script(.src(publishedScripts.versioned(path).description), .type(.module)) {}
		}

		for inlineScript in inlineScripts {
			script(.type(.module)) {
				HTMLRaw(inlineScript)
			}
		}
	}
}

/**
The visible part of every page: the header, the page content, and the footer. Components read the path of the page from the environment, like the header for the link of the current section.
*/
struct SiteBody<Content: Page>: HTML {
	let page: Content

	/**
	The ID of the content of the page, which the skip link goes to.
	*/
	private static var mainID: ElementID {
		ElementID("content")
	}

	var body: some HTML {
		content
			.taskLocalValue(RoutePath.$current, page.path)
	}

	@ContentBuilder
	private var content: some HTML {
		// The first link of the page, for keyboard users, so they can skip the links of the header. It is above the screen until Tab reaches it.
		a(.href("#\(Self.mainID)")) {
			"Skip to Content"
		}
		.buttonStyle(size: .small)
		.style {
			$0
				.position(.fixed)
				.top(.rootEm(0.75))
				.leading(.rootEm(0.75))
				.zIndex(100)
				.offset(y: .percent(-200))
				.focus {
					$0.offset(y: .zero)
				}
		}

		SiteHeader(variant: page.navigation, background: page.headerBackground)

		main(.id(Self.mainID)) {
			page.body
		}

		SiteFooter(app: page.feedbackApp)
		UnicornEasterEgg()
		LinkPreview()
	}
}

/**
The `<head>` tags that describe a page to browsers, search engines, feed readers, and social media.
*/
private struct MetadataHead: HTML {
	let path: RoutePath
	let metadata: PageMetadata

	let socialImage: SocialImage

	private var canonicalURL: String {
		path.absoluteURL.absoluteString
	}

	/**
	The page background in light and dark mode, for the bar of the browser. Resolved once, as finding the value of a palette shade is slow and every page has it.
	*/
	private static let themeColors = (
		light: SemanticColor.pageBackgroundColors.light.resolved.description,
		dark: SemanticColor.pageBackgroundColors.dark.resolved.description
	)

	/**
	Fetches a page of the site when the pointer rests on a link to it, and prerenders it when the link is pressed, so it opens at once. On a phone, Chrome also fetches the large links near the last tap. A prerender also loads the images of the page, which is too much data for a link that the visitor may not open. Not the 1999 page, which is large, and not the random app page, which picks another app each time, or the feedback form, in a prerender. Browsers without the Speculation Rules API ignore it. Encoded once, as every page has the same rules.
	*/
	private static let speculationRules = JSONScript(
		speculationRules: SpeculationRules(
			prefetch: [SpeculationRules.Rule(excludedPaths: [.geoCities], eagerness: .moderate)],
			prerender: [SpeculationRules.Rule(excludedPaths: [.geoCities, .randomApp, .feedback], eagerness: .conservative)]
		)
	)

	var body: some HTML {
		meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
		meta(.name(.author), .content(Site.author.name))
		meta(.name("generator"), .content("SiteKit, in Swift (\(Site.sourceURL.absoluteString))"))
		meta(.name("twitter:site"), .content(Site.author.twitterHandle))
		meta(.name("twitter:creator"), .content(Site.author.twitterHandle))
		meta(.name("fediverse:creator"), .content(Site.author.fediverseHandle.description))
		meta(.name("twitter:card"), .content("summary_large_image"))
		meta(.name("theme-color"), .content(Self.themeColors.light), .media(.light))
		meta(.name("theme-color"), .content(Self.themeColors.dark), .media(.dark))

		// Dark mode visitors do not see a white page before the stylesheet loads.
		meta(.name("color-scheme"), .content("light dark"))

		if let description = metadata.description {
			meta(.name(.description), .content(description))
		}

		// Search engines may show a large image of an indexed page, like in Google Discover, instead of a thumbnail.
		meta(.name("robots"), .content(metadata.isIndexed ? "max-image-preview:large" : "noindex"))

		if let appStoreID = metadata.appStoreID {
			meta(.name("apple-itunes-app"), .content("app-id=\(appStoreID)\(App.appStoreBannerCampaign.map { ", affiliate-data=\($0)" } ?? "")"))
		}

		link(.rel(.canonical), .href(canonicalURL))
		link(.rel(.stylesheet), .href(Stylesheet.versionedSitePath))
		link(.rel("apple-touch-icon"), .href(#path("/apple-touch-icon.png")))
		link(.rel(.icon), .href(metadata.favicon))

		// The feed of the page first, like the release notes of an app, as a feed reader shows the feeds in this order, and some take the first one.
		for feed in metadata.feeds + SiteFeed.allCases.map(\.link) {
			link(
				.rel("alternate"),
				.type(.rss),
				.title(feed.title),
				.href(feed.path)
			)
		}

		// The Markdown copy of the page, and `llms.txt`, which describes the site, for AI assistants, as the llms.txt proposal suggests. A copy is much smaller to read than the page.
		if Site.pagesWithMarkdownCopies.contains(path) {
			link(.rel("alternate"), .type(.markdown), .href(path.markdownCopy))
		}

		if let dataFile = metadata.dataFile {
			link(.rel("alternate"), .type(.json), .href(dataFile))
		}

		link(.rel("describedby"), .href(Site.llmsPath))

		for origin in metadata.preconnectOrigins {
			link(.rel("preconnect"), .href(.url(origin.url)))
		}

		Self.speculationRules

		meta(.property("og:title"), .content(metadata.documentTitle))
		meta(.property("og:type"), .content(metadata.kind.openGraphType))
		meta(.property("og:url"), .content(canonicalURL))
		meta(.property("og:image"), .content(socialImage.url.absoluteString))
		meta(.property("og:image:width"), .content(String(OpenGraphCard.width)))
		meta(.property("og:image:height"), .content(String(OpenGraphCard.height)))
		meta(.property("og:image:alt"), .content(socialImage.description))
		meta(.property("og:locale"), .content("en_US"))
		meta(.property("og:site_name"), .content(Site.name))

		if let description = metadata.description {
			meta(.property("og:description"), .content(description))
		}

		if let video = metadata.video {
			meta(.property("og:video"), .content(video.path.absoluteURL.absoluteString))
			meta(.property("og:video:type"), .content(MediaType.mpeg4.rawValue))
			meta(.property("og:video:width"), .content(String(video.size.width)))
			meta(.property("og:video:height"), .content(String(video.size.height)))
		}

		// X reads the title, description, and image from the Open Graph tags.

		if case .article(let publishedOn, let modifiedOn, let tags) = metadata.kind {
			meta(.property("article:published_time"), .content(publishedOn.description))
			meta(.property("article:modified_time"), .content(modifiedOn.description))
			meta(.property("article:author"), .content(Site.author.name))

			for tag in tags {
				meta(.property("article:tag"), .content(tag.rawValue))
			}
		}
	}
}

extension Stylesheet {
	/**
	Sets the accent of a page on the `html` element, like the color of the icon on an app page.
	*/
	static func accent(_ color: Color) -> Self {
		Stylesheet {
			Rule(":root", Style().setting(Color.accent, to: color))
		}
	}

	/**
	The attribute that `site.js` sets on the root element while a section link goes to a section that is close, so only that scrolls smoothly.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case smoothScrolling = "smooth-scrolling"
	}

	/**
	The styles of the `html` and `body` elements that ``SiteLayout`` renders. They are in the base layer of the shared stylesheet.
	*/
	static let document = Stylesheet {
		Rule(
			"html",
			Style()
			.lineHeight(1.5)
			.fontFamily(.system)
			.declaration(raw: .webkitTextSizeAdjust, .percent(100))
			.declaration(raw: .webkitTapHighlightColor, .transparent)
			// Section links scroll the section a little below the header. The scroll spy of ``AppSecondaryNavigation`` reads it.
			.scrollPadding(top: SiteHeader.height + .rootEm(0.5))
			// On a short screen, the header is not sticky, so it covers no section.
			.media(.shortScreen) {
				$0.scrollPadding(top: .rootEm(0.5))
			}
			// Pages that scroll and pages that do not have the same width, so the layout does not move between them with always-visible scroll bars.
			.scrollbarGutter(.stable)
			// Only for a section link to a section that is close, which `site.js` marks, so a link far down a long page, like the “Get” button, or a page that opens at a section, jumps at once instead of scrolling through many screens.
			.when(Hooks.smoothScrolling) {
				$0.media(.allowsMotion) {
					$0.scrollBehavior(.smooth)
				}
			}
			// The text grows a little, from 16px on 1280px wide screens to 17px on 1920px wide screens, so large screens get larger text without a jump at a breakpoint, but lines of text do not get too long.
			.fluidFontSize(
				fromRem: 1,
				toRem: 1.0625,
				between: .desktop,
				and: Breakpoint(minimumWidthInRem: 120)
			)
		)

		// No focus rings, not even the ones of the browser, as the site does not want them. Text fields show their focus with their border (`FormField`), and parts that only show on focus, like the link of a section, still show.
		Rule(
			":focus-visible",
			Style()
			.noOutline()
		)

		// The text of the primary color in light mode, and of the softer body color in dark mode, where white text glares, with their colors for more contrast.
		Rule(
			"body",
			Style()
			.color(.primaryText, dark: .bodyText)
			.background(.pageBackground)
			.overflow(horizontal: .clip)
			.declaration(raw: .webkitFontSmoothing, "antialiased")
			.declaration(raw: .mozOSXFontSmoothing, "grayscale")
		)
	}
}

/**
The speculation rules of every page: prefetch or prerender a page of the site when the visitor is about to open a link to it, except the excluded pages.
*/
extension SpeculationRules.Rule {
	/**
	The links to the pages of the site, except the excluded pages. Not the links to files, like a photo, a download, or a feed, as the browser downloads the whole file, and does not use it when the visitor opens it. The paths of the pages have no dot, and the paths of the files have one. The pattern only looks for the dot in the path, not in the query or the fragment.
	*/
	fileprivate init(excludedPaths: [RoutePath], eagerness: Eagerness) {
		self.init(
			condition: Condition(all: [
				.hrefMatches("/*"),
				.notMatching(["/*.*"] + excludedPaths.map(\.description)),
			]),
			eagerness: eagerness
		)
	}
}
