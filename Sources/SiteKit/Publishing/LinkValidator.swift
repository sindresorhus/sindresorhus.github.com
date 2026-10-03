import Foundation

/**
Finds problems with the internal links in the published HTML: links to missing files, links to missing fragment IDs, and IDs that are used twice on a page, which makes fragment links ambiguous.

It checks `href` and `src` attributes, and the `og:image` and `og:url` meta tags.
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
		}

		/**
		The page that contains the link.
		*/
		public let page: String
		public let link: String
		public let problem: Problem

		public var description: String {
			let note = switch problem {
			case .missingFile:
				""
			case .missingFragment:
				" (missing fragment)"
			case .duplicateID:
				" (duplicate ID)"
			}

			return "\(page): \(link)\(note)"
		}
	}

	public let site: URL
	public let output: URL

	nonisolated(unsafe) private static let id = /\sid="([^"]+)"/
	nonisolated(unsafe) private static let link = /\s(href|src)="([^"]+)"|\sproperty="og:(?:image|url)" content="([^"]+)"/

	public init(site: URL, output: URL) {
		self.site = site
		self.output = output.resolvingSymlinksInPath()
	}

	/**
	The problems, sorted by page and link. The pages are checked in parallel.
	*/
	public func brokenLinks() async throws -> [BrokenLink] {
		let pages = try htmlFiles()

		// The IDs of every page, to check fragments in links to other pages.
		let ids = try await withThrowingTaskGroup(of: (String, [String]).self) { group in
			for page in pages {
				group.addTask {
					let html = try String(contentsOf: page, encoding: .utf8)
					return (page.path(relativeTo: output), html.matches(of: Self.id).map { String($0.1).removingPercentEncoding ?? String($0.1) })
				}
			}

			return try await group.reduce(into: [String: [String]]()) { $0[$1.0] = $1.1 }
		}

		let idsByFile = ids.mapValues(Set.init)

		// The exact paths of all files. The disk may ignore case, but the web server does not, so `/Apps` must not pass for `/apps`.
		let files = Set(try output.filesRecursively().map(pathAsWritten))

		let brokenLinks = try await withThrowingTaskGroup(of: [BrokenLink].self) { group in
			for page in pages {
				group.addTask {
					try brokenLinks(on: page, ids: ids[page.path(relativeTo: output)] ?? [], idsByFile: idsByFile, files: files)
				}
			}

			return try await group.reduce(into: [BrokenLink]()) { $0 += $1 }
		}

		return Set(brokenLinks).sorted(using: [KeyPathComparator(\.page, comparator: String.StandardComparator.lexical), KeyPathComparator(\.link, comparator: String.StandardComparator.lexical)])
	}

	private func brokenLinks(on page: URL, ids: [String], idsByFile: [String: Set<String>], files: Set<String>) throws -> [BrokenLink] {
		let html = try String(contentsOf: page, encoding: .utf8)
		let pagePath = routePath(of: page)
		let base = site.appending(path: pagePath)
		var brokenLinks = [BrokenLink]()

		var seenIDs = Set<String>()

		for id in ids where !seenIDs.insert(id).inserted {
			brokenLinks.append(BrokenLink(page: pagePath, link: "#\(id)", problem: .duplicateID))
		}

		for match in html.matches(of: Self.link) {
			guard let link = (match.2 ?? match.3).map(String.init) else {
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

			guard
				let target = output.servedFile(forPath: resolved.path(percentEncoded: true)),
				files.contains(pathAsWritten(of: target))
			else {
				brokenLinks.append(BrokenLink(page: pagePath, link: link, problem: .missingFile))
				continue
			}

			guard
				match.1 != "src",
				let fragment = resolved.fragment?.removingPercentEncoding,
				!fragment.isEmpty,
				target.pathExtension == "html"
			else {
				continue
			}

			if idsByFile[target.path(relativeTo: output)]?.contains(fragment) != true {
				brokenLinks.append(BrokenLink(page: pagePath, link: link, problem: .missingFragment))
			}
		}

		return brokenLinks
	}

	/**
	The path of a file in the output, relative to it, in the case it is written in. Unlike `path(relativeTo:)`, it does not resolve symlinks, which gives the case on disk.
	*/
	private func pathAsWritten(of file: URL) -> String {
		String(file.standardizedFileURL.path(percentEncoded: false).dropFirst(output.standardizedFileURL.path(percentEncoded: false).count).drop { $0 == "/" })
	}

	/**
	Throws if the output directory does not exist, so a wrong path does not pass with nothing checked.
	*/
	private func htmlFiles() throws -> [URL] {
		try output.filesRecursively().filter { $0.pathExtension == "html" }
	}

	private func routePath(of file: URL) -> String {
		let relative = file.path(relativeTo: output)
		return relative == "index.html" ? "/" : "/" + relative.replacing(/\.html$/, with: "")
	}
}
