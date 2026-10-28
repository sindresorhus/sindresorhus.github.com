import Foundation

/**
The HTTP or HTTPS origin of a site hosted at its root, without credentials, a prefix path, a query, or a fragment.
*/
public struct SiteOrigin: Hashable, Sendable, CustomStringConvertible {
	public let url: URL

	/**
	Checks a code-owned site origin. Use the validating initializer for configuration or other external input.
	*/
	public init(_ url: URL) {
		do {
			try self.init(validating: url)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Validates and normalizes a root origin, accepting an optional trailing slash.
	*/
	public init(validating url: URL) throws(ContentError) {
		guard
			var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
			let scheme = components.scheme?.lowercased(),
			["http", "https"].contains(scheme),
			let host = components.host,
			!host.isEmpty,
			components.user == nil,
			components.password == nil,
			components.percentEncodedPath.isEmpty || components.percentEncodedPath == "/",
			components.query == nil,
			components.fragment == nil
		else {
			throw ContentError(reason: "Must be an HTTP or HTTPS site origin without credentials, a prefix path, a query, or a fragment, got “\(url.absoluteString)”.")
		}

		components.scheme = scheme
		components.host = host.lowercased()
		components.path = ""

		guard let normalized = components.url else {
			throw ContentError(reason: "Could not normalize the site origin “\(url.absoluteString)”.")
		}

		self.url = normalized
	}

	public var description: String {
		url.absoluteString
	}
}

/**
The URL path of a route, like `/`, `/apps`, or `/rss.xml`.

Paths always start with `/`, have no repeated `/`, and never end with `/` (except the root), matching the site's “no trailing slash” URLs.
*/
public struct RoutePath: Hashable, Sendable, CustomStringConvertible, ValidatedValue {
	public let description: String

	public init(_ path: String) {
		do {
			try self.init(structure: path, isFromContent: false)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	A path from content, like `/old-name` in frontmatter. Throws if it does not start with `/`, or has a `.` or `..` component, which would publish a file outside the output directory, or a character that a link must percent-encode, which would make the `href` and the canonical URL different.

	A file name can have those characters, like a screenshot with a space in its name, so the check for them is here and not in ``init(_:)``, which also makes paths from file names.
	*/
	public init(validating path: String) throws(ContentError) {
		try self.init(structure: path, isFromContent: true)
	}

	/**
	The path with the checks that every path needs.
	*/
	private init(structure path: String, isFromContent: Bool) throws(ContentError) {
		guard path.hasPrefix("/") else {
			throw ContentError(reason: "Must be a path that starts with “/”, got “\(path)”.")
		}

		guard !isFromContent || !path.contains(where: { " ?#%".contains($0) }) else {
			throw ContentError(reason: "Must not have a space, “?”, “#”, or “%”, which a link must encode, got “\(path)”.")
		}

		let components = path.split(separator: "/")

		guard !components.contains(where: { $0 == "." || $0 == ".." }) else {
			throw ContentError(reason: "Must not have “.” or “..” in it, got “\(path)”.")
		}

		// Without empty components: repeated slashes, as `/blog//post` would write the same file as `/blog/post`, and `//example.com` in a link goes to another host. And all trailing slashes, as one left would write a hidden file, like `old/.html` for `/old//`. Pages make paths thousands of times, so it is not a regex, which is much slower.
		self.description = "/" + components.joined(separator: "/")
	}

	public static let root = Self("/")

	/**
	The path of the page that is rendering, for presentation, like highlighting the link of the current section. Read it with `@TaskLocalValue(requiring: RoutePath.$current)`.
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
	Appends a path of one or more components, like `apps/faq`, so a slug with a slash makes a nested path.
	*/
	public func appending(path: String) -> Self {
		Self("\(description)/\(path)")
	}

	/**
	The path without its last component, like `/blog/post` for `/blog/post/image.png`, or the root for a path with one component, like `/about`, and for the root.
	*/
	var parent: Self {
		Self("/" + description.split(separator: "/").dropLast().joined(separator: "/"))
	}

	/**
	The path with another extension on its last component, like `/dato/screenshot1.jxl` for `/dato/screenshot1.png` and `jxl`. Only the last component changes, so a dot in a directory is kept, like `/v1.0/file.jxl` for `/v1.0/file`, which had no extension. A leading dot is part of the name, not an extension, like in `.htaccess`.
	*/
	public func replacingPathExtension(_ pathExtension: String) -> Self {
		let name = description.split(separator: "/").last ?? ""
		precondition(!name.isEmpty, "The root has no file name to change the extension of.")
		let nameWithoutExtension = name.dropFirst().lastIndex(of: ".").map { name[..<$0] } ?? name
		return parent.appending("\(nameWithoutExtension).\(pathExtension)")
	}

	/**
	The path without the leading `/`, like `apps/dato` for `/apps/dato`, relative to a directory of the site.
	*/
	public var relativePath: String {
		String(description.dropFirst())
	}

	/**
	The rest of the path after another path that it starts with (``starts(with:)``), like `post/image.png` for `/blog/post/image.png` after `/blog`, and empty for the same path. `nil` when it does not start with the other path.
	*/
	func relative(to other: Self) -> String? {
		guard starts(with: other) else {
			return nil
		}

		return String(description.dropFirst(other.description.count).trimmingPrefix("/"))
	}

	/**
	The whole URL of the path on the site, like `https://sindresorhus.com/apps`.
	*/
	public func absoluteURL(site: SiteOrigin) -> URL {
		self == .root ? site.url.appending(path: "/") : site.url.appending(path: description)
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
