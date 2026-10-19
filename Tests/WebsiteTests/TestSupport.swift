import Foundation
@testable import SiteKit
import TestSupport
import Testing
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

	/**
	The text of the content warnings, with the paths relative to the project, like in a build, which runs in the project root. The projects of the tests are in the temporary directory, so their warnings have full paths, with or without resolved symbolic links (`/private/var` for `/var`).

	- Parameter output: The published site. Default: `dist` in the project.
	*/
	@MainActor
	func warningTexts(output: URL? = nil) -> [String] {
		// The root of an existing project ends with `/`.
		let path = project.root.path(percentEncoded: false)
		let root = path.hasSuffix("/") ? path : path + "/"

		return warnings(output: output ?? project.root.appending(path: "dist")).map { warning in
			// The resolved path first, as it ends with the other one.
			warning.description
				.replacing("/private" + root, with: "")
				.replacing(root, with: "")
		}
	}
}

/**
A page of the site with its HTML, and the custom elements (``ScriptedElement``) that it shows.
*/
struct RenderedPage: CustomTestStringConvertible {
	let route: Route
	let html: String
	let elements: [any ScriptedElement.Type]

	var testDescription: String {
		route.path.description
	}
}

extension RenderedPage {
	/**
	Every page of the site from the real content (``SiteContent/website``), with the component gallery, which shows the components that the pages only show with data.

	They are rendered once, in parallel like in a build, and the tests share them, as rendering every page is slow. Each page renders in a collector of its own, like in a build, so a test can check the scripts against the elements that the pages show, as types, without a list of the elements.
	*/
	static var website: [Self] {
		get async throws {
			try await renderingWebsite.value
		}
	}

	private static let renderingWebsite = Task {
		let routes = try await Site(content: .website).routes(includesGallery: true)

		return try await withThrowingTaskGroup { group in
			for (index, route) in routes.enumerated() {
				guard case .page(_, let render) = route.output else {
					continue
				}

				group.addTask {
					let resources = PageResources(sharedStylesheet: .site)
					let html = try resources.collect {
						try render()
					}

					return (index: index, page: Self(route: route, html: html, elements: resources.elements))
				}
			}

			var pages = [(index: Int, page: Self)]()

			for try await page in group {
				pages.append(page)
			}

			return pages.sorted(using: KeyPathComparator(\.index)).map(\.page)
		}
	}
}

extension ContributionYear.Totals {
	/**
	No contributions by kind, for a test that only needs the calendar of a year.
	*/
	static let zero = Self(commitCount: 0, pullRequestCount: 0, reviewCount: 0, repositoryCount: 0, committedRepositoryCount: 0, repositoryCommits: [])
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

extension Decodable {
	/**
	The value of the JSON, decoded like a response of ``ResponseCache``, with ISO 8601 dates.
	*/
	init(json: String) throws {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		self = try decoder.decode(Self.self, from: Data(json.utf8))
	}
}

extension ResponseCache {
	/**
	A cache with a fresh response for each URL, so the test does not use the network. The requests must not have a body, as the body is part of the cache key. It is in a new directory of the `.temporaryDirectory` trait, unless a directory is given.
	*/
	init(responses: [String: String], directory: URL? = nil) throws {
		let directory = try directory ?? URL.temporaryDirectory()

		for (url, body) in responses {
			let responseURL = try #require(URL(string: url), "An invalid fixture URL: \(url)")
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
The error when a route is not the kind of output that the test renders, like a redirect instead of a page.
*/
private struct UnexpectedOutputError: Error {}

extension Route {
	/**
	The HTML of the page of the route. It throws when the route is not a page.
	*/
	func renderedHTML() throws -> String {
		guard case .page(_, let render) = output else {
			throw UnexpectedOutputError()
		}

		return try render()
	}

	/**
	The contents of the file of the route, like a feed. It throws when the route is not a file.
	*/
	func renderedFile() async throws -> Data {
		guard case .file(let render) = output else {
			throw UnexpectedOutputError()
		}

		return try await render()
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
