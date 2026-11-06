import Foundation
import Synchronization

/**
Finds problems with the internal links in the published HTML: links to missing files, links to the `.html` file of a page, like `/dato.html` for `/dato`, links to missing fragment IDs, IDs that are used twice on a page, which makes fragment links ambiguous, and references to IDs that are not on the page, like `aria-labelledby` of a dialog.

It checks `href` and `src` attributes, the `og:image` and `og:url` meta tags, and the attributes that refer to elements by ID, like `aria-labelledby`, `for`, and `popovertarget`, in the published pages and redirects of the routes. The text of code blocks (`<pre>`) is not checked, as it is code, not markup. Public files are copied as they are, so their links are not checked.
*/
public struct LinkValidator: Sendable {
	public struct BrokenLink: Hashable, Sendable, CustomStringConvertible {
		public enum Problem: Hashable, Sendable {
			/**
			The link goes to no published file, or to the `.html` file of a page, like `/dato.html`, where the suggestion is the path of the page.
			*/
			case missingFile(String, suggestion: String? = nil)
			case missingFragment(String, suggestion: String? = nil)

			/**
			The page has more than one element with the ID. The link is the ID as a fragment, like `#faq`.
			*/
			case duplicateID(String)

			/**
			An attribute that refers to an element by ID, like `aria-labelledby`, refers to an ID that is not on the page. The link is the attribute, like `aria-labelledby="title"`.
			*/
			case missingReference(attribute: IDReferenceAttribute, id: String)
		}

		/**
		The page that contains the link.
		*/
		public let page: RoutePath
		/**
		The diagnostic text of the destination or ID reference.
		*/
		public var link: String {
			switch problem {
			case .missingFile(let link, _), .missingFragment(let link, _):
				link
			case .duplicateID(let id):
				"#\(id)"
			case .missingReference(let attribute, let id):
				"\(attribute.rawValue)=\"\(id)\""
			}
		}

		/**
		The authored destination, if the problem concerns a navigation or resource link.
		*/
		public var destination: String? {
			switch problem {
			case .missingFile(let link, _), .missingFragment(let link, _):
				link
			case .duplicateID, .missingReference:
				nil
			}
		}
		public let problem: Problem

		/**
		The closest published path to a missing file, like `/gifski` for `/apps/gifski`, or `/dato` for `/dato/`, or the closest ID of the page to a missing fragment, like `#refund` for `/apps/faq#refnd`, so the writer sees why the link is broken.
		*/
		public var suggestion: String? {
			switch problem {
			case .missingFile(_, let suggestion), .missingFragment(_, let suggestion):
				suggestion
			case .duplicateID, .missingReference:
				nil
			}
		}

		/**
		The page, the link, and the problem, like `/about: /apps#missing (missing fragment)`.
		*/
		public var description: String {
			"\(SourceLocation.page(page)): \(message)"
		}

		/**
		The link and the problem, like `/apps#missing (missing fragment)` or `/apps/faq#refnd (missing fragment, did you mean #refund?)`, without where the link is.
		*/
		public var message: String {
			let note = switch problem {
			case .missingFile:
				suggestion.map { " (did you mean \($0)?)" } ?? ""
			case .missingFragment:
				" (missing fragment\(suggestion.map { ", did you mean \($0)?" } ?? ""))"
			case .duplicateID:
				" (duplicate ID)"
			case .missingReference:
				" (missing ID)"
			}

			return "\(link)\(note)"
		}
	}

	public let site: SiteOrigin

	public init(site: SiteOrigin) {
		self.site = site
	}

	/**
	The problems in the published routes, sorted by page and link. The pages are checked in parallel.

	- Parameter published: What ``Publisher/publish(_:)`` published. Links resolve against its files, like GitHub Pages resolves them, and with the same case, as the web server does not ignore case like the disk may.
	- Parameter additionalLinks: More links of pages, by the path of the page, which are checked like the navigation links in its HTML, like the links of content that the page does not show today. A link that the HTML has too is reported once.
	*/
	public func brokenLinks(in routes: [Route], published: PublishedSite, additionalLinks: [RoutePath: [String]] = [:]) async -> [BrokenLink] {
		let files = published.files
		let previousPages = Self.previousPages.withLock { $0 }

		// The IDs of every page, to check fragments in links to other pages. A page that did not change since the previous check of the process, like in a rebuild of `website serve`, which changes a few pages, is not read again.
		let pages = await routes.filter { $0.outputFile.description.hasSuffix(".html") }.concurrentMap { route -> LinkedPage? in
			guard let html = published.routeFiles[route.outputFile] else {
				return nil
			}

			return previousPages[html].map { LinkedPage(route: route, reading: $0) } ?? LinkedPage(route: route, html: html)
		}.compactMap { $0 }

		Self.previousPages.withLock { previousPages in
			previousPages = pages.keyed(by: \.html)
		}

		let idsByFile = Dictionary(uniqueKeysWithValues: pages.map { ($0.route.outputFile, Set($0.ids)) })
		let pagePathsByFile = Dictionary(uniqueKeysWithValues: routes.compactMap { route -> (PublishedFilePath, RoutePath)? in
			switch route.output {
			case .page, .redirect:
				(route.outputFile, route.path)
			case .file:
				nil
			}
		})
		// Sorted, so a suggestion is the same on each build, as the files are a set.
		let sitePaths = files.map(\.sitePath).sorted()
		let brokenLinks = await pages.concurrentMap { page in
			brokenLinks(
				on: page,
				additionalLinks: additionalLinks[page.route.path] ?? [],
				idsByFile: idsByFile,
				pagePathsByFile: pagePathsByFile,
				files: files,
				sitePaths: sitePaths
			)
		}.flatMap { $0 }

		return Set(brokenLinks).sorted(using: [KeyPathComparator(\.page.description, comparator: String.StandardComparator.lexical), KeyPathComparator(\.link, comparator: String.StandardComparator.lexical)])
	}

	/**
	The pages of the previous check of the process, by their HTML, so a rebuild of `website serve` only reads the pages that changed. Only the pages of the previous check are kept, so the memory does not grow with each rebuild.
	*/
	private static let previousPages = Mutex<[Data: LinkedPage]>([:])

	private func brokenLinks(
		on page: LinkedPage,
		additionalLinks: [String],
		idsByFile: [PublishedFilePath: Set<String>],
		pagePathsByFile: [PublishedFilePath: RoutePath],
		files: Set<PublishedFilePath>,
		sitePaths: [String]
	) -> [BrokenLink] {
		let path = page.route.path
		let base = path.absoluteURL(site: site)
		var brokenLinks = [BrokenLink]()
		var seenIDs = Set<String>()

		for id in page.ids where !seenIDs.insert(id).inserted {
			brokenLinks.append(BrokenLink(page: path, problem: .duplicateID(id)))
		}

		for reference in page.references {
			for id in reference.attribute.ids(in: reference.ids) where !seenIDs.contains(id) {
				brokenLinks.append(BrokenLink(page: path, problem: .missingReference(attribute: reference.attribute, id: id)))
			}
		}

		// Not part of the page that was read, as that is kept by its HTML for the next check.
		let links = page.links + additionalLinks.map { (link: $0, kind: LinkedPage.LinkKind.navigation) }

		for (link, kind) in links {
			guard
				!link.hasPrefix("//"),
				let resolved = URL(string: link, relativeTo: base)?.absoluteURL,
				resolved.host == site.url.host,
				resolved.scheme?.hasPrefix("http") == true
			else {
				continue
			}

			guard let target = resolved.path(percentEncoded: true).servedFileCandidates.first(where: files.contains) else {
				let suggestion = resolved.path().closestSitePath(in: sitePaths)
				brokenLinks.append(BrokenLink(page: path, problem: .missingFile(link, suggestion: suggestion)))
				continue
			}

			// A page is at its path without `.html`, like `/dato` for `dato.html`. The host also serves the name of the file, but that is a second URL of the page, which is not its canonical URL and has no link preview. An HTML file route or public HTML file is at the name of its file.
			if
				kind == .navigation,
				let pagePath = pagePathsByFile[target],
				resolved.path(percentEncoded: false) == "/\(target.description)"
			{
				brokenLinks.append(BrokenLink(page: path, problem: .missingFile(link, suggestion: pagePath.description)))
				continue
			}

			guard
				kind == .navigation,
				let fragment = resolved.fragment?.removingPercentEncoding,
				!fragment.isEmpty,
				// The browser scrolls to the top for `#top` when no element has that ID.
				fragment.lowercased() != "top",
				target.description.hasSuffix(".html")
			else {
				continue
			}

			// Public HTML files are not checked, so their IDs are not known.
			if
				let targetIDs = idsByFile[target],
				!targetIDs.contains(fragment)
			{
				// Sorted, so the suggestion is the same on each build, as the IDs are a set.
				let suggestion = fragment.closest(in: targetIDs.sorted()).map { "#\($0)" }
				brokenLinks.append(BrokenLink(page: path, problem: .missingFragment(link, suggestion: suggestion)))
			}
		}

		return brokenLinks
	}
}

/**
What the check reads from the HTML of a page, with the escapes of the values decoded.
*/
private struct LinkedPage: Sendable {
	let route: Route

	/**
	The published file of the page.
	*/
	let html: Data

	/**
	The IDs, in the order of the page, as written, as an ID is literal text. Only the fragment of a link is percent-decoded.
	*/
	var ids = [String]()

	/**
	The `href` and `src` attributes, and the `content` of the `og:image` and `og:url` meta tags. A source, like of an image, has no fragment to check.
	*/
	var links = [(link: String, kind: LinkKind)]()

	/**
	Whether a link navigates to a document or loads a resource whose fragment is not checked.
	*/
	enum LinkKind: Sendable {
		case navigation
		case resource
	}

	/**
	The attributes that refer to other elements of the page by ID, like `aria-labelledby`, and their IDs. Some take a list of IDs, separated by spaces.
	*/
	var references = [(attribute: IDReferenceAttribute, ids: String)]()

	/**
	Any attribute, like `href="/apps"`. One search for every attribute is faster than a search for each kind. The whitespace is outside the name, so the regex engine checks it once at each position.

	Limitation: Text in HTML has its quotes unescaped, so a `="` in text without a closing quote, like inline code of `x="`, hides the attributes up to the next quote from the check.
	*/
	nonisolated(unsafe) private static let attribute = /\s([a-z-]+)="([^"]*)"/

	/**
	A meta start tag, keeping a `>` inside a quoted attribute value within the tag.
	*/
	nonisolated(unsafe) private static let metaTag = /<(?i:meta)(?=[\s\/>])(?:[^>"']|"[^"]*"|'[^']*')*>/

	/**
	The start tag of a `<pre>` and its text. Text in HTML has its `<` escaped, but not its quotes, so the text of an HTML code sample, like `&lt;a href="/x"&gt;`, would look like an attribute.
	*/
	nonisolated(unsafe) private static let preformattedText = /(?s)(<pre(?:\s[^>]*)?>).*?<\/pre>/

	/**
	A page with the same HTML as another page, which has the same IDs and links, like the same page in the previous build.
	*/
	init(route: Route, reading page: Self) {
		self.route = route
		self.html = page.html
		self.ids = page.ids
		self.links = page.links
		self.references = page.references
	}

	init(route: Route, html: Data) {
		self.route = route
		self.html = html

		// Without the text of the code blocks, which can look like HTML. The start tag stays, as it can have an ID.
		let html = String(decoding: html, as: UTF8.self).replacing(Self.preformattedText) { $0.1 + "</pre>" }

		for match in html.matches(of: Self.attribute) {
			let name = match.1
			let value = match.2

			guard !value.isEmpty else {
				continue
			}

			switch name {
			case "id":
				ids.append(String(value).decodingHTMLEscapes)
			case "href", "src":
				links.append((String(value).decodingHTMLEscapes, kind: name == "src" ? .resource : .navigation))
			default:
				if let attribute = IDReferenceAttribute(rawValue: String(name)) {
					references.append((attribute, String(value).decodingHTMLEscapes))
				}
			}
		}

		// Like `<meta property="og:image" content="…">`, with the attributes in either order.
		for tag in html.matches(of: Self.metaTag) {
			let attributes = tag.0.matches(of: Self.attribute)

			guard
				let property = attributes.first(where: { $0.1 == "property" })?.2,
				property == "og:image" || property == "og:url",
				let content = attributes.first(where: { $0.1 == "content" })?.2,
				!content.isEmpty
			else {
				continue
			}

			links.append((String(content).decodingHTMLEscapes, kind: .navigation))
		}
	}
}

extension PublishedFilePath {
	/**
	The path of the file on the site, like `/dato` for `dato.html`, `/apps` for `apps/index.html`, and `/dato/icon.png` for `dato/icon.png`, the reverse of ``Swift/String/servedFileCandidates``.
	*/
	fileprivate var sitePath: String {
		var path = description

		if path.hasSuffix(".html") {
			path = String(path.dropLast(".html".count))
		}

		if path == "index" {
			return "/"
		}

		if path.hasSuffix("/index") {
			path = String(path.dropLast("/index".count))
		}

		return "/\(path)"
	}
}

extension String {
	/**
	The site path that the path most likely meant, like `/gifski` for `/apps/gifski`, `/dato` for `/dato/`, or `/apps/faq` for `/apps/FAQ`: the one path with the same last component, like the page of an app, which is not at `/apps/<slug>`, or else the closest path (``closest(in:)``), like for a file name that many directories have (`icon.png`), or else the first path with the same last component.
	*/
	fileprivate func closestSitePath(in paths: [String]) -> String? {
		guard let lastComponent = split(separator: "/").last else {
			return closest(in: paths)
		}

		let sameLastComponent = paths.filter { $0.split(separator: "/").last == lastComponent }

		guard sameLastComponent.count != 1 else {
			return sameLastComponent.first
		}

		return closest(in: paths) ?? sameLastComponent.first
	}
}
