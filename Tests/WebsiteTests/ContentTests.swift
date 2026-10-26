import Elementary
import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

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

		An app that does one thing.
		""")

		#expect(app.title == "Test")
		#expect(app.platforms == [.macOS])
		#expect(!app.isPaid)
		#expect(app.showsSupportLink)
		// The description is the introduction, not the subtitle, which the title of the page already has.
		#expect(app.description == "An app that does one thing.")
		// A new app can be previewed before it has an icon.
		#expect(app.iconPath == App.placeholderIconPath)
	}

	/**
	A page without an introduction, like one that starts with a heading, still has a description, as search results and link previews need one.
	*/
	@Test
	func `the description of a page without an introduction is the subtitle`() async throws {
		let app = try await App(markdown: """
		---
		title: 'Test'
		subtitle: 'Test app'
		publicationDate: '2026-01-01'
		platforms: ['macOS']
		---

		## Features
		""")

		#expect(app.description == "Test app")
	}

	@Test(arguments: [
		("isDraft: 'false'", "Invalid `isDraft`"),
		("unexpected: true", "Unknown key unexpected,"),
		("platforms: ['Amiga']", "Invalid `platforms[0]`"),
		("appStoreID: -1", "Invalid `appStoreID`"),
		("repositoryURL: 'github.com/sindresorhus'", "Invalid `repositoryURL`"),
		("links: {Docs: '/docs'}", "Invalid `links.Docs`"),
		("links: {'Mac App Store': '/docs'}", "Invalid `links.'Mac App Store'`"),
		("pressQuotes: [{quote: 'Great', source: 'Example', url: 'example.com'}]", "Invalid `pressQuotes[0].url`"),
		("olderMacOSVersions: ['9']", "Invalid `olderMacOSVersions[0]`"),
		("olderVersions: [{version: '1.0.0', macOS: '9', url: 'https://example.com/app.zip'}]", "Invalid `olderVersions[0].macOS`"),
		("olderVersions: [{version: '1.0.0', macOS: '13', url: 'app.zip'}]", "Invalid `olderVersions[0].url`"),
		("announcement: {text: 'Sale', url: 'relative/path'}", "Invalid `announcement.url`"),
		("redirectFrom: ['old-name']", "Invalid `redirectFrom[0]`"),
		("script: '/missing.js'", "The `script` /missing.js does not exist"),
		("description: ' '", "Invalid `description`"),
		("downloads: 9007199254740992", "Invalid `downloads`"),
		("pressQuotes: [{quote: '', source: 'Example'}]", "Invalid `pressQuotes[0].quote`"),
		("minimumOSVersion: '26'", "Invalid `minimumOSVersion`"),
		("releasesRepository: 'dato-meta'", "Invalid `releasesRepository`"),
		("testFlightURL: 'testflight.apple.com/join/abc'", "Invalid `testFlightURL`"),
		("gitHubDownload: {repository: 'sindresorhus/test', file: ''}", "Invalid `gitHubDownload.file`"),
		("nonAppStoreVersion: {version: '1.0.0', macOS: 26, url: 'app.zip'}", "Invalid `nonAppStoreVersion.url`"),
		("announcement: {text: ''}", "Invalid `announcement.text`"),
		("announcement: {text: 'Sale', url: 'https://example.com', linkText: ' '}", "Invalid `announcement.linkText`"),
	])
	func `strict app frontmatter rejects invalid values`(line: String, reason: String) async throws {
		let platforms = line.hasPrefix("platforms:") ? "" : "platforms: ['macOS']\n"
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\n\(platforms)\(line)\n---")

		try #require(errors.count == 1, "\(errors)")
		#expect(errors[0].reason.hasPrefix(reason))
		#expect(errors[0].line != nil)
	}

	/**
	A mistake at the top level has no key, so the message names the frontmatter.
	*/
	@Test
	func `a frontmatter that is not an object is an error, not a crash`() async throws {
		let errors = await loadingErrors("---\n[1]\n---")

		try #require(errors.count == 1, "\(errors)")
		#expect(errors[0].reason.hasPrefix("Invalid frontmatter"))
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
		testFlightURL: 'https://testflight.apple.com/join/abc'
		showsSupportLink: false
		links: {
			Zebra: 'https://example.com/zebra',
			TestFlight: 'https://example.com/beta',
			Apple: 'https://example.com/apple',
		}
		---
		""")

		#expect(app.links.map(\.title) == ["Zebra", "TestFlight", "Apple"])
		#expect(app.links.map(\.destination.description) == ["https://example.com/zebra", "https://testflight.apple.com/join/abc", "https://example.com/apple"])
	}

	@Test
	func `the download buttons come from the repo, the GitHub download, and Gumroad`() async throws {
		let freeApp = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nrepositoryURL: 'https://github.com/sindresorhus/test'\ngitHubDownload: {repository: 'sindresorhus/test-meta', file: 'Test.App.zip'}\n---\n\nText.")
		let paidApp = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 6\ngumroadID: 'test'\n---\n\nText.")

		#expect(freeApp.mainLinks.map(\.title) == ["Learn More", "Download"])
		#expect(freeApp.mainLinks.map(\.destination.description) == ["https://github.com/sindresorhus/test", "https://github.com/sindresorhus/test-meta/releases/latest/download/Test.App.zip"])
		#expect(paidApp.mainLinks.map(\.title) == ["Buy"])
		#expect(paidApp.mainLinks.map(\.destination.description) == ["https://sindresorhus.gumroad.com/l/test?wanted=true"])
	}

	@Test
	func `older macOS versions in the readme get a link`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nrepositoryURL: 'https://github.com/sindresorhus/test'\nolderMacOSVersions: ['14']\nshowsSupportLink: false\n---\n\nText.")

		#expect(app.links == [LabeledLink("Older Versions", url: #URL("https://github.com/sindresorhus/test#download"))])
	}

	@Test(arguments: [
		"minimumOSVersion: 18",
		"testFlightURL: 'https://example.com/join/abc'",
		"gumroadID: 'test'",
		"isPaid: true\nprice: 6",
		"isPaid: true\nprice: 6\ngumroadID: 'Test App'",
		"nonAppStoreVersion: {version: '1.0.0', macOS: 26, url: 'https://example.com/app.zip'}",
		"appStoreID: 123\nnonAppStoreVersion: {version: '1.0.0', macOS: 15, url: 'https://example.com/app.zip'}",
	])
	func `typed app facts are checked`(lines: String) async {
		await #expect(throws: ContentError.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n\(lines)\n---\n\nText.")
		}
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
		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "app-not-showing-in-menu-bar", "some-question", "why-is-this-free-without-ads", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.links.filter { $0.destination == "/apps/faq#app-not-showing-in-menu-bar" }.map(\.line) == [nil])

		// The feedback page suggests them like the questions of the file, except the menu bar question, which only links to the general question.
		let questions = try #require(FAQSuggestions.Questions(apps: [app], faq: nil).apps.first).questions
		#expect(questions.map(\.question) == ["Some question", "Why is this free without ads?", "Can you localize the app into my language?"])
		#expect(questions.first?.url == .path(app.path, fragment: "some-question"))
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
		#expect(!app.markdown.html.contains("How to make the app show up in the menu bar"))
		#expect(!app.markdown.html.contains("I don’t plan to localize the app."))
	}

	@Test(.temporaryDirectory)
	func `an app gets the shared questions it picks`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "About the file.\n\n### Shared question {#shared}\n<!-- @faq.keywords automatic -->\n\n1. Open [the FAQ](/apps/faq).\n2. Uncheck it.\n\n### Not picked {#not-picked}\n\nAnswer.\n",
		]))
		let source = "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: [\n\t'shared'\n]\n---\n\n## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.\n"
		let app = try await App(markdown: source, project: project)
		let appWithAnswer = try await App(markdown: source + "\n### Shared question\n\nMy own answer.\n", project: project)

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "some-question", "shared", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.html.contains("<li>Uncheck it.</li>"))
		// The text before the first question explains the file, and the questions that the app does not pick are left out.
		#expect(!app.markdown.html.contains("About the file."))
		#expect(!app.markdown.html.contains("Not picked"))
		// The added answer is not in the file of the app, so it has no line.
		#expect(app.markdown.links.filter { $0.destination == "/apps/faq" }.map(\.line) == [nil])
		#expect(app.faqHeadings.map(\.text) == ["Some question", "Shared question", "Can you localize the app into my language?"])

		let questions = try #require(FAQSuggestions.Questions(apps: [app], faq: nil).apps.first).questions
		#expect(questions.first { $0.question == "Shared question" }?.extraWords.contains("automatic") == true)

		#expect(appWithAnswer.markdown.html.contains("My own answer."))
		#expect(!appWithAnswer.markdown.html.contains("Uncheck it."))
		// An unknown ID, an ID that is picked twice, and a page without a FAQ section are reported at the `sharedQuestions` key.
		let unknownErrors = await loadingErrors(source.replacing("'shared'", with: "'unknown'"), project: project)
		#expect(unknownErrors.map(\.line) == [6])
		#expect(unknownErrors.map(\.reason) == ["`sharedQuestions` has `unknown`, which is not the ID of a question in `content/shared-questions.md`."])
		let twiceErrors = await loadingErrors(source.replacing("'shared'", with: "'shared', 'shared'"), project: project)
		#expect(twiceErrors.map(\.line) == [6])
		#expect(twiceErrors.map(\.reason) == ["`sharedQuestions` has `shared` twice."])
		let noFAQErrors = await loadingErrors(source.replacing("## Frequently Asked Questions {#faq}", with: "## Other"), project: project)
		#expect(noFAQErrors.map(\.line) == [6])
		#expect(noFAQErrors.map(\.reason) == ["The shared questions are added to the FAQ section, but the page has none: `## Frequently Asked Questions {#faq}`."])
	}

	/**
	A question with `@faq.first` goes before the questions of the app, after the menu bar question, and the others after them, before the localization question.
	*/
	@Test(.temporaryDirectory)
	func `the shared questions are in the order that the app picks them`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### First {#first}\n\nAnswer.\n\n### Problem {#problem}\n<!-- @faq.first -->\n\nAnswer.\n\n### Third {#third}\n\nAnswer.\n",
		]))
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisMenuBarApp: true\nsharedQuestions: ['third', 'problem', 'first']\n---\n\n## Frequently Asked Questions {#faq}\n\n### Own question\n\nAnswer.\n", project: project)

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "app-not-showing-in-menu-bar", "problem", "own-question", "third", "first", "can-you-localize-the-app-into-my-language"])
		#expect(!app.markdown.html.contains("@faq.first"))
	}

	@Test
	func `a question of the app cannot go first`() async {
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### Own question\n<!-- @faq.first -->\n\nAnswer.\n")

		#expect(errors.map(\.line) == [10])
		#expect(errors.map(\.reason) == ["`@faq.first` is only for the questions in `content/shared-questions.md`. A question of the app goes where it is written."])
	}

	@Test(.temporaryDirectory)
	func `a shared question that is not a level 3 heading is an error in the file of the shared questions`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n\n## Section\n",
		]))
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\nText.", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [5])
	}

	@Test(.temporaryDirectory)
	func `two shared questions with the same ID are an error in the file of the shared questions`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n\n### Other question {#shared}\n\nAnswer.\n",
		]))
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\nText.", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [5])
	}

	/**
	The picked question goes after the question of the app, so the error is at the picked question, which has no line, but the reason names the ID.
	*/
	@Test(.temporaryDirectory)
	func `a shared question with the ID of a question of the app is an error`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n",
		]))
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\n## Frequently Asked Questions {#faq}\n\n### Own question {#shared}\n\nAnswer.\n", project: project)

		#expect(errors.map(\.line) == [nil])
		#expect(errors.map(\.reason) == ["The heading ID `shared` is already the ID of another heading, so links to it are ambiguous. Give one of the headings another custom ID, like `{#shared-2}`."])
	}

	/**
	A heading in a block directive is not the heading of a question, so it would give the questions after it the wrong answers.
	*/
	@Test(.temporaryDirectory)
	func `a heading in a shared answer is an error in the file of the shared questions`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\n@Details(summary: \"More\") {\n### Nested\n}\n\n### Other question {#other}\n\nAnswer.\n",
		]))
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['other']\n---\n\nText.", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [4])
	}

	@Test(.temporaryDirectory)
	func `a mistake in a shared answer is an error in the file of the shared questions`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n<!-- @faq.unknown -->\n\nAnswer.\n",
		]))
		let errors = await loadingErrors("---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\nText.", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [2])
	}

	/**
	The answers are parsed with the block directives of the app page.
	*/
	@Test(.temporaryDirectory)
	func `a shared answer can have block directives`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\n@Details(summary: \"Older macOS\") {\nOpen System Settings.\n}\n",
		]))
		let app = try await App(markdown: "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\n## Frequently Asked Questions {#faq}\n", project: project)

		#expect(app.markdown.html.contains("Older macOS"))
		#expect(!app.markdown.html.contains("@Details"))
	}

	/**
	The added menu bar question only links to the general question, which the feedback page suggests instead, as it has the answer. An answer of the app itself is suggested.
	*/
	@Test
	func `the feedback page suggests the menu bar question only when the app has its own answer`() async throws {
		let source = "---\ntitle: 'My App'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisMenuBarApp: true\n---\n\n## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.\n"
		let app = try await App(markdown: source)
		let appWithAnswer = try await App(markdown: source + "\n### The app does not show up in the menu bar\n\nMy own answer.\n")

		#expect(app.markdown.html.contains("How to make the app show up in the menu bar"))
		#expect(app.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
		#expect(appWithAnswer.faqHeadings.map(\.text) == ["Some question", "The app does not show up in the menu bar", "Can you localize the app into my language?"])
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
	func `the FAQ heading needs its ID`() async throws {
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions\n\n### A question\n\nAn answer.")

		try #require(errors.map(\.line) == [8])
		#expect(errors[0].reason.hasPrefix("The “Frequently Asked Questions” heading needs the ID `faq`"))
	}

	@Test
	func `every problem in the feedback note is reported at its key`() async {
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nfeedbackNote: 'See [this](missing.md) and ![](/image.png).'\n---\n\nText.")

		#expect(errors.map(\.line) == [6, 6])
		#expect(errors.allSatisfy { $0.reason.hasPrefix("`feedbackNote`: ") })
	}

	@Test
	func `other errors of a content file are a readable sentence`() throws {
		let errors = ContentErrors(converting: CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: "/missing.png"]), file: URL(filePath: "/test.md")).errors

		try #require(errors.map(\.file) == [URL(filePath: "/test.md")])
		#expect(errors[0].reason.contains("missing.png"))
		#expect(!errors[0].reason.contains("NSCocoaErrorDomain"))
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

		try #require(errors.errors.map(\.line) == [7])
		#expect(errors.errors[0].reason.hasPrefix("The values of `@faq.platforms` are invalid"))
	}

	@Test
	func `a pinned question needs one rank`() async throws {
		let error = try await #require(throws: ContentErrors.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.pinned -->\n\n### Another question {#another}\n<!-- @faq.pinned 1 2 -->\n\nAn answer.")
		}

		try #require(error.errors.map(\.line) == [11, 14])
		#expect(error.errors[0].reason.hasSuffix("It needs one rank, like `<!-- @faq.pinned 1 -->`."))
	}

	@Test
	func `only the general FAQ page can mark general questions`() async throws {
		let error = try await #require(throws: ContentErrors.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.general -->\n\nAn answer.")
		}

		try #require(error.errors.map(\.line) == [11])
		#expect(error.errors[0].reason.hasPrefix("Unknown directive `@faq.general`."))
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
	func `a tiny app is a card with its icon, a download button, the source, and the requirement`() throws {
		let file = try MarkdownFile(contents: "@TinyApp(title: \"Copy URL\", icon: \"/apps/copy-url/icon.png\", download: \"https://example.com/Copy-URL.zip\", source: \"https://github.com/sindresorhus/Copy-URL\", requirement: \"Requires macOS 13 or later\") {\n  Copies *URLs*.\n}\n\n@TinyApp(title: \"Safari Private\", download: \"https://example.com/Safari-Private.zip\") {\n  Opens URLs.\n}", url: Project.empty.root.appending(path: "content/pages/tiny-apps.md"))
		let html = try MarkdownDocument(parsing: file, options: .content(file, project: .empty)).html

		#expect(html.contains(#"<section class="\#(TinyAppStyles.root.className)">"#))
		#expect(html.contains(#"<img src="/apps/copy-url/icon.png" width="128" height="128" alt="""#))
		#expect(html.contains(">Copy URL</h2>"))
		#expect(html.contains("Copies <em>URLs</em>."))
		#expect(html.contains(#"<a href="https://example.com/Copy-URL.zip""#))
		#expect(html.contains(#"<a href="https://github.com/sindresorhus/Copy-URL""#))
		#expect(html.contains(">Requires macOS 13 or later</span>"))

		// Without an icon, the card has the placeholder icon, and without a source, only the download button.
		#expect(html.contains(#"<img src="\#(App.placeholderIconPath)""#))
		#expect(html.components(separatedBy: ">Source Code<").count - 1 == 1)

		// Screen readers hear the name of the app in each link, as the links of the cards would otherwise have the same names.
		#expect(html.contains("> Copy URL</span></a>"))
		#expect(html.contains("> of Copy URL</span></a>"))
		#expect(html.contains("> Safari Private</span></a>"))
	}

	@Test
	func `social links directive has no content`() throws {
		let file = try MarkdownFile(contents: "@SocialLinks {\n- A link\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))

		#expect(throws: ContentErrors.self) {
			try MarkdownDocument(parsing: file, options: .content(file, project: .empty))
		}
	}

	@Test
	func `a changelog shows the kind of each change as a badge, and a change without a kind as it is`() throws {
		let file = try MarkdownFile(contents: "@Changelog {\n- 2014\n\t- Added: Awesome\n\t- Removed: Office job\n\t- A change\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))
		let html = try MarkdownDocument(parsing: file, options: .content(file, project: .empty)).html

		#expect(html.contains(#"<div class="\#(ChangelogStyles.root.className)"><ul>\#n<li>2014\#n<ul>"#))
		#expect(html.contains(#"<li><span class="\#(Badge.Styles.root.className) \#(Badge.Kind.added.className)">Added</span> Awesome</li>"#))
		#expect(html.contains(#"<li><span class="\#(Badge.Styles.root.className) \#(Badge.Kind.removed.className)">Removed</span> Office job</li>"#))
		#expect(html.contains("<li>A change</li>"))
	}

	/**
	A list with blank lines between the changes has each change in a paragraph, which still gets its badge.
	*/
	@Test
	func `a changelog with blank lines between the changes shows the kinds as badges`() throws {
		let file = try MarkdownFile(contents: "@Changelog {\n- 2014\n\t- Added: Awesome\n\n\t- Improved: Something\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))

		// An unknown kind in a paragraph is an error too, so it is not shown as text.
		#expect(throws: ContentErrors.self) {
			try MarkdownDocument(parsing: file, options: .content(file, project: .empty))
		}

		let validFile = try MarkdownFile(contents: "@Changelog {\n- 2014\n\t- Added: Awesome\n\n\t- Removed: Office job\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))
		let html = try MarkdownDocument(parsing: validFile, options: .content(validFile, project: .empty)).html
		#expect(html.contains(#"<li>\#n<p><span class="\#(Badge.Styles.root.className) \#(Badge.Kind.added.className)">Added</span> Awesome</p>"#))
		#expect(html.contains(#"<p><span class="\#(Badge.Styles.root.className) \#(Badge.Kind.removed.className)">Removed</span> Office job</p>"#))
	}

	@Test
	func `an image path with a dot component is a content error`() throws {
		let file = try MarkdownFile(contents: "![Photo](/images/../photo.png)", url: Project.empty.root.appending(path: "content/pages/about.md"))

		#expect(throws: ContentErrors.self) {
			try MarkdownDocument(parsing: file, options: .content(file, project: .empty))
		}
	}

	@Test
	func `a change of an unknown kind is a content error`() throws {
		let file = try MarkdownFile(contents: "@Changelog {\n- 2014\n\t- Improved: Something\n}", url: Project.empty.root.appending(path: "content/pages/about.md"))

		#expect(throws: ContentErrors.self) {
			try MarkdownDocument(parsing: file, options: .content(file, project: .empty))
		}
	}

	@Test
	func `older versions get a section before the non-App Store version`() async throws {
		func loadApp(isPaid: Bool) async throws -> App {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nappStoreID: 123\nisPaid: \(isPaid)\nolderVersions: [\n\t{version: '2.0.0', macOS: '15', url: 'https://example.com/a.zip?b=1&c=2'},\n\t{version: '1.10', macOS: '10.15', url: 'https://example.com/old.zip'},\n]\nnonAppStoreVersion: {version: '3.0.0', macOS: 26, url: 'https://example.com/new.zip'}\n---\n\nText.")
		}

		let freeApp = try await loadApp(isPaid: false)
		let paidApp = try await loadApp(isPaid: true)

		#expect(freeApp.markdown.headings.map(\.id) == ["older-versions", "non-app-store-version"])
		#expect(freeApp.markdown.html.contains(#"<p>A special version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.</p>"#))
		#expect(freeApp.markdown.html.contains(#"<a href="https://example.com/new.zip">Download</a> <em>(3.0.0)</em>"#))
		#expect(freeApp.markdown.html.contains("<em>Requires macOS 26 or later</em>"))
		#expect(freeApp.overflowLinks.contains(LabeledLink("Non-App Store Version", destination: .fragment("non-app-store-version"))))
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
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/apps/dato.md": "",
			"content/apps/gifski/index.md": "",
			"content/apps/gifski/icon.png": "",
			"content/blog/post.md": "",
			"content/blog/photo.png": "",
			"content/pages/apps/faq.md": "",
		]))

		let file = try MarkdownFile(contents: "Text.", url: project.root.appending(path: "content/blog/post.md"), relativeTo: project.root.appending(path: "content/blog"))

		#expect(try file.resolvingLink("../apps/dato.md#faq", project: project) == LinkDestination.path(App.path(slug: "dato"), fragment: "faq").description)
		#expect(try file.resolvingLink("post.md", project: project) == BlogPost.path(slug: "post").description)
		#expect(try file.resolvingLink("../pages/apps/faq.md", project: project) == RoutePath.faq.description)
		#expect(try file.resolvingLink("https://example.com/readme.md", project: project) == "https://example.com/readme.md")
		// The link stays as it is written, so Foundation does not encode it differently from the text of the content.
		#expect(try file.resolvingLink("https://example.com/über", project: project) == "https://example.com/über")
		#expect(throws: ContentError.self) {
			try file.resolvingLink("missing.md", project: project)
		}

		// A link without a file extension goes to a page, like `donate`, so it stays. A file next to a page that is not a page bundle is not published, so a link to it is an error.
		#expect(try file.resolvingLink("donate", project: project) == "donate")
		#expect(throws: ContentError.self) {
			try file.resolvingLink("photo.png", project: project)
		}

		// A page bundle has the page of its directory, and its files are linked by their published path, next to the page.
		let bundleFile = try MarkdownFile(contents: "Text.", url: project.root.appending(path: "content/apps/gifski/index.md"), relativeTo: project.root.appending(path: "content/apps"))
		#expect(try file.resolvingLink("../apps/gifski/index.md", project: project) == App.path(slug: "gifski").description)
		#expect(try bundleFile.resolvingLink("icon.png", project: project) == App.path(slug: "gifski").appending("icon.png").description)
		#expect(try bundleFile.resolvingLink("../dato.md", project: project) == App.path(slug: "dato").description)

		// A file that does not exist, like a typo, is an error instead of a broken link.
		#expect(throws: ContentError.self) {
			try bundleFile.resolvingLink("missing.png", project: project)
		}
	}

	/**
	The page routes of the site are the path rules of the content types, so the files of a page bundle are next to its page for each type.
	*/
	@Test(.temporaryDirectory)
	func `the files of a page bundle are next to its page for every content type`() throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/apps/dato/index.md": "",
			"content/apps/dato/icon.png": "",
			"content/blog/post/index.md": "",
			"content/blog/post/image.png": "",
			"content/pages/about/index.md": "",
			"content/pages/about/photo.jpg": "",
		]))

		for (directory, slug, file) in [("content/apps", "dato", "icon.png"), ("content/blog", "post", "image.png"), ("content/pages", "about", "photo.jpg")] {
			let contentFile = project.root.appending(path: "\(directory)/\(slug)/\(file)")
			let page = try #require(RoutePath(contentFile: project.root.appending(path: "\(directory)/\(slug)/index.md"), project: project))
			#expect(project.publicPath(ofContentFile: contentFile) == page.appending(file))
			#expect(project.publicFile(page.appending(file)) == contentFile)
		}
	}

	@Test(.temporaryDirectory)
	func `apps and posts in a subdirectory are an error instead of a crash`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
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

		let redirect = try #require(Site(content: content).routes().first { $0.path == "/blog/old-name" })

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
		let routes = Site(content: content).routes()

		let route = try #require(routes.first { $0.path == "/blog/unlisted" })
		#expect(route.sitemapEntry == nil)

		let blog = try #require(routes.first { $0.path == .blog }).renderedHTML()
		let feed = try await String(decoding: #require(routes.first { $0.path == SiteFeed.blog.path }).renderedFile(), as: UTF8.self)

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

	@Test
	func `years of open source counts whole years since the first repo`() throws {
		func years(on date: String) throws -> Int? {
			let buildDate = try Date(date, strategy: .iso8601.year().month().day())
			return SiteContent(apps: [], posts: [], pages: [], buildDate: buildDate, project: .empty).yearsOfOpenSource
		}

		#expect(try years(on: "2026-09-05") == 14)
		#expect(try years(on: "2026-09-06") == 15)
	}

	/**
	The wall of love only has the apps that are listed and maintained, so it would show all quotes for the link of another app.
	*/
	@Test
	func `an unlisted app does not link to the wall of love`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Hidden'\nsubtitle: 'A hidden app'\npublicationDate: '2020-01-01'\nplatforms: ['iOS']\nisUnlisted: true\nappStoreID: 123\n---\n\nText.", slug: "hidden")
		let review = AppStoreReview(title: "Great", text: "A review that is long enough to be shown on the page of the app.", author: "A reviewer", rating: 5, date: try Date("2026-01-01T00:00:00Z", strategy: .iso8601))
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreReviews: [123: [review]], buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601), project: .empty)

		let html = try AppPage(app: app, content: content).renderedHTML()
		#expect(html.contains("A review that is long enough"))
		#expect(!html.contains("/apps/reviews?app=hidden"))
	}

	/**
	AVFoundation reads the size of a video, so the page reserves its space before it loads.
	*/
	@Test
	func `app videos have their pixel size`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		let video = try #require(app.media.first { $0.kind == .video })
		#expect(video.size == PixelSize(width: 1280, height: 720))
	}

	/**
	The videos have their own label, so the screenshots are numbered without them.
	*/
	@Test
	func `the first screenshot after a video is screenshot 1`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		#expect(app.media.map(\.kind) == [.video, .image])
		#expect(AppMedia(app: app).render().matches(of: /alt="[^"]*"/).map { String($0.output) } == [#"alt="Googly Eyes screenshot 1""#])
	}

	@Test
	func `app media with one item has no buttons`() async throws {
		let apps = try await SiteContent.website.apps
		let single = try #require(apps.first { $0.media.count == 1 })
		let several = try #require(apps.first { $0.media.count > 1 })
		#expect(!AppMedia(app: single).render().contains("<button"))
		#expect(AppMedia(app: several).render().contains(#"data-part="next""#))
	}

	/**
	The page has no App Store download for an archived app, so the structured data does not offer it there.
	*/
	@Test
	func `the structured data of an archived app does not offer it on the App Store`() async throws {
		let app = try await App(markdown: "---\nisArchived: true\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nappStoreID: 123\n---\n\nThe app is no longer available.\n")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "version": "2.0.0", "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#)
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
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nshowsSupportLink: false\n---\n\nText.")
		#expect(app.links.isEmpty)
		#expect(AppHero(app: app, info: nil, buildDate: .now).render().contains("Show QR Code"))
	}

	/**
	An archived app is no longer available, so it is not passed on, and it has no terms or discounts.
	*/
	@Test
	func `an archived app has no QR code, sharing, terms, or discounts`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nisArchived: true\nisPaid: true\n---\n\nText.")
		let html = AppHero(app: app, info: nil, buildDate: .now).render()
		#expect(html.contains("Show Random App"))
		#expect(!html.contains("Show QR Code"))
		#expect(!html.contains("Share…"))
		#expect(!html.contains(AppHero.qrCodeID))
		#expect(!html.contains(AppHero.sharePopoverID))
		#expect(app.pageOverflowLinks.isEmpty)
	}

	/**
	An archived app gets no support, and the feedback page does not list it.
	*/
	@Test
	func `an archived app does not invite feedback in its FAQ`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Old App'\nsubtitle: 'Test app'\npublicationDate: '2020-01-01'\nplatforms: ['macOS']\nisArchived: true\n---\n\n## Frequently Asked Questions {#faq}\n\n### A question\n\nAn answer.")
		#expect(!app.markdown.html.contains("feedback?product="))
		#expect(app.faqHeadings.map(\.text).contains("A question"))
	}

	/**
	Like the apps page and the about page, which count the active apps, without the archived ones.
	*/
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

		let content = try await SiteContent.load(from: Project.site(root: root), externalData: .none)
		#expect(content.warnings.contains { $0.message.contains("dates of the last commits") })
	}

	@Test(.temporaryDirectory)
	func `two files of one page and two apps with one App Store ID are errors`() async throws {
		let app = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nappStoreID: 123\n---"
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/apps/about.md": app.replacing("appStoreID: 123\n", with: ""),
			"content/apps/first.md": app,
			"content/apps/second.md": app,
			"content/blog/.keep": "",
			"content/pages/about.md": "---\ntitle: 'About'\n---",
		]))

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.count == 2)
		#expect(errors.errors.contains { $0.reason.contains("the same page as `content/") && $0.reason.contains("which is at /about") })
		#expect(errors.errors.contains { $0.reason == "It has the same `appStoreID` as Test, so they would share its price, rating, and reviews." })
	}

	@Test
	func `sponsors without a place in the Markdown are an error`() async throws {
		let error = try await #require(throws: ContentError.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'Supporters'\nsponsorTiers: [{title: 'Sponsor', price: '$100/month', sponsors: [{name: 'Someone'}]}]\n---\n\nThanks.", slug: "supporters")
		}

		#expect(error.line == 3)
		#expect(error.reason.contains("@Sponsors"))
	}

	/**
	A tier with logos is a list of links, so a sponsor in it without a logo needs a URL too.
	*/
	@Test
	func `a sponsor in a tier with logos needs a URL`() async throws {
		let error = try await #require(throws: ContentError.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'Supporters'\nsponsorTiers: [{title: 'Sponsor', price: '$100/month', sponsors: [{name: 'Logo', url: 'https://example.com', logo: {path: '/logo.png', width: 100}}, {name: 'Someone'}]}]\n---\n\n@Sponsors\n", slug: "supporters")
		}

		#expect(error.reason.contains("“Someone” is in a tier with logos"))
	}

	/**
	The content errors of loading the app, with lines in the file.
	*/
	private func loadingErrors(_ source: String, project: Project = .empty) async -> [ContentError] {
		do {
			_ = try await App(markdown: source, project: project)
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
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: 4.99\nsetappID: 1\ngumroadID: 'test'\n---\n\nText.")
		let offer = try #require(Schema.SoftwareApplication(app: app, info: nil).offers)

		#expect(app.priceText(info: nil) == "$4.99, one-time purchase")
		#expect(offer.price == Decimal(string: "4.99"))
		#expect(offer.priceCurrency == "USD")
		#expect(offer.url.absoluteString == "https://sindresorhus.gumroad.com/l/test?wanted=true")
	}

	@Test(arguments: [("4.999", false), ("0", false), ("20", true)])
	func `a price in frontmatter has at most two decimals`(price: String, isValid: Bool) async {
		#expect(await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nprice: \(price)\ngumroadID: 'test'\n---\n\nText.").isEmpty == isValid)
	}

	@Test
	func `the reviews show the rounded App Store rating, and the hero does not`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\n---\n\nText.")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#)
		let review = AppStoreReview(title: "Great", text: "A review.", author: "A reviewer", rating: 5, date: .now)

		#expect(AppReviews(reviews: [review], rating: info.rating).render().contains(">Rated 4.6 out of 5 from 1,563 ratings on the App Store</p>"))
		#expect(!AppHero(app: app, info: info, buildDate: .now).render().contains("Rated"))
		#expect(Schema.SoftwareApplication(app: app, info: info).aggregateRating?.ratingValue == 4.6)
	}

	@Test
	func `the combined rating weights the apps by their number of ratings`() throws {
		let infos = try [
			AppStoreInfo(json: #"{"trackId": 1, "averageUserRating": 4, "userRatingCount": 100}"#),
			AppStoreInfo(json: #"{"trackId": 2, "averageUserRating": 5, "userRatingCount": 200}"#),
			// Mac App Store apps always have a rating count of 0.
			AppStoreInfo(json: #"{"trackId": 3, "averageUserRating": 0, "userRatingCount": 0, "kind": "mac-software"}"#),
		]

		let rating = try #require(infos.combinedRating)
		// 4.67, which is not halfway, so it only rounds to 4.7 when the average is weighted. Without the weights, it is 4.5.
		#expect(rating.average == 14.0 / 3)
		#expect(rating.roundedAverage == 4.7)
		#expect(rating.count == 300)
		#expect(infos.suffix(1).combinedRating == nil)
	}

	/**
	Google requires an `aggregateRating` with more than one review (“Multiple reviews without aggregateRating object”), and the App Store does not have a rating for every app, so the structured data only has the reviews with a rating.
	*/
	@Test
	func `the structured data only has the reviews of an app when it has a rating`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\n---\n\nText.")
		let rated = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#)
		let unrated = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD"}"#)
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
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], buildDate: .now, project: .empty)

		let html = try AppPage(app: app, content: content).renderedHTML()
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
			try AppStoreInfo(json: #"{"trackId": 123, "price": \#(price), "currency": "USD"}"#).priceText(isPaid: true)
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

	@Test
	func `the availability leaves out the platforms only when the requirement already names the one platform`() async throws {
		func availabilityText(_ frontmatter: String) async throws -> String? {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\n\(frontmatter)\n---\n\nText.").availabilityText
		}

		#expect(try await availabilityText("platforms: ['macOS']\nminimumOSVersion: 26") == "Requires macOS 26 or later")
		#expect(try await availabilityText("platforms: ['iOS', 'macOS']\nminimumOSVersion: 27") == "Available on macOS, iOS — Requires version 27 or later")
		#expect(try await availabilityText("platforms: ['macOS']") == "Available on macOS")
		#expect(try await availabilityText("platforms: ['iOS']\nminimumOSVersion: 27") == "Requires iOS 27 or later")
	}

	@Test
	func `a paid app on the Mac and iOS is one purchase for all platforms`() async throws {
		func priceText(platforms: String) async throws -> String? {
			let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: \(platforms)\nisPaid: true\nappStoreID: 123\n---\n\nText.")
			return app.priceText(info: try AppStoreInfo(json: #"{"trackId": 123, "price": 4.99, "currency": "USD"}"#))
		}

		#expect(try await priceText(platforms: "['macOS', 'iOS']") == "$4.99, one-time purchase for all platforms")
		#expect(try await priceText(platforms: "['macOS']") == "$4.99, one-time purchase")
		#expect(try await priceText(platforms: "['iOS', 'watchOS']") == "$4.99, one-time purchase")
	}

	@Test
	func `an app that is two years old says since when it is available`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2020-06-01'\nplatforms: ['macOS']\n---\n\nText.")

		#expect(app.availableSinceText(at: try Date("2026-01-01T00:00:00Z", strategy: .iso8601)) == "Since 2020")
		#expect(app.availableSinceText(at: try Date("2021-06-01T00:00:00Z", strategy: .iso8601)) == nil)
	}

	@Test
	func `the trial of an app page shows the requirement, how to install it, and Setapp`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisPaid: true\nsetappID: 1\n---\n\n## Trial {#trial}\n\n@Trial(url: \"https://example.com/App-trial.zip\", macOS: \"26\") {\n  Try it.\n}\n")

		#expect(app.markdown.html.contains("<p><em>Requires macOS 26 or later</em></p>"))
		#expect(app.markdown.html.contains("<p><em>Download it to the Downloads folder, double-click to unzip, and then move it to the <code translate=\"no\">/Applications</code> folder.</em></p>"))
		#expect(app.markdown.html.contains(#"<p>You can also <a href="https://go.setapp.com/stp181?refAppID=1&amp;utm_medium=vendor_program&amp;utm_content=button">try it on Setapp</a> for 7 days for free.</p>"#))
	}

	@Test
	func `a platform badge must be for a platform of the app`() async throws {
		func load(platforms: String) async throws -> App {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: \(platforms)\n---\n\nWorks ^[iOS only](platform: \"iOS\").")
		}

		let error = await #expect(throws: (any Error).self) {
			try await load(platforms: "['macOS']")
		}

		#expect(String(describing: error).contains("The platform badge is for iOS, but the app is not on it."))
		#expect(try await load(platforms: "['macOS', 'iOS']").markdown.html.contains(#"data-platform="iOS">iOS only</span>"#))
	}

	@Test
	func `the facts at the end of an app page have the platforms, the requirement, the category, the release, the privacy, and the developer`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2019-07-13'\nplatforms: ['macOS', 'iOS']\nappStoreID: 123\nminimumOSVersion: 26\n---\n\nText.", slug: "test")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "primaryGenreName": "Productivity"}"#)
		let html = AppFacts(app: app, info: info).render()

		for fact in ["<dt class=\"app-facts-label\">Platforms</dt>", "macOS, iOS", "macOS 26 or later, iOS 26 or later", "Productivity", "July 2019", #"<a href="/test/privacy-policy" class="app-facts-link">No data collected</a>"#, "Sindre Sorhus"] {
			#expect(html.contains(fact), "\(fact)")
		}
	}

	@Test
	func `the tips box can have another title, and a list can be in columns`() {
		let html = MarkdownDocument(parsing: "@Tips(title: \"Hidden features\") {\n- A tip.\n}\n\n@Columns {\n- Zoom\n- Webex\n}", options: .gallery).html

		#expect(html.contains("Hidden features</p>"))
		#expect(html.contains("<li>Zoom</li>"))
		#expect(!html.contains(">Tips</p>"))
	}

	@Test
	func `press quotes show their years only when they span years`() async throws {
		func showsYears(_ quotes: String) async throws -> Bool {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\npressQuotes: [\(quotes)]\n---\n\nText.").showsPressQuoteYears
		}

		#expect(try await showsYears("{quote: 'Good', source: 'A', year: 2021}, {quote: 'Great', source: 'B', year: 2025}"))
		#expect(try await !showsYears("{quote: 'Good', source: 'A', year: 2025}, {quote: 'Great', source: 'B', year: 2025}"))
		#expect(try await showsYears("{quote: 'Good', source: 'A', year: 2021}, {quote: 'Great', source: 'B', year: 2025}, {quote: 'Nice', source: 'Mom'}"))
		#expect(try await !showsYears("{quote: 'Good', source: 'A', year: 2021}, {quote: 'Great', source: 'B'}"))
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\npressQuotes: [{quote: 'Good', source: 'MacStories', year: 2021}]\n---\n\nText.")
		#expect(PressQuotes(quotes: app.pressQuotes, showsYears: true).render().contains("MacStories, 2021"))
	}

	@Test
	func `a Gumroad product gives the rating and the price of an app that is sold there`() throws {
		let product = try GumroadProduct(json: #"{"price_cents": 2000, "ratings": {"count": 283, "average": 4.96}}"#)

		#expect(product.price == Price(20))
		#expect(product.rating?.text == "Rated 5.0 out of 5 from 283 ratings on Gumroad")
		#expect(try GumroadProduct(json: #"{"price_cents": 600, "ratings": {"count": 0, "average": 0}}"#).rating == nil)
	}

	@Test
	func `an app card is a heading with a link, at the level of its place on the page`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\nText.", slug: "test")

		#expect(AppCard(app: app, isNew: false).render().contains(#"<h3 translate="no""#))
		#expect(AppCard(app: app, isNew: false, headingLevel: 2).render().contains(#"<h2 translate="no""#))
		#expect(AppCard(app: app, isNew: false).render().contains(#"<a href="/test""#))
	}

	@Test
	func `the privacy summary links to the policy`() async throws {
		func privacySummary(_ frontmatter: String) async throws -> String {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n\(frontmatter)\n---\n\nText.").privacySummary
		}

		#expect(try await privacySummary("") == "No data collected")
		#expect(try await privacySummary("hasSentry: true") == "No personal data collected")
		#expect(try await privacySummary("privacyNote: 'Your questions are sent to OpenAI.'") == "Privacy details")
	}

	@Test
	func `the structured data has the category, the requirement, the release notes, the size, and the other pages`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['iOS']\nappStoreID: 123\nrepositoryURL: 'https://github.com/sindresorhus/test'\nminimumOSVersion: 26\n---\n\nText.")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "currentVersionReleaseDate": "2026-09-10T22:21:32Z", "fileSizeBytes": "19244046", "primaryGenreName": "Developer Tools"}"#)
		let schema = Schema.SoftwareApplication(app: app, info: info)

		#expect(schema.type == "MobileApplication")
		#expect(schema.applicationCategory == "DeveloperApplication")
		#expect(Schema.SoftwareApplication(app: app, info: nil).applicationCategory == "UtilitiesApplication")
		#expect(schema.softwareRequirements == "iOS 26 or later")
		#expect(schema.dateModified == "2026-09-10")
		#expect(schema.fileSize == "19.2 MB")
		#expect(schema.sameAs == [#URL("https://apps.apple.com/app/id123"), #URL("https://github.com/sindresorhus/test")])
	}

	/**
	Safari shows the App Store banner on the device that runs the app, but an Apple Watch app is installed from the iPhone, so it gets a QR code.
	*/
	@Test
	func `only apps that run on iOS or visionOS get the App Store banner, and watch apps also get a QR code`() async throws {
		func app(_ frontmatter: String) async throws -> App {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nappStoreID: 123\n\(frontmatter)\n---\n\nText.")
		}

		let watchApp = try await app("platforms: ['watchOS']")
		#expect(!watchApp.showsAppStoreBanner)
		#expect(watchApp.qrCodeURL != nil)

		let macApp = try await app("platforms: ['macOS']")
		#expect(!macApp.showsAppStoreBanner)
		#expect(macApp.qrCodeURL == nil)

		#expect(try await app("platforms: ['visionOS']").showsAppStoreBanner)
		#expect(try await !app("platforms: ['iOS']\nisArchived: true").showsAppStoreBanner)
	}

	@Test
	func `the feedback link of an app selects it, also when its name has a plus`() {
		#expect(App.feedbackURL(appTitle: "Plash+", referrer: .faq).description == "/feedback?product=Plash%2B&referrer=Website-FAQ")
	}

	@Test
	func `dates are shown in English and UTC, whatever the settings of the build machine`() throws {
		// The next day in time zones east of UTC, like in Norway, and the day before in time zones west of it, so a format in the time zone of the machine fails the test on any machine that is not in UTC.
		for date in [try Date("2024-06-05T23:30:00Z", strategy: .iso8601), try Date("2024-06-05T00:30:00Z", strategy: .iso8601)] {
			#expect(date.formatted(.siteDay) == "June 5, 2024")
			#expect(date.formatted(.siteDayWithoutYear) == "June 5")
			#expect(date.formatted(.siteMonth) == "June 2024")
		}
	}

	@Test
	func `the sum of a sequence`() {
		#expect([1, 2, 3].sum == 6)
		#expect([Int]().sum == 0)
		#expect([0.5, 0.25].sum == 0.75 as Double)
	}

	@Test
	func `a sequence without the later elements with the same key`() {
		#expect(["ky", "got", "ky", "Got"].uniqued(by: \.self) == ["ky", "got", "Got"])
		#expect(["ky", "got", "Got"].uniqued { $0.lowercased() } == ["ky", "got"])
	}

	/**
	The first element finishes last, so the results are in the order of the elements, not of the transforms.
	*/
	@Test
	func `a concurrent map keeps the order of the elements`() async throws {
		let results = try await [3, 2, 1, 0].concurrentMap { number in
			try await Task.sleep(for: .milliseconds(number * 20))
			return number * 2
		}

		#expect(results == [6, 4, 2, 0])
	}
}

struct AppTests {
	private let markdown = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nrepositoryURL: 'https://github.com/test/repo?view=readme#old'\n---\n\nText."

	@Test
	func `new app badges begin before the publication day and end thirty days after it`() async throws {
		let app = try await App(markdown: markdown)
		#expect(app.isNew(at: app.publicationDate.addingTimeInterval(-30 * 86400)))
		#expect(app.isNew(at: app.publicationDate.addingTimeInterval(-1)))
		#expect(app.isNew(at: app.publicationDate))
		#expect(app.isNew(at: app.publicationDate.addingTimeInterval(30 * 86400 - 1)))
		#expect(!app.isNew(at: app.publicationDate.addingTimeInterval(30 * 86400)))
	}

	@Test
	func `older version links replace existing fragments and preserve queries`() async throws {
		let app = try await App(markdown: markdown)
		#expect(app.olderVersionsURL?.absoluteString == "https://github.com/test/repo?view=readme#download")
	}

	@Test
	func `link merging preserves order while the final replacement wins`() {
		let original = [LabeledLink("A", path: "/a"), LabeledLink("B", path: "/b")]
		let additions = [LabeledLink("A", path: "/first"), LabeledLink("C", path: "/c"), LabeledLink("A", path: "/last"), LabeledLink("C", path: "/latest")]
		let merged = original.merging(additions)
		#expect(merged.map(\.title) == ["A", "B", "C"])
		#expect(merged.map(\.destination) == [.path("/last"), .path("/b"), .path("/latest")])
	}

	/**
	The other categories come from fields, like `isMenuBarApp`, so in `categories` they would silently do nothing.
	*/
	@Test
	func `only hand-picked categories are allowed in the frontmatter`() async throws {
		await #expect(throws: ContentError.self) {
			try await App(markdown: markdown.replacing("---\n\nText.", with: "categories: ['menu-bar']\n---\n\nText."))
		}

		let app = try await App(markdown: markdown.replacing("---\n\nText.", with: "categories: ['shortcuts']\n---\n\nText."))
		#expect(app.categories == [.shortcuts])
	}
}
