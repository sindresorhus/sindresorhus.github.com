import Foundation

/**
Where a link goes: an absolute URL, like `https://example.com`, a page of the site, like `/apps/faq`, or a fragment of the same page, like `#faq`.

Decoding throws for anything else, like a relative path, which would resolve differently on each page.

```swift
a(.href(.path(.feedback, query: [URLQueryItem(name: "product", value: "Dato")]))) {
	"Send feedback"
}
```
*/
public enum LinkDestination: ValidatedValue, Hashable, Sendable, CustomStringConvertible {
	case url(AbsoluteURL)

	/**
	An absolute URL supplied by the code. A relative URL is a programming error; decoded content uses the throwing initializer.
	*/
	public static func url(_ url: URL) -> Self {
		.url(AbsoluteURL(url))
	}

	/**
	A page of the site, with an optional query and fragment, like `/feedback?product=Dato` or `/apps/faq#refund`. The fragment is decoded text, like an HTML element ID, and is percent-encoded when the link is written.

	Limitation: A `+` in a query from content is a literal plus, not a space.
	*/
	case path(RoutePath, query: [URLQueryItem] = [], fragment: String? = nil)

	/**
	A section of the same page, as decoded text, like `faq` for `#faq`.
	*/
	case fragment(String)

	public init(validating string: String) throws(ContentError) {
		if string.hasPrefix("#") {
			guard let components = URLComponents(string: string) else {
				throw ContentError(reason: "Must have a valid fragment, got “\(string)”.")
			}

			self = .fragment(components.fragment ?? "")
			return
		}

		if
			string.hasPrefix("/"),
			!string.hasPrefix("//")
		{
			// The route path ends at the query or the fragment.
			let path = string.prefix { $0 != "?" && $0 != "#" }

			guard let components = URLComponents(string: String(string.dropFirst(path.count))) else {
				throw ContentError(reason: "Must have a valid query and fragment, got “\(string)”.")
			}

			self = .path(try RoutePath(validating: String(path)), query: components.queryItems ?? [], fragment: components.fragment)
			return
		}

		guard
			let url = URL(string: string),
			url.scheme?.isEmpty == false
		else {
			throw ContentError(reason: "Must be an absolute URL, a path that starts with “/”, or a fragment that starts with “#”, got “\(string)”.")
		}

		self = .url(url)
	}

	/**
	The link for an `href` attribute.
	*/
	public var description: String {
		switch self {
		case .url(let url):
			url.description
		case .path(let path, let query, let fragment):
			path.description + Self.queryString(query) + Self.fragmentString(fragment)
		case .fragment(let fragment):
			Self.fragmentString(fragment)
		}
	}

	/**
	Whether the link goes to a section of the same page.
	*/
	public var isFragment: Bool {
		if case .fragment = self {
			return true
		}

		return false
	}

	/**
	The whole URL, like for a feed. A fragment resolves against the current page; a site path resolves against the site regardless of the current page.

	- Parameter page: The current page, so a fragment like `#faq` points to its section.
	*/
	public func absoluteURL(site: SiteOrigin, page: RoutePath) -> URL {
		switch self {
		case .url(let url):
			return url.value
		case .path(let path, _, _):
			return URL(string: description, relativeTo: site.url)?.absoluteURL ?? path.absoluteURL(site: site)
		case .fragment:
			let pageURL = page.absoluteURL(site: site)
			return URL(string: description, relativeTo: pageURL)?.absoluteURL ?? pageURL
		}
	}

	/**
	The percent-encoded fragment including `#`, or no fragment when absent. An empty fragment keeps its `#`.
	*/
	private static func fragmentString(_ fragment: String?) -> String {
		var components = URLComponents()
		components.fragment = fragment
		return components.percentEncodedFragment.map { "#\($0)" } ?? ""
	}

	/**
	The query, like `?product=Dato`, or an empty string without query items.
	*/
	private static func queryString(_ queryItems: [URLQueryItem]) -> String {
		guard !queryItems.isEmpty else {
			return ""
		}

		// Forms read `+` in a query as a space, and `URLComponents` leaves it as is.
		return "?" + queryItems.formEncodedQuery
	}
}

extension LinkDestination: Encodable {
	/**
	Encodes the link as it is written in an `href` attribute, like `/apps/faq#refund`, for data that scripts read.
	*/
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(description)
	}
}
