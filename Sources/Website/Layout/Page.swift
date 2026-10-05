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
	The accent of the page, like `tint(_:)` in SwiftUI, for the links and the buttons, also in the header, like the color of the icon on an app page. `nil` keeps the accent of the site.
	*/
	var tint: Color? { get }

	/**
	The background of the site header. Pages with a background that continues behind the header make it see-through at the top.
	*/
	var headerBackground: SiteHeader.Background { get }

	/**
	How the page is listed in the sitemap, like when its content last changed. Defaults to a plain entry when search engines may index the page, and none otherwise.
	*/
	var sitemapEntry: SitemapEntry? { get }

	/**
	The preview image for social media, which is published with the page. `nil` uses the site card.
	*/
	var socialCard: OpenGraphCard? { get }
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

	var headerBackground: SiteHeader.Background {
		.standard
	}

	var tint: Color? {
		nil
	}

	var sitemapEntry: SitemapEntry? {
		metadata.isIndexed ? SitemapEntry() : nil
	}

	var socialCard: OpenGraphCard? {
		nil
	}

	/**
	The body renders first and collects the styles and scripts it uses. Then the document is rendered with only those.
	*/
	var route: Route {
		.page(path, sitemapEntry: sitemapEntry) {
			let resources = PageResources(sharedStylesheet: .site)
			let body = try resources.collect {
				SiteBody(page: self).render()
			}

			return SiteLayout(page: self, bodyHTML: body, resources: resources).render()
		}
	}
}

extension RouteBuilder {
	/**
	The page and its social card. It is more specific than the `RouteConvertible` overload, so it is used for pages.
	*/
	static func buildExpression(_ page: some Page) -> [Route] {
		[page.route] + [page.socialCard?.route].compactMap(\.self)
	}

	static func buildExpression(_ pages: [some Page]) -> [Route] {
		pages.flatMap(buildExpression)
	}
}
