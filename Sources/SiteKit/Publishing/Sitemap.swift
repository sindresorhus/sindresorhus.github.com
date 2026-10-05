import Foundation

/**
How a page is listed in the sitemap.
*/
public struct SitemapEntry: Sendable {
	/**
	When the content of the page last changed.
	*/
	public var lastModified: Date?

	/**
	The important images of the page, like screenshots.
	*/
	public var images: [URL]

	public init(lastModified: Date? = nil, images: [URL] = []) {
		self.lastModified = lastModified
		self.images = images
	}
}

/**
The sitemap: `sitemap-index.xml` points to `sitemap-0.xml`. The split keeps the URLs that search engines already know.
*/
public struct Sitemap {
	/**
	The path to link to, like in `robots.txt`.
	*/
	public static let indexPath: RoutePath = "/sitemap-index.xml"

	let site: URL

	/**
	The routes to list. Routes without a sitemap entry are left out.
	*/
	let pages: [Route]

	var routes: [Route] {
		let entries = pages
			.sorted(using: KeyPathComparator(\.path.description))
			.compactMap { page -> String? in
				guard let entry = page.sitemapEntry else {
					return nil
				}

				let lastModified = entry.lastModified.map { "<lastmod>\($0.isoDay)</lastmod>" } ?? ""
				let images = entry.images.map { "<image:image><image:loc>\($0.absoluteString.escapedForHTML)</image:loc></image:image>" }.joined()
				return "<url><loc>\(page.path.absoluteURL(site: site).absoluteString.escapedForHTML)</loc>\(lastModified)\(images)</url>"
			}
			.joined()

		let index = RoutePath("/sitemap-0.xml").absoluteURL(site: site).absoluteString.escapedForHTML

		return [
			.text(Self.indexPath) {
				#"<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><sitemap><loc>\#(index)</loc></sitemap></sitemapindex>"#
			},
			.text("/sitemap-0.xml") {
				#"<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">\#(entries)</urlset>"#
			},
		]
	}
}
