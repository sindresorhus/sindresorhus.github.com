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

	/**
	A look belongs in a style (the “Styles” section of AGENTS.md), also in the Markdown of the content. A value of the build, like the accent of an app, is a custom property in a style of the element (``ElementStyle``), like `tint(_:)`.
	*/
	@Test(arguments: try await routes(where: isPage))
	func `the page has no style attributes`(route: Route) throws {
		// The text of a script is not markup.
		let markup = try route.renderedHTML().replacing(/<script\b.*?<\/script>/.dotMatchesNewlines(), with: "")
		let attributes = markup.matches(of: /<[a-zA-Z][^>]*?\sstyle="[^"]*"/).map { String($0.output) }
		#expect(attributes.isEmpty, "\(attributes.joined(separator: "\n"))")
	}

	/**
	Elementary does not check how elements nest, and raw HTML in content is not checked either.
	*/
	@Test(arguments: try await routes(where: isPage))
	func `the page nests elements like the HTML parser does`(route: Route) throws {
		let errors = Self.nestingErrors(in: try route.renderedHTML())
		#expect(errors.isEmpty, "\(errors.joined(separator: "\n"))")
	}

	@Test
	func `the nesting check finds elements that the HTML parser moves`() {
		#expect(Self.nestingErrors(in: #"<a href="/"><button>Go</button></a>"#) == ["<button> inside <a>"])
		#expect(Self.nestingErrors(in: #"<p>Text<ul><li>Item</li></ul></p>"#) == ["<ul> inside <p>", "</p> without <p>"])
		#expect(Self.nestingErrors(in: #"<div><span></div></span>"#) == ["</div> closes <span>", "</span> without <span>"])
		#expect(Self.nestingErrors(in: #"<button><textarea>Text</textarea></button><p><li>Item</li></p><section>"#) == ["<textarea> inside <button>", "<li> inside <p>", "</p> without <p>", "<section> without </section>"])
		#expect(Self.nestingErrors(in: #"<a href="/"><a href="/about">About</a></a><form><form></form></form>"#) == ["<a> inside <a>", "<form> inside <form>"])

		// A button starts a new scope, so a block in it does not close the paragraph around it.
		#expect(Self.nestingErrors(in: #"<p><button><div>Go</div></button></p>"#).isEmpty)

		// A hidden input is not interactive, a template has its own content, and the content of a script is text.
		#expect(Self.nestingErrors(in: #"<button><input type="hidden"></button><p><template><div></div></template></p><a><script>"<a>"</script></a>"#).isEmpty)

		// An attribute can contain `>`, a comment can look like a tag, and an SVG element can close itself.
		#expect(Self.nestingErrors(in: #"<a title="a > b"><!-- <button> --></a><svg><path d="M0 0"/></svg>"#).isEmpty)
	}

	/**
	Where the HTML nests elements in a way that the HTML spec does not allow, like a button in a link, which assistive technologies handle badly, or a list in a paragraph, which the HTML parser moves out of the paragraph. It also finds closing tags that do not match.
	*/
	private static func nestingErrors(in html: String) -> [String] {
		// Elements that a link or a button must not contain. A hidden input is not interactive.
		let interactiveElements: Set = ["a", "button", "details", "embed", "iframe", "input", "label", "select", "textarea"]

		// Elements that close an open paragraph in the HTML parser.
		let paragraphClosingElements: Set = ["address", "article", "aside", "blockquote", "dd", "details", "dialog", "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hgroup", "hr", "li", "main", "menu", "nav", "ol", "p", "pre", "search", "section", "summary", "table", "ul"]

		// Elements that start a new scope, so the elements outside do not matter.
		let scopeElements: Set = ["button", "caption", "math", "object", "svg", "table", "td", "template", "th"]

		let voidElements: Set = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"]

		// The content of comments and raw text elements can look like tags. The raw text elements stay, as a text area is interactive.
		let markup = html
			.replacing(/<!--.*?-->/.dotMatchesNewlines(), with: "")
			.replacing(/<(script|style|textarea|title)\b(?:[^>"']|"[^"]*"|'[^']*')*>.*?<\/\1>/.dotMatchesNewlines()) { "<\($0.1)></\($0.1)>" }

		var errors = [String]()
		var openElements = [String]()

		for match in markup.matches(of: /<(\/?)([a-zA-Z][a-zA-Z0-9-]*)((?:[^>"']|"[^"]*"|'[^']*')*)>/) {
			let name = match.2.lowercased()

			guard match.1.isEmpty else {
				guard let index = openElements.lastIndex(of: name) else {
					errors.append("</\(name)> without <\(name)>")
					continue
				}

				if index != openElements.indices.last {
					errors.append("</\(name)> closes <\(openElements[index + 1])>")
				}

				openElements.removeSubrange(index...)
				continue
			}

			let ancestors = openElements.reversed().prefix { $0 != "template" && $0 != "svg" && $0 != "math" }
			let isInteractive = interactiveElements.contains(name) && !(name == "input" && match.3.contains(/type="hidden"/))

			if
				isInteractive,
				let ancestor = ancestors.first(where: { $0 == "a" || $0 == "button" })
			{
				errors.append("<\(name)> inside <\(ancestor)>")
			}

			if
				paragraphClosingElements.contains(name),
				openElements.reversed().prefix(while: { !scopeElements.contains($0) }).contains("p"),
				let paragraphIndex = openElements.lastIndex(of: "p")
			{
				errors.append("<\(name)> inside <p>")

				// The HTML parser closes the paragraph here, so the elements after it are not in it.
				openElements.removeSubrange(paragraphIndex...)
			}

			if
				name == "form",
				ancestors.contains("form")
			{
				errors.append("<form> inside <form>")
			}

			guard
				!voidElements.contains(name),
				!match.3.hasSuffix("/")
			else {
				continue
			}

			openElements.append(name)
		}

		return errors + openElements.map { "<\($0)> without </\($0)>" }
	}

	/**
	Without the headings, what I am working on now, the numbers, and the projects are at the end of the page.
	*/
	@Test
	func `the about page has the headings that the now card, the numbers, and the popular projects are above`() async throws {
		let content = try await SiteContent.load(from: .website, externalData: .none, buildDate: .now)
		let page = try #require(content.page(.about))

		#expect(page.markdown.contentSeparated(beforeHeadings: [AboutPage.nowNextHeadingID, AboutPage.numbersNextHeadingID, AboutPage.projectsNextHeadingID]) != nil)
	}

	/**
	Without the network, the numbers section has the numbers that the build does not get, like the years, and both cards.
	*/
	@Test
	func `the about page has the numbers without the network`() async throws {
		let content = try await SiteContent.website
		let page = try #require(content.page(.about))

		let html = try AboutPage(page: page, content: content).renderedHTML()
		let parts = html.split(separator: #"id="\#(AboutPage.numbersID)""#)
		try #require(parts.count == 2)
		let numbers = try #require(parts[1].split(separator: #"id="\#(AboutPage.numbersNextHeadingID)""#).first)

		#expect(numbers.contains("Apps</h3>"))
		#expect(numbers.contains("years of craft"))
		#expect(numbers.contains("Open Source</h3>"))
		#expect(numbers.contains("years of open source"))
	}

	/**
	The status of the now page is a card that links to it, at the end of the introduction.
	*/
	@Test
	func `the about page shows the status of the now page before the first section`() async throws {
		let content = try await SiteContent.website
		let page = try #require(content.page(.about))
		let status = try #require(content.page(.now)?.frontmatter.status)

		let html = try AboutPage(page: page, content: content).renderedHTML()
		let parts = html.split(separator: #"id="\#(AboutPage.nowNextHeadingID)""#)
		try #require(parts.count == 2)
		let introduction = parts[0]
		let card = try #require(introduction.split(separator: #"<a href="/now""#).last)

		#expect(card.contains(status))
	}

	/**
	The numbers below the title are also in the numbers section, with the others.
	*/
	@Test
	func `the about page has the numbers below the title in the numbers section too`() async throws {
		let loadedContent = try await SiteContent.website
		let repositoryCount = 1144
		let content = SiteContent(apps: loadedContent.apps, posts: loadedContent.posts, pages: loadedContent.pages, gitHubAccount: GitHub.Account(repositoryCount: repositoryCount, followerCount: 84_740, starCount: 1_099_747, maintenance: GitHub.Maintenance(closedIssueCount: 22_815, mergedPullRequestCount: 13_831), repositories: []), buildDate: loadedContent.buildDate, project: .website)
		let page = try #require(content.page(.about))

		let html = try AboutPage(page: page, content: content).renderedHTML()
		let parts = html.split(separator: #"id="\#(AboutPage.numbersID)""#)
		try #require(parts.count == 2)
		let top = parts[0]
		let numbers = try #require(parts[1].split(separator: #"id="\#(AboutPage.numbersNextHeadingID)""#).first)

		#expect(top.contains(">\(repositoryCount.approximateCount) repos</span>"))
		#expect(top.contains("years of app craft"))
		#expect(numbers.contains(#">\#(repositoryCount.approximateCount)</span> <span class="\#(StatCard.Styles.label.className)">repos</span>"#))
		#expect(numbers.contains("years of craft"))
		#expect(numbers.contains(">22K+</span> <span class=\"\(StatCard.Styles.label.className)\">issues closed</span>"))
		#expect(numbers.contains(">13K+</span> <span class=\"\(StatCard.Styles.label.className)\">pull requests merged from others</span>"))
	}

	/**
	The busiest weekday has its short name, like “Thu” for the Thursday of 2026-01-01.
	*/
	@Test
	func `the about page shows the busiest weekday by its short name`() async throws {
		let loadedContent = try await SiteContent.website
		let page = try #require(loadedContent.page(.about))
		let json = #"{"totalContributions": 13, "weeks": [{"contributionDays": [{"date": "2026-01-01", "contributionCount": 9, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-02", "contributionCount": 4, "contributionLevel": "FIRST_QUARTILE"}]}]}"#
		let calendar = try JSONDecoder().decode(ContributionCalendar.self, from: Data(json.utf8))
		let year = ContributionYear(year: 2026, calendar: calendar, until: try Date("2026-12-31T12:00:00Z", strategy: .iso8601))
		let content = SiteContent(apps: loadedContent.apps, posts: loadedContent.posts, pages: loadedContent.pages, contributionYears: [year], buildDate: loadedContent.buildDate, project: .website)

		let html = try AboutPage(page: page, content: content).renderedHTML()
		#expect(html.contains(#">Thu</span> <span class="\#(StatCard.Styles.label.className)">busiest weekday</span>"#))
	}

	/**
	The number of the most-downloaded packages on npm that are mine is left out when it is zero, like the other numbers.
	*/
	@Test
	func `the about page shows how many of the most-downloaded npm packages are mine only when some are`() async throws {
		let loadedContent = try await SiteContent.website
		let page = try #require(loadedContent.page(.about))

		func html(mostDownloadedPackageNames: [String]) throws -> String {
			var npmStatistics = NPMStatistics()
			npmStatistics.packages = [NPMStatistics.Package(name: "chalk", version: "6.0.0", description: nil, date: .now, weeklyDownloads: 1000, dependentCount: nil, repository: "chalk/chalk")]
			npmStatistics.mostDownloadedPackageNames = mostDownloadedPackageNames
			let content = SiteContent(apps: loadedContent.apps, posts: loadedContent.posts, pages: loadedContent.pages, npmStatistics: npmStatistics, buildDate: loadedContent.buildDate, project: .website)
			return try AboutPage(page: page, content: content).renderedHTML()
		}

		let label = "of the 10 most-downloaded packages"
		#expect(try html(mostDownloadedPackageNames: ["semver", "chalk"]).contains(#">1</span> <span class="\#(StatCard.Styles.label.className)">\#(label)</span>"#))
		#expect(try !html(mostDownloadedPackageNames: ["semver"]).contains(label))
	}

	/**
	The packages of the day leave out packages without a description, of the Yeoman and imagemin organizations, and with an archived repo. The repos of the day leave out forks, archived repos, repos for settings, and the repos of npm packages. The link of a package can have capitals, and it is still the same repo.
	*/
	@Test
	func `the projects of the day leave out the packages and repos that are not worth finding`() throws {
		func package(_ name: String, description: String? = "Does a thing", repository: String?) -> NPMStatistics.Package {
			NPMStatistics.Package(name: name, version: "1.0.0", description: description, date: .now, weeklyDownloads: 10, dependentCount: nil, repository: repository)
		}

		var npmStatistics = NPMStatistics()
		npmStatistics.packages = [
			// The link of a package can have capitals, like `SindreSorhus/Ky`, and it is the same repo.
			package("ky", repository: "SindreSorhus/Ky"),
			package("no-description", description: nil, repository: "sindresorhus/no-description"),
			package("yeoman-environment", repository: "yeoman/environment"),
			package("imagemin-svgo", repository: "imagemin/imagemin-svgo"),
			package("old-thing", repository: "sindresorhus/Old-Thing"),
			package("no-repo", repository: nil),
		]

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let repositories = try ["Defaults", "ky", "old-thing", "forked", ".github"].map { name in
			let isArchived = name == "old-thing"
			let isFork = name == "forked"
			return try decoder.decode(GitHubRepository.self, from: Data(#"{"name": "\#(name)", "description": "Does a thing", "html_url": "https://github.com/sindresorhus/\#(name)", "created_at": "2020-01-01T00:00:00Z", "archived": \#(isArchived), "fork": \#(isFork), "stargazers_count": 1, "language": "Swift"}"#.utf8))
		}

		let account = GitHub.Account(repositoryCount: repositories.count, followerCount: 1, starCount: 1, maintenance: GitHub.Maintenance(closedIssueCount: 1, mergedPullRequestCount: 1), repositories: repositories)
		let content = SiteContent(apps: [], posts: [], pages: [], gitHubAccount: account, npmStatistics: npmStatistics, buildDate: .now, project: .empty)

		#expect(content.discoverablePackages.map(\.name) == ["ky", "no-repo"])
		#expect(content.discoverableRepositories.map(\.name) == ["Defaults"])
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

	/**
	A page that search engines must not index, like the random app page, would otherwise be in the sitemap, which asks them to index it.
	*/
	@Test
	func `a page is in the sitemap exactly when search engines may index it`() async throws {
		var pageCount = 0

		for route in try await Self.routes(where: Self.isPage) {
			guard case .page(let sitemapEntry, let render) = route.output else {
				continue
			}

			let isNotIndexed = try render().contains(#"<meta name="robots" content="noindex">"#)
			#expect(isNotIndexed == (sitemapEntry == nil), "\(route.path)")
			pageCount += 1
		}

		#expect(pageCount > 100)
	}

	/**
	The 404 page suggests the closest page to a mistyped path, so it must only suggest pages that exist and that visitors look for.
	*/
	@Test
	func `the 404 page suggests only indexed pages, without the home page and old paths`() async throws {
		let site = try await Self.site()
		let route = try #require(site.routes(project: .website).first { $0.path == .notFound })

		let json = try #require(try route.renderedHTML().firstMatch(of: /<script[^>]*id="not-found-data"[^>]*>(.*?)<\/script>/)?.1)
		let paths = try JSONDecoder().decode([String: [String]].self, from: Data(json.utf8))["paths"] ?? []
		let oldPaths = Set(site.content.documents.flatMap(\.redirectFrom).map(\.description))

		#expect(paths.contains(RoutePath.apps.description))
		#expect(paths.contains(App.path(slug: "lungo").description))
		#expect(!paths.contains("/"))
		#expect(!paths.contains(RoutePath.notFound.description))
		#expect(!paths.contains(RoutePath.randomApp.description))
		#expect(oldPaths.isDisjoint(with: paths))
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
		#expect(!output.appending(path: "scripts/elements/CopyButton.js").exists)

		// Each page has one import map, before its module scripts, as browsers only use an import map that comes first, and every script in it is published with the hash it maps to.
		for page in try output.filesRecursively() where page.pathExtension == "html" {
			let html = try String(contentsOf: page, encoding: .utf8)

			// Not the files that are published unchanged, like `public/feedback/index.html`.
			guard
				!Project.website.publicDirectory.appending(path: page.path(relativeTo: output)).isFile,
				html.contains(#"type="module""#)
			else {
				continue
			}

			// Every script that the page loads from `/scripts` has its hash, also the scripts of the elements, which the build finds in the `Scripts` folders.
			for match in html.matches(of: /<script\b[^>]*\bsrc="(\/scripts\/[^"]+)"/) {
				#expect(match.1.contains("?v="), "\(page.lastPathComponent) loads \(match.1) without its hash.")
			}

			let importMaps = html.matches(of: /<script type="importmap">(.*?)<\/script>/)
			try #require(importMaps.count == 1, "\(page.lastPathComponent) must have one import map.")
			let firstModule = try #require(html.firstRange(of: #"type="module""#))
			#expect(importMaps[0].range.upperBound <= firstModule.lowerBound, "The import map of \(page.lastPathComponent) must come before its module scripts.")

			let imports = try JSONDecoder().decode([String: [String: String]].self, from: Data(importMaps[0].1.utf8))["imports"] ?? [:]
			#expect(imports["/scripts/geocities-element.js"]?.hasPrefix("/scripts/geocities-element.js?v=") == true)

			for (path, url) in imports {
				#expect(url.hasPrefix(path + "?v="), "The import map of \(page.lastPathComponent) maps \(path) to \(url).")
				#expect(output.appending(path: String(path.dropFirst())).isFile, "The import map of \(page.lastPathComponent) has \(path), which is not published.")
			}
		}
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

	/**
	With reduced motion, nothing moves by itself (“Motion” in `AGENTS.md`), as `animation()` writes the animation in `@media (prefers-reduced-motion: no-preference)`. The exceptions are the essential animations, and the scroll-driven animations, which follow the scrolling of the visitor and have their `animation-timeline` on the next line.
	*/
	@Test
	func `animations only run for visitors who allow motion`() async throws {
		let essentialAnimations = [ProseAnimations.targetHighlight.name]
		var stylesheets = [Stylesheet.site.css]
		var animationCount = 0

		for route in try await Self.routes(where: Self.isPage) {
			stylesheets += try route.renderedHTML().matches(of: /<style>(.*?)<\/style>/.dotMatchesNewlines()).map { String($0.1) }
		}

		for css in stylesheets {
			let lines = css.split(separator: "\n").map { $0.trimmingPrefix(while: \.isWhitespace) }
			var preludes = [Substring]()

			for (index, line) in lines.enumerated() {
				if line.hasSuffix("{") {
					preludes.append(line)
					continue
				}

				if line == "}" {
					preludes.removeLast()
					continue
				}

				guard
					let value = line.wholeMatch(of: /animation: (.+);/)?.1,
					value != "none"
				else {
					continue
				}

				animationCount += 1

				let isAllowed = preludes.contains { $0.contains("prefers-reduced-motion: no-preference") }
					|| essentialAnimations.contains { value.hasPrefix("\($0) ") }
					|| lines.indices.contains(index + 1) && lines[index + 1].hasPrefix("animation-timeline:")

				#expect(isAllowed, "The animation also runs with reduced motion: \(value)")
			}
		}

		#expect(animationCount > 0)
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

		let html = try route.renderedHTML()
		#expect(html.contains(#"<code data-part="code" class="code-block-code"><span class="code-block-attribute">@MainActor</span>"#))
		#expect(html.contains(#"<code data-part="code" class="code-block-code"><span class="code-block-comment"># Every kind of highlighted token.</span>"#))
		#expect(html.ranges(of: "customElements.define('code-block'").count == 1)
	}

	/**
	The icons have the hash of the sprite wherever they render, also outside a build, like Markdown that renders while the content loads.
	*/
	@Test
	func `icons have the hash of the sprite without a build`() {
		let html = CodeBlock(source: "ls\n", language: "console").render()

		#expect(html.contains(/href="\/assets\/icons\.svg\?v=[0-9a-f]+#/))
	}

	@Test
	func `each line of a console code block is an element, for the prompt of the styles`() {
		let html = CodeBlock(source: "open -g 'a<b'\n\nls\n", language: "console").render()

		#expect(html.contains(#"<code data-part="code" class="code-block-code code-block-console"><span>open -g 'a&lt;b'</span>\#n\#n<span>ls</span>\#n</code>"#))
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
