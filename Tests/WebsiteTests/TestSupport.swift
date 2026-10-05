import Foundation
import SiteKit
import Website

extension Project {
	/**
	The project of the website, with the real content.
	*/
	static let website = Project(root: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

	/**
	A project in a directory that does not exist, for content that a test makes without files.
	*/
	static let empty = Project(root: FileManager.default.temporaryDirectory.appending(path: "website-tests-empty-project"))
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
			let entry = #"{"date": \#(Date.now.timeIntervalSinceReferenceDate), "body": "\#(Data(body.utf8).base64EncodedString())"}"#
			try Data(entry.utf8).write(to: directory.appending(path: "\(String(url.stableHash, radix: 16)).json"))
		}

		self.init(directory: directory, maximumAge: .seconds(60 * 60))
	}
}
