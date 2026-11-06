import Elementary
import Foundation
import SiteKit

/**
A page of the site. The ``SiteLayout`` wraps the body in the document with the head, header, and footer.

Pages are added to the routes directly:

```swift
@RouteBuilder
var routes: [Route] {
	HomePage()
	ContactPage()
}
```
*/
protocol Page: RouteConvertible, Sendable {
	associatedtype Body: HTML
	associatedtype Head: HTML = EmptyHTML

	var path: RoutePath { get }
	var metadata: PageMetadata { get }

	/**
	The content of the page, inside `<main>`.
	*/
	@ContentBuilder
	var body: Body { get }

	/**
	Elements at the start of `<head>`, like a script that must run before the page shows. Most pages have none.

	The head renders after the body has collected its styles, so a style used here, like `.style { … }`, gets no rule. Use raw elements only.
	*/
	@ContentBuilder
	var head: Head { get }

	/**
	App pages hide the donation links so the app gets the attention.
	*/
	var navigation: SiteHeader.Variant { get }

	/**
	The app that the “Feedback” link of the footer opens the form for, so the visitor does not pick it again. Defaults to the app of ``navigation``, like on an app page or its release notes. A page about an app that is not in the “Apps” section, like a guide, gives its app here.
	*/
	var feedbackApp: App? { get }

	/**
	The accent of the page, like `tint(_:)` in SwiftUI, for the links and the buttons, also in the header, like the color of the icon on an app page. `nil` keeps the accent of the site.
	*/
	var tint: Color? { get }

	/**
	The background of the site header. Pages with a background that continues behind the header make it see-through at the top.
	*/
	var headerBackground: SiteHeader.Background { get }

	/**
	How the page is listed in the sitemap, like when its content last changed. Defaults to a plain entry. A page that search engines may not index (``PageMetadata/isIndexed``) is left out of the sitemap, whatever its entry, as the sitemap asks them to index its pages.
	*/
	var sitemapEntry: SitemapEntry { get }

	/**
	The preview image for social media. Defaults to the site card. A page that people share on its own, like the discounts page, has a card with its title (``OpenGraphCard/init(page:project:)``), so the preview does not look like the home page.
	*/
	var socialImage: SocialImage { get }

	/**
	The name of the page in a link to it from a list of pages, like the suggestion of the 404 page. Defaults to the title. An app page has the name of the app, like “Dato”, as its title also has the subtitle.
	*/
	var linkTitle: String { get }
}

extension Page where Head == EmptyHTML {
	var head: EmptyHTML {
		EmptyHTML()
	}
}

extension Page {
	var navigation: SiteHeader.Variant {
		.standard
	}

	var feedbackApp: App? {
		navigation.app
	}

	var headerBackground: SiteHeader.Background {
		.standard
	}

	/**
	The color of the icon as the accent of the page, for the buttons and the links, also in the header.
	*/
	var tint: Color? {
		navigation.app?.tint
	}

	var sitemapEntry: SitemapEntry {
		SitemapEntry()
	}

	var socialImage: SocialImage {
		.site
	}

	var linkTitle: String {
		metadata.title
	}

	/**
	The URL of the preview image for social media.
	*/
	var socialImageURL: URL {
		socialImage.url
	}

	/**
	The body renders first and collects the styles and scripts it uses. Then the document is rendered with only those. The inline scripts of the elements are generated here, so a mistake in one fails the build.
	*/
	var route: Route {
		.page(path, sitemapEntry: metadata.isIndexed ? sitemapEntry : nil) {
			let body = try RenderedHTML(sharedStylesheet: .site) {
				SiteBody(page: self)
			}
			let inlineScripts = try body.resources.inlineScriptElements.map { try $0.generatedScript() }

			return SiteLayout(
				page: self,
				bodyHTML: body,
				inlineScripts: inlineScripts
			).render()
		}
		.title(linkTitle)
	}
}

/**
A draft (`isDraft: true`) in the preview of `website serve`: the page with a “Draft” label above it, which search engines may not index (``PageMetadata/isIndexed``), so it is not in the sitemap either. `website build` loads no drafts (``SiteContent/drafts``), so it never publishes one.
*/
struct DraftPage<Wrapped: Page>: Page {
	let wrapped: Wrapped

	init(_ wrapped: Wrapped) {
		self.wrapped = wrapped
	}

	var path: RoutePath {
		wrapped.path
	}

	var metadata: PageMetadata {
		var metadata = wrapped.metadata
		metadata.isIndexed = false
		return metadata
	}

	var body: some HTML {
		div {
			Badge("Draft", kind: .archived)
		}
		.style {
			$0
				.pageColumn(.page)
				.padding(.top, .rootEm(1))
		}

		wrapped.body
	}

	var head: Wrapped.Head {
		wrapped.head
	}

	var navigation: SiteHeader.Variant {
		wrapped.navigation
	}

	var feedbackApp: App? {
		wrapped.feedbackApp
	}

	var tint: Color? {
		wrapped.tint
	}

	var headerBackground: SiteHeader.Background {
		wrapped.headerBackground
	}

	var sitemapEntry: SitemapEntry {
		wrapped.sitemapEntry
	}

	var socialImage: SocialImage {
		wrapped.socialImage
	}

	var linkTitle: String {
		wrapped.linkTitle
	}
}

extension RouteBuilder {
	/**
	The page and its own social card. It is more specific than the `RouteConvertible` overload, so it is used for pages.
	*/
	static func buildExpression(_ page: some Page) -> [Route] {
		[page.route] + [page.socialImage.publishedCard?.route].compactMap(\.self)
	}

	static func buildExpression<Pages: Sequence>(_ pages: Pages) -> [Route] where Pages.Element: Page {
		pages.flatMap(buildExpression)
	}
}
