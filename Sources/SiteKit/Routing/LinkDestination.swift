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
	case url(URL)

	/**
	A page of the site, with an optional query and fragment, like `/feedback?product=Dato` or `/apps/faq#refund`. The fragment is written as it is, like an ID.

	Limitation: A `+` in a query from content is a literal plus, not a space.
	*/
	case path(RoutePath, query: [URLQueryItem] = [], fragment: String? = nil)

	/**
	A section of the same page, like `faq` for `#faq`.
	*/
	case fragment(String)

	public init(validating string: String) throws(ContentError) {
		if string.hasPrefix("#") {
			self = .fragment(String(string.dropFirst()))
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

			self = .path(RoutePath(String(path)), query: components.queryItems ?? [], fragment: components.percentEncodedFragment)
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
			url.absoluteString
		case .path(let path, let query, let fragment):
			path.description + Self.queryString(query) + (fragment.map { "#\($0)" } ?? "")
		case .fragment(let fragment):
			"#\(fragment)"
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
	The whole URL, like for a feed. A fragment of the same page has none, as it depends on the page.
	*/
	public func absoluteURL(site: URL) -> URL {
		switch self {
		case .url(let url):
			url
		case .path(let path, _, _):
			URL(string: description, relativeTo: site)?.absoluteURL ?? path.absoluteURL(site: site)
		case .fragment:
			preconditionFailure("A fragment of the same page has no absolute URL.")
		}
	}

	/**
	The query, like `?product=Dato`, or an empty string without query items.
	*/
	private static func queryString(_ queryItems: [URLQueryItem]) -> String {
		guard !queryItems.isEmpty else {
			return ""
		}

		var components = URLComponents()
		components.queryItems = queryItems

		// Forms read `+` in a query as a space, and `URLComponents` leaves it as is.
		return "?" + (components.percentEncodedQuery ?? "").replacing("+", with: "%2B")
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
