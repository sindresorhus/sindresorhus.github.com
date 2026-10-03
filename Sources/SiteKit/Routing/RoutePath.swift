import Foundation

/**
The URL path of a route, like `/`, `/apps`, or `/rss.xml`.

Paths always start with `/` and never end with `/` (except the root), matching the site's “no trailing slash” URLs.
*/
public struct RoutePath: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral, Decodable {
	public let description: String

	public init(_ path: String) {
		precondition(path.hasPrefix("/"), "A route path must start with “/”: \(path)")
		self.description = path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	/**
	Decodes a path, like `/old-name` in frontmatter. Throws if it does not start with `/`, or has a `.` or `..` component, which would publish a file outside the output directory.
	*/
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let path = try container.decode(String.self)

		guard path.hasPrefix("/") else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must be a path that starts with “/”, got “\(path)”.")
		}

		guard !path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must not have “.” or “..” in it, got “\(path)”.")
		}

		self.init(path)
	}

	public static let root: Self = "/"

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
	Appends a fragment, like `/apps/faq#refund`.
	*/
	public func fragment(_ fragment: String) -> String {
		"\(description)#\(fragment)"
	}

	public func absoluteURL(site: URL, fragment: String? = nil) -> URL {
		let url = self == .root ? site.appending(path: "/") : site.appending(path: description)

		guard let fragment else {
			return url
		}

		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		components?.fragment = fragment
		return components?.url ?? url
	}
}
