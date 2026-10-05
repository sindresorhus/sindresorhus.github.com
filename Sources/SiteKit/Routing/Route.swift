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
		case redirect(to: LinkDestination)

		/**
		Any other file, like an RSS feed or an image. Rendering can be asynchronous, like running a command-line tool.
		*/
		case file(render: @Sendable () async throws -> Data)
	}

	public let path: RoutePath
	public let output: Output

	public init(_ path: RoutePath, output: Output) {
		self.path = path
		self.output = output
	}

	/**
	- Parameter sitemapEntry: How the page is listed in the sitemap. `nil` leaves it out, like for a page that search engines must not index.
	*/
	public static func page(_ path: RoutePath, sitemapEntry: SitemapEntry? = SitemapEntry(), render: @escaping @Sendable () throws -> String) -> Self {
		Self(path, output: .page(sitemapEntry: sitemapEntry, render: render))
	}

	/**
	A page that sends visitors to another page of the site, or to a page on another site, like a blog post that moved.
	*/
	public static func redirect(_ path: RoutePath, to destination: LinkDestination) -> Self {
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
	public var outputFile: String {
		switch output {
		case .page, .redirect:
			return path == .root ? "index.html" : "\(path.relativePath).html"
		case .file:
			return path.relativePath
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

	Route.redirect("/thanks", to: .path("/supporters"))
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
