import Foundation

/**
Finds problems with the internal links in the published HTML: links to missing files, links to missing fragment IDs, IDs that are used twice on a page, which makes fragment links ambiguous, and references to IDs that are not on the page, like `aria-labelledby` of a dialog.

It checks `href` and `src` attributes, the `og:image` and `og:url` meta tags, and the attributes that refer to elements by ID (``idReferenceAttributes``), in the pages and redirects of the routes. Public files are copied as they are, so their links are not checked.
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

	nonisolated(unsafe) private static let id = /\sid="([^"]+)"/
	nonisolated(unsafe) private static let link = /\s(href|src)="([^"]+)"|\sproperty="og:(?:image|url)" content="([^"]+)"/

	/**
	The attributes that refer to other elements of the page by ID. Some take a list of IDs, separated by spaces.
	*/
	public static let idReferenceAttributes = ["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "for", "list", "popovertarget", "commandfor"]

	nonisolated(unsafe) private static let idReference = try! Regex<(Substring, Substring, Substring)>(#"\s(\#(idReferenceAttributes.joined(separator: "|")))="([^"]*)""#)

	public init(site: URL, output: URL) {
		self.site = site
		self.output = output
	}

	/**
	The problems in the published routes, sorted by page and link. The pages are checked in parallel.

	- Parameter files: Every published file, relative to the output directory, as ``Publisher/publish(_:)`` returns them. Links resolve against these, like GitHub Pages resolves them, and with the same case, as the web server does not ignore case like the disk may.
	*/
	public func brokenLinks(in routes: [Route], files: Set<String>) async throws -> [BrokenLink] {
		let pages = routes.filter { $0.outputFile.hasSuffix(".html") }

		// The HTML and the IDs of every page, to check fragments in links to other pages.
		let pagesWithIDs = try await withThrowingTaskGroup { group in
			for page in pages {
				group.addTask {
					let html = try String(contentsOf: output.appending(path: page.outputFile), encoding: .utf8)
					// As written, as an ID is literal text. Only the fragment of a link is percent-decoded.
					let ids = html.matches(of: Self.id).map { String($0.1).decodingHTMLEscapes }
					return (page: page, html: html, ids: ids)
				}
			}

			return try await group.reduce(into: []) { $0.append($1) }
		}

		let idsByFile = Dictionary(uniqueKeysWithValues: pagesWithIDs.map { ($0.page.outputFile, Set($0.ids)) })

		let brokenLinks = await withTaskGroup { group in
			for page in pagesWithIDs {
				group.addTask {
					brokenLinks(on: page.page.path, html: page.html, ids: page.ids, idsByFile: idsByFile, files: files)
				}
			}

			return await group.reduce(into: [BrokenLink]()) { $0 += $1 }
		}

		return Set(brokenLinks).sorted(using: [KeyPathComparator(\.page.description, comparator: String.StandardComparator.lexical), KeyPathComparator(\.link, comparator: String.StandardComparator.lexical)])
	}

	private func brokenLinks(on page: RoutePath, html: String, ids: [String], idsByFile: [String: Set<String>], files: Set<String>) -> [BrokenLink] {
		let base = page.absoluteURL(site: site)
		var brokenLinks = [BrokenLink]()
		var seenIDs = Set<String>()

		for id in ids where !seenIDs.insert(id).inserted {
			brokenLinks.append(BrokenLink(page: page, link: "#\(id)", problem: .duplicateID))
		}

		for match in html.matches(of: Self.idReference) {
			for id in String(match.2).decodingHTMLEscapes.split(whereSeparator: \.isWhitespace) where !seenIDs.contains(String(id)) {
				brokenLinks.append(BrokenLink(page: page, link: "\(match.1)=\"\(id)\"", problem: .missingReference))
			}
		}

		for match in html.matches(of: Self.link) {
			guard let link = (match.2 ?? match.3).map({ String($0).decodingHTMLEscapes }) else {
				continue
			}

			guard
				!link.hasPrefix("//"),
				let resolved = URL(string: link, relativeTo: base)?.absoluteURL,
				resolved.host == site.host,
				resolved.scheme?.hasPrefix("http") == true
			else {
				continue
			}

			guard let target = resolved.path(percentEncoded: true).servedFileCandidates.first(where: files.contains) else {
				brokenLinks.append(BrokenLink(page: page, link: link, problem: .missingFile))
				continue
			}

			guard
				match.1 != "src",
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
				brokenLinks.append(BrokenLink(page: page, link: link, problem: .missingFragment))
			}
		}

		return brokenLinks
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
