import Foundation

/**
A file in the published site: a page, a redirect, or any other file, like a feed or an image.

Routes are cheap descriptions. The content is only rendered when the site is published.
*/
public struct Route: Sendable {
	public enum Output: Sendable {
		/**
		An HTML page, listed in the sitemap unless `isInSitemap` is false.
		*/
		case page(isInSitemap: Bool, render: @Sendable () throws -> String)

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

	/**
	When the content of a page last changed, for the sitemap.
	*/
	public var lastModified: Date?

	/**
	The important images of a page, like screenshots, for the sitemap.
	*/
	public var images = [URL]()

	public init(_ path: RoutePath, output: Output) {
		self.path = path
		self.output = output
	}

	public static func page(_ path: RoutePath, isInSitemap: Bool = true, lastModified: Date? = nil, images: [URL] = [], render: @escaping @Sendable () throws -> String) -> Self {
		var route = Self(path, output: .page(isInSitemap: isInSitemap, render: render))
		route.lastModified = lastModified
		route.images = images
		return route
	}

	public static func redirect(_ path: RoutePath, to destination: RoutePath) -> Self {
		Self(path, output: .redirect(to: .path(destination)))
	}

	/**
	A page that sends visitors to a page on another site, like a blog post that moved.
	*/
	public static func redirect(_ path: RoutePath, to url: URL) -> Self {
		Self(path, output: .redirect(to: .url(url)))
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
		let relative = String(path.description.dropFirst())

		switch output {
		case .page, .redirect:
			return path == .root ? "index.html" : "\(relative).html"
		case .file:
			return relative
		}
	}

	public var isInSitemap: Bool {
		guard case .page(let isInSitemap, _) = output else {
			return false
		}

		return isInSitemap
	}
}

/**
Builds a list of routes with loops and conditions.

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
	public static func buildExpression(_ route: Route) -> [Route] {
		[route]
	}

	public static func buildExpression(_ routes: [Route]) -> [Route] {
		routes
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
