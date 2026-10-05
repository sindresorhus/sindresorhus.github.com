import Elementary
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import SiteKit

@Suite
struct PublishingTests {
	private let site = URL(string: "https://example.com")!

	@Test
	func `route paths append components`() throws {
		#expect(RoutePath("/apps/") == "/apps")
		// All trailing slashes, as a path with one left, like `/old/`, writes a hidden file, `old/.html`.
		#expect(RoutePath("/old//") == "/old")

		// Repeated slashes inside, as `/blog//post` writes the same file as `/blog/post`, and `//example.com` in a link goes to another host.
		#expect(RoutePath("/blog//post") == "/blog/post")
		#expect(try RoutePath(validating: "//example.com") == "/example.com")
		#expect(RoutePath("//") == .root)
		#expect(Route.redirect("/old//", to: .path(.root)).outputFile == "old.html")
		#expect(RoutePath("/blog/post").starts(with: "/blog"))
		#expect(RoutePath("/blog").starts(with: "/blog"))
		#expect(!RoutePath("/blogroll").starts(with: "/blog"))
		#expect(RoutePath("/apps").starts(with: .root))
		#expect(RoutePath.root.appending("blog").appending("post") == "/blog/post")
	}

	@Test(arguments: [
		(Route.page(.root) { "" }, "index.html"),
		(Route.page("/apps") { "" }, "apps.html"),
		(Route.page("/apps/") { "" }, "apps.html"),
		(Route.page("/blog/macos-13.1") { "" }, "blog/macos-13.1.html"),
		(Route.redirect("/v1.0", to: .path(.root)), "v1.0.html"),
		(Route.text("/dato/rss.xml") { "" }, "dato/rss.xml"),
	])
	func `the route kind decides the output file`(route: Route, outputFile: String) {
		#expect(route.outputFile == outputFile)
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
		#expect(LinkDestination.path("/dato/release-notes", fragment: "1.2.0").absoluteURL(site: site).absoluteString == "https://example.com/dato/release-notes#1.2.0")
	}

	@Test
	func `link destinations encode their query, also a plus, which forms read as a space`() {
		let destination = LinkDestination.path(.root.appending("feedback"), query: [URLQueryItem(name: "product", value: "A & B+C")], fragment: "form")

		#expect(destination.description == "/feedback?product=A%20%26%20B%2BC#form")
		#expect(destination.absoluteURL(site: site).absoluteString == "https://example.com/feedback?product=A%20%26%20B%2BC#form")
	}

	@Test
	func `a path from content keeps its query and fragment out of the route path`() throws {
		#expect(try LinkDestination(validating: "/apps/faq#refund") == .path("/apps/faq", fragment: "refund"))
		#expect(try LinkDestination(validating: "/feedback?product=Dato") == .path("/feedback", query: [URLQueryItem(name: "product", value: "Dato")]))
		#expect(try LinkDestination(validating: "#faq") == .fragment("faq"))
		#expect(try LinkDestination(validating: "/a#a%20b").description == "/a#a%20b")
		#expect(try LinkDestination(validating: "mailto:a@example.com") == .url(#require(URL(string: "mailto:a@example.com"))))
		#expect(throws: ContentError.self) {
			try LinkDestination(validating: "apps/faq")
		}
	}

	@Test(.temporaryDirectory)
	func `publishes routes, assets, redirects, and the sitemap`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "User-agent: *"])
		let output = project.root.appending(path: "dist")

		let image = try #require(URL(string: "https://example.com/a.png"))

		try await Publisher(site: site, project: project, output: output).publish([
			.page("/") { "<a href=\"/about\">About</a>" },
			.page("/about", sitemapEntry: SitemapEntry(images: [image])) { "<h1 id=\"top\">About</h1>" },
			.page("/hidden", sitemapEntry: nil) { "Hidden" },
			.text("/feed.xml") { "<rss/>" },
			.redirect("/old", to: .path("/about")),
		])

		#expect(try String(contentsOf: output.appending(path: "about.html"), encoding: .utf8) == "<h1 id=\"top\">About</h1>")
		#expect(FileManager.default.fileExists(atPath: output.appending(path: "robots.txt").path))
		#expect(try String(contentsOf: output.appending(path: "old.html"), encoding: .utf8).contains(#"<link rel="canonical" href="https://example.com/about">"#))

		let sitemap = try String(contentsOf: output.appending(path: "sitemap-0.xml"), encoding: .utf8)
		#expect(sitemap.contains("<url><loc>https://example.com/</loc></url><url><loc>https://example.com/about</loc><image:image><image:loc>https://example.com/a.png</image:loc></image:image></url></urlset>"))
	}

	@Test(.temporaryDirectory)
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

	@Test(.temporaryDirectory)
	func `missing directories are errors`() async throws {
		let project = Project(root: try URL.temporaryDirectory())

		let publishingError = try await #require(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([])
		}

		guard case .fileSystem(let error) = publishingError else {
			Issue.record("Expected a file system error, got \(publishingError)")
			return
		}

		#expect((error as? CocoaError)?.code == .fileReadNoSuchFile)

		let validationError = try await #require(throws: CocoaError.self) {
			try await LinkValidator(site: site, output: project.root.appending(path: "missing")).brokenLinks(in: [.page("/") { "" }], files: ["index.html"])
		}

		#expect(validationError.code == .fileReadNoSuchFile)
	}

	@Test(.temporaryDirectory)
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
		#expect("/apps".servedFileCandidates == ["apps", "apps.html", "apps/index.html"])
		#expect("/blog/".servedFileCandidates == ["blog/index.html"])
		#expect("/".servedFileCandidates == ["index.html"])
	}

	@Test(.temporaryDirectory)
	func `refuses an output directory that would delete the project`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])

		for output in [project.root, project.root.deletingLastPathComponent(), project.publicDirectory.appending(path: "dist")] {
			await #expect(throws: PublishingError.self) {
				try await Publisher(site: site, project: project, output: output).publish([])
			}
		}

		#expect(FileManager.default.fileExists(atPath: project.publicDirectory.appending(path: "robots.txt").path))
	}

	/**
	The default disk of macOS ignores case, so the project root in other case is the same directory.
	*/
	@Test(.temporaryDirectory)
	func `refuses the project as the output directory in other case`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = URL(filePath: project.root.path(percentEncoded: false).uppercased(), directoryHint: .isDirectory)
		try #require(output.isDirectory)

		await #expect(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: output).publish([.page("/a") { "A" }])
		}

		#expect(project.publicDirectory.appending(path: "robots.txt").exists)
	}

	@Test(.temporaryDirectory)
	func `refuses a symlink to the project as the output directory`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let link = try URL.temporaryDirectory().appending(path: "site-link")
		try FileManager.default.createSymbolicLink(at: link, withDestinationURL: project.root)

		await #expect(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: URL(filePath: link.path(percentEncoded: false), directoryHint: .isDirectory)).publish([.page("/a") { "A" }])
		}

		#expect(!project.root.appending(path: "a.html").exists)
	}

	/**
	HTML writes `&` as `&amp;` in attributes, so a link to a file with `&` in its name has `&amp;` in its `href`.
	*/
	@Test(.temporaryDirectory)
	func `a link with an escaped ampersand in its path is not broken`() async throws {
		let project = try makeProject(publicFiles: ["files/a&b.pdf": ""])
		let output = project.root.appending(path: "dist")
		let routes: [Route] = [.page(.root) { #"<a href="/files/a&amp;b.pdf">PDF</a>"# }]
		let files = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files).isEmpty)
	}

	/**
	An `id` is literal text, so `a%20b` is the ID itself. Only the fragment of a link is percent-decoded, so `#a%2520b` links to it.
	*/
	@Test(.temporaryDirectory)
	func `an ID with a percent sign is compared as written`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let routes: [Route] = [.page(.root) { ##"<label for="a%20b">A</label><input id="a%20b"> <a href="#a%2520b">Field</a>"## }]
		let files = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files).isEmpty)
	}

	/**
	Only the directories of the path are resolved, as resolving the symlink itself gives the path of its target, which can be outside the public directory.
	*/
	@Test(.temporaryDirectory)
	func `a symlinked public file keeps its path`() async throws {
		let outside = try URL.temporaryDirectory(files: ["font.woff2": "font"])
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let fonts = project.publicDirectory.appending(path: "fonts")
		try fonts.createDirectory()
		try FileManager.default.createSymbolicLink(at: fonts.appending(path: "font.woff2"), withDestinationURL: outside.appending(path: "font.woff2"))

		#expect(try project.publicFiles().map(\.path).contains("fonts/font.woff2"))
	}

	/**
	A browser scrolls to the top for `#top` when no element has that ID, like the empty fragment.
	*/
	@Test(.temporaryDirectory)
	func `a link to the top fragment is not broken`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let routes: [Route] = [.page(.root) { ##"<a href="#top">Top</a> <a href="/#TOP">Top</a>"## }]
		let files = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files).isEmpty)
	}

	/**
	The target is published, as a copy of the link itself would not resolve from the output directory.
	*/
	@Test(.temporaryDirectory)
	func `a public file that is a relative symlink is published as its target`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let shared = project.root.appending(path: "shared")
		try shared.createDirectory()
		try Data("font".utf8).write(to: shared.appending(path: "font.woff2"))
		try FileManager.default.createSymbolicLink(atPath: project.publicDirectory.appending(path: "font.woff2").path(percentEncoded: false), withDestinationPath: "../shared/font.woff2")
		let output = try URL.temporaryDirectory().appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)

		try await publisher.publish([])
		#expect((try? String(contentsOf: output.appending(path: "font.woff2"), encoding: .utf8)) == "font")
		await #expect(throws: Never.self) {
			try await publisher.publish([])
		}
	}

	/**
	A broken symbolic link from an earlier build is replaced or removed, so the output has exactly the published files.
	*/
	@Test(.temporaryDirectory)
	func `broken symbolic links in the output are replaced and removed`() async throws {
		let project = try makeProject(publicFiles: ["font.woff2": "font"])
		let output = try URL.temporaryDirectory().appending(path: "dist")
		try output.createDirectory()
		try FileManager.default.createSymbolicLink(atPath: output.appending(path: "font.woff2").path(percentEncoded: false), withDestinationPath: "missing.woff2")
		try FileManager.default.createSymbolicLink(atPath: output.appending(path: "old.txt").path(percentEncoded: false), withDestinationPath: "missing.txt")

		try await Publisher(site: site, project: project, output: output).publish([])
		#expect((try? String(contentsOf: output.appending(path: "font.woff2"), encoding: .utf8)) == "font")
		#expect((try? FileManager.default.destinationOfSymbolicLink(atPath: output.appending(path: "old.txt").path(percentEncoded: false))) == nil)
	}

	/**
	The file is published at the place of the link, so a link to it in the page resolves to that place.
	*/
	@Test(.temporaryDirectory)
	func `a symlinked page bundle file has the public path of the link`() throws {
		let outside = try URL.temporaryDirectory(files: ["icon.png": "icon"])
		let project = try Project(root: URL.temporaryDirectory(files: ["content/apps/dato/index.md": "Text.", "public/robots.txt": ""]))
		let link = project.contentDirectory.appending(path: "apps/dato/icon.png")
		try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside.appending(path: "icon.png"))

		#expect(try project.publicFiles().map(\.path).contains("apps/dato/icon.png"))
		#expect(project.publicPath(ofContentFile: link) == "/apps/dato/icon.png")
	}

	@Test(.temporaryDirectory)
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

	@Test(.temporaryDirectory)
	func `finds broken links and fragments`() async throws {
		let project = try makeProject(publicFiles: ["image.png": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page("/") {
				#"<a href="/about">Fine</a> <a href="/about#top">Fine</a> <img src="/image.png"> <a href="https://example.com/about">Fine</a> <a href="https://elsewhere.com/missing">External</a> <a href="/missing">Broken</a> <a href="/about#missing">Broken</a> <a href="/about/">Broken</a> <div data-id="missing"></div>"#
			},
			.page("/about") { ##"<h1 id="top">About</h1> <a href="#top">Fine</a> <a href="#nope">Broken</a> <p id="top">Duplicate</p> <meta property="og:image" content="https://example.com/missing.png">"## },
		]

		let files = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files)

		#expect(brokenLinks.map(\.description) == [
			"/: /about#missing (missing fragment)",
			"/: /about/",
			"/: /missing",
			"/about: #nope (missing fragment)",
			"/about: #top (duplicate ID)",
			"/about: https://example.com/missing.png",
		])
	}

	@Test(.temporaryDirectory)
	func `finds references to IDs that are not on the page`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page("/") {
				#"<dialog aria-labelledby="title" aria-describedby="text missing-text"><h2 id="title">Title</h2><p id="text">Text</p></dialog> <label for="name">Name</label> <input id="name" list="missing-list"> <button popovertarget="menu">Menu</button> <span aria-label="Fine" data-for="ignored"></span>"#
			},
		]

		let files = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files)

		#expect(brokenLinks.map(\.description) == [
			#"/: aria-describedby="missing-text" (missing ID)"#,
			#"/: list="missing-list" (missing ID)"#,
			#"/: popovertarget="menu" (missing ID)"#,
		])
	}

	@Test(.temporaryDirectory)
	func `the files of page bundles are published at their path in the content directory`() async throws {
		let project = try Project(root: URL.temporaryDirectory(files: [
			"public/robots.txt": "",
			"content/apps/dato/index.md": "Dato",
			"content/apps/dato/icon.png": "icon",
			"content/apps/dato/notes.md": "",
			"content/spelling.txt": "",
		]))
		let output = project.root.appending(path: "dist")

		let files = try await Publisher(site: site, project: project, output: output).publish([])

		#expect(files.isSuperset(of: ["robots.txt", "apps/dato/icon.png"]))
		#expect(!files.contains("apps/dato/index.md"))
		#expect(!files.contains("apps/dato/notes.md"))
		#expect(!files.contains("spelling.txt"))
		#expect(try String(contentsOf: output.appending(path: "apps/dato/icon.png"), encoding: .utf8) == "icon")
		#expect(project.publicFile("/apps/dato/icon.png") == project.contentDirectory.appending(path: "apps/dato/icon.png"))
		#expect(project.publicFile("/robots.txt") == project.publicDirectory.appending(path: "robots.txt"))
	}

	@Test(.temporaryDirectory)
	func `a public file and a page bundle file with the same path are a collision`() async throws {
		let project = try Project(root: URL.temporaryDirectory(files: [
			"public/apps/dato/icon.png": "",
			"content/apps/dato/index.md": "",
			"content/apps/dato/icon.png": "",
		]))

		await #expect(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([])
		}
	}

	private func makeProject(publicFiles: [String: String]) throws -> Project {
		try Project(root: URL.temporaryDirectory(files: Dictionary(uniqueKeysWithValues: publicFiles.map { ("public/\($0.key)", $0.value) })))
	}

	@Test(.temporaryDirectory)
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

	@Test(.temporaryDirectory)
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

	@Test(.temporaryDirectory)
	func `links that differ in case from the file are broken`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page("/") { #"<a href="/About">About</a> <a href="/about">About</a>"# },
			.page("/about") { "About" },
		]

		let files = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = try await LinkValidator(site: site, output: output).brokenLinks(in: routes, files: files)
		#expect(brokenLinks.map(\.link) == ["/About"], "\(brokenLinks)")
	}

	@Test
	func `JSON in a script cannot end the script element`() {
		#expect(!JSONScript(id: "data", ["text": "</script><b>"]).render().contains("</script><b>"))
	}

	@Test
	func `JSON in a script has no less-than sign, so a comment cannot keep the script element open`() throws {
		let text = "Great <!--<script> app"
		let html = JSONScript(id: "data", ["text": text]).render()
		let json = try #require(html.firstMatch(of: /<script[^>]*>(.*)<\/script>/)?.1)
		#expect(!json.contains("<"))
		#expect(try JSONDecoder().decode([String: String].self, from: Data(json.utf8)) == ["text": text])
	}

	@Test(.temporaryDirectory, arguments: ["png", "jpg"])
	func `media sizes are the pixel sizes of images`(fileExtension: String) throws {
		let file = try URL.temporaryDirectory().appending(path: "image.\(fileExtension)")
		let context = try #require(CGContext(data: nil, width: 30, height: 20, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
		let image = try #require(context.makeImage())
		let type = fileExtension == "png" ? UTType.png : UTType.jpeg
		let destination = try #require(CGImageDestinationCreateWithURL(file as CFURL, type.identifier as CFString, 1, nil))
		CGImageDestinationAddImage(destination, image, nil)
		#expect(CGImageDestinationFinalize(destination))

		let size = try #require(file.mediaSize)
		#expect(size.width == 30)
		#expect(size.height == 20)
		#expect(file.deletingLastPathComponent().appending(path: "missing.png").mediaSize == nil)
	}

}
