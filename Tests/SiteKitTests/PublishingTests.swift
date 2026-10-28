import Elementary
import Foundation
import ImageIO
import SOML
import TestSupport
import Testing
import UniformTypeIdentifiers
@testable import SiteKit

struct PublishingTests {
	private let site = SiteOrigin(#URL("https://example.com"))

	@Test
	func `route outputs render pages redirects and binary files without a publisher`() async throws {
		let page = Route.page(#path("/hello")) { "<p>Héllo</p>" }
		let file = Route.file(#path("/data.bin")) { Data([0, 255, 1]) }
		let redirect = Route.redirect(#path("/old"), to: RedirectDestination.path(#path("/new"), query: [URLQueryItem(name: "q", value: "a+b&c")]))

		#expect(try await page.output.render(site: site) == Data("<p>Héllo</p>".utf8))
		#expect(try await file.output.render(site: site) == Data([0, 255, 1]))
		let html = String(decoding: try await redirect.output.render(site: site), as: UTF8.self)
		#expect(html.contains(#"href="/new?q=a%2Bb%26c""#))
		#expect(html.contains(#"rel="canonical" href="https://example.com/new?q=a%2Bb%26c""#))
	}

	@Test
	func `output rendering preserves failures for the publisher to contextualize`() async {
		let page = Route.page(#path("/broken")) { throw CocoaError(.fileReadCorruptFile) }
		await #expect(throws: CocoaError.self) {
			try await page.output.render(site: site)
		}
	}

	@Test
	func `published assets retain their site path source and exact output file`() {
		let source = URL(filePath: "/project/public/images/logo.png")
		let asset = PublishedAsset(path: #path("/images/logo.png"), source: source)
		#expect(asset.source == source)
		#expect(asset.path == #path("/images/logo.png"))
		#expect(asset.outputFile == PublishedFilePath("images/logo.png"))
	}

	@Test(arguments: IDReferenceAttribute.allCases)
	func `every supported ID reference attribute is checked`(attribute: IDReferenceAttribute) async {
		let html = #"<div \#(attribute.rawValue)="missing"></div>"#
		let routes = [Route.page(.root) { html }]
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])
		let problems = await LinkValidator(site: site).brokenLinks(in: routes, published: published)
		#expect(problems.map(\.problem) == [.missingReference(attribute: attribute, id: "missing")])
		#expect(problems.map(\.link) == [#"\#(attribute.rawValue)="missing""#])
	}

	@Test(arguments: [IDReferenceAttribute.for, .list, .popoverTarget, .commandFor])
	func `single ID reference attributes cannot refer to a whitespace separated list`(attribute: IDReferenceAttribute) async {
		let html = #"<div id="first"></div><div id="second"></div><div \#(attribute.rawValue)="first second"></div>"#
		let routes = [Route.page(.root) { html }]
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])
		let problems = await LinkValidator(site: site).brokenLinks(in: routes, published: published)
		#expect(problems.map(\.link) == [#"\#(attribute.rawValue)="first second""#])
	}

	@Test
	func `served file candidates reject encoded traversal and NUL before reaching the filesystem`() {
		#expect("/a/%2e%2e/private".servedFileCandidates.isEmpty)
		#expect("/a%00b".servedFileCandidates.isEmpty)
		#expect("/a/./b/".servedFileCandidates == [PublishedFilePath("a/b/index.html")])
		#expect("/a%20b".servedFileCandidates == [PublishedFilePath("a b"), PublishedFilePath("a b.html"), PublishedFilePath("a b/index.html")])
	}

	@Test
	func `pixel geometry handles portrait landscape and small source images`() throws {
		let landscape = try #require(PixelSize(width: 2048, height: 1280))
		let portrait = try #require(PixelSize(width: 800, height: 1600))
		let small = try #require(PixelSize(width: 300, height: 200))
		#expect(landscape.displayWidth(maximumHeight: 640) == 1024)
		#expect(landscape.retinaWidth(maximumHeight: 640, maximumWidth: 1024) == 2048)
		#expect(portrait.retinaWidth(maximumHeight: 640, maximumWidth: 1024) == 640)
		#expect(small.displayWidth(maximumHeight: 640) == 300)
		#expect(!small.isSharpOnRetina(maximumHeight: 640, maximumWidth: 1024))
		#expect(landscape.isSharpOnRetina(maximumHeight: 640, maximumWidth: 1024))
		let threshold = try #require(PixelSize(width: 1946, height: 1216))
		#expect(threshold.isSharpOnRetina(maximumHeight: 640, maximumWidth: 1024))
		#expect(!threshold.isSharpOnRetina(maximumHeight: 640, maximumWidth: 1024, tolerance: 1))
	}

	@Test(.timeLimit(.minutes(1)))
	func `asynchronous pipe collection preserves binary output larger than a pipe buffer`() async throws {
		let process = Process()
		process.executableURL = URL(filePath: "/bin/dd")
		process.arguments = ["if=/dev/zero", "bs=65536", "count=2"]
		process.standardError = FileHandle.nullDevice
		let pipe = Pipe()
		process.standardOutput = pipe
		var output = Data()
		let status = try await process.runUntilExit {
			output = try await pipe.fileHandleForReading.readDataToEnd()
		}
		#expect(status == .exit(0))
		#expect(output == Data(repeating: 0, count: 131_072))
	}

	@Test
	func `absolute destinations retain validated URL payloads and support non-HTTP schemes`() throws {
		let absolute = try AbsoluteURL(validating: #URL("mailto:hello@example.com"))
		let destination = LinkDestination.url(absolute)
		#expect(destination.description == "mailto:hello@example.com")
		#expect(destination.absoluteURL(site: site, page: .root) == absolute.value)
		#expect(RedirectDestination.url(absolute).absoluteURL(site: site) == absolute.value)
		#expect(LinkDestination.url(absolute.value) == destination)
	}

	@Test
	func `code-owned absolute destination conveniences reject relative URLs`() async {
		await #expect(processExitsWith: .failure) {
			_ = LinkDestination.url(URL(string: "relative")!)
		}
		await #expect(processExitsWith: .failure) {
			_ = RedirectDestination.url(URL(string: "relative")!)
		}
	}

	@Test(arguments: [ElementID?.none, ElementID("a&b")])
	func `optional attributes omit absent values and keep present values escaped`(id: ElementID?) {
		let html = input(.type(.email))
			.attributes(optional: id.map { .id($0) })
			.attributes(.required)
			.render()

		#expect(html == (id == nil ? #"<input type="email" required>"# : #"<input type="email" id="a&amp;b" required>"#))
	}

	@Test(arguments: ["", "two ids", "a\tb", "a\nb", "a\rb", "a\u{C}b", " \u{301}"])
	func `element IDs reject empty text and ASCII whitespace`(text: String) {
		#expect(throws: ContentError.self) {
			try ElementID(validating: text)
		}
	}

	@Test(arguments: ["1.2.0", "a&b", "a%20b", "æøå", "a\u{A0}b"])
	func `element IDs preserve valid opaque tokens`(text: String) throws {
		#expect(try ElementID(validating: text) == ElementID(text))
		#expect(ElementID(text).rawValue == text)
	}

	@Test
	func `invalid code-owned element IDs stop the build`() async {
		await #expect(processExitsWith: .failure) {
			_ = ElementID("two ids")
		}
	}

	@Test(arguments: [
		"file:///tmp/site",
		"ftp://example.com",
		"https://user@example.com",
		"https://user:password@example.com",
		"https://example.com/prefix",
		"https://example.com/?query=value",
		"https://example.com/#fragment",
		"https://example.com/?",
		"https://example.com/#",
	])
	func `site origins reject URLs that are not root HTTP origins`(value: String) throws {
		let url = try #require(URL(string: value))
		#expect(throws: ContentError.self) {
			try SiteOrigin(validating: url)
		}
	}

	@Test
	func `site origins normalize root slashes and preserve ports in route URLs`() throws {
		let origin = try SiteOrigin(validating: #URL("https://EXAMPLE.com:8443/"))
		#expect(origin == SiteOrigin(#URL("https://example.com:8443")))
		#expect(RoutePath.root.absoluteURL(site: origin).absoluteString == "https://example.com:8443/")
		#expect(LinkDestination.path(#path("/apps"), query: [URLQueryItem(name: "name", value: "a+b")], fragment: "details").absoluteURL(site: origin, page: .root).absoluteString == "https://example.com:8443/apps?name=a%2Bb#details")
	}

	@Test
	func `typed element IDs retain their values in labels ARIA references popovers and JSON scripts`() {
		let control = ElementID("email")
		let hint = ElementID("email-hint")
		let error = ElementID("email-error")
		let popover = ElementID("details")
		let suggestions = ElementID("email&suggestions")
		let labelHTML = label(.for(control)) {
			"Email"
		}.render()
		let buttonHTML = button(.popoverTarget(popover)) {
			"Details"
		}.render()
		let escapedLabelHTML = label(.for(ElementID("a&b"))) {
			"Label"
		}.render()

		#expect(labelHTML == #"<label for="email">Email</label>"#)
		#expect(input(.id(control), .list(id: suggestions), .ariaDescribedBy(hint, error), .ariaLabelledBy(hint, error), .ariaControls(popover, suggestions)).render() == #"<input id="email" list="email&amp;suggestions" aria-describedby="email-hint email-error" aria-labelledby="email-hint email-error" aria-controls="details email&amp;suggestions">"#)
		#expect(buttonHTML == #"<button popovertarget="details">Details</button>"#)
		#expect(escapedLabelHTML == #"<label for="a&amp;b">Label</label>"#)
		#expect(LinkDestination.fragment(control).description == "#email")
		#expect(JSONScript(id: ElementID("data"), ["value": 1]).render() == #"<script type="application/json" id="data">{"value":1}</script>"#)
		#expect("#\(control)" == "#email")
	}

	@Test(.temporaryDirectory)
	func `a JPEG XL copy of an image is made once and then read from the cache`() async throws {
		let directory = try URL.temporaryDirectory()
		let image = directory.appending(path: "image.png")
		let context = try #require(CGContext(
			data: nil,
			width: 256,
			height: 256,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: CGColorSpace(name: CGColorSpace.sRGB)!,
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		))

		// Stripes, so the image has some detail.
		for row in 0..<256 {
			context.setFillColor(
				red: Double(row) / 255,
				green: 0.5,
				blue: 1 - Double(row) / 255,
				alpha: 1
			)
			context.fill(
				CGRect(
					x: 0,
					y: row,
					width: 256,
					height: 1
				)
			)
		}

		let destination = try #require(CGImageDestinationCreateWithURL(
			image as CFURL,
			UTType.png.identifier as CFString,
			1,
			nil
		))
		CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
		#expect(CGImageDestinationFinalize(destination))

		let cache = directory.appending(path: "cache")
		let copy = try #require(try await image.jpegXLVersion(cacheDirectory: cache))
		let signature = try Data(contentsOf: copy).prefix(2)

		// A JPEG XL codestream starts with `FF 0A`, and the container with a box of 12 bytes.
		#expect(signature == Data([0xFF, 0x0A]) || signature == Data([0x00, 0x00]))
		#expect(try copy.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? .max < image.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
		#expect(try await image.jpegXLVersion(cacheDirectory: cache) == copy)
	}

	@Test
	func `route paths drop extra slashes, and compare and append whole components`() throws {
		#expect(RoutePath("/apps/") == #path("/apps"))
		// All trailing slashes, as a path with one left, like `/old/`, writes a hidden file, `old/.html`.
		#expect(RoutePath("/old//") == #path("/old"))

		// Repeated slashes inside, as `/blog//post` writes the same file as `/blog/post`, and `//example.com` in a link goes to another host.
		#expect(RoutePath("/blog//post") == #path("/blog/post"))
		#expect(try RoutePath(validating: "//example.com") == #path("/example.com"))
		#expect(RoutePath("//") == .root)
		#expect(Route.redirect(RoutePath("/old//"), to: .root).outputFile == "old.html")
		#expect(RoutePath("/blog/post").starts(with: #path("/blog")))
		#expect(RoutePath("/blog").starts(with: #path("/blog")))
		#expect(!RoutePath("/blogroll").starts(with: #path("/blog")))
		#expect(RoutePath("/apps").starts(with: .root))
		#expect(RoutePath.root.appending("blog").appending("post") == #path("/blog/post"))
		#expect(RoutePath.root.appending(path: "blog/post") == #path("/blog/post"))
		#expect(RoutePath("/blog").appending(path: "/post//images/") == #path("/blog/post/images"))
		#expect(RoutePath("/blog").appending(path: "") == #path("/blog"))
		#expect(RoutePath.root.appending(path: "/") == .root)
	}

	@Test
	func `the rest of a route path after another path`() {
		#expect(RoutePath("/blog/post/image.png").relative(to: #path("/blog")) == "post/image.png")
		#expect(RoutePath("/dato/icon.png").relative(to: .root) == "dato/icon.png")
		#expect(RoutePath("/blog").relative(to: #path("/blog")) == "")
		#expect(RoutePath.root.relative(to: .root) == "")
		#expect(RoutePath("/blogroll").relative(to: #path("/blog")) == nil)
	}

	@Test
	func `a route path with another extension changes only its last component`() {
		#expect(RoutePath("/dato/screenshot1.png").replacingPathExtension("jxl") == #path("/dato/screenshot1.jxl"))
		#expect(RoutePath("/v1.0/file").replacingPathExtension("jxl") == #path("/v1.0/file.jxl"))
		#expect(RoutePath("/a.tar.gz").replacingPathExtension("zip") == #path("/a.tar.zip"))
		#expect(RoutePath("/.htaccess").replacingPathExtension("txt") == #path("/.htaccess.txt"))
	}

	@Test(arguments: [
		(Route.page(.root) { "" }, "index.html"),
		(Route.page(#path("/apps")) { "" }, "apps.html"),
		(Route.page(RoutePath("/apps/")) { "" }, "apps.html"),
		(Route.page(#path("/blog/macos-13.1")) { "" }, "blog/macos-13.1.html"),
		(Route.redirect(#path("/v1.0"), to: .root), "v1.0.html"),
		(Route.text(#path("/dato/rss.xml")) { "" }, "dato/rss.xml"),
	])
	func `the route kind decides the output file`(route: Route, outputFile: String) {
		#expect(route.outputFile == PublishedFilePath(outputFile))
	}

	@Test(arguments: ["", "/index.html", "a/", "a//b", ".", "..", "a/../b", "a/./b", "a\0b"])
	func `published file paths reject absolute empty and traversing paths`(path: String) {
		#expect(throws: ContentError.self) {
			try PublishedFilePath(validating: path)
		}
	}

	@Test(arguments: ["index.html", ".nojekyll", "blog/a.b.html", "images/100% ready #1.png", "æøå.txt"])
	func `published file paths preserve relative filenames when resolving their URL`(path: String) throws {
		let file = try PublishedFilePath(validating: path)
		let directory = URL(filePath: "/site")

		#expect(file.description == path)
		#expect(file.fileURL(in: directory).path(percentEncoded: false) == "/site/\(path)")
		#expect(file == PublishedFilePath(path))
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
		#expect(LinkDestination.path(#path("/dato/release-notes"), fragment: "1.2.0").absoluteURL(site: site, page: #path("/other")).absoluteString == "https://example.com/dato/release-notes#1.2.0")
	}

	@Test
	func `link destinations encode their query, also a plus, which forms read as a space`() {
		let destination = LinkDestination.path(.root.appending("feedback"), query: [URLQueryItem(name: "product", value: "A & B+C")], fragment: "form")

		#expect(destination.description == "/feedback?product=A%20%26%20B%2BC#form")
		#expect(destination.absoluteURL(site: site, page: #path("/other")).absoluteString == "https://example.com/feedback?product=A%20%26%20B%2BC#form")
	}

	@Test(arguments: [RoutePath.root, #path("/apps/dato")])
	func `fragment destinations resolve against the current page`(page: RoutePath) {
		let destination = LinkDestination.fragment("some section")
		#expect(destination.absoluteURL(site: site, page: page).absoluteString == "\(page.absoluteURL(site: site).absoluteString)#some%20section")
		#expect(LinkDestination.url(#URL("https://elsewhere.com/post?q=a+b#section")).absoluteURL(site: site, page: page).absoluteString == "https://elsewhere.com/post?q=a+b#section")
	}

	@Test(arguments: [
		("", ""),
		("some section", "some%20section"),
		("100%", "100%25"),
		("literal%20text", "literal%2520text"),
		("æøå", "%C3%A6%C3%B8%C3%A5"),
		("a#b", "a%23b"),
	])
	func `fragment values are decoded text and encode once when serialized`(fragment: String, encoded: String) throws {
		let local = LinkDestination.fragment(fragment)
		let otherPage = LinkDestination.path(#path("/other"), fragment: fragment)

		#expect(local.description == "#\(encoded)")
		#expect(otherPage.description == "/other#\(encoded)")
		#expect(try LinkDestination(validating: local.description) == local)
		#expect(try LinkDestination(validating: otherPage.description) == otherPage)
		#expect(local.absoluteURL(site: site, page: #path("/current")).absoluteString == "https://example.com/current#\(encoded)")
		#expect(otherPage.absoluteURL(site: site, page: .root).absoluteString == "https://example.com/other#\(encoded)")
		#expect(try JSONEncoder().encode(local) == JSONEncoder().encode("#\(encoded)"))
	}

	@Test(arguments: ["literal%20text", "æøå", "a#b"])
	func `serialized typed fragments resolve to the exact element ID`(text: String) async throws {
		let id = try ElementID(validating: text)
		let html = div {
			span(.id(id)) {
				"Section"
			}
			a(.href(.fragment(id))) {
				"Open section"
			}
		}.render()
		let routes = [Route.page(.root) { html }]
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
	}

	@Test
	func `absent fragments stay distinct from empty fragments`() throws {
		#expect(LinkDestination.fragment("").description == "#")
		#expect(LinkDestination.path(#path("/other"), fragment: "").description == "/other#")
		#expect(LinkDestination.path(#path("/other")).description == "/other")
		#expect(try LinkDestination(validating: "/other#") == .path(#path("/other"), fragment: ""))
		#expect(try LinkDestination(validating: "#") == .fragment(""))
	}

	@Test
	func `redirect destinations retain their site paths and encoded queries`() {
		let destination = RedirectDestination.path(#path("/feedback"), query: [URLQueryItem(name: "product", value: "A & B+C")])
		#expect(destination.absoluteURL(site: site).absoluteString == "https://example.com/feedback?product=A%20%26%20B%2BC")
	}

	@Test
	func `a path from content keeps its query and fragment out of the route path`() throws {
		#expect(try LinkDestination(validating: "/apps/faq#refund") == .path(#path("/apps/faq"), fragment: "refund"))
		#expect(try LinkDestination(validating: "/feedback?product=Dato") == .path(#path("/feedback"), query: [URLQueryItem(name: "product", value: "Dato")]))
		#expect(try LinkDestination(validating: "#faq") == .fragment("faq"))
		#expect(try LinkDestination(validating: "/a#a%20b").description == "/a#a%20b")
		#expect(try LinkDestination(validating: "mailto:a@example.com") == .url(#URL("mailto:a@example.com")))
		#expect(throws: ContentError.self) {
			try LinkDestination(validating: "apps/faq")
		}
	}

	@Test(.temporaryDirectory)
	func `publishes routes, assets, redirects, and the sitemap`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "User-agent: *"])
		let output = project.root.appending(path: "dist")

		let image = #URL("https://example.com/a.png")

		try await Publisher(site: site, project: project, output: output).publish(
			[
				.page(#path("/")) { "<a href=\"/about\">About</a>" },
				.page(#path("/about"), sitemapEntry: SitemapEntry(images: [image])) { "<h1 id=\"top\">About</h1>" },
				.page(#path("/hidden"), sitemapEntry: nil) { "Hidden" },
				.text(#path("/feed.xml")) { "<rss/>" },
				.redirect(#path("/old"), to: #path("/about")),
			]
		)

		#expect(try String(contentsOf: output.appending(path: "about.html"), encoding: .utf8) == "<h1 id=\"top\">About</h1>")
		#expect(output.appending(path: "robots.txt").exists)
		#expect(try String(contentsOf: output.appending(path: "old.html"), encoding: .utf8).contains(#"<link rel="canonical" href="https://example.com/about">"#))

		let sitemap = try String(contentsOf: output.appending(path: "sitemap-0.xml"), encoding: .utf8)
		#expect(sitemap.contains("<url><loc>https://example.com/</loc></url><url><loc>https://example.com/about</loc><image:image><image:loc>https://example.com/a.png</image:loc></image:image></url></urlset>"))
	}

	@Test
	func `a link from content cannot go to another host, and a plus in its query stays a plus`() throws {
		// `//example.com` is a link to another host, not a path of the site.
		#expect(throws: ContentError.self) {
			try LinkDestination(validating: "//example.com/a")
		}

		#expect(throws: ContentError.self) {
			try LinkDestination(validating: "example.com")
		}

		#expect(throws: ContentError.self) {
			try RoutePath(validating: "apps")
		}

		#expect(try LinkDestination(validating: "/feedback?product=A+B").description == "/feedback?product=A%2BB")
	}

	@Test
	func `links and paths encode as the text of an href, for scripts`() throws {
		let data = try JSONEncoder().encode(["link": LinkDestination.path(#path("/apps/faq"), fragment: "refund"), "fragment": .fragment("top")])
		#expect(try JSONDecoder().decode([String: String].self, from: data) == ["link": "/apps/faq#refund", "fragment": "#top"])
		#expect(try JSONDecoder().decode([String].self, from: JSONEncoder().encode([RoutePath("/apps/")])) == ["/apps"])
	}

	@Test(.temporaryDirectory)
	func `a redirect page escapes its destination, and search engines do not index it`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let destination = RedirectDestination.path(#path("/feedback"), query: [URLQueryItem(name: "product", value: "A"), URLQueryItem(name: "referrer", value: "B")])

		try await Publisher(site: site, project: project, output: output).publish([
			.page(#path("/feedback")) { "" },
			// A path with a query, passed to the redirect factory, for the escaping.
			Route.redirect(#path("/old"), to: destination),
			.redirect(#path("/elsewhere"), to: #URL("https://elsewhere.com/a?b=1&c=2")),
		])

		let html = try String(contentsOf: output.appending(path: "old.html"), encoding: .utf8)
		#expect(html.contains(#"<meta name="robots" content="noindex">"#))
		#expect(html.contains(#"<meta http-equiv="refresh" content="0; url=/feedback?product=A&amp;referrer=B">"#))
		#expect(html.contains(#"<link rel="canonical" href="https://example.com/feedback?product=A&amp;referrer=B">"#))
		#expect(html.contains(#"<a href="/feedback?product=A&amp;referrer=B">"#))
		#expect(!html.contains("&referrer"))

		let external = try String(contentsOf: output.appending(path: "elsewhere.html"), encoding: .utf8)
		#expect(external.contains(#"<link rel="canonical" href="https://elsewhere.com/a?b=1&amp;c=2">"#))
		#expect(external.contains(#"content="0; url=https://elsewhere.com/a?b=1&amp;c=2""#))
	}

	@Test(.temporaryDirectory)
	func `the sitemap has the day of the last change in UTC, and its index points to it`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		// The next day in time zones east of UTC, like in Norway.
		let lastModified = try Date("2024-06-05T23:30:00Z", strategy: .iso8601)

		try await Publisher(site: site, project: project, output: output).publish(
			[
				.page(#path("/b"), sitemapEntry: SitemapEntry(lastModified: SOML.Date(lastModified))) { "" },
				.page(#path("/a")) { "" },
			]
		)

		let sitemap = try String(contentsOf: output.appending(path: "sitemap-0.xml"), encoding: .utf8)
		#expect(sitemap.contains("<url><loc>https://example.com/a</loc></url><url><loc>https://example.com/b</loc><lastmod>2024-06-05</lastmod></url>"))

		let index = try String(contentsOf: output.appending(path: "sitemap-index.xml"), encoding: .utf8)
		#expect(index.contains("<sitemap><loc>https://example.com/sitemap-0.xml</loc></sitemap>"))
	}

	@Test
	func `bytes become lowercase hexadecimal digits`() {
		#expect([0, 10, 255].hexString == "000aff")
		#expect([UInt8]().hexString == "")
	}

	@Test
	func `straight quotes become typographic quotes`() {
		#expect(#"She said "it's fine" ('really')."#.typographicQuotes == "She said “it’s fine” (‘really’).")
		#expect(#""Great app""#.typographicQuotes == "“Great app”")
		#expect(#""'Nested'" quotes"#.typographicQuotes == "“‘Nested’” quotes")
		#expect("Typographic “quotes” stay".typographicQuotes == "Typographic “quotes” stay")
	}

	/**
	The class names of element styles and seeded shuffles, like the puzzles of Appdle, come from the hash, so a different hash in another process would change the output of every build.
	*/
	@Test
	func `the stable hash is FNV-1a`() {
		#expect("".stableHash == 0xCBF2_9CE4_8422_2325)
		#expect("a".stableHash == 0xAF63_DC4C_8601_EC8C)
		#expect("foobar".stableHash == 0x8594_4171_F739_67E8)
	}

	@Test(.temporaryDirectory)
	func `publishing again only writes changes and removes stale files`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": "User-agent: *"])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)

		try await publisher.publish([.page(#path("/a")) { "A" }, .page(#path("/b/c")) { "C" }])
		let date = try output.appending(path: "a.html").resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
		try await Task.sleep(for: .milliseconds(20))

		try await publisher.publish([.page(#path("/a")) { "A" }])

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
		#expect(publishingError.description == "Could not read or write a file: The directory “\(project.publicDirectory.path(percentEncoded: false))” does not exist.")
	}

	@Test(.temporaryDirectory)
	func `publishing returns the content of the file of each route, without the public files`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let published = try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([.page(#path("/a")) { "A" }])

		#expect(published.routeFiles["a.html"] == Data("A".utf8))
		#expect(published.routeFiles["robots.txt"] == nil)
		#expect(published.files.isSuperset(of: ["a.html", "robots.txt"]))
	}

	@Test(.temporaryDirectory)
	func `link validation uses the published snapshot after the output changes`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)
		let routes: [Route] = [
			.page(.root) { #"<a href="/about#present">Present</a><a href="/about#missing">Missing</a><a href="/robots.txt">Robots</a>"# },
			.page(#path("/about")) { #"<h1 id="present">About</h1>"# },
		]
		let published = try await publisher.publish(routes)

		// A later build removes the original target page and changes the HTML of the referring page.
		try await publisher.publish([.page(.root) { "New build" }])

		let brokenLinks = await LinkValidator(site: site).brokenLinks(in: routes, published: published)
		#expect(brokenLinks.map(\.description) == ["/: /about#missing (missing fragment)"])
	}

	@Test(.temporaryDirectory)
	func `served files resolve like GitHub Pages and stay inside the directory`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		try await Publisher(site: site, project: project, output: output).publish([.page(#path("/")) { "" }, .page(#path("/blog")) { "" }, .page(#path("/blog/post")) { "" }])
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

		#expect(project.publicDirectory.appending(path: "robots.txt").exists)
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
			try await Publisher(site: site, project: project, output: output).publish([.page(#path("/a")) { "A" }])
		}

		#expect(project.publicDirectory.appending(path: "robots.txt").exists)
	}

	@Test(.temporaryDirectory)
	func `refuses a symlink to the project as the output directory`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let link = try URL.temporaryDirectory().appending(path: "site-link")
		try FileManager.default.createSymbolicLink(at: link, withDestinationURL: project.root)

		await #expect(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: URL(filePath: link.path(percentEncoded: false), directoryHint: .isDirectory)).publish([.page(#path("/a")) { "A" }])
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
		let published = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
	}

	/**
	An `id` is literal text, so `a%20b` is the ID itself. Only the fragment of a link is percent-decoded, so `#a%2520b` links to it.
	*/
	@Test(.temporaryDirectory)
	func `an ID with a percent sign is compared as written`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let routes: [Route] = [.page(.root) { ##"<label for="a%20b">A</label><input id="a%20b"> <a href="#a%2520b">Field</a>"## }]
		let published = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
	}

	/**
	Only the directories of the path are resolved, as resolving the symlink itself gives the path of its target, which can be outside the public directory.
	*/
	@Test(.temporaryDirectory)
	func `a symlinked public file keeps its path`() throws {
		let outside = try URL.temporaryDirectory(files: ["font.woff2": "font"])
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let fonts = project.publicDirectory.appending(path: "fonts")
		try fonts.createDirectory()
		try FileManager.default.createSymbolicLink(at: fonts.appending(path: "font.woff2"), withDestinationURL: outside.appending(path: "font.woff2"))

		#expect(try project.publicFiles().map(\.path).contains(#path("/fonts/font.woff2")))
	}

	/**
	A browser scrolls to the top for `#top` when no element has that ID, like the empty fragment.
	*/
	@Test(.temporaryDirectory)
	func `a link to the top fragment is not broken`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")
		let routes: [Route] = [.page(.root) { ##"<a href="#top">Top</a> <a href="/#TOP">Top</a>"## }]
		let published = try await Publisher(site: site, project: project, output: output).publish(routes)

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
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
		#expect(try String(contentsOf: output.appending(path: "font.woff2"), encoding: .utf8) == "font")
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
		#expect(try String(contentsOf: output.appending(path: "font.woff2"), encoding: .utf8) == "font")
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

		#expect(try project.publicFiles().map(\.path).contains(#path("/apps/dato/icon.png")))
		#expect(project.publicPath(ofContentFile: link) == #path("/apps/dato/icon.png"))
	}

	@Test(.temporaryDirectory)
	func `rejects routes that write the same file`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let publisher = Publisher(site: site, project: project, output: project.root.appending(path: "dist"))

		await #expect(throws: PublishingError.self) {
			try await publisher.publish([.page(#path("/a")) { "" }, .text(#path("/a.html")) { "" }])
		}

		await #expect(throws: PublishingError.self) {
			try await publisher.publish([.text(#path("/robots.txt")) { "" }])
		}
	}

	@Test(.temporaryDirectory)
	func `finds broken links and fragments`() async throws {
		let project = try makeProject(publicFiles: ["image.png": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page(#path("/")) {
				#"<a href="/about">Fine</a> <a href="/about#top">Fine</a> <img src="/image.png"> <a href="https://example.com/about">Fine</a> <a href="https://elsewhere.com/missing">External</a> <a href="/missing">Broken</a> <a href="/about#missing">Broken</a> <a href="/about/">Broken</a> <div data-id="missing"></div>"#
			},
			.page(#path("/about")) { ##"<h1 id="top">About</h1> <a href="#top">Fine</a> <a href="#nope">Broken</a> <p id="top">Duplicate</p> <meta property="og:image" content="https://example.com/missing.png">"## },
		]

		let published = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = await LinkValidator(site: site).brokenLinks(in: routes, published: published)

		#expect(brokenLinks.map(\.description) == [
			"/: /about#missing (missing fragment)",
			"/: /about/",
			"/: /missing",
			"/about: #nope (missing fragment)",
			"/about: #top (duplicate ID)",
			"/about: https://example.com/missing.png",
		])
	}

	@Test
	func `ID references preserve nonbreaking spaces within a valid element ID`() async throws {
		let identifier = try ElementID(validating: "a\u{A0}b")
		let description = ElementID("description")
		let html = div {
			span(.id(identifier)) {
				"Title"
			}
			span(.id(description)) {
				"Description"
			}
			button(.ariaLabelledBy(identifier), .ariaDescribedBy(identifier, description)) {
				"Action"
			}
		}.render()
		let routes = [Route.page(.root) {
			html
		}]
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
	}

	@Test(arguments: ["\t", "\n", "\r", "\u{C}"])
	func `ID references split on ASCII whitespace`(separator: String) async {
		let html = #"<div><span id="a"></span><span id="b"></span><button aria-describedby="a\#(separator)b">Action</button></div>"#
		let routes = [Route.page(.root) {
			html
		}]
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])

		#expect(await LinkValidator(site: site).brokenLinks(in: routes, published: published).isEmpty)
	}

	@Test(.temporaryDirectory)
	func `finds references to IDs that are not on the page`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page(#path("/")) {
				#"<dialog aria-labelledby="title" aria-describedby="text missing-text"><h2 id="title">Title</h2><p id="text">Text</p></dialog> <label for="name">Name</label> <input id="name" list="missing-list"> <button popovertarget="menu">Menu</button> <span aria-label="Fine" data-for="ignored"></span>"#
			},
		]

		let published = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = await LinkValidator(site: site).brokenLinks(in: routes, published: published)

		#expect(brokenLinks.map(\.description) == [
			#"/: aria-describedby="missing-text" (missing ID)"#,
			#"/: list="missing-list" (missing ID)"#,
			#"/: popovertarget="menu" (missing ID)"#,
		])
	}

	/**
	The quotes of text are not escaped, so an HTML code sample has text that looks like attributes.
	*/
	@Test(.temporaryDirectory)
	func `the text of code blocks is not checked, but the attributes of the code block are`() async throws {
		let project = try makeProject(publicFiles: ["robots.txt": ""])
		let output = project.root.appending(path: "dist")

		let routes: [Route] = [
			.page(#path("/")) {
				##"<pre id="sample" tabindex="0"><code>&lt;a href="/missing"&gt;&lt;p id="sample" aria-labelledby="nope"&gt;</code></pre> <a href="#sample">Fine</a> <pre aria-labelledby="missing-label">Text</pre>"##
			},
		]

		let published = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = await LinkValidator(site: site).brokenLinks(in: routes, published: published)

		#expect(brokenLinks.map(\.description) == [
			#"/: aria-labelledby="missing-label" (missing ID)"#,
		])
	}

	@Test(.temporaryDirectory)
	func `the files of page bundles are published at their path in the content directory`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/robots.txt": "",
					"content/apps/dato/index.md": "Dato",
					"content/apps/dato/icon.png": "icon",
					"content/apps/dato/notes.md": "",
					"content/spelling.txt": "",
				]
			)
		)
		let output = project.root.appending(path: "dist")

		let files = try await Publisher(site: site, project: project, output: output).publish([.page(#path("/apps/dato")) { "" }]).files

		#expect(files.isSuperset(of: ["robots.txt", "apps/dato/icon.png"]))
		#expect(!files.contains("apps/dato/index.md"))
		#expect(!files.contains("apps/dato/notes.md"))
		#expect(!files.contains("spelling.txt"))
		#expect(try String(contentsOf: output.appending(path: "apps/dato/icon.png"), encoding: .utf8) == "icon")
		#expect(project.publicFile(#path("/apps/dato/icon.png")) == project.contentDirectory.appending(path: "apps/dato/icon.png"))
		#expect(project.publicFile(#path("/robots.txt")) == project.publicDirectory.appending(path: "robots.txt"))
	}

	/**
	A content directory with a page route publishes the files of its page bundles next to the pages, like `/dato/icon.png` for apps at `/dato`, and finds them by that path. A page can still be a single Markdown file.
	*/
	@Test(.temporaryDirectory)
	func `the files of page bundles are published next to their pages`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/robots.txt": "",
					"content/apps/dato/index.md": "Dato",
					"content/apps/dato/icon.png": "icon",
					"content/apps/gifski.md": "Gifski",
					"content/blog/post/index.md": "Post",
					"content/blog/post/image.png": "image",
					"content/blog/other.md": "Other",
				]
			),
			pageRoutes: ["content/apps": .root, "content/blog": #path("/blog")]
		)
		let output = project.root.appending(path: "dist")

		let files = try await Publisher(site: site, project: project, output: output).publish([.page(#path("/dato")) { "" }, .page(#path("/blog/post")) { "" }]).files

		#expect(files.isSuperset(of: ["robots.txt", "dato/icon.png", "blog/post/image.png"]))
		#expect(!files.contains("apps/dato/icon.png"))
		#expect(project.publicFile(#path("/dato/icon.png")) == project.contentDirectory.appending(path: "apps/dato/icon.png"))
		#expect(project.publicFile(#path("/dato")) == project.contentDirectory.appending(path: "apps/dato"))
		#expect(project.publicFile(#path("/blog/post/image.png")) == project.contentDirectory.appending(path: "blog/post/image.png"))
		// The old path, at the content directory, is not published, so it is not found.
		#expect(project.publicFile(#path("/apps/dato/icon.png")) == project.publicDirectory.appending(path: "apps/dato/icon.png"))
		#expect(project.publicPath(ofContentFile: project.contentDirectory.appending(path: "blog/post/image.png")) == #path("/blog/post/image.png"))
	}

	/**
	A draft has no page, so the images of an app before its launch are not published either.
	*/
	@Test(.temporaryDirectory)
	func `the files of a page bundle without a page are not published`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/robots.txt": "",
					"content/apps/draft/index.md": "Draft",
					"content/apps/draft/icon.png": "icon",
				]
			),
			pageRoutes: ["content/apps": .root]
		)

		let files = try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([]).files

		#expect(files.contains("robots.txt"))
		#expect(!files.contains("draft/icon.png"))
	}

	@Test(.temporaryDirectory)
	func `a public file and a page bundle file with the same path are a collision`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/apps/dato/icon.png": "",
					"content/apps/dato/index.md": "",
					"content/apps/dato/icon.png": "",
				]
			)
		)

		await #expect(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([.page(#path("/apps/dato")) { "" }])
		}
	}

	/**
	A redirect is often a key in the frontmatter of another file, so the message names both files, relative to the project, also when the build runs in another directory.
	*/
	@Test(.temporaryDirectory)
	func `a collision names where each route comes from`() async throws {
		let project = try Project(root: URL.temporaryDirectory(files: ["public/robots.txt": ""]))
		let routes = [
			Route.redirect(#path("/lungo"), to: #path("/dato")).source("`redirectFrom` of", .file(project.root.appending(path: "content/apps/dato/index.md"))),
			Route.page(#path("/lungo")) { "" }.source("the page of", .file(project.root.appending(path: "content/apps/lungo/index.md"))),
		]

		let error = try await #require(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish(routes)
		}

		#expect(error.description == "Two sources write lungo.html: `redirectFrom` of content/apps/dato/index.md and the page of content/apps/lungo/index.md. Change one of them.")
	}

	@Test(.temporaryDirectory)
	func `a redirect that a page file shadows names both sources`() async throws {
		let project = try Project(root: URL.temporaryDirectory(files: ["public/robots.txt": ""]))
		let routes = [
			Route.page(#path("/dato")) { "" }.source("the page of", .file(project.root.appending(path: "content/apps/dato/index.md"))),
			Route.redirect(#path("/dato.html"), to: #path("/dato")).source("`redirectFrom` of", .file(project.root.appending(path: "content/apps/dato/index.md"), line: 12)),
		]

		let error = try await #require(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish(routes)
		}

		#expect(error.description == "The URL /dato.html of `redirectFrom` of content/apps/dato/index.md:12 is also served from dato.html, the page of content/apps/dato/index.md, so the host may serve that file instead. Change one of them.")
	}

	@Test(arguments: ["/../escape", "/a/./b", "/a/../../b"])
	func `link destinations validate their route paths`(path: String) {
		#expect(throws: ContentError.self) {
			try LinkDestination(validating: path)
		}
	}

	@Test(arguments: ["/a b", "/a?b", "/a%20b"])
	func `route paths reject characters that a link must encode`(path: String) {
		#expect(throws: ContentError.self) {
			try RoutePath(validating: path)
		}
	}

	@Test(.temporaryDirectory)
	func `a public file at the path of a page shadows it`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/apps": "",
				]
			)
		)

		do {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([.page(#path("/apps")) { "Apps" }])
			Issue.record("The publisher accepted a file that answers the URL of a page.")
		} catch {
			#expect("\(error)" == "The URL /apps of the route /apps is also served from apps, the file public/apps, so the host may serve that file instead. Change one of them.")
		}
	}

	@Test(.temporaryDirectory)
	func `a public file with a space in its name is published`() async throws {
		// A screenshot has a space in its name, which is fine in a file name and encoded in the link.
		let file = "Screenshot 2026-10-21 at 10.00.00.png"
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/\(file)": "",
				]
			)
		)

		let files = try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([]).files
		#expect(files.contains(PublishedFilePath(file)))
	}

	@Test(.temporaryDirectory)
	func `a file at the path with index.html does not shadow the page`() async throws {
		// `/feedback` is served from `feedback.html`, so a page of a file at `/feedback/` is a different URL.
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/feedback/index.html": "",
				]
			)
		)

		let files = try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([.page(#path("/feedback")) { "Feedback" }]).files
		#expect(files.contains("feedback.html"))
	}

	@Test(.temporaryDirectory)
	func `refuses to publish into a git checkout`() async throws {
		let project = try Project(
			root: URL.temporaryDirectory(
				files: [
					"public/robots.txt": "",
					"dist/.git/HEAD": "",
				]
			)
		)

		let error = try await #require(throws: PublishingError.self) {
			try await Publisher(site: site, project: project, output: project.root.appending(path: "dist")).publish([.page(#path("/")) { "Home" }])
		}

		guard case .repositoryOutput = error else {
			Issue.record("Expected a repository output error, got \(error)")
			return
		}
	}

	@Test
	func `form queries round trip special characters without inventing parameters`() throws {
		let query = "Swift + C# & Rust? a=b"
		let items = [URLQueryItem(name: "q", value: query)]
		let url = #URL("https://example.com/search").appending(formQueryItems: items)
		let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
		#expect(components.queryItems == items)
		#expect(!items.formEncodedQuery.contains("+"))
		#expect(url.absoluteString.contains("%2B"))
		#expect(#URL("https://example.com").appending(formQueryItems: []) == #URL("https://example.com"))
	}

	@Test
	func `form queries keep the query that the URL already has`() {
		let url = #URL("https://example.com/search?q=a+b#top").appending(formQueryItems: [URLQueryItem(name: "tag", value: "c+d")])
		#expect(url.absoluteString == "https://example.com/search?q=a+b&tag=c%2Bd#top")
	}

	@Test(.temporaryDirectory)
	func `served files cannot follow symlinks outside the site`() throws {
		let outside = try URL.temporaryDirectory(files: ["secret.txt": "private"])
		let output = try URL.temporaryDirectory(files: ["index.html": "Home"])
		try FileManager.default.createSymbolicLink(at: output.appending(path: "secret.txt"), withDestinationURL: outside.appending(path: "secret.txt"))
		try FileManager.default.createSymbolicLink(at: output.appending(path: "escape"), withDestinationURL: outside)
		#expect(output.servedFile(forPath: "/secret.txt") == nil)
		#expect(output.servedFile(forPath: "/escape/secret.txt") == nil)
		#expect(output.servedFile(forPath: "/") != nil)
	}

	@Test(.temporaryDirectory)
	func `publishing removes output symlinks without modifying their targets`() async throws {
		let project = try makeProject(publicFiles: ["asset.txt": "Asset"])
		let outside = try URL.temporaryDirectory(files: ["keep.txt": "Keep", "index.html": "Private"])
		let output = try URL.temporaryDirectory(files: ["old.txt": "Old"])
		try FileManager.default.createSymbolicLink(at: output.appending(path: "nested"), withDestinationURL: outside)
		try FileManager.default.createSymbolicLink(at: output.appending(path: "index.html"), withDestinationURL: outside.appending(path: "index.html"))
		try await Publisher(site: site, project: project, output: output).publish([.page(.root) { "Home" }, .page(#path("/nested/new")) { "New" }])
		#expect(try String(contentsOf: outside.appending(path: "keep.txt"), encoding: .utf8) == "Keep")
		#expect(try String(contentsOf: outside.appending(path: "index.html"), encoding: .utf8) == "Private")
		#expect(!outside.appending(path: "new.html").exists)
		#expect(try String(contentsOf: output.appending(path: "nested/new.html"), encoding: .utf8) == "New")
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

		try await publisher.publish([.page(#path("/a")) { "A" }])
		try Data("v2, longer".utf8).write(to: source)
		try await publisher.publish([.page(#path("/a")) { "A" }])
		#expect(try String(contentsOf: output.appending(path: "robots.txt"), encoding: .utf8) == "v2, longer")

		try source.removeIfExists()
		try await publisher.publish([.page(#path("/a")) { "A" }])
		#expect(!output.appending(path: "robots.txt").exists)
	}

	@Test(.temporaryDirectory)
	func `a public file renamed only in case is published with the new name`() async throws {
		let project = try makeProject(publicFiles: ["Logo.txt": "Logo"])
		let output = project.root.appending(path: "dist")
		let publisher = Publisher(site: site, project: project, output: output)

		try await publisher.publish([.page(#path("/a")) { "A" }])
		try FileManager.default.moveItem(at: project.publicDirectory.appending(path: "Logo.txt"), to: project.publicDirectory.appending(path: "logo.txt"))
		try await publisher.publish([.page(#path("/a")) { "A" }])

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
			.page(#path("/")) { #"<a href="/About">About</a> <a href="/about">About</a>"# },
			.page(#path("/about")) { "About" },
		]

		let published = try await Publisher(site: site, project: project, output: output).publish(routes)
		let brokenLinks = await LinkValidator(site: site).brokenLinks(in: routes, published: published)
		#expect(brokenLinks.map(\.link) == ["/About"], "\(brokenLinks)")
	}

	@Test
	func `JSON in a script has no less-than sign, so it cannot end the script element or keep it open with a comment`() throws {
		let text = "Great </script><b> <!--<script> app"
		let html = JSONScript(id: ElementID("data"), ["text": text]).render()
		let json = try #require(html.firstMatch(of: /<script[^>]*>(.*)<\/script>/)?.1)
		#expect(!json.contains("<"))
		#expect(try JSONDecoder().decode([String: String].self, from: Data(json.utf8)) == ["text": text])
	}

	@Test(.temporaryDirectory, arguments: ["png", "jpg"])
	func `image sizes are the pixel sizes of images`(fileExtension: String) throws {
		let file = try URL.temporaryDirectory().appending(path: "image.\(fileExtension)")
		try writeImage(to: file, type: fileExtension == "png" ? .png : .jpeg)

		#expect(file.imageSize == PixelSize(width: 30, height: 20))
		#expect(file.deletingLastPathComponent().appending(path: "missing.png").imageSize == nil)
	}

	@Test(.temporaryDirectory)
	func `image metadata reads size depth and display policy from the same header`() throws {
		let file = try URL.temporaryDirectory().appending(path: "image.png")
		try writeImage(to: file, bitsPerComponent: 16, properties: [kCGImagePropertyDPIWidth: 144.0, kCGImagePropertyDPIHeight: 144.0])
		let metadata = try #require(file.imageMetadata)
		#expect(metadata.size == PixelSize(width: 30, height: 20))
		#expect(metadata.displaySize == PixelSize(width: 15, height: 10))
		#expect(metadata.bitDepth == 16)
		#expect(metadata.horizontalDPI == 144)
		try Data([0, 1, 2]).write(to: file)
		#expect(file.imageMetadata == nil)
	}

	@Test(.temporaryDirectory, arguments: [(72.0, 30), (144.0, 15), (300.0, 30)])
	func `display sizes are half the pixel sizes of images with 144 DPI, like screenshots of a Retina display`(dpi: Double, expectedWidth: Int) throws {
		let file = try URL.temporaryDirectory().appending(path: "image.png")
		try writeImage(to: file, properties: [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi])

		#expect(file.displaySize == PixelSize(width: expectedWidth, height: expectedWidth * 2 / 3))
		#expect(file.imageSize?.width == 30)
	}

	@Test(.temporaryDirectory, arguments: [8, 16])
	func `the bit depth of an image is its bits per channel`(bitsPerComponent: Int) throws {
		let file = try URL.temporaryDirectory().appending(path: "image.png")
		try writeImage(to: file, bitsPerComponent: bitsPerComponent)

		#expect(file.imageBitDepth == bitsPerComponent)
		#expect(file.deletingLastPathComponent().appending(path: "missing.png").imageBitDepth == nil)
	}
}

/**
Writes a 30×20 image of the type to the file, like a screenshot, with the bits per channel and the properties, like its DPI.
*/
private func writeImage(
	to file: URL,
	type: UTType = .png,
	bitsPerComponent: Int = 8,
	properties: [CFString: Any] = [:]
) throws {
	let context = try #require(CGContext(
		data: nil,
		width: 30,
		height: 20,
		bitsPerComponent: bitsPerComponent,
		bytesPerRow: 0,
		space: CGColorSpaceCreateDeviceRGB(),
		bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
	))
	let image = try #require(context.makeImage())
	let destination = try #require(CGImageDestinationCreateWithURL(
		file as CFURL,
		type.identifier as CFString,
		1,
		nil
	))
	CGImageDestinationAddImage(destination, image, properties as CFDictionary)
	try #require(CGImageDestinationFinalize(destination))
}

extension PublishingTests {
	@Test
	func `concurrent mapping preserves input order for throwing and nonthrowing transforms`() async throws {
		let input = Array(0..<30)
		let values = await input.concurrentMap { value in
			await Task.yield()
			return value * value
		}
		let throwingValues = try await input.concurrentMap { value async throws -> Int in
			await Task.yield()
			return value * value
		}
		#expect(values == input.map { $0 * $0 })
		#expect(throwingValues == values)
	}

	@Test
	func `concurrent mapping propagates transform failures`() async {
		enum Failure: Error {
			case failed
		}

		await #expect(throws: Failure.self) {
			try await [1, 2, 3].concurrentMap { value in
				guard value != 2 else {
					throw Failure.failed
				}

				return value
			}
		}
	}

	@Test
	func `typed link problems retain payloads without manufacturing navigation destinations`() async throws {
		let html = #"<div id="same"></div><div id="same"></div><button aria-controls="missing"></button><a href="/missing">Missing</a>"#
		let route = Route.page(.root) { html }
		let published = PublishedSite(routeFiles: ["index.html": Data(html.utf8)], publicFiles: [])
		let problems = await LinkValidator(site: site).brokenLinks(in: [route], published: published)
		#expect(Set(problems.map(\.problem)) == [.duplicateID("same"), .missingReference(attribute: .ariaControls, id: "missing"), .missingFile("/missing")])
		#expect(problems.compactMap(\.destination) == ["/missing"])
	}

	@Test
	func `missing fragments retain the authored destination`() async {
		let targetHTML = #"<div id="present"></div>"#
		let linkingHTML = #"<a href="/target#absent">Absent</a>"#
		let target = Route.page(#path("/target")) { targetHTML }
		let linking = Route.page(#path("/linking")) { linkingHTML }
		let published = PublishedSite(
			routeFiles: [
				"target.html": Data(targetHTML.utf8),
				"linking.html": Data(linkingHTML.utf8)
			],
			publicFiles: []
		)
		let problems = await LinkValidator(site: site).brokenLinks(in: [target, linking], published: published)
		#expect(problems.map(\.problem) == [.missingFragment("/target#absent")])
		#expect(problems.map(\.destination) == ["/target#absent"])
		#expect(problems.map(\.link) == ["/target#absent"])
	}
}

extension PublishingTests {
	@Test
	func `publishing diagnostics retain typed paths roles and project relative source locations`() {
		let root = URL(filePath: "/project", directoryHint: .isDirectory)
		let page = Route.Source(role: "the page of", location: .file(root.appending(path: "content/page.md")))
		let redirect = Route.Source(role: "`redirectFrom` of", location: .file(root.appending(path: "content/other.md")))
		let collision = PublishingError.collision(file: PublishedFilePath("page.html"), firstSource: page, secondSource: redirect, root: root)
		#expect(collision.description.contains("the page of content/page.md"))
		#expect(collision.description.contains("`redirectFrom` of content/other.md"))
		#expect(!collision.description.contains("/project/"))
		let shadowed = PublishingError.shadowed(#path("/page"), source: page, file: PublishedFilePath("page"), fileSource: redirect, root: root)
		#expect(shadowed.description.contains("The URL /page of the page of content/page.md"))
	}
}
