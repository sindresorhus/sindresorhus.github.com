import Elementary
import Foundation
import ImageIO
import SiteKit
import Testing
@testable import Website

/**
Renders every page of the site from the real content, without the network: there is no App Store or GitHub data.
*/
@Suite
struct PageTests {
	private static func site() async throws -> Site {
		try await Site(content: .website)
	}

	private static func routes(where isIncluded: (Route) -> Bool) async throws -> [Route] {
		try await site().routes(project: .website, includesGallery: true).filter(isIncluded)
	}

	private static func isPage(_ route: Route) -> Bool {
		guard case .page = route.output else {
			return false
		}

		return true
	}

	@Test(arguments: try await routes(where: isPage))
	func `the page has one h1 and a short description`(route: Route) throws {
		guard case .page(_, let render) = route.output else {
			return
		}

		let html = try render()

		// The content of a template is not part of the page until a script uses it.
		let document = html.replacing(/<template[\s>].*?<\/template>/.dotMatchesNewlines(), with: "")
		let hasOneHeading = document.matches(of: /<h1[\s>]/).count == 1
		#expect(hasOneHeading, "The page must have one <h1>.")

		let description = html.firstMatch(of: /<meta name="description" content="([^"]*)">/).map { String($0.1).replacing("&amp;", with: "&").replacing("&quot;", with: "\"").replacing("&lt;", with: "<").replacing("&gt;", with: ">") }
		let hasShortDescription = (description?.count ?? 0) <= 160
		#expect(hasShortDescription, "The description is longer than 160 characters.")

		if !hasOneHeading || !hasShortDescription {
			Attachment.record(html, named: "\(route.outputFile.replacing("/", with: "_"))")
		}
	}

	@Test
	func `every page has a unique title`() async throws {
		var pathsByTitle = [String: RoutePath]()

		for route in try await Self.routes(where: Self.isPage) {
			guard case .page(_, let render) = route.output else {
				continue
			}

			let html = try render()
			let title = try #require(html.firstMatch(of: /<title>([^<]*)<\/title>/)?.1, "\(route.path) has no <title>.")
			#expect(pathsByTitle[String(title)] == nil, "\(route.path) has the same title as \(pathsByTitle[String(title)]?.description ?? ""): \(title)")
			pathsByTitle[String(title)] = route.path
		}

		#expect(pathsByTitle.count > 100)
	}

	@Test(arguments: try await routes { $0.path.starts(with: "/og") })
	func `the social card is a 1200×630 image`(route: Route) async throws {
		guard case .file(let render) = route.output else {
			return
		}

		let data = try await render()
		let properties = CGImageSourceCreateWithData(data as CFData, nil).flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
		let hasCardSize = properties?[kCGImagePropertyPixelWidth] as? Int == 1200 && properties?[kCGImagePropertyPixelHeight] as? Int == 630
		#expect(hasCardSize)

		if !hasCardSize {
			Attachment.record(data, named: route.path.description.split(separator: "/").last.map(String.init) ?? "card")
		}
	}

	/**
	The whole build, like `website build`, but offline: it publishes every route and checks the links.
	*/
	@Test(.temporaryDirectory)
	func `the site builds without broken links`() async throws {
		let output = try URL.temporaryDirectory().appending(path: "dist")
		let report = try await Site.build(project: .website, output: output, externalData: .none)

		#expect(report.brokenLinks == [])
		#expect(report.warnings == [])
		#expect(report.routeCount > 200)

		// The files that every page loads have their content hash in the URL, so they can be cached for a year.
		let home = try String(contentsOf: output.appending(path: "index.html"), encoding: .utf8)
		#expect(home.contains(#"href="/assets/site.css?v="#))
		#expect(home.contains(#"src="/scripts/site.js?v="#))
		#expect(home.contains(#"href="/assets/icons.svg?v="#))

		// Also in Markdown, which renders before the pages, like the icons of the copy button of a code block.
		let appPage = try String(contentsOf: output.appending(path: "lungo.html"), encoding: .utf8)
		#expect(appPage.contains("<code-block"))
		#expect(!appPage.contains(#"href="/assets/icons.svg#"#))

		// An element with an inline script, like the copy button, has its script in the page, once, and no script file.
		let contact = try String(contentsOf: output.appending(path: "contact.html"), encoding: .utf8)
		#expect(contact.ranges(of: "customElements.define('copy-button'").count == 1)
		#expect(!output.appending(path: "scripts/elements/copy-button.js").exists)
	}

	/**
	A class without a rule does nothing, and a rule without a class is dead code. Each page has its component styles in a `<style>` element, and the shared rules are in the stylesheet that every page links to.
	*/
	@Test
	func `every class has a rule, and every shared rule has a class`() async throws {
		let routes = try await Self.site().routes(project: .website, includesGallery: true)
		let sharedClasses = Self.classNames(inCSS: Stylesheet.site.css)
		var usedClasses = Set<String>()

		for route in routes {
			guard case .page(_, let render) = route.output else {
				continue
			}

			let html = try render()
			let pageClasses = Set(html.matches(of: /\sclass="([^"]*)"/).flatMap { $0.1.split(separator: " ").map(String.init) })
			let definedClasses = html.matches(of: /<style>(.*?)<\/style>/.dotMatchesNewlines()).reduce(into: sharedClasses) { $0.formUnion(Self.classNames(inCSS: String($1.1))) }
			let undefinedClasses = pageClasses.subtracting(definedClasses).filter { !Self.classesWithoutRules.contains($0) && !$0.hasPrefix("language-") }

			#expect(undefinedClasses.isEmpty, "\(route.path) uses classes without rules: \(undefinedClasses.sorted())")
			usedClasses.formUnion(pageClasses)
		}

		#expect(sharedClasses.subtracting(usedClasses).sorted() == [], "The shared stylesheet has rules for classes that no page uses.")
	}

	/**
	Classes without rules of their own:
	- `icon`, which components use to style the icons inside them.
	*/
	private static let classesWithoutRules: Set = ["icon"]

	/**
	The class names in the selectors of the CSS, like `prose` for `.prose :where(p)`. View transition classes, like `*.app-icon`, are not element classes, and neither are quoted attribute values, like `png` in `[src$='/icon.png']`.
	*/
	private static func classNames(inCSS css: String) -> Set<String> {
		Set(css.split(separator: "\n").filter { $0.hasSuffix("{") && !$0.contains("view-transition") }.flatMap { line in
			line.replacing(/'[^']*'|"[^"]*"/, with: "").matches(of: /\.([a-z][a-z0-9-]*)/).map { String($0.1) }
		})
	}

	@Test
	func `the shared stylesheet defines each class once`() async {
		// Top-level rules in the layers are indented once.
		let selectors = Stylesheet.site.css.split(separator: "\n").compactMap { line in
			line.wholeMatch(of: /\t(\.[a-z0-9-]+) \{/).map { String($0.1) }
		}

		#expect(!selectors.isEmpty)
		#expect(Dictionary(grouping: selectors, by: \.self).filter { $0.value.count > 1 }.keys.sorted() == [])
	}

	/**
	Markdown renders before the pages, so the page gets the script of the code blocks from the resources of the document.
	*/
	@Test
	func `code blocks in Markdown are highlighted, and the page gets their script once`() async throws {
		let route = try #require(try await Self.site().routes(project: .website, includesGallery: true).first { $0.path == "/_gallery" })

		guard case .page(_, let render) = route.output else {
			Issue.record("Expected a page, got \(route.output)")
			return
		}

		let html = try render()
		#expect(html.contains(#"<code class="code-block-code"><span class="code-block-attribute">@MainActor</span>"#))
		#expect(html.ranges(of: "customElements.define('code-block'").count == 1)
	}

	@Test
	func `each line of a console code block is an element, for the prompt of the styles`() {
		let html = CodeBlock(source: "open -g 'a<b'\n\nls\n", language: "console").render()

		#expect(html.contains(#"<code class="code-block-code code-block-console"><span>open -g 'a&lt;b'</span>\#n\#n<span>ls</span>\#n</code>"#))
	}

	@Test
	func `llms-full.txt has the older versions and the sponsors from the frontmatter`() async throws {
		let route = try #require(try await Self.site().routes(project: .website).first { $0.path == "/llms-full.txt" })

		guard case .file(let render) = route.output else {
			Issue.record("Expected a file, got \(route.output)")
			return
		}

		let text = String(decoding: try await render(), as: UTF8.self)
		#expect(text.contains("## Older Versions\n\n- ["))
		#expect(text.contains("- [GitHub](https://github.com)"))
		#expect(!text.contains("@Sponsors"))
	}

	/**
	The file is read outside the site, so a link to another page, like `donate.md` on the about page, is an absolute URL.
	*/
	@Test
	func `llms-full.txt has absolute links`() async throws {
		let route = try #require(try await Self.site().routes(project: .website).first { $0.path == "/llms-full.txt" })

		guard case .file(let render) = route.output else {
			Issue.record("Expected a file, got \(route.output)")
			return
		}

		let text = String(decoding: try await render(), as: UTF8.self)
		#expect(!text.contains("](donate.md)"))
		#expect(!text.contains("](../"))
		#expect(text.contains("](https://sindresorhus.com/supporters)"))
		#expect(text.contains("](https://sindresorhus.com/donate)"))
		#expect(text.firstMatch(of: /(src|href)="\//) == nil)
	}

	@Test
	func `every feed renders, and redirect items keep their GUIDs`() async throws {
		let site = try await Self.site()
		var feeds = [String: String]()

		for route in site.routes(project: .website) where route.path.description.hasSuffix("rss.xml") || route.path.description.hasPrefix("/rss-") {
			guard case .file(let render) = route.output else {
				continue
			}

			feeds[route.path.description] = String(decoding: try await render(), as: UTF8.self)
		}

		#expect(feeds.count >= 3)

		// Feed readers know the items by their GUIDs, so the GUIDs of redirect posts must not change. The content may have no listed redirect posts.
		let blogFeed = try #require(feeds["/rss.xml"])
		let redirectPosts = site.content.listedPosts.filter(\.isRedirect)

		for post in redirectPosts {
			#expect(blogFeed.contains("<guid isPermaLink=\"false\">https://sindresorhus.com/blog/\(post.slug)</guid>"))
		}
	}
}

extension Route: CustomTestStringConvertible {
	public var testDescription: String {
		path.description
	}
}
