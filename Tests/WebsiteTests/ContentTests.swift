import Elementary
import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct ContentTests {
	@Test
	func `minimal app frontmatter loads with defaults`() async throws {
		let app = try await App(markdown: """
		---
		title: 'Test'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		---

		Test app.
		""")

		#expect(app.title == "Test")
		#expect(app.platforms == [.macOS])
		#expect(!app.isPaid)
		#expect(app.showsSupportLink)
		#expect(app.description == "Test app. Test app.")
		// A new app can be previewed before it has an icon.
		#expect(app.iconPath == App.placeholderIconPath)
	}

	@Test(arguments: [
		("isDraft: 'false'", "Invalid `isDraft`"),
		("unexpected: true", "Unknown key unexpected,"),
		("platforms: ['Amiga']", "Invalid `platforms.[0]`"),
		("appStoreID: -1", "Invalid `appStoreID`"),
		("repositoryURL: 'github.com/sindresorhus'", "Invalid `repositoryURL`"),
		("links: {Docs: '/docs'}", "Invalid `links.Docs`"),
		("pressQuotes: [{quote: 'Great', source: 'Example', url: 'example.com'}]", "Invalid `pressQuotes.[0].url`"),
		("olderMacOSVersions: ['9']", "Invalid `olderMacOSVersions.[0]`"),
		("olderVersions: [{version: '1.0.0', macOS: '9', url: 'https://example.com/app.zip'}]", "Invalid `olderVersions.[0].macOS`"),
		("olderVersions: [{version: '1.0.0', macOS: '13', url: 'app.zip'}]", "Invalid `olderVersions.[0].url`"),
		("announcement: {text: 'Sale', url: 'relative/path'}", "Invalid `announcement.url`"),
		("redirectFrom: ['old-name']", "Invalid `redirectFrom.[0]`"),
		("script: '/missing.js'", "The `script` /missing.js does not exist"),
		("description: ' '", "Invalid `description`"),
		("downloads: 9007199254740992", "Invalid `downloads`"),
		("pressQuotes: [{quote: '', source: 'Example'}]", "Invalid `pressQuotes.[0].quote`"),
	])
	func `strict app frontmatter rejects invalid values`(line: String, reason: String) async {
		let platforms = line.hasPrefix("platforms:") ? "" : "platforms: ['macOS']\n"
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\n\(platforms)\(line)\n---")

		#expect(errors.count == 1)
		#expect(errors.first?.reason.hasPrefix(reason) == true, "\(errors)")
		#expect(errors.first?.line != nil)
	}

	@Test
	func `subtitle must not end with punctuation`() async {
		await #expect(throws: ContentError.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app.'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---")
		}
	}

	@Test
	func `links keep their order and merge like JavaScript objects`() async throws {
		let app = try await App(markdown: """
		---
		title: 'Test'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		repositoryURL: 'https://github.com/sindresorhus/test'
		mainLinks: {
			Zebra: 'https://example.com/zebra',
			'Learn More': 'https://example.com/more',
			Apple: 'https://example.com/apple',
		}
		---
		""")

		#expect(app.mainLinks.map(\.destination.description) == ["https://example.com/more", "https://example.com/zebra", "https://example.com/apple"])
		#expect(app.mainLinks.map(\.title) == ["Learn More", "Zebra", "Apple"])
	}

	@Test
	func `FAQ section gets the feedback question`() async throws {
		let app = try await App(markdown: """
		---
		title: 'My App'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		---

		## Frequently Asked Questions {#faq}

		### Some question

		Answer.
		""")

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "some-question", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.html.contains("https://sindresorhus.com/feedback?product=My%20App&amp;referrer=Website-FAQ"))
		// The added answer is not in the file, so it has no line.
		#expect(app.markdown.links.filter { $0.destination.contains("/feedback?") }.map(\.line) == [nil])
		#expect(app.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
		#expect(app.links.contains(LabeledLink("FAQ", destination: .fragment("faq"))))
	}

	/**
	The added questions go before the first question, so text under the FAQ heading stays above the questions instead of becoming an answer.
	*/
	@Test
	func `text under the FAQ heading stays above the questions`() async throws {
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisMenuBarApp: true\n---\n\n## Frequently Asked Questions {#faq}\n\nThese are common questions.\n\n### A question\n\nAn answer.")
		let html = app.markdown.html
		let intro = try #require(html.range(of: "These are common questions."))
		let firstQuestion = try #require(html.range(of: "<details"))
		#expect(intro.lowerBound < firstQuestion.lowerBound)
	}

	/**
	The answer goes after the directives of the question, which must be directly below it.
	*/
	@Test
	func `an existing feature request question with directives gets the feedback answer`() async throws {
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### I have a feature request, bug report, or some feedback\n<!-- @faq.keywords idea -->\n\nSure.")
		#expect(app.markdown.html.contains("send it here."))
	}

	@Test
	func `existing feature request question gets the feedback answer`() async throws {
		let app = try await App(markdown: """
		---
		title: 'My App'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		---

		## Frequently Asked Questions {#faq}

		### I have a feature request, bug report, or some feedback {#requests}

		Sure.
		""")

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.html.contains("send it here."))
	}

	@Test
	func `a free menu bar app on the App Store gets the common questions`() async throws {
		let app = try await App(markdown: """
		---
		title: 'My App'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		isMenuBarApp: true
		appStoreID: 1
		---

		## Frequently Asked Questions {#faq}

		### Some question

		Answer.
		""")

		// The menu bar question goes first, after the feedback question, and the others go after the questions of the file.
		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "the-app-does-not-show-up-in-the-menu-bar", "some-question", "why-is-this-free-without-ads", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.links.filter { $0.destination == "/apps/faq#app-not-showing-in-menu-bar" }.map(\.line) == [nil])

		// The feedback page suggests them like the questions of the file.
		let questions = try #require(FAQSuggestions.Questions(apps: [app], faq: nil).apps.first).questions
		#expect(questions.map(\.question) == ["The app does not show up in the menu bar", "Some question", "Why is this free without ads?", "Can you localize the app into my language?"])
		#expect(questions.first?.url == .path(app.path, fragment: "the-app-does-not-show-up-in-the-menu-bar"))
	}

	/**
	The questions are level 3 headings, so a level 4 question would be a heading in the answer above it.
	*/
	@Test
	func `a level 4 heading in the FAQ section is an error`() async {
		#expect(await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question\n\nAnswer.\n\n#### Another question\n\nAnswer.").map(\.line) == [14])
		#expect(await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n#### Not in the FAQ\n\n## Frequently Asked Questions {#faq}\n\n### A question\n\nAnswer.").isEmpty)
	}

	@Test
	func `an app that is not in the menu bar or on the App Store gets only the localization question`() async throws {
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.")
		let paidApp = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nappStoreID: 1\n---\n\n## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.")

		#expect(app.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
		#expect(paidApp.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
	}

	@Test
	func `an app without a FAQ section gets no common questions`() async throws {
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisMenuBarApp: true\n---\n\nText.")

		#expect(app.markdown.headings.isEmpty)
	}

	@Test
	func `a file that writes a common question keeps its own answer`() async throws {
		let app = try await App(markdown: """
		---
		title: 'My App'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		isMenuBarApp: true
		---

		## Frequently Asked Questions {#faq}

		### Can you localize the app into my language? {#language}

		No, the app is English-only.

		### The app does not show up in the menu bar

		My own answer.
		""")

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "language", "the-app-does-not-show-up-in-the-menu-bar"])
		#expect(app.markdown.html.contains("My own answer."))
		#expect(!app.markdown.html.contains("Try this"))
		#expect(!app.markdown.html.contains("I don’t plan to localize the app."))
	}

	@Test
	func `related apps are similar apps, without the app itself, and the same all day`() async throws {
		var apps = [App]()

		for slug in ["a", "b", "c", "d", "e", "f"] {
			apps.append(try await App(markdown: "---\ntitle: '\(slug)'\nsubtitle: 'App'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---", slug: slug))
		}

		let morning = Date(timeIntervalSince1970: 1_800_000_000)
		let related = apps[0].relatedApps(from: apps, on: morning)

		#expect(related.count == 4)
		#expect(!related.map(\.slug).contains("a"))
		#expect(related.map(\.slug) == apps[0].relatedApps(from: apps, on: morning.addingTimeInterval(60)).map(\.slug))
	}

	@Test
	func `an impossible day is rejected instead of moved`() async {
		await #expect(throws: ContentError.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-02-30'\nplatforms: ['macOS']\n---\n\nText.")
		}
	}

	@Test
	func `the FAQ heading needs its ID`() async {
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions\n\n### A question\n\nAn answer.")

		#expect(errors.map(\.line) == [8])
		#expect(errors.first?.reason.hasPrefix("The “Frequently Asked Questions” heading needs the ID `faq`") == true)
	}

	@Test
	func `every problem in the feedback note is reported at its key`() async {
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nfeedbackNote: 'See [this](missing.md) and ![](/image.png).'\n---\n\nText.")

		#expect(errors.map(\.line) == [6, 6])
		#expect(errors.allSatisfy { $0.reason.hasPrefix("`feedbackNote`: ") })
	}

	@Test
	func `body problems are reported at their lines in the file`() async {
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\nText.\n\n![](/image.png)\n\n## Question\n<!-- @faq.platforms Amiga -->")

		#expect(errors.map(\.line) == [10, 13])
	}

	@Test
	func `blog posts check the heading directives`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Post'\npublicationDate: '2026-01-01'\n---\n\n## Question\n<!-- @faq.platforms Amiga -->", slug: "post")
		}

		#expect(errors.errors.map(\.line) == [7])
		#expect(errors.errors.first?.reason.hasPrefix("The values of `@faq.platforms` are invalid") == true)
	}

	@Test
	func `a pinned question needs one rank`() async {
		let error = await #expect(throws: ContentErrors.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.pinned -->\n\n### Another question {#another}\n<!-- @faq.pinned 1 2 -->\n\nAn answer.")
		}

		#expect(error?.errors.map(\.line) == [11, 14])
		#expect(error?.errors.first?.reason.hasSuffix("It needs one rank, like `<!-- @faq.pinned 1 -->`.") == true)
	}

	@Test
	func `only the general FAQ page can mark general questions`() async {
		let error = await #expect(throws: ContentErrors.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.general -->\n\nAn answer.")
		}

		#expect(error?.errors.map(\.line) == [11])
		#expect(error?.errors.first?.reason.hasPrefix("Unknown directive `@faq.general`.") == true)
	}

	@Test
	func `an app needs a platform`() async {
		await #expect(throws: ContentError.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: []\n---\n\nText.")
		}
	}

	@Test
	func `details and tips directives look like collapsible sections and alerts`() throws {
		let file = try MarkdownFile(contents: "@Details(summary: \"Why *not*?\") {\n  Because.\n}\n\n@Tips {\n  - One\n}", url: Project.empty.root.appending(path: "content/blog/post.md"))
		let html = try MarkdownDocument(parsing: file, options: .content(file, project: .empty)).html

		#expect(html.contains(#"<details class="\#(ProseStyles.collapsibleSection.className)"><summary class="\#(ProseStyles.collapsibleSummary.className)"><span class="\#(ProseStyles.collapsibleTitle.className)">Why <em>not</em>?</span>"#))
		#expect(html.contains(#"<div class="\#(MarkdownTheme.site.classes(for: .alert(.tip)))" dir="auto"><p class="\#(ProseStyles.alertTitle.className)" dir="auto">"#))
		#expect(html.contains("Tips</p><ul>"))
	}

	@Test
	func `cards, steps, and social links directives keep nested lists and render the social links`() throws {
		let file = try MarkdownFile(contents: "@Cards {\n- Title\n\t- Point\n}\n\n@Steps {\n1. First\n\t- Note\n1. Second\n}\n\n@SocialLinks", url: Project.empty.root.appending(path: "content/pages/about.md"))
		let html = try MarkdownDocument(parsing: file, options: .content(file, project: .empty)).html

		#expect(html.contains(#"<div class="\#(CardListStyles.root.className)"><ul>\#n<li>Title\#n<ul>\#n<li>Point</li>"#))
		#expect(html.contains(#"<div class="\#(StepListStyles.root.className)"><ol>\#n<li>First\#n<ul>\#n<li>Note</li>\#n</ul>\#n</li>\#n<li>Second</li>"#))
		#expect(html.contains(#"<a href="https://github.com/sindresorhus" rel="me""#))
	}

	@Test
	func `social links directive has no content`() throws {
		let file = try MarkdownFile(contents: "@SocialLinks {\n- A link\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))

		#expect(throws: ContentErrors.self) {
			try MarkdownDocument(parsing: file, options: .content(file, project: .empty))
		}
	}

	@Test
	func `older versions get a section before the non-App Store version`() async throws {
		func loadApp(isPaid: Bool) async throws -> App {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: \(isPaid)\nolderVersions: [\n\t{version: '2.0.0', macOS: '15', url: 'https://example.com/a.zip?b=1&c=2'},\n\t{version: '1.10', macOS: '10.15', url: 'https://example.com/old.zip'},\n]\n---\n\nText.\n\n## Non-App Store Version\n\nDownload.")
		}

		let freeApp = try await loadApp(isPaid: false)
		let paidApp = try await loadApp(isPaid: true)

		#expect(freeApp.markdown.headings.map(\.id) == ["older-versions", "non-app-store-version"])
		#expect(freeApp.links.contains(LabeledLink("Older Versions", destination: .fragment("older-versions"))))
		#expect(freeApp.olderMacOSVersions == [.v15, .v10_15])
		#expect(freeApp.markdown.html.contains(#"<li><a href="https://example.com/a.zip?b=1&amp;c=2">2.0.0</a> for macOS 15+</li>"#))
		#expect(!freeApp.markdown.html.contains("These are free for everyone"))
		#expect(paidApp.markdown.html.contains(#"<li><a href="https://example.com/old.zip">1.10</a> for macOS 10.15</li>"#))
		#expect(paidApp.markdown.html.contains("<p>These are free for everyone but they will not run on newer macOS versions.</p>"))
	}

	@Test(arguments: [
		"olderMacOSVersions: ['13']\nolderVersions: [{version: '1.0.0', macOS: '13', url: 'https://example.com/app.zip'}]",
		"olderVersions: [{version: '1.0.0', macOS: '13', url: 'https://example.com/a.zip'}, {version: '1.1.0', macOS: '13', url: 'https://example.com/b.zip'}]",
		"olderMacOSVersions: ['13']",
	])
	func `older versions cannot be combined with older macOS versions or repeat a macOS version, and older macOS versions need a repo`(lines: String) async {
		await #expect(throws: ContentError.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n\(lines)\n---\n\nText.")
		}
	}

	@Test
	func `list subtitles and descriptions get the prose styles`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n- Get Active Browser Tab\n\t: Gets the URL\n\t:: Supports Safari.")

		#expect(app.markdown.html.contains(#"<span class="\#(ProseStyles.listSubtitle.className)">Gets the URL</span>\#n<span class="\#(ProseStyles.listDescription.className)">Supports Safari.</span>"#))
	}

	@Test(.temporaryDirectory)
	func `links to content files go to the pages of their content types`() throws {
		let project = Project(root: try URL.temporaryDirectory(files: [
			"content/apps/dato.md": "",
			"content/apps/gifski/index.md": "",
			"content/apps/gifski/icon.png": "",
			"content/blog/post.md": "",
			"content/pages/apps/faq.md": "",
		]))

		let file = try MarkdownFile(contents: "Text.", url: project.root.appending(path: "content/blog/post.md"), relativeTo: project.root.appending(path: "content/blog"))

		#expect(try file.resolvingLink("../apps/dato.md#faq", project: project) == LinkDestination.path(App.path(slug: "dato"), fragment: "faq").description)
		#expect(try file.resolvingLink("post.md", project: project) == BlogPost.path(slug: "post").description)
		#expect(try file.resolvingLink("../pages/apps/faq.md", project: project) == RoutePath.faq.description)
		#expect(try file.resolvingLink("https://example.com/readme.md", project: project) == "https://example.com/readme.md")
		#expect(throws: ContentError.self) {
			try file.resolvingLink("missing.md", project: project)
		}

		// A page bundle has the page of its directory, and its files are linked by their published path.
		let bundleFile = try MarkdownFile(contents: "Text.", url: project.root.appending(path: "content/apps/gifski/index.md"), relativeTo: project.root.appending(path: "content/apps"))
		#expect(try file.resolvingLink("../apps/gifski/index.md", project: project) == App.path(slug: "gifski").description)
		#expect(try bundleFile.resolvingLink("icon.png", project: project) == "/apps/gifski/icon.png")
		#expect(try bundleFile.resolvingLink("missing.png", project: project) == "missing.png")
		#expect(try bundleFile.resolvingLink("../dato.md", project: project) == App.path(slug: "dato").description)
	}

	@Test(.temporaryDirectory)
	func `apps and posts in a subdirectory are an error instead of a crash`() async throws {
		let project = Project(root: try URL.temporaryDirectory(files: [
			"content/apps/sub/test.md": "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---",
			"content/blog/sub/post.md": "---\ntitle: 'Post'\npublicationDate: '2026-01-01'\n---",
		]))

		let appErrors = try await #require(throws: ContentErrors.self) {
			try await App.load(from: project)
		}

		let postErrors = try await #require(throws: ContentErrors.self) {
			try await BlogPost.load(from: project)
		}

		#expect(appErrors.errors.map(\.reason) == ["The file must be directly in `content/apps`."])
		#expect(postErrors.errors.map(\.reason) == ["The file must be directly in `content/blog`."])

		let page = try MarkdownFile(contents: "Text.", url: project.root.appending(path: "content/pages/page.md"))

		#expect(throws: ContentError.self) {
			try page.resolvingLink("../apps/sub/test.md", project: project)
		}

		#expect(throws: ContentError.self) {
			try page.resolvingLink("../blog/sub/post.md", project: project)
		}
	}

	@Test
	func `old paths of a post redirect to the post`() async throws {
		let post = try await BlogPost(markdown: "---\ntitle: 'Post'\npublicationDate: '2026-01-01'\nredirectFrom: ['/blog/old-name']\n---\n\nText.", slug: "post")
		let content = SiteContent(apps: [], posts: [post], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let redirect = try #require(Site(content: content).routes(project: .empty).first { $0.path == "/blog/old-name" })

		guard case .redirect(let destination) = redirect.output else {
			Issue.record("Expected a redirect, got \(redirect.output)")
			return
		}

		#expect(destination == .path("/blog/post"))
	}

	/**
	An unlisted post keeps its page, as its URL may already be shared, but the blog, the feeds, and the sitemap leave it out.
	*/
	@Test
	func `an unlisted post keeps its page, but is not listed`() async throws {
		let listed = try await BlogPost(markdown: "---\ntitle: 'Listed'\npublicationDate: '2026-01-01'\n---\n\nText.", slug: "listed")
		let unlisted = try await BlogPost(markdown: "---\ntitle: 'Unlisted'\npublicationDate: '2026-01-02'\nisUnlisted: true\n---\n\nText.", slug: "unlisted")
		let content = SiteContent(apps: [], posts: [listed, unlisted], pages: [], buildDate: .now, project: .empty)
		let routes = Site(content: content).routes(project: .empty)

		let route = try #require(routes.first { $0.path == "/blog/unlisted" })
		#expect(route.sitemapEntry == nil)

		guard
			case .page(_, let renderBlog) = try #require(routes.first { $0.path == .blog }).output,
			case .file(let renderFeed) = try #require(routes.first { $0.path == SiteFeed.blog.path }).output
		else {
			Issue.record("The blog is not a page, or its feed is not a file.")
			return
		}

		let blog = try renderBlog()
		let feed = try String(decoding: await renderFeed(), as: UTF8.self)

		for html in [blog, feed] {
			#expect(html.contains("/blog/listed"))
			#expect(!html.contains("/blog/unlisted"))
		}
	}

	/**
	Whole years, so the years only go up on the day the first app was published.
	*/
	@Test
	func `years of craft counts whole years since the first app`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2015-06-09'\nplatforms: ['macOS']\n---\n\nText.")

		func years(on date: String) throws -> Int? {
			let buildDate = try Date(date, strategy: .iso8601.year().month().day())
			return SiteContent(apps: [app], posts: [], pages: [], buildDate: buildDate, project: .empty).yearsOfCraft
		}

		#expect(try years(on: "2026-03-01") == 10)
		#expect(try years(on: "2026-06-09") == 11)
		#expect(try years(on: "2026-12-31") == 11)
	}

	/**
	The wall of love only has the apps that are listed and maintained, so it would show all quotes for the link of another app.
	*/
	@Test
	func `an unlisted app does not link to the wall of love`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Hidden'\nsubtitle: 'A hidden app'\npublicationDate: '2020-01-01'\nplatforms: ['iOS']\nisUnlisted: true\nappStoreID: 123\n---\n\nText.", slug: "hidden")
		let review = AppStoreReview(title: "Great", text: "A review that is long enough to be shown on the page of the app.", author: "A reviewer", rating: 5, date: try Date("2026-01-01T00:00:00Z", strategy: .iso8601))
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreReviews: [123: [review]], buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601), project: .empty)

		guard case .page(_, let render) = AppPage(app: app, content: content).route.output else {
			Issue.record("The app page is not a page.")
			return
		}

		let html = try render()
		#expect(html.contains("A review that is long enough"))
		#expect(!html.contains("/apps/reviews?app=hidden"))
	}

	/**
	Like the apps page and the about page, which count the active apps, without the archived ones.
	*/
	/**
	The videos have their own label, so the screenshots are numbered without them.
	*/
	/**
	AVFoundation reads the size of a video, so the page reserves its space before it loads.
	*/
	@Test
	func `app videos have their pixel size`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		let video = try #require(app.media.first { $0.kind == .video })
		#expect(video.width == 1280)
		#expect(video.height == 720)
	}

	@Test
	func `the first screenshot after a video is screenshot 1`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		#expect(app.media.map(\.kind) == [.video, .image])
		#expect(AppMedia(app: app).render().matches(of: /alt="[^"]*"/).map { String($0.output) } == [#"alt="Googly Eyes screenshot 1""#])
	}

	/**
	An archived app gets no support, and the feedback page does not list it.
	*/
	/**
	The page has no App Store download for an archived app, so the structured data does not offer it there.
	*/
	@Test
	func `the structured data of an archived app does not offer it on the App Store`() async throws {
		let app = try await App(markdown: "---\nisArchived: true\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nappStoreID: 123\n---\n\nThe app is no longer available.\n")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "version": "2.0.0", "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#.utf8))
		let schema = Schema.SoftwareApplication(app: app, info: info)

		#expect(app.downloadOptions.isEmpty)
		#expect(schema.downloadUrl == nil)
		#expect(schema.offers == nil)
		#expect(schema.aggregateRating?.ratingValue == 4.5)
	}

	/**
	The menu has the QR code, sharing, and a random app, which are not elsewhere on the page.
	*/
	@Test
	func `an app without section links still has the overflow menu`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nisArchived: true\n---\n\nText.")
		#expect(app.links.isEmpty)
		#expect(AppHero(app: app, info: nil).render().contains("Show QR Code"))
	}

	@Test
	func `an archived app shares its page, not its App Store page`() async throws {
		let app = try await App(markdown: "---\nisArchived: true\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nappStoreID: 123\n---\n\nThe app is no longer available.\n", slug: "test")
		#expect(app.shareURL == app.path.absoluteURL)
	}

	@Test
	func `an archived app does not invite feedback in its FAQ`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Old App'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nisArchived: true\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question\n\nAn answer.")
		#expect(!app.markdown.html.contains("feedback?product="))
		#expect(app.faqHeadings.map(\.text).contains("A question"))
	}

	@Test
	func `the 1999 page counts the active apps`() async throws {
		var apps = [App]()

		for slug in ["a", "b", "c"] {
			apps.append(try await App(markdown: "---\ntitle: '\(slug)'\nsubtitle: 'App'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\(slug == "c" ? "\nisArchived: true" : "")\n---", slug: slug))
		}
		let content = SiteContent(apps: apps, posts: [], pages: [], buildDate: .now, project: .empty)

		#expect(GeoCitiesPage(content: content).body.render().contains("2 apps and counting"))
	}

	/**
	Without the dates of the last commits, the sitemap and the update dates of posts use other dates, so a git failure in a repository is a warning, not silent.
	*/
	@Test(.temporaryDirectory)
	func `a git repository whose commit dates cannot be read is a warning`() async throws {
		let root = try URL.temporaryDirectory()

		for directory in ["content/apps", "content/blog", "content/pages", ".git"] {
			try root.appending(path: directory).createDirectory()
		}

		let content = try await SiteContent.load(from: Project(root: root), externalData: .none)
		#expect(content.warnings.contains { $0.message.contains("dates of the last commits") })
	}

	@Test
	func `sponsors without a place in the Markdown are an error`() async throws {
		await #expect {
			try await MarkdownPage(markdown: "---\ntitle: 'Supporters'\nsponsorTiers: [{title: 'Sponsor', price: '$100/month', sponsors: [{name: 'Someone'}]}]\n---\n\nThanks.", slug: "supporters")
		} throws: { error in
			let error = error as? ContentError
			return error?.line == 3 && error?.reason.contains("@Sponsors") == true
		}
	}

	/**
	The content errors of loading the app, with lines in the file.
	*/
	private func loadingErrors(_ source: String) async -> [ContentError] {
		do {
			_ = try await App(markdown: source)
			return []
		} catch {
			return ContentErrors(converting: error, file: URL(filePath: "/test.md")).errors
		}
	}

	@Test
	func `a free app downloaded from its own site gets an offer with the price 0`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nrepositoryURL: 'https://github.com/sindresorhus/test'\n---\n\nText.")
		let offer = try #require(Schema.SoftwareApplication(app: app, info: nil).offers)

		#expect(offer.price == 0)
		#expect(offer.url.absoluteString == "https://github.com/sindresorhus/test")
	}

	@Test
	func `a paid app without App Store info gets no offer`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nrepositoryURL: 'https://github.com/sindresorhus/test'\n---\n\nText.")

		#expect(Schema.SoftwareApplication(app: app, info: nil).offers == nil)
	}

	@Test
	func `the feedback scripts read every key of their data`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nrepositoryURL: 'https://github.com/sindresorhus/test'\nfeedbackNote: 'A note.'\n---\n\nText.\n\n## Frequently Asked Questions {#faq}\n\n### Why?\n\nBecause.")

		func keys(in value: Any) -> Set<String> {
			if let object = value as? [String: Any] {
				return object.reduce(into: Set(object.keys)) { $0.formUnion(keys(in: $1.value)) }
			}

			if let array = value as? [Any] {
				return array.reduce(into: Set<String>()) { $0.formUnion(keys(in: $1)) }
			}

			return []
		}

		func unusedKeys(of data: some Encodable, in script: String) throws -> [String] {
			let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(data))
			return keys(in: json).filter { !script.contains(".\($0)") && !script.contains("{\($0)") && !script.contains(" \($0),") && !script.contains(" \($0)}") }.sorted()
		}

		let pageScript = try String(contentsOf: Project.website.publicDirectory.appending(path: "scripts/feedback.js"), encoding: .utf8)
		#expect(try unusedKeys(of: FeedbackData(apps: [app]), in: pageScript) == [], "`feedback.js` does not read these keys of `FeedbackData`. Rename them in both places.")
		#expect(try unusedKeys(of: FAQSuggestions.Questions(apps: [app], faq: nil), in: FAQSuggestions.script.source) == [], "The script of `FAQSuggestions` does not read these keys of `FAQSuggestions.Questions`. Rename them in both places.")
	}

	@Test
	func `a paid app sold on its own site shows its price and gets an offer`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 4.99\nsetappID: 1\nmainLinks: {Buy: 'https://example.com/buy'}\n---\n\nText.")
		let offer = try #require(Schema.SoftwareApplication(app: app, info: nil).offers)

		#expect(app.priceText(info: nil) == "$4.99, one-time purchase")
		#expect(offer.price == Decimal(string: "4.99"))
		#expect(offer.priceCurrency == "USD")
		#expect(offer.url.absoluteString == "https://example.com/buy")
	}

	@Test
	func `a price in frontmatter has at most two decimals`() async {
		#expect(await !loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 4.999\n---\n\nText.").isEmpty)
		#expect(await !loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 0\n---\n\nText.").isEmpty)
		#expect(await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 20\n---\n\nText.").isEmpty)
	}

	@Test
	func `the reviews show the rounded App Store rating, and the hero does not`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\n---\n\nText.")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#.utf8))
		let review = AppStoreReview(title: "Great", text: "A review.", author: "A reviewer", rating: 5, date: .now)

		#expect(AppReviews(reviews: [review], rating: info.rating).render().contains(">Rated 4.6 out of 5 from 1,563 ratings on the App Store</p>"))
		#expect(!AppHero(app: app, info: info).render().contains("Rated"))
		#expect(Schema.SoftwareApplication(app: app, info: info).aggregateRating?.ratingValue == 4.6)
	}

	/**
	Google requires an `aggregateRating` with more than one review (“Multiple reviews without aggregateRating object”), and the App Store does not have a rating for every app, so the structured data only has the reviews with a rating.
	*/
	@Test
	func `the structured data only has the reviews of an app when it has a rating`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\n---\n\nText.")
		let rated = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#.utf8))
		let unrated = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "price": 0, "currency": "USD"}"#.utf8))
		let reviews = [
			AppStoreReview(title: "Great", text: "A review.", author: "A reviewer", rating: 5, date: .now),
			AppStoreReview(title: "Nice", text: "Another review.", author: "Another reviewer", rating: 5, date: .now),
		]

		#expect(Schema.SoftwareApplication(app: app, info: rated, reviews: reviews).review?.count == 2)
		#expect(Schema.SoftwareApplication(app: app, info: unrated, reviews: reviews).review == nil)
		#expect(Schema.SoftwareApplication(app: app, info: nil, reviews: reviews).review == nil)
		#expect(Schema.SoftwareApplication(app: app, info: rated, reviews: []).review == nil)
	}

	/**
	The rating is in the structured data, so the page shows it too, also when there are no reviews to show.
	*/
	@Test
	func `an app page shows the rating without reviews`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\n---\n\nText.", slug: "test")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#.utf8))
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], buildDate: .now, project: .empty)

		guard case .page(_, let render) = AppPage(app: app, content: content).route.output else {
			Issue.record("The app page is not a page.")
			return
		}

		let html = try render()
		#expect(html.contains(">Rated 4.6 out of 5 from 1,563 ratings on the App Store</p>"))
		#expect(!html.contains("Recent Reviews"))
		#expect(!html.contains("/apps/reviews?app=test"))
	}

	@Test
	func `platform badges have the badge look and the platform`() {
		let html = MarkdownDocument(parsing: #"A ^[*Mac*](platform: "macOS") app."#, options: .gallery).html

		#expect(html.contains(#"<span class="badge badge-platform" data-platform="macOS"><em>Mac</em></span>"#))
	}

	@Test
	func `the price shows cents only when it has them`() throws {
		func priceText(_ price: String) throws -> String? {
			try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "price": \#(price), "currency": "USD"}"#.utf8)).priceText(isPaid: true)
		}

		#expect(try priceText("4.99") == "$4.99, one-time purchase")
		#expect(try priceText("4.00") == "$4, one-time purchase")
		#expect(try priceText("0.00") == "Free to download, with an in-app purchase")
	}

	@Test
	func `the privacy note replaces the statement that no data is collected`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nhasSentry: true\nprivacyNote: 'Your questions are sent to OpenAI.'\n---\n\nText.")
		let page = PrivacyPolicyPage(app: app)
		let html = page.body.render()

		#expect(html.contains("<p>Your questions are sent to OpenAI.</p>"))
		#expect(!html.contains("No personal information"))
		#expect(html.contains("anonymous crash reports"))
		#expect(page.metadata.description == "The privacy policy of the Test app. Your questions are sent to OpenAI. Anonymous crash reports are sent to Sentry.")
	}
}
