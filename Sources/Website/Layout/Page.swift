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
protocol Page: Sendable {
	associatedtype Body: HTML

	var path: RoutePath { get }
	var metadata: PageMetadata { get }

	/**
	The content of the page, inside `<main>`.
	*/
	@HTMLBuilder
	var body: Body { get }

	/**
	Whether the page is listed in the sitemap. Defaults to whether search engines may index it.
	*/
	var isInSitemap: Bool { get }

	/**
	App pages hide the donation links so the app gets the attention.
	*/
	var navigation: SiteHeader.Variant { get }

	/**
	When the content last changed, for the sitemap.
	*/
	var lastModified: Date? { get }

	/**
	The important images, like screenshots, for the sitemap.
	*/
	var sitemapImages: [URL] { get }
}

extension Page {
	var isInSitemap: Bool {
		metadata.isIndexed
	}

	var navigation: SiteHeader.Variant {
		.standard
	}

	var lastModified: Date? {
		nil
	}

	var sitemapImages: [URL] {
		[]
	}

	/**
	The body renders first and collects the styles and scripts it uses. Then the document is rendered with only those.
	*/
	var route: Route {
		.page(path, isInSitemap: isInSitemap, lastModified: lastModified, images: sitemapImages) {
			let resources = PageResources(sharedStyleSets: Stylesheet.sharedStyleSets)
			let body = resources.collect {
				SiteBody(page: self).render()
			}

			guard resources.duplicateClassNames.isEmpty else {
				throw StyleError.duplicateClassNames(resources.duplicateClassNames.sorted())
			}

			return SiteLayout(page: self, bodyHTML: body, resources: resources).render()
		}
	}
}

extension RouteBuilder {
	static func buildExpression(_ page: some Page) -> [Route] {
		[page.route]
	}

	static func buildExpression(_ pages: [some Page]) -> [Route] {
		pages.map(\.route)
	}
}

enum StyleError: Error, CustomStringConvertible {
	/**
	Two style sets generate the same class name, like `Badge.Styles` and a top-level `BadgeStyles`, so their styles would clash.
	*/
	case duplicateClassNames([String])

	var description: String {
		switch self {
		case .duplicateClassNames(let names):
			"More than one style set generates the class names \(names.joined(separator: ", ")). Rename one of the types."
		}
	}
}
