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
		page.metadata.title
	}

	var lang: String {
		"en"
	}

	var head: some HTML {
		MetadataHead(path: page.path, metadata: page.metadata)

		// The styles of the components on the page. The shared styles are in the stylesheet that every page links to.
		Elementary.style {
			HTMLRaw(Stylesheet {
				Layer("components") {
					resources.styleNodes
				}
			}.css)
		}

		script(.src("https://gc.zgo.at/count.js"), .async, .data("goatcounter", value: "https://sindresorhus.goatcounter.com/count")) {}
	}

	var body: some HTML {
		HTMLRaw(bodyHTML)

		for path in ["/scripts/site.js"] + resources.scripts {
			script(.src(path), .type(.module)) {}
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

	@HTMLBuilder
	private var content: some HTML {
		SiteHeader(variant: page.navigation)

		main {
			page.body
		}

		SiteFooter()
		UnicornEasterEgg()
	}
}

extension RoutePath {
	/**
	The path of the page that is rendering, for presentation, like highlighting the link of the current section. Read it with `@Environment(requiring: RoutePath.$current)`.
	*/
	@TaskLocal static var current: RoutePath?
}

/**
The `<head>` tags that describe a page to browsers, search engines, feed readers, and social media.
*/
private struct MetadataHead: HTML {
	let path: RoutePath
	let metadata: PageMetadata

	private var canonicalURL: String {
		path.absoluteURL(site: Site.url).absoluteString
	}

	private var socialTitle: String {
		metadata.socialTitle ?? metadata.title
	}

	private var imageURL: String {
		metadata.image.path.absoluteURL(site: Site.url).absoluteString
	}

	var body: some HTML {
		meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
		meta(.name(.author), .content(Site.author.name))
		meta(.name("generator"), .content("SiteKit, in Swift (\(Site.sourceURL.absoluteString))"))
		meta(.name("twitter:site"), .content(Site.author.twitterHandle))
		meta(.name("twitter:creator"), .content(Site.author.twitterHandle))
		meta(.name("fediverse:creator"), .content(Site.author.fediverseHandle))
		meta(.name("twitter:card"), .content("summary_large_image"))
		meta(.name("theme-color"), .content("#ffffff"), .custom(name: "media", value: "(prefers-color-scheme: light)"))
		meta(.name("theme-color"), .content("#020617"), .custom(name: "media", value: "(prefers-color-scheme: dark)"))

		if let description = metadata.description {
			meta(.name(.description), .content(description))
			meta(.name("twitter:description"), .content(description))
		}

		meta(.name("robots"), .content(metadata.isIndexed ? "index, follow" : "noindex, follow"))

		if let appStoreID = metadata.appStoreID {
			meta(.name("apple-itunes-app"), .content("app-id=\(appStoreID)\(metadata.appStoreCampaign.map { ", affiliate-data=\($0)" } ?? "")"))
		}

		link(.rel(.canonical), .href(canonicalURL))
		link(.rel(.stylesheet), .href(Stylesheet.sitePath))
		link(.rel("sitemap"), .href(Sitemap.indexPath))
		link(.rel("apple-touch-icon"), .href("/apple-touch-icon.png"))
		link(.rel(.icon), .href(metadata.favicon))

		for feed in SiteFeed.allCases.map(\.metadata) + metadata.feeds {
			link(.rel("alternate"), .custom(name: "type", value: "application/rss+xml"), .title(feed.title), .href(feed.path))
		}

		for origin in metadata.preconnectOrigins {
			link(.rel("preconnect"), .href(origin))
		}

		// Prefetches a page of the site when the pointer rests on a link to it, so it opens at once. Browsers without the Speculation Rules API ignore it.
		HTMLRaw(#"<script type="speculationrules">{"prefetch":[{"where":{"href_matches":"/*"},"eagerness":"moderate"}]}</script>"#)

		meta(.property("og:title"), .content(socialTitle))
		meta(.property("og:type"), .content(metadata.kind.openGraphType))
		meta(.property("og:url"), .content(canonicalURL))
		meta(.property("og:image"), .content(imageURL))
		meta(.property("og:image:width"), .content("1200"))
		meta(.property("og:image:height"), .content("630"))
		meta(.property("og:image:alt"), .content(metadata.image.description))
		meta(.property("og:locale"), .content("en_US"))
		meta(.property("og:site_name"), .content(Site.name))

		if let description = metadata.description {
			meta(.property("og:description"), .content(description))
		}

		meta(.name("twitter:title"), .content(socialTitle))
		meta(.name("twitter:image"), .content(imageURL))

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
	The styles of the `html` and `body` elements that ``SiteLayout`` renders. They are in the base layer of the shared stylesheet.
	*/
	static let document = Stylesheet {
		Rule("html", Style()
			.lineHeight(1.5)
			.fontFamily(.system)
			.declaration("-webkit-text-size-adjust", .percent(100))
			.declaration("-webkit-tap-highlight-color", .transparent)
			// The header is 72px high.
			.declaration(.scrollPaddingTop, .px(80))
			// Pages that scroll and pages that do not have the same width, so the layout does not move between them with always-visible scroll bars.
			.declaration("scrollbar-gutter", "stable")
			.media("(prefers-reduced-motion: no-preference)") {
				$0.declaration(.scrollBehavior, "smooth")
			}
			.breakpoint(.xxl) {
				$0.font(size: .px(20))
			}
		)

		Rule("body", Style()
			// The header and the app hero are not nested, so the timeline of the hero is made available from here.
			.timelineScope(AppHero.timeline)
			.color(.gray(900), dark: .slate(300))
			.background(.pageBackground)
			.letterSpacing(.em(-0.025))
			.overflow(horizontal: .clip)
			.declaration("-webkit-font-smoothing", "antialiased")
			.declaration("-moz-osx-font-smoothing", "grayscale")
		)
	}
}
