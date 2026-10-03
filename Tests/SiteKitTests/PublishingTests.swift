import Foundation
import Testing
@testable import SiteKit

@Suite
struct PublishingTests {
	private let site = URL(string: "https://example.com")!

	@Test
	func `route paths append components`() {
		#expect(RoutePath("/apps/") == "/apps")
		#expect(RoutePath("/blog/post").starts(with: "/blog"))
		#expect(RoutePath("/blog").starts(with: "/blog"))
		#expect(!RoutePath("/blogroll").starts(with: "/blog"))
		#expect(RoutePath("/apps").starts(with: .root))
		#expect(RoutePath.root.appending("blog").appending("post") == "/blog/post")
	}

	@Test
	func `the route kind decides the output file`() {
		#expect(Route.page(.root) { "" }.outputFile == "index.html")
		#expect(Route.page("/apps") { "" }.outputFile == "apps.html")
		#expect(Route.page("/apps/") { "" }.outputFile == "apps.html")
		#expect(Route.page("/blog/macos-13.1") { "" }.outputFile == "blog/macos-13.1.html")
		#expect(Route.redirect("/v1.0", to: "/").outputFile == "v1.0.html")
		#expect(Route.text("/dato/rss.xml") { "" }.outputFile == "dato/rss.xml")
	}

	@Test
	func `invalid route paths stop the build`() async {
		await #expect(processExitsWith: .failure) {
			_ = RoutePath("apps")
		}

		await #expect(processExitsWith: .failure) {
			_ = RoutePath.root.appending("a/b")
		}

		await #expect(processExitsWith: .failure) {
			_ = Route.file(.root) { Data() }
		}
	}

	@Test
	func `route paths make absolute URLs`() {
		#expect(RoutePath.root.absoluteURL(site: site).absoluteString == "https://example.com/")
		#expect(RoutePath("/apps").absoluteURL(site: site).absoluteString == "https://example.com/apps")
		#expect(RoutePath("/dato/release-notes").absoluteURL(site: site, fragment: "1.2.0").absoluteString == "https://example.com/dato/release-notes#1.2.0")
	}

	@Test
	func `publishes routes, assets, redirects, and the sitemap`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "User-agent: *"])
		let output = project.root.appending(path: "dist")

		try await Publisher(site: site, project: project, output: output).publish([
			.page("/") { "<a href=\"/about\">About</a>" },
			.page("/about", images: [URL(string: "https://example.com/a.png")!]) { "<h1 id=\"top\">About</h1>" },
			.page("/hidden", isInSitemap: false) { "Hidden" },
			.text("/feed.xml") { "<rss/>" },
			.redirect("/old", to: "/about"),
		])

		#expect(try String(contentsOf: output.appending(path: "about.html"), encoding: .utf8) == "<h1 id=\"top\">About</h1>")
		#expect(FileManager.default.fileExists(atPath: output.appending(path: "robots.txt").path))
		#expect(try String(contentsOf: output.appending(path: "old.html"), encoding: .utf8).contains(#"<link rel="canonical" href="https://example.com/about">"#))

		let sitemap = try String(contentsOf: output.appending(path: "sitemap-0.xml"), encoding: .utf8)
		#expect(sitemap.contains("<url><loc>https://example.com/</loc></url><url><loc>https://example.com/about</loc><image:image><image:loc>https://example.com/a.png</image:loc></image:image></url></urlset>"))
	}

	@Test
	func `publishing again only writes changes and removes stale files`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "User-agent: *"])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)

		try await publisher.publish([.page("/a") { "A" }, .page("/b/c") { "C" }])
		let date = try output.appending(path: "a.html").resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
		try await Task.sleep(for: .milliseconds(20))

		try await publisher.publish([.page("/a") { "A" }])

		#expect(try output.appending(path: "a.html").resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate == date)
		#expect(!output.appending(path: "b/c.html").exists)
		#expect(!output.appending(path: "b").exists)
		#expect(output.appending(path: "robots.txt").isFile)
	}

	@Test
	func `missing directories are errors`() async throws {
		let project = Project(root: try URL.temporaryDirectory())

		await #expect(throws: (any Error).self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([])
		}

		await #expect(throws: (any Error).self) {
			try await LinkValidator(site: site, output: project.root.appending(path: "missing")).brokenLinks()
		}
	}

	@Test
	func `served files resolve like GitHub Pages and stay inside the directory`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		try await Publisher(site: site, project: project, output: output).publish([.page("/") { "" }, .page("/blog") { "" }, .page("/blog/post") { "" }])
		try Data().write(to: project.root.appending(path: "dist.html"))

		#expect(output.servedFile(forPath: "/")?.lastPathComponent == "index.html")
		#expect(output.servedFile(forPath: "/blog")?.lastPathComponent == "blog.html")
		#expect(output.servedFile(forPath: "/blog/post")?.lastPathComponent == "post.html")
		#expect(output.servedFile(forPath: "/robots.txt")?.lastPathComponent == "robots.txt")
		#expect(output.servedFile(forPath: "/blog/") == nil)
		#expect(output.servedFile(forPath: "/../dist.html") == nil)
		#expect(output.servedFile(forPath: "/%2e%2e/dist.html") == nil)
	}

	@Test
	func `refuses an output directory that would delete the project`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])

		for output in [project.root, project.root.deletingLastPathComponent(), project.publicDirectory.appending(path: "dist")] {
			await #expect(throws: PublishingError.self) {
				try await Publisher(site: site, project: project, output: output).publish([])
			}
		}

		#expect(FileManager.default.fileExists(atPath: project.publicDirectory.appending(path: "robots.txt").path))
	}

	@Test
	func `rejects routes that write the same file`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let publisher = Publisher(site: site, project: project, output: project.root.appending(path: "dist"))

		await #expect(throws: PublishingError.self) {
			try await publisher.publish([.page("/a") { "" }, .text("/a.html") { "" }])
		}

		await #expect(throws: PublishingError.self) {
			try await publisher.publish([.text("/robots.txt") { "" }])
		}
	}

	@Test
	func `finds broken links and fragments`() async throws {
		let project = try makeProject(publicFiles: ["image.png": ""])
		let output = project.root.appending(path: "dist")

		try await Publisher(site: site, project: project, output: output).publish([
			.page("/") {
				#"<a href="/about">Fine</a> <a href="/about#top">Fine</a> <img src="/image.png"> <a href="https://example.com/about">Fine</a> <a href="https://elsewhere.com/missing">External</a> <a href="/missing">Broken</a> <a href="/about#missing">Broken</a> <a href="/about/">Broken</a> <div data-id="missing"></div>"#
			},
			.page("/about") { ##"<h1 id="top">About</h1> <a href="#top">Fine</a> <a href="#nope">Broken</a> <p id="top">Duplicate</p> <meta property="og:image" content="https://example.com/missing.png">"## },
		])

		let brokenLinks = try await LinkValidator(site: site, output: output).brokenLinks()

		#expect(brokenLinks.map(\.description) == [
			"/: /about#missing (missing fragment)",
			"/: /about/",
			"/: /missing",
			"/about: #nope (missing fragment)",
			"/about: #top (duplicate ID)",
			"/about: https://example.com/missing.png",
		])
	}

	private func makeProject(publicFiles: [String: String]) throws -> Project {
		try Project(root: URL.temporaryDirectory(files: Dictionary(uniqueKeysWithValues: publicFiles.map { ("public/\($0.key)", $0.value) })))
	}

	@Test
	func `public files are updated and removed when they change`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "v1"])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)
		let source = project.publicDirectory.appending(path: "robots.txt")

		try await publisher.publish([.page("/a") { "A" }])
		try Data("v2, longer".utf8).write(to: source)
		try await publisher.publish([.page("/a") { "A" }])
		#expect(try String(contentsOf: output.appending(path: "robots.txt"), encoding: .utf8) == "v2, longer")

		try source.removeIfExists()
		try await publisher.publish([.page("/a") { "A" }])
		#expect(!output.appending(path: "robots.txt").exists)
	}

	@Test
	func `a public file renamed only in case is published with the new name`() async throws {
		let project = try makeProject(publicFiles: ["Logo.txt": "Logo"])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)

		try await publisher.publish([.page("/a") { "A" }])
		try FileManager.default.moveItem(at: project.publicDirectory.appending(path: "Logo.txt"), to: project.publicDirectory.appending(path: "logo.txt"))
		try await publisher.publish([.page("/a") { "A" }])

		#expect(try FileManager.default.contentsOfDirectory(atPath: output.path(percentEncoded: false)).contains("logo.txt"))
	}

	@Test(arguments: ["/../escape", "/a/../../b", "/./a"])
	func `decoded paths cannot leave the output directory`(path: String) {
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(RoutePath.self, from: Data("\"\(path)\"".utf8))
		}
	}

	@Test
	func `links that differ in case from the file are broken`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		try await Publisher(site: site, project: project, output: output).publish([
			.page("/") { #"<a href="/About">About</a> <a href="/about">About</a>"# },
			.page("/about") { "About" },
		])

		let brokenLinks = try await LinkValidator(site: site, output: output).brokenLinks()
		#expect(brokenLinks.map(\.link) == ["/About"], "\(brokenLinks)")
	}

	@Test
	func `JSON in a script cannot end the script element`() {
		#expect(!JSONScript(id: "data", ["text": "</script><b>"]).render().contains("</script><b>"))
	}

}

@Suite
struct ContentLoadingTests {
	struct Frontmatter: SiteKit.Frontmatter {
		let links: OrderedMapping<String>
	}

	@Test
	func `ordered mappings keep the YAML order`() throws {
		let file = try MarkdownFile(contents: "---\nlinks:\n  Zebra: z\n  Apple: a\n  Mango: m\n---\nBody", url: URL(filePath: "/content/test.md"))
		let frontmatter = try file.decodeFrontmatter(as: Frontmatter.self)

		#expect(frontmatter.links.map(\.key) == ["Zebra", "Apple", "Mango"])
		#expect(frontmatter.links["Apple"] == "a")
		#expect(file.body == "Body")
		#expect(file.slug == "test")
	}

	struct Note: ContentEntry {
		@Frontmatter
		struct Frontmatter {
			var title: String

			@Key("draft")
			var isDraft: Bool = false
		}

		static let directory = "content/notes"
		static let sortOrder = [KeyPathComparator(\Note.title)]

		let title: String
		let slug: String
		let isDraft: Bool

		init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) {
			self.title = frontmatter.title
			self.slug = file.slug
			self.isDraft = frontmatter.isDraft
		}
	}

	@Test
	func `entries with the same sort key load in file path order`() async throws {
		let names = (10..<40).map { "note-\($0)" }
		let root = try URL.temporaryDirectory(files: Dictionary(uniqueKeysWithValues: names.map { ("\(Note.directory)/\($0).md", "---\ntitle: Same\n---\nBody") }))

		for _ in 0..<5 {
			#expect(try await Note.load(from: Project(root: root)).map(\.slug) == names)
		}
	}

	@Test
	func `loading leaves out drafts, sorts, and names all broken files`() async throws {
		let root = try URL.temporaryDirectory()
		let directory = root.appending(path: Note.directory)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

		for (name, frontmatter) in [("b", "title: B"), ("a", "title: A"), ("c", "title: C\ndraft: true")] {
			try Data("---\n\(frontmatter)\n---\nBody".utf8).write(to: directory.appending(path: "\(name).md"))
		}

		#expect(try await Note.load(from: Project(root: root)).map(\.title) == ["A", "B"])

		try Data("---\ntitle: D\nunknown: true\n---\n".utf8).write(to: directory.appending(path: "d.md"))
		try Data("---\ntitle: E\nunknown: true\n---\n".utf8).write(to: directory.appending(path: "e.md"))

		let error = try await #require(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: root))
		}

		// Every broken file is reported, not only the first.
		#expect(error.errors.map(\.file.lastPathComponent) == ["d.md", "e.md"])
	}

	@Test
	func `frontmatter fences allow a byte order mark and trailing spaces`() throws {
		let file = try MarkdownFile(contents: "\u{FEFF}--- \nlinks:\n  A: a\n---\t\nBody", url: URL(filePath: "/content/test.md"))
		#expect(file.frontmatter == "links:\n  A: a")
		#expect(file.body == "Body")
	}

	@Test
	func `frontmatter errors name the line`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: A\nlinks:\n  - a\nunknown: true\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: Frontmatter.self)
		}

		#expect(error.line == 3)
		#expect(error.description.hasPrefix("/content/test.md:3: Invalid `links`"))

		let strict = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: Note.Frontmatter.self)
		}

		// The first unknown key, in alphabetical order.
		#expect(strict.line == 3)
		#expect(strict.reason == "Unknown key(s): links, unknown in frontmatter.")
	}

	@Test
	func `a missing content directory is an error`() async {
		await #expect(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: try URL.temporaryDirectory()))
		}
	}

	@Test
	func `last commit dates ignore moves without changes`() throws {
		let root = try URL.temporaryDirectory()
		try root.appending(path: "old").createDirectory()

		func git(_ arguments: String..., date: String = "2026-01-01T00:00:00Z") throws {
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "user.name=Test", "-c", "user.email=test@example.com"] + arguments
			process.environment = ["GIT_COMMITTER_DATE": date, "GIT_AUTHOR_DATE": date, "PATH": "/usr/bin:/bin:/opt/homebrew/bin"]
			process.standardOutput = FileHandle.nullDevice
			try process.run()
			process.waitUntilExit()
		}

		try git("init", "--quiet")
		try Data("A".utf8).write(to: root.appending(path: "old/a.md"))
		try Data("B".utf8).write(to: root.appending(path: "old/b.md"))
		try git("add", ".")
		try git("commit", "--quiet", "-m", "Add")
		try Data("A, changed".utf8).write(to: root.appending(path: "old/a.md"))
		try git("commit", "--quiet", "-am", "Change", date: "2026-02-01T00:00:00Z")
		try git("mv", "old", "content")
		try git("commit", "--quiet", "-m", "Move", date: "2026-03-01T00:00:00Z")

		let dates = Project(root: root).lastCommitDates(in: "content")
		#expect(dates["content/a.md"] == Date(timeIntervalSince1970: 1_769_904_000))
		#expect(dates["content/b.md"] == Date(timeIntervalSince1970: 1_767_225_600))
	}

	@Test
	func `slugs are relative to the content directory`() throws {
		let file = try MarkdownFile(contents: "Body", url: URL(filePath: "/content/apps/faq.md"), relativeTo: URL(filePath: "/content"))
		#expect(file.slug == "apps/faq")
	}
}
