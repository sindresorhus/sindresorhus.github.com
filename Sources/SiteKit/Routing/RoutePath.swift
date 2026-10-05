import Foundation

/**
The URL path of a route, like `/`, `/apps`, or `/rss.xml`.

Paths always start with `/`, have no repeated `/`, and never end with `/` (except the root), matching the site's “no trailing slash” URLs.
*/
public struct RoutePath: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral, ValidatedValue {
	public let description: String

	public init(_ path: String) {
		precondition(path.hasPrefix("/"), "A route path must start with “/”: \(path)")
		// Repeated slashes, as `/blog//post` would write the same file as `/blog/post`, and `//example.com` in a link goes to another host. And all trailing slashes, as one left would write a hidden file, like `old/.html` for `/old//`.
		let trimmed = path.replacing(/\/{2,}/, with: "/").replacing(/\/+$/, with: "")
		self.description = trimmed.isEmpty ? "/" : trimmed
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	/**
	A path from content, like `/old-name` in frontmatter. Throws if it does not start with `/`, or has a `.` or `..` component, which would publish a file outside the output directory.
	*/
	public init(validating path: String) throws(ContentError) {
		guard path.hasPrefix("/") else {
			throw ContentError(reason: "Must be a path that starts with “/”, got “\(path)”.")
		}

		guard !path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }) else {
			throw ContentError(reason: "Must not have “.” or “..” in it, got “\(path)”.")
		}

		self.init(path)
	}

	public static let root: Self = "/"

	/**
	The path of the page that is rendering, for presentation, like highlighting the link of the current section. Read it with `@Environment(requiring: RoutePath.$current)`.
	*/
	@TaskLocal public static var current: RoutePath?

	/**
	Whether the path is the other path or inside it, by whole components: `/blog/post` starts with `/blog`, but `/blogroll` does not.
	*/
	public func starts(with other: Self) -> Bool {
		other == .root || self == other || description.hasPrefix(other.description + "/")
	}

	/**
	Appends one path component, like a slug.
	*/
	public func appending(_ component: String) -> Self {
		precondition(!component.isEmpty && !component.contains("/"), "A path component cannot be empty or contain “/”: \(component)")
		return Self(self == .root ? "/\(component)" : "\(description)/\(component)")
	}

	/**
	The path without the leading `/`, like `apps/dato` for `/apps/dato`, relative to a directory of the site.
	*/
	var relativePath: String {
		String(description.dropFirst())
	}

	/**
	The whole URL of the path on the site, like `https://sindresorhus.com/apps`.
	*/
	public func absoluteURL(site: URL) -> URL {
		self == .root ? site.appending(path: "/") : site.appending(path: description)
	}
}

extension RoutePath: Encodable {
	/**
	Encodes the path as a string, like `/apps`, for data that scripts read.
	*/
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(description)
	}
}
