import Elementary
import Foundation
import SiteKit

/**
The document every page is rendered in: the head with metadata, and the body with the header, the page content, and the footer.
*/
struct SiteLayout<Content: Page>: HTMLDocument {
	let page: Content

	/**
	The rendered ``SiteBody``.
	*/
	let bodyHTML: String

	/**
	The styles and scripts that the body uses.
	*/
	let resources: PageResources

	var title: String {
		page.metadata.documentTitle
	}

	var lang: String {
		"en"
	}

	var head: some HTML {
		page.head

		if let tint = page.tint {
			Elementary.style {
				HTMLRaw(Stylesheet.accent(tint).css)
			}
		}

		MetadataHead(path: page.path, metadata: page.metadata, socialCard: page.socialCard)

		// The styles of the components on the page. The shared styles are in the stylesheet that every page links to.
		Elementary.style {
			HTMLRaw(Stylesheet {
				Layer(.components) {
					resources.styleNodes
				}

				Layer(.elements) {
					resources.elementStyleNodes
				}
			}.css)
		}

		// The counter counts a page when it is visible. A page that the speculation rules prerender is hidden until the visitor opens it, so a prerendered page that nobody opens is not counted.
		script(.src("https://gc.zgo.at/count.js"), .async, .data("goatcounter", value: "https://sindresorhus.goatcounter.com/count")) {}
	}

	var body: some HTML {
		HTMLRaw(bodyHTML)

		for path in ["/scripts/site.js"] + resources.scripts {
			script(.src(path.versioned), .type(.module)) {}
		}

		// The build generates these scripts before the pages render (`Site.contentHashes`), so a mistake in one fails the build there, and they cannot fail here.
		for element in resources.inlineScriptElements {
			script(.type(.module)) {
				HTMLRaw((try? element.generatedScript()) ?? "")
			}
		}
	}
}

/**
The visible part of every page: the header, the page content, and the footer. Components read the path of the page from the environment, like the header for the link of the current section.
*/
struct SiteBody<Content: Page>: HTML {
	let page: Content

	var body: some HTML {
		content
			.environment(RoutePath.$current, page.path)
	}

	@ContentBuilder
	private var content: some HTML {
		SiteHeader(variant: page.navigation, background: page.headerBackground)

		main {
			page.body
		}

		SiteFooter()
		UnicornEasterEgg()
	}
}

/**
The `<head>` tags that describe a page to browsers, search engines, feed readers, and social media.
*/
private struct MetadataHead: HTML {
	let path: RoutePath
	let metadata: PageMetadata

	/**
	The card of the page, or `nil` for the site card.
	*/
	let socialCard: OpenGraphCard?

	private var canonicalURL: String {
		path.absoluteURL.absoluteString
	}

	private var socialTitle: String {
		metadata.socialTitle ?? metadata.documentTitle
	}

	private var imageURL: String {
		(socialCard?.path ?? OpenGraphCard.sitePath).absoluteURL.absoluteString
	}

	var body: some HTML {
		meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
		meta(.name(.author), .content(Site.author.name))
		meta(.name("generator"), .content("SiteKit, in Swift (\(Site.sourceURL.absoluteString))"))
		meta(.name("twitter:site"), .content(Site.author.twitterHandle))
		meta(.name("twitter:creator"), .content(Site.author.twitterHandle))
		meta(.name("fediverse:creator"), .content(Site.author.fediverseHandle))
		meta(.name("twitter:card"), .content("summary_large_image"))
		meta(.name("theme-color"), .content(SemanticColor.pageBackground.colors.light.resolved.description), .media(.light))
		meta(.name("theme-color"), .content(SemanticColor.pageBackground.colors.dark.resolved.description), .media(.dark))

		// Dark mode visitors do not see a white page before the stylesheet loads.
		meta(.name("color-scheme"), .content("light dark"))

		if let description = metadata.description {
			meta(.name(.description), .content(description))
		}

		if !metadata.isIndexed {
			meta(.name("robots"), .content("noindex"))
		}

		if let appStoreID = metadata.appStoreID {
			meta(.name("apple-itunes-app"), .content("app-id=\(appStoreID)\(metadata.appStoreCampaign.map { ", affiliate-data=\($0)" } ?? "")"))
		}

		link(.rel(.canonical), .href(canonicalURL))
		link(.rel(.stylesheet), .href(Stylesheet.sitePath.versioned))
		link(.rel("apple-touch-icon"), .href(RoutePath("/apple-touch-icon.png")))
		link(.rel(.icon), .href(metadata.favicon))

		for feed in SiteFeed.allCases.map(\.link) + metadata.feeds {
			link(.rel("alternate"), .custom(name: "type", value: "application/rss+xml"), .title(feed.title), .href(feed.path))
		}

		for origin in metadata.preconnectOrigins {
			link(.rel("preconnect"), .href(origin))
		}

		// Prerenders a page of the site when the pointer rests on a link to it, so it opens at once. Not the random app page, which picks another app each time, or the feedback form. Browsers without the Speculation Rules API ignore it.
		JSONScript(speculationRules: SpeculationRules(excludedPaths: [.randomApp, .feedback]))

		meta(.property("og:title"), .content(socialTitle))
		meta(.property("og:type"), .content(metadata.kind.openGraphType))
		meta(.property("og:url"), .content(canonicalURL))
		meta(.property("og:image"), .content(imageURL))
		meta(.property("og:image:width"), .content(String(OpenGraphCard.width)))
		meta(.property("og:image:height"), .content(String(OpenGraphCard.height)))
		meta(.property("og:image:alt"), .content(socialCard?.description ?? Site.name))
		meta(.property("og:locale"), .content("en_US"))
		meta(.property("og:site_name"), .content(Site.name))

		if let description = metadata.description {
			meta(.property("og:description"), .content(description))
		}

		// X reads the title, description, and image from the Open Graph tags.

		if case .article(let publishedAt, let tags) = metadata.kind {
			meta(.property("article:published_time"), .content(publishedAt.formatted(.iso8601)))
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
	The styles of the `html` and `body` elements that ``SiteLayout`` renders. They are in the base layer of the shared stylesheet.
	*/
	static let document = Stylesheet {
		Rule("html", Style()
			.lineHeight(1.5)
			.fontFamily(.system)
			.declaration(.webkitTextSizeAdjust, .percent(100))
			.declaration(.webkitTapHighlightColor, .transparent)
			// Section links scroll the section a little below the header. The scroll spy of ``AppSecondaryNavigation`` reads it.
			.scrollPadding(top: SiteHeader.height + .rootEm(0.5))
			// Pages that scroll and pages that do not have the same width, so the layout does not move between them with always-visible scroll bars.
			.scrollbarGutter(.stable)
			.media(.allowsMotion) {
				$0.scrollBehavior(.smooth)
			}
			// The text grows a little, from 16px on 1280px wide screens to 17px on 1920px wide screens, so large screens get larger text without a jump at a breakpoint, but lines of text do not get too long.
			.fluidFontSize(fromRem: 1, toRem: 1.0625, between: .desktop, and: Breakpoint(minimumWidthInRem: 120))
		)

		// No focus rings, not even the ones of the browser, as the site does not want them. Text fields show their focus with their border (`FormField`), and parts that only show on focus, like the link of a section, still show.
		Rule(":focus-visible", Style()
			.noOutline()
		)

		Rule("body", Style()
			.color(.gray(900), dark: .gray(300))
			.background(.pageBackground)
			.overflow(horizontal: .clip)
			.declaration(.webkitFontSmoothing, "antialiased")
			.declaration(.mozOSXFontSmoothing, "grayscale")
		)
	}
}

/**
The speculation rules of every page: prerender a page of the site when the pointer rests on a link to it, except the excluded pages.
*/
private struct SpeculationRules: Encodable {
	struct Rule: Encodable {
		struct Condition: Encodable {
			struct PathPattern: Encodable {
				let pathname: RoutePath
			}

			struct Not: Encodable {
				let hrefMatches: [PathPattern]
			}

			struct Clause: Encodable {
				var hrefMatches: String?
				var not: Not?
			}

			let and: [Clause]
		}

		let `where`: Condition
		let eagerness = "moderate"
	}

	let prerender: [Rule]

	init(excludedPaths: [RoutePath]) {
		self.prerender = [
			Rule(where: Rule.Condition(and: [
				Rule.Condition.Clause(hrefMatches: "/*"),
				Rule.Condition.Clause(not: Rule.Condition.Not(hrefMatches: excludedPaths.map { Rule.Condition.PathPattern(pathname: $0) })),
			])),
		]
	}
}
