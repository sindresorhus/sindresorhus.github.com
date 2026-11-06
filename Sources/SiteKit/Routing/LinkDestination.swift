import Foundation

/**
Where a link goes: an absolute URL, like `https://example.com`, a page of the site, like `/apps/faq`, or a fragment of the same page, like `#faq`.

Decoding throws for anything else, like a relative path, which would resolve differently on each page. It also throws for a link that only works on this Mac, like the preview (`http://localhost:4321`, or `http://Sindres-MacBook-Pro.local:4321` on the local network) or a `file:` link, for a `javascript:` link, and for a link to a pane of System Settings that it does not know (``SystemSettingsPane``).

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
			let scheme = url.scheme,
			!scheme.isEmpty
		else {
			throw ContentError(reason: "Must be an absolute URL, a path that starts with “/”, or a fragment that starts with “#”, got “\(string)”.")
		}

		// The preview runs on this Mac, so a link that is copied from the browser while writing is broken for every visitor.
		// `website serve --local-network` prints the Bonjour name of this Mac, like `http://Sindres-MacBook-Pro.local:4321`, which only resolves on the local network. Only for web links, as another scheme can name a device of the reader, like `smb://nas.local/Media`.
		let host = url.host()?.lowercased()
		let isLocalNetworkPreview = ["http", "https"].contains(scheme.lowercased()) && host?.hasSuffix(".local") == true

		if ["localhost", "127.0.0.1"].contains(host) || isLocalNetworkPreview {
			throw ContentError(reason: "The link “\(string)” goes to the preview on this Mac. Use the site path, like `/dato`.")
		}

		switch scheme.lowercased() {
		case "file":
			throw ContentError(reason: "The link “\(string)” goes to a file on this Mac. Publish the file next to the page, and link to it, like `[guide](guide.pdf)`.")
		case "javascript":
			throw ContentError(reason: "The link “\(string)” runs a script. Link to a page instead.")
		case SystemSettingsPane.scheme:
			// The pane ends at the anchor, like `?Privacy_Accessibility`, which is not checked.
			let pane = String(string.dropFirst(scheme.count + 1).prefix { $0 != "?" })

			guard SystemSettingsPane(rawValue: pane) != nil else {
				let suggestion = pane.closest(in: SystemSettingsPane.allCases.map(\.rawValue)).map { " Did you mean `\($0)`?" } ?? " Add it to `LinkDestination.SystemSettingsPane` when System Settings has it."
				throw ContentError(reason: "The link “\(string)” goes to `\(pane)`, which is not a known pane of System Settings.\(suggestion)")
			}
		default:
			break
		}

		self = .url(url)
	}

	/**
	A pane of System Settings that a link opens, like `x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Shortcuts`. The raw value is the ID of the pane: the bundle ID of its extension in `/System/Library/ExtensionKit/Extensions`. The cases are the panes that the content links to, checked against macOS 27.2, so a typo in an ID is a content error. Add a case when the content needs another pane. The part after `?`, like `?Privacy_Accessibility`, is not checked.

	The list is in the code, not read from the system of the build, as the build can run on another macOS version, like on GitHub Actions.
	*/
	enum SystemSettingsPane: String, CaseIterable {
		case accessibility = "com.apple.Accessibility-Settings.extension"
		case airDropHandoff = "com.apple.AirDrop-Handoff-Settings.extension"
		case appleAccount = "com.apple.systempreferences.AppleIDSettings"
		case battery = "com.apple.Battery-Settings.extension"
		case controlCenter = "com.apple.ControlCenter-Settings.extension"
		case dateTime = "com.apple.Date-Time-Settings.extension"
		case desktopDock = "com.apple.Desktop-Settings.extension"
		case focus = "com.apple.Focus-Settings.extension"
		case keyboard = "com.apple.Keyboard-Settings.extension"
		case languageRegion = "com.apple.Localization-Settings.extension"
		case lockScreen = "com.apple.Lock-Screen-Settings.extension"
		case loginItems = "com.apple.LoginItems-Settings.extension"
		case privacySecurity = "com.apple.settings.PrivacySecurity.extension"
		case sound = "com.apple.Sound-Settings.extension"
		case wallpaper = "com.apple.Wallpaper-Settings.extension"

		/**
		The scheme of the links to System Settings.
		*/
		static let scheme = "x-apple.systempreferences"
	}

	/**
	The link for an `href` attribute.
	*/
	public var description: String {
		switch self {
		case .url(let url):
			url.description
		case .path(let path, let query, let fragment):
			path.percentEncodedPath + Self.queryString(query) + Self.fragmentString(fragment)
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
