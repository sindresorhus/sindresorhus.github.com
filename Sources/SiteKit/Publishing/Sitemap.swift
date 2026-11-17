import Foundation
import SOML

/**
How a page is listed in the sitemap.
*/
public struct SitemapEntry: Sendable {
	/**
	The UTC day on which the content of the page last changed.
	*/
	public var lastModified: SOML.Date?

	/**
	The important images of the page, like screenshots.
	*/
	public var images: [AbsoluteURL]

	/**
	The important videos of the page, like the demo of an app, for the video results of Google.
	*/
	public var videos: [Video]

	/**
	A video of the page with the tags Google needs for a video sitemap, so search engines can show it in video results.
	*/
	public struct Video: Sendable {
		/**
		The title of the video, like “Gifski demo”.
		*/
		public let title: String

		/**
		What the video shows, in one sentence.
		*/
		public let description: String

		/**
		An image of the video, like its poster.
		*/
		public let thumbnail: AbsoluteURL

		/**
		The video file.
		*/
		public let content: AbsoluteURL

		public init(
			title: String,
			description: String,
			thumbnail: AbsoluteURL,
			content: AbsoluteURL
		) {
			self.title = title
			self.description = description
			self.thumbnail = thumbnail
			self.content = content
		}
	}

	public init(lastModified: SOML.Date? = nil, images: [AbsoluteURL] = [], videos: [Video] = []) {
		self.lastModified = lastModified
		self.images = images
		self.videos = videos
	}
}

/**
The sitemap: `sitemap-index.xml` points to `sitemap-0.xml`. The split keeps the URLs that search engines already know.
*/
public struct Sitemap {
	/**
	The path to link to, like in `robots.txt`.
	*/
	public static let indexPath = #path("/sitemap-index.xml")

	/**
	The path of the sitemap that the index points to.
	*/
	public static let contentPath = #path("/sitemap-0.xml")

	/**
	The paths of the pages that a published sitemap lists (``contentPath``), like `/dato`. An image of a page, like `<image:loc>`, is not a page. An empty `urlset` is valid. Malformed XML, another kind of document, or a page without an absolute URL throws, so a failed response cannot replace a usable cached sitemap. External entities are never loaded.
	*/
	public static func pagePaths(inXML xml: String) throws(ContentError) -> [RoutePath] {
		let document: XMLDocument

		do {
			document = try XMLDocument(xmlString: xml, options: .nodeLoadExternalEntitiesNever)
		} catch {
			throw ContentError(reason: "Could not read the sitemap XML: \(error.descriptiveMessage)")
		}

		guard
			let root = document.rootElement(),
			root.localName == "urlset"
		else {
			throw ContentError(reason: "A sitemap must have a `urlset` root element.")
		}

		return try root.childElements(named: "url", namespaceURI: root.uri).map { page throws(ContentError) in
			guard
				let location = page.childElements(named: "loc", namespaceURI: root.uri).first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
				let parsedURL = URL(string: location)
			else {
				throw ContentError(reason: "A sitemap page needs an absolute URL in `loc`.")
			}

			let url = try AbsoluteURL(validating: parsedURL).value
			// The home page can be without its slash, like `https://sindresorhus.com`.
			let path = url.path(percentEncoded: false)
			return try RoutePath(validating: path.isEmpty ? "/" : path)
		}
	}

	let site: SiteOrigin

	/**
	The routes to list. Routes without a sitemap entry are left out.
	*/
	let pages: [Route]

	var routes: [Route] {
		let entries = pages
			.sorted(using: KeyPathComparator(\.path.description, comparator: String.StandardComparator.lexical))
			.compactMap { page -> String? in
				guard let entry = page.sitemapEntry else {
					return nil
				}

				let lastModified = entry.lastModified.map { "<lastmod>\($0)</lastmod>" } ?? ""
				let images = entry.images.map { "<image:image><image:loc>\($0.value.absoluteString.escapedForHTML)</image:loc></image:image>" }.joined()
				let videos = entry.videos.map { "<video:video><video:thumbnail_loc>\($0.thumbnail.value.absoluteString.escapedForHTML)</video:thumbnail_loc><video:title>\($0.title.escapedForHTML)</video:title><video:description>\($0.description.escapedForHTML)</video:description><video:content_loc>\($0.content.value.absoluteString.escapedForHTML)</video:content_loc></video:video>" }.joined()
				return "<url><loc>\(page.path.absoluteURL(site: site).absoluteString.escapedForHTML)</loc>\(lastModified)\(images)\(videos)</url>"
			}
			.joined()

		let index = Self.contentPath.absoluteURL(site: site).absoluteString.escapedForHTML

		return [
			.text(Self.indexPath) {
				#"<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><sitemap><loc>\#(index)</loc></sitemap></sitemapindex>"#
			},
			.text(Self.contentPath) {
				#"<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">\#(entries)</urlset>"#
			},
		]
	}
}

extension XMLElement {
	/**
	The immediate elements with the local name and namespace, including elements without a namespace. Foundation's `elements(forLocalName:uri:)` does not match elements without a namespace, even with a `nil` or empty URI.
	*/
	fileprivate func childElements(named localName: String, namespaceURI: String?) -> [XMLElement] {
		(children ?? []).compactMap { $0 as? XMLElement }.filter { $0.localName == localName && $0.uri == namespaceURI }
	}
}
