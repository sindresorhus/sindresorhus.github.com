import Elementary
import Foundation
import ImageIO
import RegexBuilder
import RSS
import SiteKit
import SOML
import TestSupport
import Testing
@testable import Website

/**
Renders every page of the site from the real content, without the network: there is no App Store or GitHub data.
*/
struct PageTests {
	@Test(arguments: [false, true])
	func `screenshot rendering keeps dimensions alternatives and its loading policy`(loadsImmediately: Bool) throws {
		let size = try #require(PixelSize(width: 640, height: 480))
		let asset = ScreenshotAsset(
			path: #path("/test/screenshot1.png"),
			number: 1,
			size: size,
			jpegXL: nil
		)
		let html = ScreenshotImage(asset: asset, alternativeText: "A result & its settings", loadsImmediately: loadsImmediately) {
			$0.style(AppMedia.Styles.media)
		}.render()

		#expect(html.contains("src=\"/test/screenshot1.png\""))
		#expect(html.contains("width=\"640\" height=\"480\""))
		#expect(html.contains("alt=\"A result &amp; its settings\""))
		#expect(html.contains("decoding=\"async\""))
		#expect(html.contains("loading=\"lazy\"") == !loadsImmediately)
		#expect(!html.contains("<picture"))
	}

	@Test
	func `button appearance stays available on links and buttons`() {
		let link = a(.href("/apps")) {
			"Apps"
		}.buttonStyle(.secondary, size: .small).render()
		let button = Elementary.button(.type(.submit)) {
			"Send"
		}.buttonStyle(.secondary, size: .small).render()

		for html in [link, button] {
			#expect(html.contains(ButtonStyles.root.className))
			#expect(html.contains(ButtonStyles.secondary.className))
			#expect(html.contains(ButtonStyles.small.className))
		}
		#expect(button.contains("type=\"submit\""))
	}

	@Test
	func `an app review section owns visibility and wall link eligibility`() async throws {
		let app = try await App(title: "A reviewable app")
		#expect(AppReviews(listing: AppListing(app: app)) == nil)

		let rating = try #require(SetappRating(ratingValue: 99, bestRating: 100, count: 30))
		#expect(AppReviews(listing: AppListing(app: app, setappRating: rating)) == nil)

		let review = AppStoreReview(title: "Useful", text: "Works well.", author: "A reader", rating: .five, date: .now)
		let reviews = try #require(AppReviews(listing: AppListing(app: app, appStoreReviews: [review])))
		#expect(reviews.app?.slug == app.slug)
		#expect(reviews.render().contains("Wall of Love"))

		let archived = try await App(frontmatter: "isArchived: true")
		let archivedReviews = try #require(AppReviews(listing: AppListing(app: archived, appStoreReviews: [review])))
		#expect(archivedReviews.app == nil)
		#expect(!archivedReviews.render().contains("Wall of Love"))
	}

	@Test
	func `press presentation changes only press quotes while reviews retain cards`() async throws {
		let app = try await App(frontmatter: "pressQuotes: [{quote: 'A useful app', source: 'Publication'}]")
		let quote = try #require(app.pressQuotes.first)
		let card = QuoteFigure(kind: .press(quote)).render()
		let pullQuote = QuoteFigure(kind: .press(quote, presentation: .pullQuote)).render()
		let review = AppStoreReview(title: "Useful", text: "Works well.", author: "A reader", rating: .five, date: .now)
		let reviewCard = QuoteFigure(kind: .review(review)).render()

		#expect(card.contains(QuoteFigure.Styles.card.className))
		#expect(!pullQuote.contains(QuoteFigure.Styles.card.className))
		#expect(pullQuote.contains(QuoteFigure.Styles.quotationMark.className))
		#expect(reviewCard.contains(QuoteFigure.Styles.card.className))
	}

	@Test
	func `app prose headings and optional back links identify the same app`() async throws {
		let app = try await App(title: "Named App", slug: "named-app")
		let linked = ProsePage(app: app, title: "Privacy") {
			"Policy."
		}.render()
		let unlinked = ProsePage(app: app, title: "Privacy", linksBack: false) {
			"Policy."
		}.render()
		let guide = ProsePage(title: .plain("A guide", intro: "Steps"), backTo: app) {
			"Content."
		}.render()

		for html in [linked, unlinked] {
			#expect(html.contains("Privacy"))
			#expect(html.contains("for Named App"))
		}
		#expect(linked.contains("href=\"/named-app\""))
		#expect(!unlinked.contains("href=\"/named-app\""))
		#expect(guide.contains("A guide"))
		#expect(guide.contains("Steps"))
		#expect(guide.contains("href=\"/named-app\""))
	}

	@Test
	func `app grid new badges use the supplied build date`() async throws {
		let app = try await App(publicationDate: "2026-01-01")
		let recent = try Date("2026-01-15T00:00:00Z", strategy: .iso8601)
		let later = try Date("2026-02-15T00:00:00Z", strategy: .iso8601)

		#expect(AppGrid(apps: [app], buildDate: recent).render().contains(">New</span>"))
		#expect(!AppGrid(apps: [app], buildDate: later).render().contains(">New</span>"))
	}

	@Test
	func `day text formats the normalized UTC day for people and machines`() throws {
		let day = SOML.Date(try Date("2026-03-01T00:30:00+02:00", strategy: .iso8601))
		let html = DateText(day: day, format: .siteDay).render()

		#expect(html == #"<time datetime="2026-02-28">February 28, 2026</time>"#)
	}

	private static func site() async throws -> Site {
		try await Site(content: .website)
	}

	@Test(arguments: try await RenderedPage.website)
	func `the page has one h1 and a short description`(page: RenderedPage) {
		// The content of a template is not part of the page until a script uses it.
		let document = page.html.replacing(/<template[\s>].*?<\/template>/.dotMatchesNewlines(), with: "")
		let hasOneHeading = document.matches(of: /<h1[\s>]/).count == 1
		#expect(hasOneHeading, "The page must have one <h1>.")

		let description = page.html.firstMatch(of: /<meta name="description" content="([^"]*)">/).map { String($0.1).replacing("&amp;", with: "&").replacing("&quot;", with: "\"").replacing("&lt;", with: "<").replacing("&gt;", with: ">") }
		// The frontmatter checks the descriptions of the content (`SnippetText`), so this catches the descriptions that code makes, like the one of a privacy policy.
		let hasShortDescription = (description?.count ?? 0) <= SnippetText.maximumLength
		#expect(hasShortDescription, "The description is longer than \(SnippetText.maximumLength) characters.")

		if !hasOneHeading || !hasShortDescription {
			Attachment.record(page.html, named: "\(page.route.outputFile.description.replacing("/", with: "_"))")
		}
	}

	/**
	A look belongs in a style (the “Styles” section of AGENTS.md), also in the Markdown of the content. A value of the build, like the accent of an app, is a custom property in a style of the element (``ElementStyle``), like `tint(_:)`.
	*/
	@Test(arguments: try await RenderedPage.website)
	func `the page has no style attributes`(page: RenderedPage) {
		// The text of a script is not markup.
		let markup = page.html.replacing(/<script\b.*?<\/script>/.dotMatchesNewlines(), with: "")
		let attributes = markup.matches(of: /<[a-zA-Z][^>]*?\sstyle="[^"]*"/).map { String($0.output) }
		#expect(attributes.isEmpty, "\(attributes.joined(separator: "\n"))")
	}

	/**
	ARIA does not allow a name on an element whose role cannot have one, like a `div`, a `span`, a `p`, or a `pre` without a role, so screen readers do not say it. Such an element needs a role, like `group`.
	*/
	@Test(arguments: try await RenderedPage.website)
	func `the page names only elements with a role that can have a name`(page: RenderedPage) {
		let elements = page.html
			.matches(of: /<(?:div|span|p|pre)\b((?:[^>"']|"[^"]*"|'[^']*')*)>/)
			.filter { $0.1.contains(/\saria-label(?:ledby)?="/) && !$0.1.contains(/\srole="/) }
			.map { String($0.output.0) }
		#expect(elements.isEmpty, "\(elements.joined(separator: "\n"))")
	}

	/**
	Elementary does not check how elements nest, and raw HTML in content is not checked either.
	*/
	@Test(arguments: try await RenderedPage.website)
	func `the page nests elements like the HTML parser does`(page: RenderedPage) {
		let errors = Self.nestingErrors(in: page.html)
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
		let content = try await SiteContent.website
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
		let status = try #require(content.page(.now)?.status?.introduction)

		let html = try AboutPage(page: page, content: content).renderedHTML()
		let parts = html.split(separator: #"id="\#(AboutPage.nowNextHeadingID)""#)
		try #require(parts.count == 2)
		let introduction = parts[0]
		let card = try #require(introduction.split(separator: #"<a href="/now""#).last)

		#expect(card.contains(status))
		#expect(!card.contains("]("))
	}

	/**
	The descriptions count the apps that a visitor can get, like the list of the apps page, not the archived apps, which the stats count.
	*/
	@Test
	func `the descriptions of the home and apps pages count the active apps`() async throws {
		let content = SiteContent.test(apps: [try await App(title: "Active", slug: "active"), try await App(title: "Old", frontmatter: "isArchived: true", slug: "old")])

		#expect(HomePage(content: content).metadata.description?.contains(": 1 app for Mac") == true)
		#expect(AppsPage(content: content).metadata.description?.hasPrefix("1 app for Mac") == true)
	}

	/**
	The numbers below the title are also in the numbers section, with the others.
	*/
	@Test
	func `the about page has the numbers below the title in the numbers section too`() async throws {
		let loadedContent = try await SiteContent.website
		let repositoryCount = 1144
		let content = SiteContent.test(
			apps: loadedContent.apps,
			posts: loadedContent.posts,
			pages: loadedContent.pages,
			gitHubAccount: GitHub.Account(
				repositoryCount: repositoryCount,
				followerCount: 84_740,
				starCount: 1_099_747,
				maintenance: GitHub.Maintenance(closedIssueCount: 22_815, mergedPullRequestCount: 13_831),
				repositories: []
			),
			buildDate: loadedContent.buildDate,
			project: .website
		)
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
		let json = #"{"totalContributions": 13, "weeks": [{"contributionDays": [{"date": "2026-01-01", "contributionCount": 9}, {"date": "2026-01-02", "contributionCount": 4}]}]}"#
		let calendar = try ContributionCalendar(json: json)
		let year = ContributionYear(
			year: 2026,
			calendar: calendar,
			totals: .zero,
			until: try Date("2026-12-31T12:00:00Z", strategy: .iso8601)
		)
		let content = SiteContent.test(
			apps: loadedContent.apps,
			posts: loadedContent.posts,
			pages: loadedContent.pages,
			contributionYears: [year],
			buildDate: loadedContent.buildDate,
			project: .website
		)

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
			npmStatistics.search = .complete(total: 1, packages: [NPMStatistics.Package(
				name: "chalk",
				version: "6.0.0",
				description: nil,
				date: .now,
				weeklyDownloads: 1000,
				dependentCount: nil,
				repository: #repository("chalk/chalk")
			)])
			npmStatistics.mostDownloadedPackageNames = mostDownloadedPackageNames
			let content = SiteContent.test(
				apps: loadedContent.apps,
				posts: loadedContent.posts,
				pages: loadedContent.pages,
				npmStatistics: npmStatistics,
				buildDate: loadedContent.buildDate,
				project: .website
			)
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
		func package(_ name: String, description: String? = "Does a thing", repository: GitHubRepositoryName?) -> NPMStatistics.Package {
			NPMStatistics.Package(
				name: name,
				version: "1.0.0",
				description: description,
				date: .now,
				weeklyDownloads: 10,
				dependentCount: nil,
				repository: repository
			)
		}

		var npmStatistics = NPMStatistics()
		npmStatistics.search = .complete(total: 6, packages: [
			// The link of a package can have capitals, like `SindreSorhus/Ky`, and it is the same repo.
			package("ky", repository: #repository("SindreSorhus/Ky")),
			package("no-description", description: nil, repository: #repository("sindresorhus/no-description")),
			package("yeoman-environment", repository: #repository("yeoman/environment")),
			package("imagemin-svgo", repository: #repository("imagemin/imagemin-svgo")),
			package("old-thing", repository: #repository("sindresorhus/Old-Thing")),
			package("no-repo", repository: nil),
		])

		let repositories = try ["Defaults", "ky", "old-thing", "forked", ".github"].map { name in
			let isArchived = name == "old-thing"
			let isFork = name == "forked"
			return try GitHubRepository(json: #"{"name": "\#(name)", "full_name": "sindresorhus/\#(name)", "description": "Does a thing", "html_url": "https://github.com/sindresorhus/\#(name)", "created_at": "2020-01-01T00:00:00Z", "archived": \#(isArchived), "fork": \#(isFork), "stargazers_count": 1, "language": "Swift"}"#)
		}

		let account = GitHub.Account(
			repositoryCount: repositories.count,
			followerCount: 1,
			starCount: 1,
			maintenance: GitHub.Maintenance(closedIssueCount: 1, mergedPullRequestCount: 1),
			repositories: repositories
		)
		let content = SiteContent.test(gitHubAccount: account, npmStatistics: npmStatistics)

		#expect(content.discoverablePackages.map(\.name) == ["ky", "no-repo"])
		#expect(content.discoverableRepositories.map(\.name) == ["Defaults"])
	}

	@Test
	func `every page has a unique title`() async throws {
		var pathsByTitle = [String: RoutePath]()

		for page in try await RenderedPage.website {
			let path = page.route.path
			let title = try #require(page.html.firstMatch(of: /<title>([^<]*)<\/title>/)?.1, "\(path) has no <title>.")
			#expect(pathsByTitle[String(title)] == nil, "\(path) has the same title as \(pathsByTitle[String(title)]?.description ?? ""): \(title)")
			pathsByTitle[String(title)] = path
		}

		#expect(pathsByTitle.count > 100)
	}

	/**
	A page that search engines must not index, like the random app page, would otherwise be in the sitemap, which asks them to index it.
	*/
	@Test
	func `a page is in the sitemap exactly when search engines may index it`() async throws {
		var pageCount = 0

		for page in try await RenderedPage.website {
			let isNotIndexed = page.html.contains(#"<meta name="robots" content="noindex">"#)
			#expect(isNotIndexed == (page.route.sitemapEntry == nil), "\(page.route.path)")
			#expect(page.html.contains(#"<meta name="robots" content="max-image-preview:large">"#) == !isNotIndexed, "\(page.route.path)")
			pageCount += 1
		}

		#expect(pageCount > 100)
	}

	/**
	The real content may have no unlisted post with a page of its own, so the test above may not cover it.
	*/
	@Test
	func `an unlisted post is not in the sitemap and not indexed`() async throws {
		let post = try await BlogPost(markdown: "---\nisUnlisted: true\ntitle: 'Hidden'\npublicationDate: 2026-01-01\n---\n\nText.", slug: "hidden")
		let page = BlogPostPage(
			post: post,
			content: SiteContent.test(posts: [post])
		)

		#expect(page.route.sitemapEntry == nil)
		#expect(try page.renderedHTML().contains(#"<meta name="robots" content="noindex">"#))
	}

	/**
	The real posts all have a description, and a post on another site has no text here to read.
	*/
	@Test
	func `a blog post row leaves out a missing description and the reading time of a post on another site`() async throws {
		let post = try await BlogPost(markdown: "---\ntitle: 'Elsewhere'\npublicationDate: 2026-01-01\nredirectURL: 'https://example.com/post'\n---\n", slug: "elsewhere")
		let html = ArticleRow(.post(post)).render()

		#expect(!html.contains("<p"))
		#expect(!html.contains("min read"))
		#expect(html.contains(#"<time datetime="2026-01-01">January 2026</time>"#))
	}

	/**
	Sighted visitors see the new tab open, so only screen readers get the text.
	*/
	@Test
	func `a link that opens in a new tab says so to screen readers`() {
		let newTabLink = Link("crash report", destination: .crashReportQuestion, opensInNewTab: true).render()
		let link = Link("crash report", destination: .crashReportQuestion).render()

		#expect(newTabLink.contains(#"target="_blank""#))
		#expect(newTabLink.contains(#"<span class="visually-hidden"> (opens in a new tab)</span></a>"#))
		#expect(!link.contains("new tab"))
	}

	/**
	The “Code” button of the home page and “popular projects” on the about page go to the Open Source page, which links to my GitHub profile and to the repos of its projects.
	*/
	@Test
	func `the home page and the about page link to the open source page, which links to the GitHub profile`() async throws {
		let pages = try await RenderedPage.website
		let html = { (path: RoutePath) in try #require(pages.first { $0.route.path == path }).html }
		let openSourceLink = #"href="\#(RoutePath.openSource)""#

		#expect(try html(.root).contains(openSourceLink))
		#expect(try html(.about).contains(openSourceLink))
		#expect(try html(.openSource).contains(#"href="\#(Site.author.gitHubURL)""#))

		for project in OpenSourceProject.all {
			#expect(project.repository.isOwners, "\(project.name) is not a repo of my account or my organizations.")
			#expect(try html(.openSource).contains(#"href="\#(project.repository.url)""#))
		}
	}

	@Test
	func `no open source project is on the page twice`() {
		let repositories = OpenSourceProject.all.map(\.repository)
		let duplicates = Dictionary(grouping: repositories, by: \.self).filter { $0.value.count > 1 }.keys
		#expect(duplicates.isEmpty, "\(duplicates.map(\.description)) are repeated in the catalog.")
	}

	@Test
	func `the open source catalog excludes Plash and the cross platform wallpaper package`() {
		#expect(!OpenSourceProject.Group.apps.projects.contains { $0.name == "Plash" })
		#expect(!OpenSourceProject.Group.mac.projects.contains { $0.name == "wallpaper" })
		#expect(OpenSourceProject.Group.mac.projects.contains { $0.name == "macos-wallpaper" })
	}

	/**
	The cards of a group fill the rows of the grid, which has two or four columns, or three for a group of three. A group of two keeps two columns on wide screens.
	*/
	@Test(arguments: OpenSourceProject.Group.allCases)
	func `each open source group has two or three projects or a multiple of four`(group: OpenSourceProject.Group) {
		let count = group.projects.count
		#expect((2...3).contains(count) || (count > 0 && count.isMultiple(of: 4)), "\(group.title) has \(count) projects.")
	}

	/**
	The profile card has the contributions of the last year, with their number as text, as screen readers skip the heatmap. Without a GitHub token, the build has no contributions, so the card leaves them out.
	*/
	@Test
	func `the open source page shows the contributions only when the build has them`() throws {
		let json = #"{"totalContributions": 13, "weeks": [{"contributionDays": [{"date": "2026-01-01", "contributionCount": 9}, {"date": "2026-01-02", "contributionCount": 4}]}]}"#
		var activity = RecentActivity()
		activity.profile = try GitHub.Profile(contributions: ContributionCalendar(json: json), sponsorCount: 0, commentCount: 0)
		let withContributions = try OpenSourcePage(content: SiteContent.test(recentActivity: activity)).renderedHTML()
		let withoutContributions = try OpenSourcePage(content: SiteContent.test()).renderedHTML()
		let cell = ContributionHeatmap.Styles.cells.className

		#expect(withContributions.contains(cell))
		#expect(withContributions.contains("13 contributions on GitHub in the last year."))
		#expect(!withoutContributions.contains(cell))
		#expect(!withoutContributions.contains("contributions on GitHub"))
	}

	/**
	The quote in the footer is from Apple, so its credit is in its tooltip.
	*/
	@Test
	func `the quote in the footer is credited`() {
		#expect(SiteFooter().render().contains(#"<q title="Apple, “Think Different” (1997)""#))
	}

	/**
	On an app page and a guide, the “Feedback & Support” link of the footer opens the form for the app, so the visitor does not pick the app again. Other pages link to the picker.
	*/
	@Test
	func `the footer of an app page links to the feedback form of the app`() async throws {
		let pages = try await RenderedPage.website
		let appPage = try #require(pages.first { $0.route.path == #path("/dato") }).html
		let guidePage = try #require(pages.first { $0.route.path == Guide.path(slug: "convert-video-to-gif-mac") }).html
		let otherPage = try #require(pages.first { $0.route.path == .root }).html

		#expect(appPage.contains(#"<a href="/feedback?product=Dato" class="site-footer-link">Feedback &amp; Support</a>"#))
		#expect(guidePage.contains(#"<a href="/feedback?product=Gifski" class="site-footer-link">Feedback &amp; Support</a>"#))
		#expect(otherPage.contains(#"<a href="/feedback" class="site-footer-link">Feedback &amp; Support</a>"#))
	}

	/**
	The 404 page suggests the closest page to a mistyped path, so it must only suggest pages that exist and that visitors look for.
	*/
	@Test
	func `the 404 page suggests only indexed pages, without the home page and old paths`() async throws {
		let page = try #require(try await RenderedPage.website.first { $0.route.path == .notFound })

		let json = try #require(page.html.scriptTags.first { $0.id == "not-found-data" }?.body)
		struct NotFoundData: Decodable {
			struct Page: Decodable {
				let path: String
			}

			let pages: [Page]
		}

		let paths = try JSONDecoder().decode(NotFoundData.self, from: Data(json.utf8)).pages.map(\.path)
		let oldPaths = Set(try await SiteContent.website.documents.flatMap(\.redirectFrom).map(\.description))

		#expect(paths.contains(RoutePath.apps.description))
		#expect(paths.contains(App.path(slug: "lungo").description))
		#expect(!paths.contains("/"))
		#expect(!paths.contains(RoutePath.notFound.description))
		#expect(!paths.contains(RoutePath.randomApp.description))
		#expect(oldPaths.isDisjoint(with: paths))
	}

	/**
	Google asks a page that links to the pages of its items to give each item only its position and URL, as each app page has the full structured data of its app.
	*/
	@Test
	func `the structured data of the apps page is a list of links to the app pages`() async throws {
		let page = try #require(try await RenderedPage.website.first { $0.route.path == RoutePath.apps })
		let json = try #require(page.html.scriptTags.first { $0.type == "application/ld+json" }?.body)
		let list = try #require(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
		let items = try #require(list["itemListElement"] as? [[String: Any]])
		let apps = try await SiteContent.website.activeAppsWithPages

		#expect(items.count == apps.count)
		#expect(items.allSatisfy { Set($0.keys) == ["@type", "position", "url"] })
		#expect(items.first?["url"] as? String == apps.first?.path.absoluteURL.absoluteString)
	}

	/**
	The whole build, like `website build`, but offline: it publishes every route and checks the links.
	*/
	@Test(.temporaryDirectory)
	func `the site builds without broken links`() async throws {
		let output = try URL.temporaryDirectory().appending(path: "dist")
		let report = try await Site.build(project: .website, output: output, externalData: .none, isPreview: false)

		#expect(report.brokenLinks == [])
		#expect(report.warnings == [])
		#expect(report.routes.count > 200)

		// The files that every page loads have their content hash in the URL, so they can be cached for a year.
		let home = try String(contentsOf: output.appending(path: "index.html"), encoding: .utf8)
		#expect(home.contains(#"href="/assets/site.css?v="#))
		#expect(home.contains(#"src="/scripts/site.js?v="#))
		#expect(home.contains(#"href="/assets/icons.svg?v="#))

		// Also in Markdown, which renders before the pages, like the icons of the copy button of a code block.
		let appPage = try String(contentsOf: output.appending(path: "lungo.html"), encoding: .utf8)
		#expect(appPage.contains(#"class="code-block""#))
		#expect(!appPage.contains(#"href="/assets/icons.svg#"#))

		// An element with an inline script, like the header of the site, has its script in the page, once, and no script file.
		#expect(appPage.ranges(of: "customElements.define('site-header'").count == 1)
		#expect(!output.appending(path: "scripts/elements/SiteHeader.js").exists)

		// An element with a script file, like the copy button, loads the published file once.
		let contact = try String(contentsOf: output.appending(path: "contact.html"), encoding: .utf8)
		#expect(contact.ranges(of: "/scripts/elements/CopyButton.js?v=").count == 1)
		#expect(output.appending(path: "scripts/elements/CopyButton.js").exists)

		// Every social card is a 1200×630 image. Only the header of each file is read.
		let cards = try output.appending(path: "og").filesRecursively()
		#expect(cards.count > 50)

		for card in cards {
			let properties = CGImageSourceCreateWithURL(card as CFURL, nil).flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
			let hasCardSize = properties?[kCGImagePropertyPixelWidth] as? Int == 1200 && properties?[kCGImagePropertyPixelHeight] as? Int == 630
			#expect(hasCardSize, "\(card.lastPathComponent) is not a 1200×630 image.")
		}

		// Each page has at most one import map, with only the scripts that its scripts import, before its module scripts, as browsers only use an import map that comes first, and every script in it is published with the hash it maps to.
		for page in try output.filesRecursively() where page.pathExtension == "html" {
			let html = try String(contentsOf: page, encoding: .utf8)

			// Not the files that are published unchanged from `public`.
			guard
				!Project.website.publicDirectory.appending(path: page.path(relativeTo: output)).isFile,
				html.contains(#"type="module""#)
			else {
				continue
			}

			// Every script that the page loads from `/scripts` has its hash, also the scripts of the elements, which the build finds in the `Scripts` folders.
			let scripts = html.scriptTags
			for source in scripts.compactMap(\.source) where source.hasPrefix("/scripts/") {
				#expect(source.contains("?v="), "\(page.lastPathComponent) loads \(source) without its hash.")
			}

			let importMaps = scripts.filter { $0.type == "importmap" }
			try #require(importMaps.count <= 1, "\(page.lastPathComponent) must have at most one import map.")

			// A page whose scripts import nothing has none.
			guard let importMap = importMaps.first else {
				continue
			}

			let firstModule = try #require(scripts.first { $0.type == "module" }?.range)
			#expect(importMap.range.upperBound <= firstModule.lowerBound, "The import map of \(page.lastPathComponent) must come before its module scripts.")

			let imports = try JSONDecoder().decode(Site.Scripts.ImportMap.self, from: Data(importMap.body.utf8)).imports

			if page.lastPathComponent == "1999.html" {
				#expect(imports.keys.contains("/scripts/geocities-element.js"))
			}

			// Every script that a script of the page imports is in the map, so it loads with its hash.
			for source in scripts.compactMap(\.source) where source.hasPrefix("/scripts/") {
				let path = source.prefix { $0 != "?" }
				let script = try String(contentsOf: output.appending(path: String(path.dropFirst())), encoding: .utf8)

				for imported in script.matches(of: /^import\b[^;'\n]*'(\/scripts\/[^']+)'/.anchorsMatchLineEndings()) {
					#expect(imports.keys.contains(String(imported.1)), "The import map of \(page.lastPathComponent) does not have \(imported.1), which \(path) imports.")
				}
			}

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
		let sharedClasses = Self.classNames(inCSS: Stylesheet.site.css)
		var usedClasses = Set<String>()

		for page in try await RenderedPage.website {
			let pageClasses = Set(page.html.matches(of: /\sclass="([^"]*)"/).flatMap { $0.1.split(separator: " ").map(String.init) })
			let definedClasses = page.embeddedStyles.reduce(into: sharedClasses) { $0.formUnion(Self.classNames(inCSS: String($1))) }
			let undefinedClasses = pageClasses.subtracting(definedClasses).filter { !Self.classesWithoutRules.contains($0) && !$0.hasPrefix("language-") }

			#expect(undefinedClasses.isEmpty, "\(page.route.path) uses classes without rules: \(undefinedClasses.sorted())")
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
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let quotedValue = /'[^']*'|"[^"]*"/
		let className = /\.([a-z][a-z0-9-]*)/

		return Set(css.split(separator: "\n").filter { $0.hasSuffix("{") && !$0.contains("view-transition") }.flatMap { line in
			line.replacing(quotedValue, with: "").matches(of: className).map { String($0.1) }
		})
	}

	/**
	With reduced motion, nothing moves by itself (“Motion” in `AGENTS.md`), as `animation()` writes the animation in `@media (prefers-reduced-motion: no-preference)`. The exceptions are the essential animations, and the scroll-driven animations, which follow the scrolling of the visitor and have their `animation-timeline` on the next line.
	*/
	@Test
	func `animations only run for visitors who allow motion`() async throws {
		let essentialAnimations = [ProseAnimations.targetHighlight.name]
		// Before the loops, as Swift parses a regex literal each time the code runs.
		let animationDeclaration = /animation: (.+);/
		var stylesheets = [Stylesheet.site.css]
		var animationCount = 0

		for page in try await RenderedPage.website {
			stylesheets += page.embeddedStyles.map(String.init)
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
					let value = line.wholeMatch(of: animationDeclaration)?.1,
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
	func `the shared stylesheet defines each class once`() {
		// Top-level rules in the layers are indented once.
		let selectors = Stylesheet.site.css.split(separator: "\n").compactMap { line in
			line.wholeMatch(of: /\t(\.[a-z0-9-]+) \{/).map { String($0.1) }
		}

		#expect(!selectors.isEmpty)
		#expect(Dictionary(grouping: selectors, by: \.self).filter { $0.value.count > 1 }.keys.sorted() == [])
	}

	/**
	Markdown renders before the pages, so the page gets the script of the copy buttons of the code blocks from the resources of the document.
	*/
	@Test
	func `code blocks in Markdown are highlighted, and the page gets the script of their copy button once`() async throws {
		let html = try #require(try await RenderedPage.website.first { $0.route.path == #path("/_gallery") }).html
		#expect(html.contains(#"<code class="code-block-code"><span class="code-block-attribute">@MainActor</span>"#))
		#expect(html.contains(#"<code class="code-block-code"><span class="code-block-comment"># Every kind of highlighted token.</span>"#))
		#expect(html.ranges(of: "/scripts/elements/CopyButton.js").count == 1)
	}

	/**
	The icons have the hash of the sprite wherever they render, also outside a build, like Markdown that renders while the content loads.
	*/
	@Test
	func `icons have the hash of the sprite without a build`() {
		let html = CodeBlock(source: "ls\n", language: .console).render()

		#expect(html.contains(/href="\/assets\/icons\.svg\?v=[0-9a-f]+#/))
	}

	/**
	The bar shows the language as it is written, so a typo would show as the label.
	*/
	@Test
	func `a code block with an unknown language is a problem`() {
		let document = MarkdownDocument(parsing: "Text.\n\n```swfit\nlet a = 1\n```", options: .gallery)

		#expect(document.problems.map(\.line) == [3])
		#expect(document.problems.first?.reason.hasPrefix("The code block is invalid: Must be one of `applescript`, `console`,") == true)
		#expect(document.problems.first?.reason.hasSuffix("or `yaml`, not “swfit”. Did you mean `swift`?") == true)
	}

	@Test
	func `each line of a console code block is an element, for the prompt of the styles`() {
		let html = CodeBlock(source: "open -g 'a<b'\n\nls\n", language: .console).render()

		#expect(html.contains(#"<code class="code-block-code code-block-console"><span>open -g 'a&lt;b'</span>\#n\#n<span>ls</span>\#n</code>"#))
	}

	@Test
	func `llms-full.txt has the older versions, the shared questions, and the sponsors from the frontmatter`() async throws {
		let route = try #require(try await Self.site().routes().first { $0.path == #path("/llms-full.txt") })
		let text = String(decoding: try await route.renderedFile(), as: UTF8.self)
		#expect(text.contains("## Older Versions\n\n- ["))
		#expect(text.contains("### Why does it not show week 53?\n\nYou are probably expecting"))
		#expect(text.contains("- [GitHub](https://github.com)"))
		#expect(!text.contains("@Sponsors"))
	}

	/**
	The blocks of the file keep their source, and the build only adds blocks, except for the feedback question, which gets its ID. Lines with links are left out, as the links are absolute. A block with the syntax of the site is formatted without it, so its lines with the syntax, indented lines, and table rows are left out, and smart punctuation makes its quotes typographic. HTML comments are removed.
	*/
	@Test
	func `llms-full.txt has each line of the app files`() async throws {
		let route = try #require(try await Self.site().routes().first { $0.path == #path("/llms-full.txt") })
		let lines = Set(String(decoding: try await route.renderedFile(), as: UTF8.self).replacing("’", with: "'").split(separator: "\n"))

		for app in try await SiteContent.website.activeAppsWithPages {
			let body = app.file.body.replacing(/(?s)<!--.*?-->/, with: "")

			for line in body.split(separator: "\n") where !line.allSatisfy(\.isWhitespace) && !line.contains("](") && !line.contains(#"="/"#) && !line.hasPrefix("### \(App.Section.feedbackQuestion.title)") && line.firstMatch(of: /^[\s|}@]|\+\+|\^\[|\{#/) == nil {
				#expect(lines.contains(Substring(line.replacing("’", with: "'"))), "\(app.file.slug): \(line)")
			}
		}
	}

	/**
	The file is for readers outside the site, so it has none of the syntax of the site, like block directives, keyboard shortcuts, inline notes, heading IDs, and heading directives.
	*/
	@Test
	func `llms-full.txt has no syntax of the site`() async throws {
		let route = try #require(try await Self.site().routes().first { $0.path == #path("/llms-full.txt") })
		let text = String(decoding: try await route.renderedFile(), as: UTF8.self)
		#expect(BlockDirectiveName.allCases.allSatisfy { name in text.firstMatch(of: Regex { "@\(name.rawValue)"; Anchor.wordBoundary }) == nil })
		#expect(text.firstMatch(of: /\+\+[A-Z]\w*\+/) == nil)
		#expect(!text.contains("^["))
		// Only headings, as a code block can have the syntax of an app, like `[Ana]{#00ff00}` for colored text.
		#expect(text.firstMatch(of: /^#{1,6} .*\{#[\w-]+\}$/.anchorsMatchLineEndings()) == nil)
		#expect(!text.contains("<!-- @"))
		#expect(text.contains("## Open each link in the right place\n"))
		#expect(text.contains("Shift+Command+N"))
		#expect(text.contains("## Copy URL\n\nAdds copy functionality to browser picker apps.\n\n"))
		#expect(text.firstMatch(of: /\*Requires macOS [\d.]+ or later\*/) != nil)

		// Each guide has its date and the facts of its app, like the app page.
		for resolved in try await SiteContent.website.resolvedGuides {
			let guide = resolved.guide
			#expect(text.contains("# \(guide.title)\n\nUpdated: \(guide.lastModified.foundationDate.formatted(.siteDay))\n\n\(resolved.app.title): "))
			#expect(text.contains("\nURL: \(guide.path.absoluteURL.absoluteString)\n\n"))
		}
	}

	/**
	Mastodon finds the account by the WebFinger file, so searching for an account on the domain of the site finds the Mastodon account.
	*/
	@Test
	func `WebFinger points to the Mastodon account`() async throws {
		struct Resource: Decodable {
			struct Link: Decodable {
				let rel: String
				let href: String?
				let template: String?
			}

			let subject: String
			let aliases: [String]
			let links: [Link]
		}

		let route = try #require(try await Self.site().routes().first { $0.path == #path("/.well-known/webfinger") })
		let resource = try JSONDecoder().decode(Resource.self, from: try await route.renderedFile())

		#expect(resource.subject == "acct:sindresorhus@mastodon.social")
		#expect(resource.aliases == ["https://mastodon.social/@sindresorhus", "https://mastodon.social/users/sindresorhus"])
		#expect(resource.links.first { $0.rel == "self" }?.href == "https://mastodon.social/users/sindresorhus")
		#expect(resource.links.first { $0.rel == "http://ostatus.org/schema/1.0/subscribe" }?.template == "https://mastodon.social/authorize_interaction?uri={uri}")
	}

	/**
	Assistants quote the facts of llms.txt, so each app has them, and the featured apps come first.
	*/
	@Test
	func `llms.txt has the facts of each app, with the featured apps first`() async throws {
		let route = try #require(try await Self.site().routes().first { $0.path == #path("/llms.txt") })
		let lines = String(decoding: try await route.renderedFile(), as: UTF8.self).split(separator: "\n")
		let content = try await SiteContent.website
		let appLines = lines.filter { line in content.activeAppsWithPages.contains { line.hasPrefix("- [\($0.title)](\($0.path.absoluteURL.absoluteString).md)") } }

		#expect(appLines.count == content.activeAppsWithPages.count)
		#expect(appLines.allSatisfy { $0.contains(" Platforms: ") })
		#expect(zip(appLines, content.featuredApps).allSatisfy { line, app in line.hasPrefix("- [\(app.title)]") })
		#expect(!content.featuredApps.isEmpty)
		let gifski = try #require(content.activeAppsWithPages.first { $0.file.slug == "gifski" })
		#expect(appLines.contains { $0.hasPrefix("- [Gifski]") && $0.contains("Price: Free. Platforms: \(gifski.operatingSystems). Get it from: [App Store](\(gifski.appStoreURL?.absoluteString ?? "")).") })
		#expect(appLines.contains { $0.hasPrefix("- [Dato]") && $0.contains(" Free trial: [download](https://sindresorhus.com/dato#trial).") && $0.contains(" Free older versions for macOS ") && $0.hasSuffix(": [download](https://sindresorhus.com/dato#older-versions).") })
		// The tests have no App Store data and no appcasts, so only the apps with `minimumOSVersion` have a requirement.
		#expect(content.activeAppsWithPages.allSatisfy { app in
			appLines.contains { $0.hasPrefix("- [\(app.title)]") && $0.contains(". Requires ") == (content.listing(of: app).minimumOSVersion != nil) }
		})

		for guide in content.guides {
			#expect(lines.contains("- [\(guide.title)](\(guide.path.absoluteURL.absoluteString).md): \(guide.description)"))
		}
	}

	/**
	Assistants find the pages of the site in llms.txt, so it has every indexed page, also the pages that are written in Swift, like the open-source page, and the Markdown copy of each page that has one, like `/dato.md`. The privacy policies and the release notes are left out, as the app pages have the facts, and the home page, as it is the summary at the top.
	*/
	@Test
	func `llms.txt has every indexed page, and llms-full.txt the open-source projects`() async throws {
		let routes = try await Self.site().routes()
		let content = try await SiteContent.website
		let llms = String(decoding: try #require(try await routes.first { $0.path == #path("/llms.txt") }?.renderedFile()), as: UTF8.self)
		let leftOut = Set(content.apps.map(\.privacyPolicyPath) + content.apps.compactMap(\.releaseNotes?.path) + [.root])
		let routePaths = Set(routes.map(\.path))

		for route in routes where route.sitemapEntry != nil && !leftOut.contains(route.path) {
			let url = route.path.absoluteURL.absoluteString
			#expect(llms.contains("](\(url))") || llms.contains("](\(url).md)"), "\(route.path) is not in llms.txt.")
		}

		// Each Markdown copy that llms.txt links to is published.
		for match in llms.matches(of: /\]\(https:\/\/sindresorhus\.com(\/[^)]+\.md)\)/) {
			#expect(routePaths.contains(RoutePath(String(match.1))), "\(match.1) is not published.")
		}

		let llmsFull = String(decoding: try #require(try await routes.first { $0.path == #path("/llms-full.txt") }?.renderedFile()), as: UTF8.self)
		#expect(llmsFull.contains("## Promises and Async\n\nSmall packages for async code in JavaScript.\n\n- [p-limit](https://github.com/sindresorhus/p-limit): Run promise-returning and async functions with limited concurrency. (JavaScript)"))
	}

	/**
	An assistant can read one page without the whole `llms-full.txt`, so each page has a Markdown copy next to it, which is its section of the file. An archived app says that it is no longer available, and a post has its date, as it is advice of its time.
	*/
	@Test
	func `the Markdown copy of a page is its section of llms-full.txt`() async throws {
		let routes = try await Self.site().routes()

		func text(_ path: RoutePath) async throws -> String {
			String(decoding: try await #require(routes.first { $0.path == path }).renderedFile(), as: UTF8.self)
		}

		let dato = try await text(#path("/dato.md"))
		#expect(try await text(#path("/llms-full.txt")).contains("\n\n---\n\n\(dato)\n\n---\n\n"))
		#expect(dato.hasPrefix("# Dato\n\n"))
		#expect(dato.contains(" Free trial: [download](https://sindresorhus.com/dato#trial)."))
		#expect(try await text(#path("/jiffy.md")).contains("The app is archived, so it is no longer available."))
		#expect(try await text(#path("/blog/small-focused-modules.md")).contains("Published: October 2018"))
		#expect(try await text(#path("/llms.txt")).contains("](https://sindresorhus.com/blog/small-focused-modules.md): Make small focused modules for reusability and to make it possible to build larger more advanced things that are easier to reason about. (2018)"))
	}

	/**
	The file is read outside the site, so a link to another page, like `donate.md` on the about page, is an absolute URL.
	*/
	@Test
	func `llms-full.txt has absolute links`() async throws {
		let route = try #require(try await Self.site().routes().first { $0.path == #path("/llms-full.txt") })
		let text = String(decoding: try await route.renderedFile(), as: UTF8.self)
		#expect(!text.contains("](donate.md)"))
		#expect(!text.contains("](../"))
		#expect(text.contains("](https://sindresorhus.com/supporters)"))
		#expect(text.contains("](https://sindresorhus.com/donate)"))
		#expect(text.firstMatch(of: /(src|href)="\//) == nil)
	}

	/**
	Compact link previews, like in Messages, show only the title and the domain, so the title of an app has its subtitle.
	*/
	@Test
	func `the social title of an app page has the subtitle`() async throws {
		let page = try #require(try await RenderedPage.website.first { $0.route.path == #path("/dato") })
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "dato" })
		#expect(page.html.contains(#"<meta property="og:title" content="\#(app.title): \#(app.subtitle)">"#))
	}

	/**
	Feed readers know the items by their GUIDs, so the GUIDs of redirect posts and of the launch of Super Menu must not change. The real content has no listed redirect posts, and Super Menu is a draft.
	*/
	@Test
	func `the blog feed keeps the GUIDs of redirect posts and of the launch of Super Menu`() async throws {
		let post = try await BlogPost(markdown: "---\ntitle: 'Elsewhere'\npublicationDate: 2026-01-01\nredirectURL: 'https://example.com/post'\n---\n", slug: "elsewhere")
		let app = try await App(title: "Super Menu", publicationDate: "2026-01-02", slug: "super-menu")
		let content = SiteContent.test(apps: [app], posts: [post])
		let xml = try SiteFeed.blog.feed(content: content).xmlString()

		#expect(xml.contains(#"<guid isPermaLink="false">https://sindresorhus.com/blog/elsewhere</guid>"#))
		#expect(xml.contains(#"<guid isPermaLink="false">https://sindresorhus.com/super-menu#launch</guid>"#))
	}
}

/**
Small layout components that can be rendered without loading every page.
*/
struct PageComponentTests {
	@Test
	func `page slices retain their specialized social card route expansion`() {
		struct CardPage: Page {
			let path: RoutePath
			let metadata = PageMetadata(title: "Card page")

			var socialImage: SocialImage {
				.card(OpenGraphCard(path: path.appending("card.jpg"), title: "Card", subtitle: "", artwork: .icons([]), description: "Card"))
			}

			var body: some HTML {
				EmptyHTML()
			}
		}

		let pages = [CardPage(path: #path("/first")), CardPage(path: #path("/second"))]
		@RouteBuilder
		var routes: [Route] {
			pages[1...]
		}
		#expect(routes.map(\.path) == [#path("/second"), #path("/second/card.jpg")])
	}

	@Test
	func `schema objects own JSON-LD keywords during direct encoding`() throws {
		let person = Schema.Person(id: #URL("https://example.com/#person"), name: "Author")
		let model = Schema.ProfilePage(context: "https://schema.org", mainEntity: person)
		let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(model)) as? [String: Any])
		#expect(object["@context"] as? String == "https://schema.org")
		#expect(object["@type"] as? String == "ProfilePage")
		#expect(object["type"] == nil)
		let author = try #require(object["mainEntity"] as? [String: Any])
		#expect(author["@type"] as? String == "Person")
		#expect(author["@id"] as? String == "https://example.com/#person")
		#expect(author["id"] == nil)
	}

	@Test(arguments: [false, true])
	func `a custom link name preserves the notice when it opens a new tab`(opensInNewTab: Bool) {
		var link = LabeledLink("Read", destination: .path(.about))
		link.accessibilityLabel = "Read about Sindre"
		let html = Link(link, opensInNewTab: opensInNewTab).render()
		let notice = opensInNewTab ? " (opens in a new tab)" : ""

		#expect(html.contains("aria-label=\"Read about Sindre\(notice)\""))
		#expect(html.contains("target=\"_blank\"") == opensInNewTab)
	}

	@Test
	func `an empty custom link name leaves its visible text accessible`() {
		var link = LabeledLink("Read about Sindre", destination: .path(.about))
		link.accessibilityLabel = ""
		let html = Link(link, opensInNewTab: true).render()

		#expect(!html.contains("aria-label="))
		#expect(html.contains("Read about Sindre"))
		#expect(html.contains(" (opens in a new tab)"))
	}

	@Test
	func `the app hero preserves the semantics of its list of facts`() async throws {
		let app = try await App(title: "A useful app")
		let html = AppHero(listing: AppListing(app: app), buildDate: .now, hasGuides: false).render()

		#expect(html.contains(#"<ul role="list" class="app-hero-facts">"#))
		#expect(html.contains("<li class=\"app-hero-fact\">"))
	}

	@Test
	func `the toy shelf remains an accessible image`() throws {
		let html = GeoCitiesKinderEgg().render()
		let shelf = try #require(html.firstMatch(of: /<canvas\b[^>]*data-part="shelf"[^>]*>/)?.output)

		#expect(shelf.contains(#"role="img""#))
		#expect(!shelf.contains(#"role="group""#))
		#expect(shelf.contains("aria-label="))
	}

	@Test
	func `a diff copies the new code with its context indentation and blank lines`() {
		let source = " let greeting = \"Hello\"\n-print(greeting)\n+print(\"🦄\")\n \tprint(greeting)\n+\n"
		let html = CodeBlock(source: source, language: .diff).render()

		// Without the newline at the end of the source. The newline that stays is the added blank line.
		#expect(html.contains("text=\"let greeting = &quot;Hello&quot;\nprint(&quot;🦄&quot;)\n\tprint(greeting)\n\""))
		#expect(html.contains(#"<span class="code-block-removed">-print(greeting)</span>"#))
		#expect(html.contains(#"<span class="code-block-added">+print("🦄")</span>"#))
	}

	@Test
	func `a JPEG XL picture without a copy renders its image with its attributes`() {
		let html = JPEGXLPicture(copy: nil) {
			img(.src("/image.png"), .alt("An image"), .width(40), .height(30))
		}.render()

		#expect(html == #"<img src="/image.png" alt="An image" width="40" height="30">"#)
	}

	private struct MetadataPage: Page {
		let path = RoutePath.root
		let metadata = PageMetadata(title: "Test")

		var body: some HTML {
			EmptyHTML()
		}
	}

	@Test
	func `a page title adds the site name unless the title names the page alone`() {
		#expect(PageMetadata(title: "Apps").documentTitle == "Apps — Sindre Sorhus")
		#expect(PageMetadata(title: "Dato", isTitleStandalone: true).documentTitle == "Dato")
		#expect(PageMetadata(title: "Sindre Sorhus", isTitleStandalone: true).documentTitle == "Sindre Sorhus")
	}

	@Test
	func `typed speculation predicates retain their JSON`() throws {
		let html = try Site.Scripts.$published.withValue(.website) {
			SiteLayout(
				page: MetadataPage(),
				bodyHTML: try RenderedHTML {
					EmptyHTML()
				},
				inlineScripts: []
			)
			.head
			.render()
		}
		let json = try #require(html.firstMatch(of: /<script type="speculationrules">(.*?)<\/script>/)?.1)
		#expect(String(json) == #"{"prefetch":[{"eagerness":"moderate","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":["/*.*","/1999"]}}]}}],"prerender":[{"eagerness":"conservative","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":["/*.*","/1999","/apps/random","/feedback"]}}]}}]}"#)
	}

	@Test
	func `FAQ previews match automatic and generated heading IDs to the right answer`() async throws {
		let app = try await App(
			frontmatter: "appStoreID: 1",
			body: """
			[First answer](#how-do-i-use-it) and [second answer](#how-do-i-use-it-1).

			[Free answer](#why-is-this-free-without-ads) and [localization answer](#can-you-localize-the-app-into-my-language).

			## Frequently Asked Questions {#faq}

			### How do I use it?

			First answer.

			### How do I use it?

			Second answer.
			"""
		)
		let data = LinkPreview.data(for: SiteContent.test(apps: [app]))
		let previews = try JSONDecoder().decode([String: [String: String]].self, from: data)

		#expect(previews["/test#how-do-i-use-it"]?["subtitle"] == "First answer.")
		#expect(previews["/test#how-do-i-use-it-1"]?["subtitle"] == "Second answer.")
		#expect(previews["/test#why-is-this-free-without-ads"]?["subtitle"] == "I just enjoy making apps. Consider leaving a nice review on the App Store.")
		#expect(previews["/test#can-you-localize-the-app-into-my-language"]?["subtitle"] == "I don’t plan to localize the app.")
	}
}
