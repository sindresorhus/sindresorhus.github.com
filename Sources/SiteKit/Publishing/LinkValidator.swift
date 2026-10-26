import Foundation

/**
Finds problems with the internal links in the published HTML: links to missing files, links to missing fragment IDs, IDs that are used twice on a page, which makes fragment links ambiguous, and references to IDs that are not on the page, like `aria-labelledby` of a dialog.

It checks `href` and `src` attributes, the `og:image` and `og:url` meta tags, and the attributes that refer to elements by ID, like `aria-labelledby`, `for`, and `popovertarget`, in the pages and redirects of the routes. The text of code blocks (`<pre>`) is not checked, as it is code, not markup. Public files are copied as they are, so their links are not checked.
*/
public struct LinkValidator: Sendable {
	public struct BrokenLink: Hashable, Sendable, CustomStringConvertible {
		public enum Problem: Hashable, Sendable {
			case missingFile
			case missingFragment

			/**
			The page has more than one element with the ID. The link is the ID as a fragment, like `#faq`.
			*/
			case duplicateID

			/**
			An attribute that refers to an element by ID, like `aria-labelledby`, refers to an ID that is not on the page. The link is the attribute, like `aria-labelledby="title"`.
			*/
			case missingReference
		}

		/**
		The page that contains the link.
		*/
		public let page: RoutePath
		public let link: String
		public let problem: Problem

		/**
		The page, the link, and the problem, like `/about: /apps#missing (missing fragment)`.
		*/
		public var description: String {
			description(at: page.description)
		}

		/**
		The link and the problem after where the link is, like `content/about.md:12: /apps#missing (missing fragment)`.
		*/
		public func description(at location: String) -> String {
			let note = switch problem {
			case .missingFile:
				""
			case .missingFragment:
				" (missing fragment)"
			case .duplicateID:
				" (duplicate ID)"
			case .missingReference:
				" (missing ID)"
			}

			return "\(location): \(link)\(note)"
		}
	}

	public let site: URL
	public let output: URL

	public init(site: URL, output: URL) {
		self.site = site
		self.output = output
	}

	/**
	The problems in the published routes, sorted by page and link. The pages are checked in parallel.

	- Parameter files: Every published file, relative to the output directory, as ``Publisher/publish(_:)`` returns them. Links resolve against these, like GitHub Pages resolves them, and with the same case, as the web server does not ignore case like the disk may.
	*/
	public func brokenLinks(in routes: [Route], files: Set<String>) async throws -> [BrokenLink] {
		// The IDs of every page, to check fragments in links to other pages.
		let pages = try await withThrowingTaskGroup { group in
			for route in routes where route.outputFile.hasSuffix(".html") {
				group.addTask {
					try LinkedPage(route: route, html: String(contentsOf: output.appending(path: route.outputFile), encoding: .utf8))
				}
			}

			return try await group.reduce(into: []) { $0.append($1) }
		}

		let idsByFile = Dictionary(uniqueKeysWithValues: pages.map { ($0.route.outputFile, Set($0.ids)) })

		let brokenLinks = await withTaskGroup { group in
			for page in pages {
				group.addTask {
					brokenLinks(on: page, idsByFile: idsByFile, files: files)
				}
			}

			return await group.reduce(into: [BrokenLink]()) { $0 += $1 }
		}

		return Set(brokenLinks).sorted(using: [KeyPathComparator(\.page.description, comparator: String.StandardComparator.lexical), KeyPathComparator(\.link, comparator: String.StandardComparator.lexical)])
	}

	private func brokenLinks(on page: LinkedPage, idsByFile: [String: Set<String>], files: Set<String>) -> [BrokenLink] {
		let path = page.route.path
		let base = path.absoluteURL(site: site)
		var brokenLinks = [BrokenLink]()
		var seenIDs = Set<String>()

		for id in page.ids where !seenIDs.insert(id).inserted {
			brokenLinks.append(BrokenLink(page: path, link: "#\(id)", problem: .duplicateID))
		}

		for reference in page.references {
			for id in reference.ids.split(whereSeparator: \.isWhitespace) where !seenIDs.contains(String(id)) {
				brokenLinks.append(BrokenLink(page: path, link: "\(reference.attribute)=\"\(id)\"", problem: .missingReference))
			}
		}

		for (link, isSource) in page.links {
			guard
				!link.hasPrefix("//"),
				let resolved = URL(string: link, relativeTo: base)?.absoluteURL,
				resolved.host == site.host,
				resolved.scheme?.hasPrefix("http") == true
			else {
				continue
			}

			guard let target = resolved.path(percentEncoded: true).servedFileCandidates.first(where: files.contains) else {
				brokenLinks.append(BrokenLink(page: path, link: link, problem: .missingFile))
				continue
			}

			guard
				!isSource,
				let fragment = resolved.fragment?.removingPercentEncoding,
				!fragment.isEmpty,
				// The browser scrolls to the top for `#top` when no element has that ID.
				fragment.lowercased() != "top",
				target.hasSuffix(".html")
			else {
				continue
			}

			// Public HTML files are not checked, so their IDs are not known.
			if
				let targetIDs = idsByFile[target],
				!targetIDs.contains(fragment)
			{
				brokenLinks.append(BrokenLink(page: path, link: link, problem: .missingFragment))
			}
		}

		return brokenLinks
	}
}

/**
What the check reads from the HTML of a page, with the escapes of the values decoded.
*/
private struct LinkedPage {
	let route: Route

	/**
	The IDs, in the order of the page, as written, as an ID is literal text. Only the fragment of a link is percent-decoded.
	*/
	var ids = [String]()

	/**
	The `href` and `src` attributes, and the `content` of the `og:image` and `og:url` meta tags. A source, like of an image, has no fragment to check.
	*/
	var links = [(link: String, isSource: Bool)]()

	/**
	The attributes that refer to other elements of the page by ID, like `aria-labelledby`, and their IDs. Some take a list of IDs, separated by spaces.
	*/
	var references = [(attribute: String, ids: String)]()

	private static let referenceAttributes: Set<Substring> = ["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "for", "list", "popovertarget", "commandfor"]

	/**
	Any attribute, like `href="/apps"`. One search for every attribute is faster than a search for each kind. The whitespace is outside the name, so the regex engine checks it once at each position.

	Limitation: Text in HTML has its quotes unescaped, so a `="` in text without a closing quote, like inline code of `x="`, hides the attributes up to the next quote from the check.
	*/
	nonisolated(unsafe) private static let attribute = /\s([a-z-]+)="([^"]*)"/

	/**
	The start tag of a `<pre>` and its text. Text in HTML has its `<` escaped, but not its quotes, so the text of an HTML code sample, like `&lt;a href="/x"&gt;`, would look like an attribute.
	*/
	nonisolated(unsafe) private static let preformattedText = /(?s)(<pre(?:\s[^>]*)?>).*?<\/pre>/

	init(route: Route, html: String) {
		self.route = route

		// Without the text of the code blocks, which can look like HTML. The start tag stays, as it can have an ID.
		let html = html.replacing(Self.preformattedText) { $0.1 + "</pre>" }
		var followsOpenGraphProperty = false

		for match in html.matches(of: Self.attribute) {
			let name = match.1
			let value = match.2

			defer {
				// Like `<meta property="og:image" content="…">`.
				followsOpenGraphProperty = name == "property" && (value == "og:image" || value == "og:url")
			}

			guard !value.isEmpty else {
				continue
			}

			switch name {
			case "id":
				ids.append(String(value).decodingHTMLEscapes)
			case "href", "src":
				links.append((String(value).decodingHTMLEscapes, isSource: name == "src"))
			case "content" where followsOpenGraphProperty:
				links.append((String(value).decodingHTMLEscapes, isSource: false))
			case _ where Self.referenceAttributes.contains(name):
				references.append((String(name), String(value).decodingHTMLEscapes))
			default:
				break
			}
		}
	}
}

extension String {
	/**
	The text of an HTML attribute value, with the escapes that HTML writes decoded, like `&amp;` to `&`. `&amp;` is last, so `&amp;lt;` is `&lt;`, not `<`.
	*/
	fileprivate var decodingHTMLEscapes: String {
		guard contains("&") else {
			return self
		}

		return replacing("&lt;", with: "<")
			.replacing("&gt;", with: ">")
			.replacing("&quot;", with: "\"")
			.replacing("&#39;", with: "'")
			.replacing("&amp;", with: "&")
	}
}
