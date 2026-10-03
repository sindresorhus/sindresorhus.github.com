import Foundation

/**
The sitemap: `sitemap-index.xml` points to `sitemap-0.xml`. The split keeps the URLs that search engines already know.
*/
public struct Sitemap {
	/**
	The path to link to, like in `<link rel="sitemap">` and `robots.txt`.
	*/
	public static let indexPath: RoutePath = "/sitemap-index.xml"

	let site: URL
	let pages: [Route]

	var routes: [Route] {
		let entries = pages
			.sorted(using: KeyPathComparator(\.path.description))
			.map { page in
				let lastModified = page.lastModified.map { "<lastmod>\($0.isoDay)</lastmod>" } ?? ""
				let images = page.images.map { "<image:image><image:loc>\($0.absoluteString.escapedForHTML)</image:loc></image:image>" }.joined()
				return "<url><loc>\(page.path.absoluteURL(site: site).absoluteString.escapedForHTML)</loc>\(lastModified)\(images)</url>"
			}
			.joined()

		let index = site.appending(path: "sitemap-0.xml").absoluteString.escapedForHTML

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
