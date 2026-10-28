import Foundation

/**
A file in the published site: a page, a redirect, or any other file, like a feed or an image.

Routes are cheap descriptions. The content is only rendered when the site is published.
*/
public struct Route: Sendable {
	public enum Output: Sendable {
		/**
		An HTML page, listed in the sitemap when it has a sitemap entry.
		*/
		case page(sitemapEntry: SitemapEntry?, render: @Sendable () throws -> String)

		/**
		An HTML page that sends visitors to another route, or to a page on another site.
		*/
		case redirect(to: RedirectDestination)

		/**
		Any other file, like an RSS feed or an image. Rendering can be asynchronous, like running a command-line tool.
		*/
		case file(render: @Sendable () async throws -> Data)

		/**
		Renders this output without choosing a file location. The publisher adds route context to failures and writes the bytes atomically.
		*/
		func render(site: SiteOrigin) async throws -> Data {
			switch self {
			case .page(_, let render):
				try Data(render().utf8)
			case .redirect(let destination):
				Data(destination.html(site: site).utf8)
			case .file(let render):
				try await render()
			}
		}
	}

	public let path: RoutePath
	public let output: Output

	/**
	Where the route comes from, like “`redirectFrom` of content/apps/dato/index.md”, so a route that writes the file of another route names the files to change (``source(_:_:)``). `nil` names the route by its path.
	*/
	public private(set) var source: Source?

	private init(_ path: RoutePath, output: Output) {
		self.path = path
		self.output = output
	}

	/**
	Where a route comes from: a file, and what of the file makes the route, like “`redirectFrom` of” `content/apps/dato/index.md`. The publisher writes the path of the file relative to the project, like the paths of the other messages.
	*/
	public struct Source: Sendable {
		/**
		What of the file makes the route, like “the page of” or “`redirectFrom` of”.
		*/
		public let role: String

		/**
		The file, like `content/apps/dato/index.md`.
		*/
		public let location: SourceLocation

		/**
		The source as the message of a collision names it, like “`redirectFrom` of content/apps/dato/index.md”.
		*/
		func description(relativeTo directory: URL) -> String {
			"\(role) \(location.description(relativeTo: directory))"
		}
	}

	/**
	The route with where it comes from, like `route.source("the page of", .file(url))`, for the message of a route that writes the file of another route.
	*/
	public func source(_ role: String, _ location: SourceLocation) -> Self {
		var route = self
		route.source = Source(role: role, location: location)
		return route
	}

	/**
	- Parameter sitemapEntry: How the page is listed in the sitemap. `nil` leaves it out, like for a page that search engines must not index.
	*/
	public static func page(_ path: RoutePath, sitemapEntry: SitemapEntry? = SitemapEntry(), render: @escaping @Sendable () throws -> String) -> Self {
		Self(path, output: .page(sitemapEntry: sitemapEntry, render: render))
	}

	/**
	A page that sends visitors to another page of the site, like a blog post that moved.
	*/
	public static func redirect(_ path: RoutePath, to destination: RoutePath) -> Self {
		redirect(path, to: RedirectDestination.path(destination))
	}

	/**
	A page that sends visitors to a page on another site, like an app page that moved to the site of the app.
	*/
	public static func redirect(_ path: RoutePath, to url: URL) -> Self {
		redirect(path, to: RedirectDestination.url(url))
	}

	/**
	A redirect to a site path with a query, or an external URL.
	*/
	public static func redirect(_ path: RoutePath, to destination: RedirectDestination) -> Self {
		Self(path, output: .redirect(to: destination))
	}

	public static func file(_ path: RoutePath, render: @escaping @Sendable () async throws -> Data) -> Self {
		precondition(path != .root, "A file route needs a file name.")
		return Self(path, output: .file(render: render))
	}

	public static func text(_ path: RoutePath, render: @escaping @Sendable () throws -> String) -> Self {
		file(path) {
			try Data(render().utf8)
		}
	}

	/**
	The file the route is written to, relative to the output directory.

	Pages and redirects are HTML files, which static hosts like GitHub Pages serve at the extensionless URL: `index.html` for `/`, and `<path>.html` for the rest, even when the path has a dot, like `/blog/macos-13.1`. Other files are written at their path, like `rss.xml`.
	*/
	public var outputFile: PublishedFilePath {
		switch output {
		case .page, .redirect:
			PublishedFilePath(path == .root ? "index.html" : "\(path.relativePath).html")
		case .file:
			PublishedFilePath(path.relativePath)
		}
	}

	/**
	How the route is listed in the sitemap. Only pages can be listed.
	*/
	public var sitemapEntry: SitemapEntry? {
		guard case .page(let sitemapEntry, _) = output else {
			return nil
		}

		return sitemapEntry
	}
}

/**
Where a redirect page sends visitors (``Route/Output/redirect(to:)``): a page of the site, with an optional query, like `/feedback?product=Dato`, or a page on another site. Unlike a ``LinkDestination``, it cannot be a fragment of the same page, which a redirect page cannot go to.
*/
public enum RedirectDestination: Hashable, Sendable, CustomStringConvertible {
	case path(RoutePath, query: [URLQueryItem] = [])
	case url(AbsoluteURL)

	/**
	An absolute URL supplied by the code. A relative URL is a programming error.
	*/
	public static func url(_ url: URL) -> Self {
		.url(AbsoluteURL(url))
	}

	private var link: LinkDestination {
		switch self {
		case .path(let path, let query):
			.path(path, query: query)
		case .url(let url):
			.url(url)
		}
	}

	/**
	The destination for an `href` attribute.
	*/
	public var description: String {
		link.description
	}

	/**
	The whole URL, like for the canonical link of the redirect page.
	*/
	public func absoluteURL(site: SiteOrigin) -> URL {
		switch self {
		case .path(let path, _):
			link.absoluteURL(site: site, page: path)
		case .url(let url):
			url.value
		}
	}

	/**
	The static redirect document, with the visible link and canonical URL derived from the same destination.
	*/
	fileprivate func html(site: SiteOrigin) -> String {
		let canonicalURL = absoluteURL(site: site)
		let href = description.escapedForHTML
		return #"<!doctype html><html lang="en"><meta charset="utf-8"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0; url=\#(href)"><link rel="canonical" href="\#(canonicalURL.absoluteString.escapedForHTML)"><title>Redirecting to: \#(href)</title><a href="\#(href)">Redirecting…</a>"#
	}
}

/**
A value that is published as a route, like a page. ``RouteBuilder`` takes it directly.
*/
public protocol RouteConvertible {
	var route: Route { get }
}

extension Route: RouteConvertible {
	public var route: Route {
		self
	}
}

/**
Builds a list of routes with loops and conditions, from routes and other values that have a route, like pages.

```swift
@RouteBuilder
var routes: [Route] {
	Route.page("/") { home.render() }

	for post in posts {
		Route.page("/blog/\(post.slug)") { post.render() }
	}

	Route.redirect("/thanks", to: "/supporters")
}
```
*/
@resultBuilder
public enum RouteBuilder {
	public static func buildExpression(_ value: some RouteConvertible) -> [Route] {
		[value.route]
	}

	public static func buildExpression(_ values: [some RouteConvertible]) -> [Route] {
		values.map(\.route)
	}

	public static func buildBlock(_ components: [Route]...) -> [Route] {
		components.flatMap(\.self)
	}

	public static func buildArray(_ components: [[Route]]) -> [Route] {
		components.flatMap(\.self)
	}

	public static func buildOptional(_ component: [Route]?) -> [Route] {
		component ?? []
	}

	public static func buildEither(first component: [Route]) -> [Route] {
		component
	}

	public static func buildEither(second component: [Route]) -> [Route] {
		component
	}
}

/**
A file path relative to the published site directory, like `blog/post.html`, distinct from a web route and a source file path.
*/
public struct PublishedFilePath: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
	public let description: String

	/**
	Checks a code-owned relative file path. Use `init(validating:)` for external input.
	*/
	public init(_ path: String) {
		do {
			try self.init(validating: path)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Checks a literal relative file path.
	*/
	public init(stringLiteral value: String) {
		self.init(value)
	}

	/**
	Validates a nonempty relative file path without empty, `.` or `..` components.
	*/
	public init(validating path: String) throws(ContentError) {
		let components = path.split(separator: "/", omittingEmptySubsequences: false)

		guard
			!path.contains("\0"),
			components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
		else {
			throw ContentError(reason: "Must be a relative file path without empty, “.” or “..” components, got “\(path)”.")
		}

		self.description = path
	}

	/**
	The URL of the file in the output directory.
	*/
	public func fileURL(in directory: URL) -> URL {
		directory.appending(path: description)
	}
}
