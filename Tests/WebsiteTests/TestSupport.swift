import Foundation
@testable import SiteKit
@testable import Website

extension Project {
	/**
	The project of the website, with the real content.
	*/
	static let website = Project.site(root: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

	/**
	A project in a directory that does not exist, for content that a test makes without files.
	*/
	static let empty = Project.site(root: URL.temporaryDirectory.appending(path: "website-tests-empty-project"))
}

extension SiteContent {
	/**
	The real content of the website, without the network: there is no App Store or GitHub data. The build date is fixed, so the tests do not change from day to day.

	It is loaded once, and the tests share it, as loading the content is slow. The content is immutable, so the tests cannot change it for each other. A test that checks loading itself loads its own.
	*/
	static var website: Self {
		get async throws {
			try await loadingWebsite.value
		}
	}

	private static let loadingWebsite = Task {
		try await load(from: .website, externalData: .none, buildDate: Date(timeIntervalSince1970: 1_790_000_000))
	}
}

extension ContentEntry {
	/**
	An entry from the Markdown of a file in the directory of its type, like `content/apps/test.md`. The file is not written to disk.
	*/
	init(markdown: String, slug: String = "test", project: Project = .empty) async throws {
		let file = try MarkdownFile(contents: markdown, url: project.root.appending(path: "\(Self.directory)/\(slug).md"))
		try await self.init(file: file, frontmatter: file.decodeFrontmatter(), project: project)
	}
}

extension ResponseCache {
	/**
	A cache with a fresh response for each URL, so the test does not use the network. The requests must not have a body, as the body is part of the cache key. It is in a new directory of the `.temporaryDirectory` trait, unless a directory is given.
	*/
	init(responses: [String: String], directory: URL? = nil) throws {
		let directory = try directory ?? URL.temporaryDirectory()

		for (url, body) in responses {
			guard let responseURL = URL(string: url) else {
				preconditionFailure("An invalid fixture URL: \(url)")
			}

			let entry = #"{"date": \#(Date.now.timeIntervalSinceReferenceDate), "body": "\#(Data(body.utf8).base64EncodedString())"}"#
			try Data(entry.utf8).write(to: directory.appending(path: "\(URLRequest(url: responseURL).responseCacheKey).json"))
		}

		self.init(directory: directory, maximumAge: .seconds(60 * 60))
	}

	/**
	A cache with the responses of npm for ``NPMStatistics/load(cache:warnings:)``: the first page of the search, the downloads of all of npm, and the most-downloaded packages, so the test does not use the network.
	*/
	static func npm(search: String, registryDownloads: String = #"{"downloads": 0}"#, mostDownloaded: String = "export const topDownload = [\n  'semver',\n]") throws -> Self {
		try Self(responses: [
			"https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=0": search,
			"https://api.npmjs.org/downloads/point/last-week": registryDownloads,
			"https://unpkg.com/npm-high-impact/lib/top-download.js": mostDownloaded,
		])
	}
}

/**
The error when a route is not a page, like a redirect.
*/
private struct NotAPageError: Error {}

extension Route {
	/**
	The HTML of the page of the route. It throws when the route is not a page.
	*/
	func renderedHTML() throws -> String {
		guard case .page(_, let render) = output else {
			throw NotAPageError()
		}

		return try render()
	}
}

extension Page {
	/**
	The HTML of the page. It throws when the route is not a page.
	*/
	func renderedHTML() throws -> String {
		try route.renderedHTML()
	}
}
