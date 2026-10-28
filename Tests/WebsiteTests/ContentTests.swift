import Elementary
import Foundation
import Markdown
import SiteKit
import SOML
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
		publicationDate: 2026-01-01
		platforms: ['macOS']
		---

		An app that does one thing.
		""")

		#expect(app.title == "Test")
		#expect(app.platforms == [.macOS])
		#expect(!app.isPaid)
		#expect(app.links.contains { $0.title == "Support" && $0.destination == app.feedbackURL })
		#expect(app.downloadCount == nil)
		// The description is the introduction, not the subtitle, which the title of the page already has.
		#expect(app.description == "An app that does one thing.")
		// A new app can be previewed before it has an icon.
		#expect(app.iconPath == App.placeholderIconPath)
	}

	@Test
	func `download count frontmatter renders the app badge`() async throws {
		let app = try await App(frontmatter: "downloadCount: 7000")
		let html = AppHero(listing: AppListing(app: app), buildDate: .now).render()

		#expect(app.downloadCount == 7000)
		#expect(html.contains(">7K+</span>"))
		#expect(html.contains(" downloads</span>"))
	}

	@Test(arguments: ["downloads: 7000", "showsSupportLink: false"])
	func `removed app frontmatter keys are rejected`(frontmatter: String) async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(frontmatter: frontmatter)
		}
		#expect(errors.errors.first?.reason.hasPrefix("Unknown key ") == true)
	}

	/**
	A page without an introduction, like one that starts with a heading, still has a description, as search results and link previews need one.
	*/
	@Test
	func `the description of a page without an introduction is the subtitle`() async throws {
		let app = try await App(body: "## Features")

		#expect(app.description == "Test app")
	}

	/**
	The download buttons link to the trial section, so only its level 2 heading counts, not a deeper heading with the same ID.
	*/
	@Test
	func `only the trial section gives the app a trial`() async throws {
		#expect(try await App(body: "## Trial {#trial}\n\nTry it.").hasTrial)
		#expect(try await !App(body: "## Features\n\n### Trial\n\nTry it.").hasTrial)
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
		("olderVersions: '14'", "Invalid `olderVersions`"),
		("olderVersions: [{version: '1.0.0', macOS: '9', url: 'https://example.com/app.zip'}]", "Invalid `olderVersions[0].macOS`"),
		("olderVersions: [{version: '1.0.0', macOS: '13', url: 'app.zip'}]", "Invalid `olderVersions[0].url`"),
		("announcement: {text: 'Sale', link: {url: 'relative/path'}}", "Invalid `announcement.link.url`"),
		("redirectFrom: ['old-name']", "Invalid `redirectFrom[0]`"),
		("script: '/missing.js'", "The `script` /missing.js does not exist"),
		("description: ' '", "Invalid `description`"),
		("downloadCount: 9007199254740992", "Invalid `downloadCount`"),
		("pressQuotes: [{quote: '', source: 'Example'}]", "Invalid `pressQuotes[0].quote`"),
		("minimumOSVersion: 26", "Invalid `minimumOSVersion`"),
		("minimumOSVersion: '26.x'", "Invalid `minimumOSVersion`"),
		("releasesRepository: 'dato-meta'", "Invalid `releasesRepository`"),
		("testFlightURL: 'testflight.apple.com/join/abc'", "Invalid `testFlightURL`"),
		("gitHubDownload: {repository: 'sindresorhus/test', file: ''}", "Invalid `gitHubDownload.file`"),
		("nonAppStoreVersion: {version: '1.0.0', macOS: 26, url: 'app.zip'}", "Invalid `nonAppStoreVersion.url`"),
		("announcement: {text: ''}", "Invalid `announcement.text`"),
		("announcement: {text: 'Sale', link: {url: 'https://example.com', text: ' '}}", "Invalid `announcement.link.text`"),
	])
	func `strict app frontmatter rejects invalid values`(line: String, reason: String) async throws {
		let platforms = line.hasPrefix("platforms:") ? "" : "platforms: ['macOS']\n"
		let errors = await loadingErrors("---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: 2026-01-01\n\(platforms)\(line)\n---")

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
		await #expect(throws: ContentErrors.self) {
			try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app.'\npublicationDate: 2026-01-01\nplatforms: ['macOS']\n---")
		}
	}

	@Test
	func `links keep their order and merge like JavaScript objects`() async throws {
		let app = try await App(
			frontmatter: """
			testFlightURL: 'https://testflight.apple.com/join/abc'
			links: {
				Zebra: 'https://example.com/zebra',
				TestFlight: 'https://example.com/beta',
				Apple: 'https://example.com/apple',
			}
			""",
			body: ""
		)

		#expect(app.links.map(\.title) == ["Zebra", "TestFlight", "Apple", "Support"])
		#expect(app.links.map(\.destination.description) == ["https://example.com/zebra", "https://testflight.apple.com/join/abc", "https://example.com/apple", app.feedbackURL.description])
	}

	@Test
	func `the download buttons come from the GitHub download, Gumroad, and the repo, which is not a place to get the app`() async throws {
		let freeApp = try await App(frontmatter: "repositoryURL: 'https://github.com/sindresorhus/test'\ngitHubDownload: {repository: 'sindresorhus/test-meta', file: 'Test.App.zip'}")
		// An app on Gumroad is paid without `isPaid`.
		let paidApp = try await App(frontmatter: "gumroad: {id: 'test', price: 6}")

		#expect(paidApp.isPaid)
		#expect(freeApp.ownOptions == [
			.link(LabeledLink("Download", url: try #require(URL(string: "https://github.com/sindresorhus/test-meta/releases/latest/download/Test.App.zip")))),
			.sourceCode(AbsoluteURL(#URL("https://github.com/sindresorhus/test"))),
		])
		#expect(paidApp.ownOptions == [.link(LabeledLink("Buy", url: try #require(URL(string: "https://sindresorhus.gumroad.com/l/test?wanted=true"))))])
		#expect(freeApp.placesToGet == [.link(LabeledLink("Download", url: try #require(URL(string: "https://github.com/sindresorhus/test-meta/releases/latest/download/Test.App.zip"))))])
	}

	@Test(arguments: [
		"minimumOSVersion: '18'",
		"testFlightURL: 'https://example.com/join/abc'",
		"isPaid: false\ngumroad: {id: 'test', price: 6}",
		"isPaid: true\nappStoreID: 123\ngumroad: {id: 'test', price: 6}",
		"isPaid: true\ngumroad: {id: 'Test App', price: 6}",
		"pressQuotes: [{quote: 'Great', source: 'Example', url: 'https://example.com/review'}]",
		"pressQuotes: [{quote: 'Great', source: 'Example', url: 'https://example.com/2023/06/review', year: 2024}]",
		"pressQuotes: [{quote: '“Great”', source: 'Example'}]",
		"pressQuotes: [{quote: 'Great', source: 'ifun.de (translated from German)'}]",
		"pressQuotes: [{quote: 'Great', source: 'ifun.de (German)'}]",
		"pressQuotes: [{quote: 'Great', source: 'Example', year: 2100}]",
		// Before the app was published, in 2026.
		"pressQuotes: [{quote: 'Great', source: 'Example', year: 2025}]",
		"nonAppStoreVersion: {version: '1.0.0', macOS: 26, url: 'https://example.com/app.zip'}",
		"appStoreID: 123\nnonAppStoreVersion: {version: '1.0.0', macOS: 15, url: 'https://example.com/app.zip'}",
	])
	func `typed app facts are checked`(lines: String) async {
		#expect(await !loadingErrors(frontmatter: lines).isEmpty)
	}

	@Test
	func `FAQ section gets the feedback question`() async throws {
		let app = try await App(
			title: "My App",
			body: """
			## Frequently Asked Questions {#faq}

			### Some question

			Answer.
			"""
		)

		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "some-question", "can-you-localize-the-app-into-my-language"])
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
		let app = try await App(title: "My App", frontmatter: "isMenuBarApp: true", body: "## Frequently Asked Questions {#faq}\n\nThese are common questions.\n\n### A question\n\nAn answer.")
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
		let app = try await App(title: "My App", body: "## Frequently Asked Questions {#faq}\n\n### I have a feature request, bug report, or some feedback\n<!-- @faq.keywords idea -->\n\nSure.")
		#expect(app.markdown.html.contains("send it here."))
	}

	/**
	The feedback question of the file gets the feedback ID, but keeps its line, so the answer of the question above it ends there.
	*/
	@Test
	func `an existing feedback question after another question keeps its line`() async throws {
		let app = try await App(title: "My App", body: "## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.\n\n### I have a feature request, bug report, or some feedback\n\nSure.")
		let feedbackHeading = try #require(app.markdown.headings.first { $0.id == App.Section.feedbackQuestion.id })

		#expect(feedbackHeading.line == 14)
		#expect(app.faqHeadings.map { app.faqAnswerMarkdown(of: $0) } == ["Answer.", nil])
	}

	@Test
	func `existing feature request question gets the feedback answer`() async throws {
		let app = try await App(
			title: "My App",
			body: """
			## Frequently Asked Questions {#faq}

			### I have a feature request, bug report, or some feedback {#requests}

			Sure.
			"""
		)

		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.html.contains("send it here."))
	}

	@Test
	func `a free menu bar app on the App Store gets the common questions`() async throws {
		let app = try await App(
			title: "My App",
			frontmatter: """
			isMenuBarApp: true
			appStoreID: 1
			""",
			body: """
			## Frequently Asked Questions {#faq}

			### Some question

			Answer.
			"""
		)

		// The menu bar question goes first, after the feedback question, and the others go after the questions of the file.
		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "app-not-showing-in-menu-bar", "some-question", "why-is-this-free-without-ads", "can-you-localize-the-app-into-my-language"])
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
		#expect(await loadingErrors(body: "## Frequently Asked Questions {#faq}\n\n### A question\n\nAnswer.\n\n#### Another question\n\nAnswer.").map(\.line) == [14])
		#expect(await loadingErrors(body: "#### Not in the FAQ\n\n## Frequently Asked Questions {#faq}\n\n### A question\n\nAnswer.").isEmpty)
	}

	@Test
	func `an app that is not in the menu bar or on the App Store gets only the localization question`() async throws {
		let app = try await App(title: "My App", body: "## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.")
		let paidApp = try await App(title: "My App", frontmatter: "isPaid: true\nappStoreID: 1", body: "## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.")

		#expect(app.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
		#expect(paidApp.faqHeadings.map(\.text) == ["Some question", "Can you localize the app into my language?"])
	}

	@Test
	func `an app without a FAQ section gets no common questions`() async throws {
		let app = try await App(title: "My App", frontmatter: "isMenuBarApp: true")

		#expect(app.markdown.headings.isEmpty)
	}

	@Test
	func `a file that writes a common question keeps its own answer`() async throws {
		let app = try await App(
			frontmatter: "isMenuBarApp: true",
			body: """
			## Frequently Asked Questions {#faq}

			### Can you localize the app into my language? {#language}

			No, the app is English-only.

			### The app does not show up in the menu bar

			My own answer.
			"""
		)

		// Only the feedback question is added, and the questions keep the answers of the file.
		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "language", "the-app-does-not-show-up-in-the-menu-bar"])
		#expect(app.faqHeadings.map { app.faqAnswerMarkdown(of: $0) } == ["No, the app is English-only.", "My own answer."])
		#expect(app.markdown.html.contains("My own answer."))
	}

	@Test(.temporaryDirectory)
	func `an app gets the shared questions it picks`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "About the file.\n\n### Shared question {#shared}\n<!-- @faq.keywords automatic -->\n\n1. Open [the FAQ](/apps/faq).\n2. Uncheck it.\n\n### Not picked {#not-picked}\n\nAnswer.\n",
				]
			)
		)
		let source = App.testMarkdown(title: "My App", frontmatter: "sharedQuestions: [\n\t'shared'\n]", body: "## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.\n")
		let app = try await App(markdown: source, project: project)
		let appWithAnswer = try await App(markdown: source + "\n### Shared question\n\nMy own answer.\n", project: project)

		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "some-question", "shared", "can-you-localize-the-app-into-my-language"])
		#expect(app.markdown.html.contains("<li>Uncheck it.</li>"))
		// The questions that the app does not pick are left out (the IDs above), and so is the text before the first question, which explains the file. The answer above is added, so this check does not pass when the build adds no shared questions.
		#expect(!app.markdown.html.contains("About the file."))
		// The added answer is not in the file of the app, so its link is at its line in the shared file, where a broken link is reported once.
		let sharedLink = try #require(app.markdown.links.first { $0.destination == "/apps/faq" })
		#expect(sharedLink.otherFile?.lastPathComponent == "shared-questions.md")
		#expect(sharedLink.line == 6)
		#expect(app.faqHeadings.map(\.text) == ["Some question", "Shared question", "Can you localize the app into my language?"])

		let questions = try #require(FAQSuggestions.Questions(apps: [app], faq: nil).apps.first).questions
		#expect(questions.first { $0.question == "Shared question" }?.extraWords.contains("automatic") == true)

		// A question of the app with the text of a shared question keeps its answer, and the shared one is not added.
		#expect(appWithAnswer.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "some-question", "shared-question", "can-you-localize-the-app-into-my-language"])
		#expect(appWithAnswer.faqHeadings.compactMap { appWithAnswer.faqAnswerMarkdown(of: $0) } == ["Answer.", "My own answer."])
		// An unknown ID is reported at its item, a page without a FAQ section at the `sharedQuestions` key, and an ID that is picked twice at the line of the second one.
		let unknownErrors = await loadingErrors(source.replacing("'shared'", with: "'unknown'"), project: project)
		#expect(unknownErrors.map(\.line) == [7])
		#expect(unknownErrors.map(\.reason) == ["`sharedQuestions` has `unknown`, which is not the ID of a question in `content/shared-questions.md`."])
		let twiceErrors = await loadingErrors(source.replacing("'shared'", with: "'shared', 'shared'"), project: project)
		#expect(twiceErrors.map(\.line) == [7])
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
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### First {#first}\n\nAnswer.\n\n### Problem {#problem}\n<!-- @faq.first -->\n\nAnswer.\n\n### Third {#third}\n\nAnswer.\n",
				]
			)
		)
		let app = try await App(title: "My App", frontmatter: "isMenuBarApp: true\nsharedQuestions: ['third', 'problem', 'first']", body: "## Frequently Asked Questions {#faq}\n\n### Own question\n\nAnswer.\n", project: project)

		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "feedback", "app-not-showing-in-menu-bar", "problem", "own-question", "third", "first", "can-you-localize-the-app-into-my-language"])
	}

	@Test
	func `a question of the app cannot go first`() async {
		let errors = await loadingErrors(body: "## Frequently Asked Questions {#faq}\n\n### Own question\n<!-- @faq.first -->\n\nAnswer.\n")

		#expect(errors.map(\.line) == [10])
		#expect(errors.map(\.reason) == ["`@faq.first` is only for the questions in `content/shared-questions.md`. A question of the app goes where it is written."])
	}

	@Test(.temporaryDirectory)
	func `a shared question that is not a level 3 heading is an error in the file of the shared questions`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n\n## Section\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['shared']", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [5])
	}

	@Test(.temporaryDirectory)
	func `two shared questions with the same ID are an error in the file of the shared questions`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n\n### Other question {#shared}\n\nAnswer.\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['shared']", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [5])
	}

	@Test(.temporaryDirectory)
	func `a shared question that is in the file twice or that has no answer is an error`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Is it native? {#native}\n\nYes.\n\n### Is it native? {#native-2}\n\nYes.\n\n### Empty {#empty}\n<!-- @faq.first -->\n\n### Last {#last}\n\nAnswer.\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['native']", project: project)

		#expect(errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"5: The question “Is it native?” is in the file twice. Keep one, and pick it with its ID.",
			"9: The question “Empty” has no answer. Write it below the heading.",
		])
	}

	/**
	The picked question goes after the question of the app, and it has no line, so the error is at the question of the app, which is the one to change, and names the picked question.
	*/
	@Test(.temporaryDirectory)
	func `a shared question with the ID of a question of the app is an error`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\nAnswer.\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['shared']", body: "## Frequently Asked Questions {#faq}\n\n### Own question {#shared}\n\nAnswer.\n", project: project)

		#expect(errors.map { "\($0.line ?? 0): \($0.reason)" } == ["11: The heading ID `shared` is also the ID of “Shared question”, which the build adds to the page, like a shared question, so links to it are ambiguous. Give this heading another custom ID, like `{#shared-2}`."])

		// Two headings of the file: the error is at the second, and says where the first is.
		let ownErrors = await loadingErrors(body: "## First {#same}\n\nText.\n\n## Second {#same}\n\nText.\n")
		#expect(ownErrors.map { "\($0.line ?? 0): \($0.reason)" } == ["12: The heading ID `same` is already the ID of “First” at line 8, so links to it are ambiguous. Give one of the headings another custom ID, like `{#same-2}`."])
	}

	/**
	A heading in a block directive is not the heading of a question, so it would give the questions after it the wrong answers.
	*/
	@Test(.temporaryDirectory)
	func `a heading in a shared answer is an error in the file of the shared questions`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\n@Details(summary: \"More\") {\n### Nested\n}\n\n### Other question {#other}\n\nAnswer.\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['other']", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [4])
	}

	@Test(.temporaryDirectory)
	func `a mistake in a shared answer is an error in the file of the shared questions`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n<!-- @faq.unknown -->\n\nAnswer.\n",
				]
			)
		)
		let errors = await loadingErrors(frontmatter: "sharedQuestions: ['shared']", project: project)

		#expect(errors.map(\.file?.lastPathComponent) == ["shared-questions.md"])
		#expect(errors.map(\.line) == [2])
	}

	/**
	The answers are parsed with the block directives of the app page.
	*/
	@Test(.temporaryDirectory)
	func `a shared answer can have block directives`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\n@Details(summary: \"Older macOS\") {\nOpen System Settings.\n}\n",
				]
			)
		)
		let app = try await App(title: "My App", frontmatter: "sharedQuestions: ['shared']", body: "## Frequently Asked Questions {#faq}\n", project: project)

		#expect(app.markdown.html.contains(#"<span class="\#(ProseStyles.collapsibleTitle.className)">Older macOS</span>"#))
	}

	/**
	The added menu bar question only links to the general question, which the feedback page suggests instead, as it has the answer. An answer of the app itself is suggested.
	*/
	@Test
	func `the feedback page suggests the menu bar question only when the app has its own answer`() async throws {
		let source = App.testMarkdown(title: "My App", frontmatter: "isMenuBarApp: true", body: "## Frequently Asked Questions {#faq}\n\n### Some question\n\nAnswer.\n")
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
			apps.append(try await App(title: slug, body: "", slug: slug))
		}

		let morning = Date(timeIntervalSince1970: 1_800_000_000)
		let related = apps[0].relatedApps(from: apps, on: morning)

		#expect(related.count == 4)
		#expect(!related.map(\.slug).contains("a"))
		#expect(related.map(\.slug) == apps[0].relatedApps(from: apps, on: morning.addingTimeInterval(60)).map(\.slug))
	}

	/**
	Most apps are equally similar to an app, so ties are shuffled daily, not broken by the publication date, which showed the same newest apps on most pages. A more similar app always comes first.
	*/
	@Test
	func `related apps spread over all equally similar apps, but the most similar always shows`() async throws {
		var apps = [App]()

		for day in 10...19 {
			let slug = "app-\(day)"
			apps.append(try await App(title: slug, publicationDate: "2026-01-\(day)", body: "", slug: slug))
		}

		let menuBarApp = try await App(title: "Menu", publicationDate: "2020-01-01", frontmatter: "isMenuBarApp: true", body: "", slug: "menu")
		let otherMenuBarApp = try await App(title: "Other", publicationDate: "2020-01-01", frontmatter: "isMenuBarApp: true", body: "", slug: "other")
		var shownSlugs = Set<String>()

		for day in 0..<30 {
			let date = Date(timeIntervalSince1970: 1_800_000_000 + Double(day) * 86_400)
			shownSlugs.formUnion(apps[0].relatedApps(from: apps, on: date).map(\.slug))
			#expect(menuBarApp.relatedApps(from: apps + [otherMenuBarApp], on: date).first?.slug == "other")
		}

		#expect(shownSlugs == Set(apps.dropFirst().map(\.slug)))
	}

	@Test
	func `an impossible day is rejected instead of moved`() async {
		await #expect(throws: ContentErrors.self) {
			try await App(publicationDate: "2026-02-30")
		}
	}

	@Test
	func `the FAQ heading needs its ID`() async throws {
		let errors = await loadingErrors(body: "## Frequently Asked Questions\n\n### A question\n\nAn answer.")

		try #require(errors.map(\.line) == [8])
		#expect(errors[0].reason.hasPrefix("The “Frequently Asked Questions” heading needs the ID `faq`"))
	}

	@Test
	func `every problem in the feedback note is reported at its key`() async {
		let errors = await loadingErrors(frontmatter: "feedbackNote: 'See [this](missing.md) and ![](/image.png).'")

		#expect(errors.map(\.line) == [6, 6])
		#expect(errors.allSatisfy { $0.reason.hasPrefix("`feedbackNote`: ") })
	}

	@Test
	func `a missing key that is written in another case is an unknown key at its line`() async {
		let errors = await loadingErrors("---\ntitle: 'Test'\nSubtitle: 'Test app'\npublicationDate: 2026-01-01\nplatforms: ['macOS']\n---\n\nText.")

		#expect(errors.map { "\($0.line ?? 0): \($0.reason)" } == ["3: Unknown key `Subtitle`. Keys are case-sensitive: `subtitle`."])
	}

	@Test
	func `the feedback note cannot have headings`() async throws {
		let errors = await loadingErrors(frontmatter: "feedbackNote: '### Restart the app first.'")

		try #require(errors.map(\.line) == [6])
		#expect(errors[0].reason.contains("`**Restart the app first.**`"))
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
		let errors = await loadingErrors(body: "Text.\n\n![](/image.png)\n\n## Question\n<!-- @faq.platforms Amiga -->")

		#expect(errors.map(\.line) == [10, 13])
	}

	@Test
	func `blog posts check the heading directives`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Post'\npublicationDate: 2026-01-01\n---\n\n## Question\n<!-- @faq.platforms Amiga -->", slug: "post")
		}

		try #require(errors.errors.map(\.line) == [7])
		#expect(errors.errors[0].reason.hasPrefix("The values of `@faq.platforms` are invalid"))
	}

	@Test
	func `a description that search results would cut is an error at its line`() async throws {
		let description = String(repeating: "a", count: SnippetText.maximumLength + 1)
		let errors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Post'\ndescription: '\(description)'\npublicationDate: 2026-01-01\n---\n\nText.", slug: "post")
		}

		let error = try #require(errors.errors.first)
		#expect(error.line == 3)
		#expect(error.reason == "Invalid `description`: Must be at most 160 characters, so search results show all of it, got 161.")
	}

	@Test
	func `a pinned question needs one rank`() async throws {
		let error = try await #require(throws: ContentErrors.self) {
			try await App(body: "## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.pinned -->\n\n### Another question {#another}\n<!-- @faq.pinned 1 2 -->\n\nAn answer.")
		}

		try #require(error.errors.map(\.line) == [11, 14])
		#expect(error.errors[0].reason == "`@faq.pinned` needs at least one value.")
	}

	@Test
	func `only the general FAQ page can mark general questions`() async throws {
		let error = try await #require(throws: ContentErrors.self) {
			try await App(body: "## Frequently Asked Questions {#faq}\n\n### A question {#question}\n<!-- @faq.general -->\n\nAn answer.")
		}

		try #require(error.errors.map(\.line) == [11])
		#expect(error.errors[0].reason.hasPrefix("Unknown directive `@faq.general`."))
	}

	@Test
	func `an app needs a platform`() async {
		await #expect(throws: ContentErrors.self) {
			try await App(platforms: [])
		}
	}

	@Test
	func `a feature plain projection preserves its title after leading comment blocks`() throws {
		var directive = BlockDirective(name: "Feature", children: [Paragraph(Markdown.Text("Body."))] as [any BlockMarkup])
		directive.argumentText = .init("title: \"<!-- An author note -->\n\n**Fast**\n\n<!-- Another note -->\"")
		let blocks = directive.plainBlocks
		let heading = try #require(blocks.first as? Markdown.Heading)

		#expect(blocks.count == 2)
		#expect(heading.level == 2)
		#expect(heading.plainText == "Fast")
		#expect(heading.child(at: 0) is Strong)
		#expect((blocks.last as? Paragraph)?.plainText == "Body.")
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
		let file = try MarkdownFile(contents: "@TinyApp(title: \"Copy URL\", icon: \"/apps/copy-url/icon.png\", download: \"https://example.com/Copy-URL.zip\", source: \"https://github.com/sindresorhus/Copy-URL\", macOS: \"13\") {\n  Copies *URLs*.\n}\n\n@TinyApp(title: \"Safari Private\", download: \"https://example.com/Safari-Private.zip\") {\n  Opens URLs.\n}", url: Project.empty.root.appending(path: "content/pages/tiny-apps.md"))
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
			try await App(frontmatter: "appStoreID: 123\nisPaid: \(isPaid)\nolderVersions: [\n\t{version: '2.0.0', macOS: '15', url: 'https://example.com/a.zip?b=1&c=2'},\n\t{version: '1.10', macOS: '10.15', url: 'https://example.com/old.zip'},\n]\nnonAppStoreVersion: {version: '3.0.0', macOS: 26, url: 'https://example.com/new.zip'}")
		}

		let freeApp = try await loadApp(isPaid: false)
		let paidApp = try await loadApp(isPaid: true)

		#expect(freeApp.markdown.headings.map(\.id.rawValue) == ["older-versions", "non-app-store-version"])
		#expect(freeApp.markdown.html.contains(#"<p>A special version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.</p>"#))
		#expect(freeApp.markdown.html.contains(#"<a href="https://example.com/new.zip">Download</a> <em>(3.0.0)</em>"#))
		#expect(freeApp.markdown.html.contains("<em>Requires macOS 26 or later</em>"))
		#expect(freeApp.overflowLinks.contains(LabeledLink("Non-App Store Version", destination: .fragment("non-app-store-version"))))
		#expect(freeApp.links.contains(LabeledLink("Older Versions", destination: .fragment("older-versions"))))
		#expect(freeApp.olderVersions.map(\.macOS) == [.v15, .v10_15])
		#expect(freeApp.markdown.html.contains(#"<li><a href="https://example.com/a.zip?b=1&amp;c=2">2.0.0</a> for macOS 15+</li>"#))
		#expect(!freeApp.markdown.html.contains("These are free for everyone"))
		#expect(paidApp.markdown.html.contains(#"<li><a href="https://example.com/old.zip">1.10</a> for macOS 10.15</li>"#))
		#expect(paidApp.markdown.html.contains("<p>These are free for everyone but they will not run on newer macOS versions.</p>"))
	}

	@Test
	func `a free older version is also for the newer macOS versions that the app does not run on`() async throws {
		func loadListing(isPaid: Bool) async throws -> AppListing {
			AppListing(app: try await App(frontmatter: "isPaid: \(isPaid)\nminimumOSVersion: '26'\nolderVersions: [\n\t{version: '2.0.0', macOS: '13', url: 'https://example.com/a.zip'},\n\t{version: '1.0.0', macOS: '11', url: 'https://example.com/b.zip'},\n]"))
		}

		let free = try await loadListing(isPaid: false)
		let paid = try await loadListing(isPaid: true)

		#expect(free.olderVersion(for: .v15)?.version == "2.0.0")
		#expect(free.olderVersion(for: .v13)?.version == "2.0.0")
		#expect(free.olderVersion(for: .v12)?.version == "1.0.0")
		#expect(free.olderVersion(for: .v10_15) == nil)
		#expect(free.olderVersion(for: .v26) == nil)
		#expect(paid.olderVersion(for: .v13)?.version == "2.0.0")
		#expect(paid.olderVersion(for: .v15) == nil)
	}

	@Test
	func `older version recommendations use the fetched requirement and need a known requirement`() async throws {
		let olderVersions = "olderVersions: [{version: '1.0.0', macOS: '13', url: 'https://example.com/old.zip'}]"
		let app = try await App(frontmatter: "minimumOSVersion: '26'\n\(olderVersions)")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "minimumOsVersion": "27.0"}"#)
		let listing = AppListing(app: app, appStoreInfo: info)

		#expect(listing.olderVersion(for: .v26)?.version == "1.0.0")
		#expect(listing.olderVersion(for: .v27) == nil)

		let unknownRequirement = AppListing(app: try await App(frontmatter: olderVersions))
		#expect(unknownRequirement.olderVersion(for: .v13)?.version == "1.0.0")
		#expect(unknownRequirement.olderVersion(for: .v15) == nil)
	}

	@Test(arguments: [
		("olderVersions: [{version: '1.0.0', macOS: '13', url: 'https://example.com/a.zip'}, {version: '1.1.0', macOS: '13', url: 'https://example.com/b.zip'}]", "`olderVersions` must be newest first, with one version for each macOS version."),
		("olderVersions: [{version: '1.0.0', macOS: '13', url: 'https://example.com/a.zip'}, {version: '2.0.0', macOS: '14', url: 'https://example.com/b.zip'}]", "`olderVersions` must be newest first, with one version for each macOS version."),
	])
	func `older versions are newest first and do not repeat a macOS version`(lines: String, reason: String) async throws {
		let errors = try #require(await #expect(throws: ContentErrors.self) {
			try await App(frontmatter: lines)
		})

		#expect(errors.errors.map(\.reason) == [reason])
	}

	@Test
	func `list subtitles and descriptions get the prose styles`() async throws {
		let app = try await App(body: "- Get Active Browser Tab\n\t: Gets the URL\n\t:: Supports Safari.")

		#expect(app.markdown.html.contains(#"<span class="\#(ProseStyles.listSubtitle.className)">Gets the URL</span>\#n<span class="\#(ProseStyles.listDescription.className)">Supports Safari.</span>"#))
	}

	@Test(.temporaryDirectory)
	func `links to content files go to the pages of their content types`() throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/dato.md": "",
					"content/apps/gifski/index.md": "",
					"content/apps/gifski/icon.png": "",
					"content/blog/post.md": "",
					"content/blog/photo.png": "",
					"content/pages/apps/faq.md": "",
				]
			)
		)

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
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/dato/index.md": "",
					"content/apps/dato/icon.png": "",
					"content/blog/post/index.md": "",
					"content/blog/post/image.png": "",
					"content/pages/about/index.md": "",
					"content/pages/about/photo.jpg": "",
				]
			)
		)

		for (directory, slug, file) in [("content/apps", "dato", "icon.png"), ("content/blog", "post", "image.png"), ("content/pages", "about", "photo.jpg")] {
			let contentFile = project.root.appending(path: "\(directory)/\(slug)/\(file)")
			let page = try #require(RoutePath(contentFile: project.root.appending(path: "\(directory)/\(slug)/index.md"), project: project))
			#expect(project.publicPath(ofContentFile: contentFile) == page.appending(file))
			#expect(project.publicFile(page.appending(file)) == contentFile)
		}
	}

	@Test(.temporaryDirectory)
	func `apps and posts in a subdirectory are an error instead of a crash`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/sub/test.md": App.testMarkdown(body: ""),
					"content/blog/sub/post.md": "---\ntitle: 'Post'\npublicationDate: 2026-01-01\n---",
				]
			)
		)

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
	func `the Setapp rating is read from the page on Setapp, and only shown as text when the app has no other rating`() async throws {
		func page(bestRating: Int) -> Data {
			Data(#"<script id="organization-jsonld" type="application/ld+json">{"@type": "Organization"}</script><script id="app-jsonld" type="application/ld+json">{"@type": "SoftwareApplication", "aggregateRating": {"@type": "AggregateRating", "ratingValue": 99, "bestRating": \#(bestRating), "ratingCount": 877}}</script>"#.utf8)
		}

		let setappRating = try SetappRating(html: page(bestRating: 100))
		#expect(setappRating.text == "99% positive from 877 ratings on Setapp")

		#expect(throws: ResponseCache.ReadError.self) {
			try SetappRating(html: page(bestRating: 5))
		}

		let app = try await App(frontmatter: "setappID: 1\nisPaid: true\ngumroad: {id: 'test', price: 10}")
		let listing = AppListing(app: app, setappRating: setappRating)
		let html = AppReviews(reviews: [], rating: listing.rating).render()
		#expect(html.contains(">99%</p>"))
		#expect(html.contains(">positive from 877 ratings on Setapp</p>"))
		#expect(!html.contains("star"))
		#expect(Schema.SoftwareApplication(listing: listing).aggregateRating == nil)

		// The rating of a store comes first, as it is in the structured data.
		let product = try GumroadProduct(json: #"{"price_cents": 1000, "ratings": {"count": 26, "average": 4.8}}"#)
		let gumroadListing = AppListing(app: app, gumroadProduct: product, setappRating: setappRating)
		#expect(gumroadListing.rating?.text == "Rated 4.8 out of 5 from 26 ratings on Gumroad")
		#expect(Schema.SoftwareApplication(listing: gumroadListing).aggregateRating?.ratingCount == 26)
	}

	/**
	The documents get `isDraft` from their frontmatter (``PublishedFrontmatter``), not the default of ``ContentEntry``, which is `false`, so a draft is not published.
	*/
	@Test
	func `a draft app, post, and guide are drafts`() async throws {
		let frontmatter = "isDraft: true\ntitle: 'Test'\npublicationDate: 2026-01-01"

		#expect(try await App(markdown: "---\n\(frontmatter)\nsubtitle: 'Test app'\nplatforms: ['macOS']\n---\n\nText.").isDraft)
		#expect(try await BlogPost(markdown: "---\n\(frontmatter)\n---\n\nText.").isDraft)
		#expect(try await Guide(markdown: "---\n\(frontmatter)\ndescription: 'A guide.'\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)").isDraft)
	}

	/**
	The real date, not the date of the build, which the tests fix, so a year after the current one is in the future.
	*/
	@Test
	func `a published app, post, or guide cannot have a date in the future, but a draft can`() async throws {
		let futureDate = "\(Calendar.current.component(.year, from: .now) + 1)-01-01"
		let message = "The date is in the future. Use `isDraft: true` until the day it is published."

		await #expect(throws: ContentErrors.self) {
			try await App(markdown: App.testMarkdown(publicationDate: futureDate))
		}

		let postErrors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Post'\npublicationDate: \(futureDate)\n---\n\nText.")
		}

		#expect(postErrors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["3: \(message)"])

		await #expect(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'Test'\npublicationDate: \(futureDate)\ndescription: 'A guide.'\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)")
		}

		#expect(try await App(markdown: App.testMarkdown(publicationDate: futureDate, frontmatter: "isDraft: true")).isDraft)
	}

	@Test
	func `old paths of a post redirect to the post`() async throws {
		let post = try await BlogPost(markdown: "---\ntitle: 'Post'\npublicationDate: 2026-01-01\nredirectFrom: ['/blog/old-name']\n---\n\nText.", slug: "post")
		let content = SiteContent(
			apps: [],
			posts: [post],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let redirect = try #require(Site(content: content).routes().first { $0.path == #path("/blog/old-name") })

		guard case .redirect(let destination) = redirect.output else {
			Issue.record("Expected a redirect, got \(redirect.output)")
			return
		}

		#expect(destination == .path(#path("/blog/post")))
	}

	/**
	An unlisted post keeps its page, as its URL may already be shared, but the blog, the feeds, and the sitemap leave it out.
	*/
	@Test
	func `an unlisted post keeps its page, but is not listed`() async throws {
		let listed = try await BlogPost(markdown: "---\ntitle: 'Listed'\npublicationDate: 2026-01-01\n---\n\nText.", slug: "listed")
		let unlisted = try await BlogPost(markdown: "---\ntitle: 'Unlisted'\npublicationDate: 2026-01-02\nisUnlisted: true\n---\n\nText.", slug: "unlisted")
		let content = SiteContent(
			apps: [],
			posts: [listed, unlisted],
			pages: [],
			buildDate: .now,
			project: .empty
		)
		let routes = Site(content: content).routes()

		let route = try #require(routes.first { $0.path == #path("/blog/unlisted") })
		#expect(route.sitemapEntry == nil)

		let blog = try #require(routes.first { $0.path == .blog }).renderedHTML()
		let feed = try await String(decoding: #require(routes.first { $0.path == SiteFeed.blog.path }).renderedFile(), as: UTF8.self)

		for html in [blog, feed] {
			#expect(html.contains("/blog/listed"))
			#expect(!html.contains("/blog/unlisted"))
		}
	}

	/**
	The guides are not posts, so they have their own list, and the blog and its feed leave them out.
	*/
	@Test
	func `a guide has a page that links its app, and is in the sitemap and the list of guides, but not in the blog`() async throws {
		let app = try await App()
		let guide = try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)", slug: "how-to-test")
		let content = SiteContent(
			apps: [app],
			posts: [],
			guides: [guide],
			pages: [],
			resolvedGuides: [try #require(Guide.Resolved(guide: guide, apps: [app]))],
			buildDate: .now,
			project: .empty
		)
		let routes = Site(content: content).routes()

		let route = try #require(routes.first { $0.path == #path("/guides/how-to-test") })
		#expect(route.sitemapEntry != nil)
		#expect(try route.renderedHTML().contains(#"href="/test""#))

		let guides = try #require(routes.first { $0.path == .guides }).renderedHTML()
		#expect(guides.contains("/guides/how-to-test"))
		#expect(guides.contains(#"<img src="\#(app.iconPath)""#))

		let appPage = try #require(routes.first { $0.path == #path("/test") }).renderedHTML()
		#expect(appPage.contains("/guides/how-to-test"))

		let blog = try #require(routes.first { $0.path == .blog }).renderedHTML()
		let feed = try await String(decoding: #require(routes.first { $0.path == SiteFeed.blog.path }).renderedFile(), as: UTF8.self)

		for html in [blog, feed] {
			#expect(!html.contains("/guides/how-to-test"))
		}
	}

	/**
	A site has one name in the press quotes, so another name is a typo, like “Cult Of Mac”, or a `url` copied from a quote of another site. The reviews of buyers on Gumroad have the names of people.
	*/
	@Test(.temporaryDirectory)
	func `a site with two names in the press quotes is an error at the less common name`() async throws {
		func quote(_ source: String, url: String) -> String {
			"{quote: 'Great', source: '\(source)', url: '\(url)', year: 2026}"
		}

		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/first.md": App.testMarkdown(title: "First", frontmatter: "pressQuotes: [\(quote("Cult of Mac", url: "https://www.cultofmac.com/1")), \(quote("Buyer", url: "https://sindresorhus.gumroad.com/l/first"))]"),
					"content/apps/second.md": App.testMarkdown(title: "Second", frontmatter: "pressQuotes: [\(quote("Cult of Mac", url: "https://cultofmac.com/2")), \(quote("MacStories", url: "https://cultofmac.com/3")), \(quote("Another Buyer", url: "https://sindresorhus.gumroad.com/l/second"))]"),
					"content/blog/.keep": "",
					"content/guides/.keep": "",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map(\.reason) == ["cultofmac.com is “Cult of Mac” in 2 quotes, but “MacStories” in Second. Use one name for the site, or check the `url`."])
	}

	@Test(.temporaryDirectory)
	func `a guide about an app that does not exist, is archived, or is unlisted is an error`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/old.md": App.testMarkdown(title: "Old", frontmatter: "isArchived: true"),
					"content/apps/hidden.md": App.testMarkdown(title: "Hidden", frontmatter: "isUnlisted: true"),
					"content/blog/.keep": "",
					"content/guides/how-to-test.md": "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['missing', 'old', 'hidden']\n---\n\n\(Guide.testBody.replacing("/test", with: "/missing"))",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map(\.reason).sorted() == ["Hidden is unlisted, so a guide cannot recommend it.", "Old is archived, so a guide cannot recommend it.", "There is no app with the slug `missing`, like `gifski` for `content/apps/gifski/index.md`."])
	}

	/**
	The mistakes between the files are reported in the same run as the mistakes of each file, so a mistake does not wait for another run. A slug of an app that did not load is not reported, as the app has its own mistake.
	*/
	@Test(.temporaryDirectory)
	func `the mistakes between files are reported with the mistakes of the files`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/broken.md": App.testMarkdown(title: "Broken", body: "# Broken\n\nText."),
					"content/blog/.keep": "",
					"content/guides/how-to-test.md": "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['broken', 'missing']\n---\n\n\(Guide.testBody.replacing("/test", with: "/broken"))",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.count == 2)
		#expect(errors.errors.contains { $0.file?.lastPathComponent == "broken.md" && $0.reason.contains("level 1 heading") })
		#expect(errors.errors.contains { $0.reason == "There is no app with the slug `missing`, like `gifski` for `content/apps/gifski/index.md`." })
	}

	/**
	A content directory that does not exist is one mistake, not one for each file that needs an app from it.
	*/
	@Test(.temporaryDirectory)
	func `a missing content directory is not reported for each app that a file needs`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/blog/.keep": "",
					"content/guides/how-to-test.md": "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map(\.reason) == ["The content directory does not exist."])
	}

	/**
	A title, a subtitle, and a description go in the `<title>`, the link previews, and the search results as they are written, so Markdown would show its syntax. The status of the now page is Markdown, so it can link.
	*/
	@Test
	func `Markdown in a plain-text field is an error, but the status of the now page is Markdown`() async throws {
		// Converted, as the decoding throws one error or all of them.
		let thrown = try await #require(throws: (any Error).self) {
			try await App(markdown: App.testMarkdown().replacing("subtitle: 'Test app'", with: "subtitle: '*Menu* bar calendar'"))
		}

		let error = try #require(ContentErrors(converting: thrown, file: URL(filePath: "/")).errors.first)
		#expect(error.line == 3)
		#expect(error.reason == "Invalid `subtitle`: This field is plain text, so Markdown is not rendered here, like `**`, `*`, a backtick, or a link. Write it without Markdown.")

		for description in ["Not **bold**.", "See [Dato](/dato).", "Use `npx`."] {
			let thrown = try await #require(throws: (any Error).self) {
				try await BlogPost(markdown: "---\ntitle: 'Test'\ndescription: '\(description)'\npublicationDate: 2026-01-01\n---\n\nText.")
			}

			#expect(ContentErrors(converting: thrown, file: URL(filePath: "/")).errors.first?.reason.contains("This field is plain text") == true)
		}

		_ = try await BlogPost(markdown: "---\ntitle: '5* hotels, and a * b'\npublicationDate: 2026-01-01\n---\n\nText.")

		let now = try await MarkdownPage(markdown: "---\ntitle: 'Now'\nstatus: 'Working on [SOML](https://soml.sh) and **apps**.'\n---\n\nText.", slug: "now")
		#expect(now.status?.inlineHTML == #"Working on <a href="https://soml.sh">SOML</a> and <strong>apps</strong>."#)
		#expect(now.status?.introduction == "Working on SOML and apps.")
	}

	/**
	The error of Swift names the type, not the values, so the valid values are listed, in the frontmatter and in the heading directives.
	*/
	@Test
	func `an invalid value of an enum lists the valid values`() async throws {
		let thrown = try #require(throws: (any Error).self) {
			try MarkdownFile(contents: App.testMarkdown().replacing("'macOS'", with: "'macos'"), url: URL(filePath: "/content/apps/test.md")).decodeFrontmatter(as: App.Frontmatter.self)
		}

		let platformError = try #require(ContentErrors(converting: thrown, file: URL(filePath: "/")).errors.first)

		#expect(platformError.line == 5)
		#expect(platformError.reason == "Invalid `platforms[0]`: Must be one of `macOS`, `iOS`, `watchOS`, `tvOS`, or `visionOS`, not “macos”.")

		let file = try MarkdownFile(contents: "", url: URL(filePath: "/content/apps/test.md"))
		let document = MarkdownDocument(parsing: "### Question {#question}\n<!-- @faq.platforms macos -->", options: .content(file, project: .empty))
		#expect(document.problems.map(\.reason) == ["The values of `@faq.platforms` are invalid: Must be one of `macOS`, `iOS`, `watchOS`, `tvOS`, or `visionOS`, not “macos”."])
	}

	/**
	The feedback page finds an app by a name in any case, so a name that differs only in case is the same name.
	*/
	@Test
	func `a feedback name that is the title or another name in any case is an error`() throws {
		let thrown = try #require(throws: ContentErrors.self) {
			try MarkdownFile(contents: App.testMarkdown(frontmatter: "feedbackNames: ['Color Picker', 'color picker', 'test']"), url: URL(filePath: "/content/apps/test.md")).decodeFrontmatter(as: App.Frontmatter.self)
		}

		#expect(thrown.errors.map(\.reason).sorted() == [
			"`feedbackNames` has `color picker` twice.",
			"`feedbackNames` has the title, which the feedback page already finds the app by.",
		])
	}

	/**
	The page shows the title as its `h1`, so a level 1 heading in the text would be a second one. A Markdown page has no other title, so it can start with one.
	*/
	@Test
	func `a level 1 heading in an app, a post, or a guide is an error`() async throws {
		let appErrors = try await #require(throws: ContentErrors.self) {
			try await App(body: "Text.\n\n# Features")
		}

		#expect(appErrors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["10: The page shows the title as its level 1 heading, so the text cannot have one. Make “Features” a level 2 heading: `## Features`."])

		let postError = try await #require(throws: ContentError.self) {
			try await BlogPost(markdown: "---\ntitle: 'Test'\npublicationDate: 2026-01-01\n---\n\n# Test\n\nText.")
		}

		#expect(postError.line == 6)

		let guideErrors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)\n\n# More")
		}

		#expect(guideErrors.errors.map(\.reason) == ["The page shows the title as its level 1 heading, so the text cannot have one. Make “More” a level 2 heading: `## More`."])

		let page = try await MarkdownPage(markdown: "---\ntitle: 'Terms'\n---\n\n# Terms\n\nText.")
		#expect(page.markdown.headings.first?.level == .h1)
	}

	/**
	All the mistakes that the types cannot catch are reported at once, each at the line of its value, also in a nested value, like an item of a list.
	*/
	@Test
	func `every frontmatter mistake is reported at its line`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(publicationDate: "2020-01-01", frontmatter: "minimumOSVersion: '25'\npressQuotes: [\n\t{quote: 'Great', source: 'First', year: 2021}\n\t{quote: 'Fine', source: 'Second', year: 2100}\n]")
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"9: `pressQuotes` has the year 2100, which is not the year of an article.",
			"6: `minimumOSVersion` must be 26 or later, as the platforms only share their version numbers from 26, got 25.",
		])

		let guideErrors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: [\n\t'test'\n\t'test'\n]\n---\n\n\(Guide.testBody)", slug: "how-to-test")
		}

		#expect(guideErrors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["8: `apps` has `test` twice."])
	}

	@Test
	func `a guide without its shape is an error at its lines`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test', 'other']\n---\n\n@Tips {\n- Use [Test](/test).\n}\n\n## Without the app\n\nText.", slug: "how-to-test")
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"9: A guide starts with the short answer: `@QuickAnswer { … }`.",
			"9: A guide needs the steps of the task: `@Steps { 1. … }`.",
			"9: A guide needs the built-in way, in a section with the heading `## Without an app`.",
		])
	}

	/**
	The content leaves out the drafts, so a link to one is a broken link, and the build says that it goes to a draft, as its file exists.
	*/
	@Test(.temporaryDirectory)
	func `a link to a draft finds the file of the draft`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/draft-app/index.md": "",
					"content/guides/keep-awake.md": "",
				]
			)
		)
		let content = SiteContent(
			apps: [],
			posts: [],
			pages: [],
			buildDate: .now,
			project: project
		)

		#expect(content.draftFile(ofLink: "/guides/keep-awake#steps")?.path(relativeTo: project.root) == "content/guides/keep-awake.md")
		#expect(content.draftFile(ofLink: "/draft-app")?.path(relativeTo: project.root) == "content/apps/draft-app/index.md")
		#expect(content.draftFile(ofLink: "/guides/missing") == nil)
		#expect(content.draftFile(ofLink: "https://example.com/guides/keep-awake") == nil)
	}

	/**
	The page shows the app box before the “Without an app” section, so an empty section would leave the box alone. A comment is a note for the author, not text, but raw HTML that shows is text.
	*/
	@Test
	func `an empty “Without an app” section is an error at its heading`() async throws {
		let body = Guide.testBody.replacing("## Without an app\n\nText.", with: "## Without an app\n\n<!-- Later. -->\n\n## Other notes\n\nText.")

		let errors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\n\(body)", slug: "how-to-test")
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["17: The section “Without an app” is empty. Write the built-in way below its heading."])

		// Raw HTML that shows is text, unlike a comment.
		let htmlBody = Guide.testBody.replacing("## Without an app\n\nText.", with: "## Without an app\n\n<table><tr><td>Text</td></tr></table>")
		_ = try await Guide(markdown: "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\n\(htmlBody)", slug: "how-to-test")
	}

	/**
	A draft is not published, so it does not need the shape of a guide yet, but its frontmatter is still checked.
	*/
	@Test
	func `a draft guide does not need its shape`() async throws {
		let draft = try await Guide(markdown: "---\nisDraft: true\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\n---\n\nNotes.", slug: "how-to-test")
		#expect(draft.isDraft)

		let errors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\nisDraft: true\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: []\n---\n\nNotes.", slug: "how-to-test")
		}

		#expect(errors.errors.map(\.reason) == ["A guide needs `apps`, the slugs of the apps that it is about, like `apps: ['gifski']`."])
	}

	/**
	Every guide has a topic, which groups it on the list of guides, so a missing or unknown topic is a mistake.
	*/
	@Test
	func `a guide needs a known topic`() async throws {
		for topic in ["", "topic: 'menu'\n"] {
			let errors = try await #require(throws: ContentErrors.self) {
				try await Guide(markdown: "---\nisDraft: true\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\n\(topic)apps: ['test']\n---\n\nNotes.", slug: "how-to-test")
			}

			#expect(errors.errors.map(\.reason).joined().contains("topic"), "\(errors.errors.map(\.reason))")
		}
	}

	/**
	The link is only checked when the first app exists, so a typo in its slug is reported at `apps` when the content loads, not as a link to change. The slugs are compared exactly, not with the files on a disk that ignores case.
	*/
	@Test(.temporaryDirectory, arguments: [("other", "9: The `@QuickAnswer` must link to `other`, the first app of `apps`: `[…](../apps/other/index.md)`."), ("Other", "6: There is no app with the slug `Other`, like `gifski` for `content/apps/gifski/index.md`.")])
	func `the short answer of a guide links to its first app`(slug: String, error: String) async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/other/index.md": App.testMarkdown(title: "Other"),
					"content/apps/test.md": App.testMarkdown(title: "Test"),
					"content/blog/.keep": "",
					"content/guides/how-to-test.md": "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['\(slug)', 'test']\n---\n\n\(Guide.testBody)",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [error])
	}

	/**
	The page shows the screenshot of the first app, so a number that the app does not have would silently show nothing.
	*/
	@Test(.temporaryDirectory)
	func `a guide with a screenshot that its first app does not have is an error`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/test.md": App.testMarkdown(title: "Test"),
					"content/blog/.keep": "",
					"content/guides/how-to-test.md": "---\ntitle: 'How to Test'\ndescription: 'Use Test.'\npublicationDate: 2026-01-01\ntopic: 'mac'\napps: ['test']\nscreenshot: {number: 1, description: 'The result'}\n---\n\n\(Guide.testBody)",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["7: Test has no screenshot 1. It has 0, like `screenshot1.png` in `content/apps/test`."])
	}

	/**
	Whole years, so the years only go up on the day the first app was published.
	*/
	@Test
	func `years of craft counts whole years since the first app`() async throws {
		let app = try await App(publicationDate: "2015-06-09")

		func years(on date: String) throws -> Int? {
			let buildDate = try Date(date, strategy: .iso8601.year().month().day())
			return SiteContent(
				apps: [app],
				posts: [],
				pages: [],
				buildDate: buildDate,
				project: .empty
			).yearsOfCraft
		}

		#expect(try years(on: "2026-03-01") == 10)
		#expect(try years(on: "2026-06-09") == 11)
		#expect(try years(on: "2026-12-31") == 11)
	}

	@Test
	func `years of open source counts whole years since the first repo`() throws {
		func years(on date: String) throws -> Int? {
			let buildDate = try Date(date, strategy: .iso8601.year().month().day())
			return SiteContent(
				apps: [],
				posts: [],
				pages: [],
				buildDate: buildDate,
				project: .empty
			).yearsOfOpenSource
		}

		#expect(try years(on: "2026-09-05") == 14)
		#expect(try years(on: "2026-09-06") == 15)
	}

	/**
	The wall of love only has the apps that are listed and maintained, so it would show all quotes for the link of another app.
	*/
	@Test
	func `an unlisted app does not link to the wall of love`() async throws {
		let app = try await App(title: "Hidden", publicationDate: "2020-01-01", platforms: [.iOS], frontmatter: "isUnlisted: true\nappStoreID: 123", slug: "hidden")
		let review = AppStoreReview(
			title: "Great",
			text: "A review that is long enough to be shown on the page of the app.",
			author: "A reviewer",
			rating: .five,
			date: try Date("2026-01-01T00:00:00Z", strategy: .iso8601)
		)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appStoreReviews: [123: [review]]),
			buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601),
			project: .empty
		)

		let html = try AppPage(app: app, content: content).renderedHTML()
		#expect(html.contains("A review that is long enough"))
		#expect(!html.contains("/apps/reviews?app=hidden"))
	}

	/**
	A paid app was often free before, and a review that calls it free would confuse visitors about the price. A word with “free” in it, like “ad-free”, is not the price.
	*/
	@Test
	func `a paid app leaves out reviews that call it free`() async throws {
		func review(_ text: String) throws -> AppStoreReview {
			AppStoreReview(
				title: "Great",
				text: text,
				author: "A reviewer",
				rating: .five,
				date: try Date("2026-01-01T00:00:00Z", strategy: .iso8601)
			)
		}

		let free = try review("This is free, it is effective, and I use it every single day.")
		let adFree = try review("An ad-free app that gives me freedom, and I use it every single day.")
		#expect(free.callsAppFree)
		#expect(!adFree.callsAppFree)

		func reviews(isPaid: Bool) async throws -> [AppStoreReview] {
			let app = try await App(publicationDate: "2020-01-01", platforms: [.iOS], frontmatter: "appStoreID: 123\nisPaid: \(isPaid)", slug: "test")
			let content = SiteContent(
				apps: [app],
				posts: [],
				pages: [],
				appData: SiteContent.AppData(appStoreReviews: [123: [free, adFree]]),
				buildDate: try Date("2026-10-07T12:00:00Z", strategy: .iso8601),
				project: .empty
			)
			return content.listing(of: app).reviews
		}

		#expect(try await reviews(isPaid: true) == [adFree])
		#expect(try await reviews(isPaid: false) == [free, adFree])
	}

	/**
	The app picker of the feedback page would announce an unlisted app, like one before its launch, but its form still works with `?product=`, like for App Review.
	*/
	@Test
	func `the feedback picker leaves out unlisted apps, but their form works`() async throws {
		let hidden = try await App(title: "Hidden", publicationDate: "2020-01-01", platforms: [.iOS], frontmatter: "isUnlisted: true", slug: "hidden")
		let shown = try await App(title: "Shown", publicationDate: "2020-01-01", platforms: [.iOS], slug: "shown")

		let html = try FeedbackPage(apps: [hidden, shown], faq: nil, project: .empty).renderedHTML()
		#expect(html.contains("product=Shown"))
		#expect(!html.contains("product=Hidden"))
		#expect(html.contains(#""title":"Hidden""#))
	}

	/**
	AVFoundation reads the size of a video, so the page reserves its space before it loads.
	*/
	@Test
	func `app videos have their pixel size`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		let video = try #require(app.media.first { $0.isVideo })
		#expect(video.size == PixelSize(width: 1280, height: 720))
	}

	/**
	The first frame of a video shows while it loads, and while it does not play, like with reduced motion.
	*/
	@Test
	func `app videos have their first frame as the poster`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		let html = AppMedia(app: app).render()
		#expect(html.contains(#"<video src="/googly-eyes/video1.mp4""#))
		#expect(html.contains(#"poster="/googly-eyes/video1-poster.jpg""#))

		let content = try await SiteContent.website
		let page = AppPage(app: app, content: content)
		let video = try #require(page.metadata.video)
		#expect(video.path == #path("/googly-eyes/video1.mp4"))
		#expect(video.poster == #path("/googly-eyes/video1-poster.jpg"))
		#expect(video.size == PixelSize(width: 1280, height: 720))
		#expect(app.screenshots.map(\.path) == app.media.filter(\.isImage).map(\.path))
		let pageHTML = try page.renderedHTML()
		#expect(pageHTML.contains(#"property="og:video" content="https://sindresorhus.com/googly-eyes/video1.mp4""#))
		#expect(pageHTML.contains(#"property="og:video:width" content="1280""#))
		#expect(pageHTML.contains(#"property="og:video:height" content="720""#))
	}

	/**
	An app page that has no place to get the app, like an `appStoreID`, a `gumroad`, a `repositoryURL`, a `gitHubDownload`, or a `setappID`, has no download button, so a visitor cannot get the app. An unlisted app has none on purpose, like an app that is not released yet, and an archived app is no longer available, so both are left out.
	*/
	@Test
	func `every listed app has a way to get it`() async throws {
		let appsWithoutDownload = try await SiteContent.website.apps.filter { $0.isActive && !$0.isDownloadable }

		#expect(appsWithoutDownload.isEmpty, "These apps have no download button: \(appsWithoutDownload.map(\.slug).joined(separator: ", ")).")
	}

	/**
	The videos have their own label, so the screenshots are numbered without them.
	*/
	@Test
	func `the first screenshot after a video is screenshot 1`() async throws {
		let app = try #require(try await SiteContent.website.apps.first { $0.slug == "googly-eyes" })
		#expect(app.media.map(\.isVideo) == [true, false])
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
	An app that is not on the App Store offers its own purchase and its trial before the subscription of Setapp. On the App Store, the stores come first.
	*/
	@Test
	func `the own download options come before Setapp only when the app is not on the App Store`() async throws {
		func app(store: String) async throws -> App {
			try await App(frontmatter: "isPaid: true\nsetappID: 1\n\(store)", body: "The app.\n\n## Trial {#trial}\n\nTry it.\n")
		}

		let gumroadApp = try await app(store: "gumroad: {id: 'test', price: 20}")
		let appStoreApp = try await app(store: "appStoreID: 123")
		let setapp = DownloadOption.setapp(try #require(gumroadApp.frontmatter.setappID))
		let appStore = DownloadOption.appStore(try #require(appStoreApp.appStoreID), placement: .downloadButton)

		#expect(gumroadApp.downloadOptions == [.link(LabeledLink("Buy", url: try #require(gumroadApp.gumroadURL))), .trial(appPath: gumroadApp.path), setapp])
		#expect(appStoreApp.downloadOptions == [appStore, setapp, .trial(appPath: appStoreApp.path)])
		#expect(appStoreApp.placesToGet == [appStore, setapp])
	}

	/**
	A broken link is reported at its line in the content, or at the content file of the page when it is not in the Markdown, like a link in raw HTML, or else at the page.
	*/
	@Test
	func `a broken link is reported where it is written`() async throws {
		let app = try await App(body: "[Missing](/missing)\n\n<a href=\"/datto\">Dato</a>")
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(content.sourceLocations(ofLink: "/missing", onPage: app.path) == [.file(app.file.url, line: 8)])
		#expect(content.sourceLocations(ofLink: "/datto", onPage: app.path) == [.file(app.file.url)])
		#expect(content.sourceLocations(ofLink: "/missing", onPage: .apps) == [.page(.apps)])
	}

	/**
	A link in a shared answer is written once, in the shared file, so it is reported there, at its line, not at each app that picks the question.
	*/
	@Test(.temporaryDirectory)
	func `a broken link in a shared answer is reported in the shared file`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [App.SharedQuestions.path: "### Shared question {#shared}\n\nRead [the FAQ](/datto).\n"]))
		let app = try await App(frontmatter: "sharedQuestions: ['shared']", body: "## Frequently Asked Questions {#faq}\n", project: project)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: project
		)

		#expect(content.sourceLocations(ofLink: "/datto", onPage: app.path) == [.file(project.root.appending(path: App.SharedQuestions.path), line: 3)])
	}

	/**
	The page has no App Store download for an archived app, so the structured data does not offer it there.
	*/
	@Test
	func `the structured data of an archived app does not offer it on the App Store`() async throws {
		let app = try await App(publicationDate: "2020-01-01", frontmatter: "isArchived: true\nappStoreID: 123", body: "The app is no longer available.\n")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "version": "2.0.0", "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#)
		let schema = Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: info))

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
		let app = try await App(publicationDate: "2020-01-01")
		#expect(app.links.map(\.title) == ["Support"])
		#expect(AppHero(listing: AppListing(app: app), buildDate: .now).render().contains("Show QR Code"))
	}

	/**
	An archived app is no longer available, so it is not passed on, and it has no terms or discounts.
	*/
	@Test
	func `an archived app has no QR code, sharing, terms, or discounts`() async throws {
		let app = try await App(publicationDate: "2020-01-01", frontmatter: "isArchived: true\nisPaid: true")
		let html = AppHero(listing: AppListing(app: app), buildDate: .now).render()
		#expect(html.contains("Show Random App"))
		#expect(!html.contains("Show QR Code"))
		#expect(!html.contains("Share…"))
		#expect(!html.contains(AppHero.qrCodeID.rawValue))
		#expect(!html.contains(AppHero.sharePopoverID.rawValue))
		#expect(app.pageOverflowLinks.isEmpty)
		#expect(!app.links.contains { $0.title == "Support" })
	}

	/**
	An archived app gets no support, and the feedback page does not list it.
	*/
	@Test
	func `an archived app does not invite feedback in its FAQ`() async throws {
		let app = try await App(title: "Old App", publicationDate: "2020-01-01", frontmatter: "isArchived: true", body: "## Frequently Asked Questions {#faq}\n\n### A question\n\nAn answer.")
		#expect(app.markdown.headings.map(\.id.rawValue) == ["faq", "a-question", "can-you-localize-the-app-into-my-language"])
	}

	/**
	Like the apps page and the about page, which count the active apps, without the archived ones.
	*/
	@Test
	func `the 1999 page counts the active apps`() async throws {
		var apps = [App]()

		for slug in ["a", "b", "c"] {
			apps.append(try await App(title: slug, publicationDate: "2020-01-01", frontmatter: slug == "c" ? "isArchived: true" : "", body: "", slug: slug))
		}
		let content = SiteContent(
			apps: apps,
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(GeoCitiesPage(content: content).body.render().contains("2 apps and counting"))
	}

	/**
	Without the dates of the last commits, the sitemap and the update dates of posts use other dates, so a git failure in a repository is a warning, not silent.
	*/
	@Test(.temporaryDirectory)
	func `a git repository whose commit dates cannot be read is a warning`() async throws {
		let root = try URL.temporaryDirectory()

		for directory in ["content/apps", "content/blog", "content/guides", "content/pages", ".git"] {
			try root.appending(path: directory).createDirectory()
		}

		try Data(SiteSettings.testSOML.utf8).write(to: root.appending(path: SiteSettings.path))

		let content = try await SiteContent.load(from: Project.site(root: root), externalData: .none)
		#expect(content.warnings.contains { $0.message.contains("dates of the last commits") })
	}

	@Test(.temporaryDirectory)
	func `two files of one page and two apps with one App Store ID are errors`() async throws {
		let app = App.testMarkdown(frontmatter: "appStoreID: 123", body: "")
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/about.md": app.replacing("appStoreID: 123\n", with: ""),
					"content/apps/first.md": app,
					"content/apps/second.md": app,
					"content/blog/.keep": "",
					"content/guides/.keep": "",
					"content/pages/about.md": "---\ntitle: 'About'\n---\n\n## Me {#some-things-about-me}\n\n## Apps {#how-i-make-an-app}\n\n## Support {#support-my-work}",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.count == 2)
		#expect(errors.errors.contains { $0.reason.contains("the same page as `content/") && $0.reason.contains("which is at /about") })
		#expect(errors.errors.contains { $0.reason == "It has the same `appStoreID` as Test, so they would share its price, rating, and reviews." })
	}

	/**
	The feedback page opens the first app with a name, so a feedback name that is the title or a feedback name of another app, in any case, is an error at its line.
	*/
	@Test(.temporaryDirectory)
	func `a feedback name of another app is an error`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/first.md": App.testMarkdown(title: "Color Picker", frontmatter: "feedbackNames: ['Picker']", body: ""),
					"content/apps/second.md": App.testMarkdown(title: "System Color Picker", frontmatter: "feedbackNames: ['Other', 'color picker']", body: ""),
					"content/apps/third.md": App.testMarkdown(title: "Third", frontmatter: "feedbackNames: ['SYSTEM color picker']", body: ""),
					"content/apps/fourth.md": App.testMarkdown(title: "Fourth", frontmatter: "feedbackNames: ['OTHER']", body: ""),
					"content/blog/.keep": "",
					"content/guides/.keep": "",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		let reasons = errors.errors.map(\.reason)
		#expect(reasons.count == 3)
		#expect(reasons.contains("`color picker` is also a name of Color Picker, so the feedback page could open the wrong app."))
		#expect(reasons.contains("`SYSTEM color picker` is also a name of System Color Picker, so the feedback page could open the wrong app."))
		// The apps load in any order, so either app of the shared feedback name has the error.
		#expect(reasons.contains { $0.hasPrefix("`OTHER` is also a name of System Color Picker") || $0.hasPrefix("`Other` is also a name of Fourth") })
	}

	/**
	The featured apps of `content/site.soml` are active apps with pages, at most four, and each mistake is at the line of its slug.
	*/
	@Test(.temporaryDirectory)
	func `featured apps that are not active apps are errors at their lines`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/active.md": App.testMarkdown(title: "Active"),
					"content/apps/old.md": App.testMarkdown(title: "Old", frontmatter: "isArchived: true"),
					"content/blog/.keep": "",
					"content/guides/.keep": "",
					"content/pages/.keep": "",
					SiteSettings.path: "featuredApps: [\n\t'active'\n\t'old'\n\t'missing'\n]\nappUserCount: 1\nsupportEmailCount: 1\n",
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"3: Old is archived, so the apps page cannot feature it.",
			"4: There is no app with the slug `missing`, like `gifski` for `content/apps/gifski/index.md`.",
		])
	}

	/**
	The site reads `content/shared-questions.md` once, so a mistake in it is reported once, at its line, not for each app that picks a question.
	*/
	@Test(.temporaryDirectory)
	func `a mistake in the shared questions is reported once, at its line`() async throws {
		let app = App.testMarkdown(frontmatter: "sharedQuestions: ['shared']", body: "## Frequently Asked Questions {#faq}\n\n### Question\n\nAnswer.")
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/apps/first.md": app,
					"content/apps/second.md": app,
					"content/blog/.keep": "",
					"content/guides/.keep": "",
					"content/pages/.keep": "",
					SiteSettings.path: SiteSettings.testSOML,
					App.SharedQuestions.path: "### Shared question {#shared}\n\nAnswer.\n\n## Oops\n\nText.\n",
				]
			)
		)

		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}

		#expect(errors.errors.map { "\($0.file?.lastPathComponent ?? ""):\($0.line ?? 0): \($0.reason)" } == ["shared-questions.md:5: The questions are level 3 headings: `### Oops`."])
	}

	@Test(.temporaryDirectory)
	func `the site settings report all their mistakes at their lines`() throws {
		let url = try URL.temporaryDirectory(files: [SiteSettings.path: "featuredApps: ['a', 'b', 'a', 'c', 'd']\nappUserCount: 0\nsupportEmailCount: -10_000\n"]).appending(path: SiteSettings.path)

		let errors = try #require(throws: ContentErrors.self) {
			try SOMLFile<SiteSettings>(url: url)
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"1: `featuredApps` has `a` twice.",
			"1: The apps page features at most 4 apps. Remove `d` or another app.",
			"2: The pages show the count, so it must be more than 0, not 0.",
			"3: The pages show the count, so it must be more than 0, not -10000.",
		])

		let missing = try #require(throws: ContentErrors.self) {
			try SOMLFile<SiteSettings>(url: url.deletingLastPathComponent().appending(path: "missing.soml"))
		}

		#expect(missing.errors.first?.reason.hasPrefix("Could not read the file") == true)
	}

	/**
	The about page is split before three headings (``AboutPage/splitHeadingIDs``), so a renamed ID is an error when the content loads, not parts that silently move to the end.
	*/
	@Test
	func `the about page needs the headings that it is split before`() async throws {
		let error = try await #require(throws: ContentError.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'About'\n---\n\n## Me {#me}\n\n## Apps {#how-i-make-an-app}\n\n## Support {#support-my-work}", slug: "about")
		}

		#expect(error.line == 5)
		#expect(error.reason.contains("`some-things-about-me`, `how-i-make-an-app`, and `support-my-work`"))

		let page = try await MarkdownPage(markdown: "---\ntitle: 'About'\n---\n\n## Me {#some-things-about-me}\n\n## Apps {#how-i-make-an-app}\n\n## Support {#support-my-work}", slug: "about")
		#expect(page.kind == .about)
	}

	/**
	The check reads the rendered blocks, so a `@Sponsors` line in a code block, which shows no sponsors, does not count.
	*/
	@Test
	func `sponsors in a code block are not a place in the Markdown`() async throws {
		let error = try await #require(throws: ContentError.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'Supporters'\nsponsorTiers: [{title: 'Sponsor', price: '$100/month', sponsors: [{name: 'Someone'}]}]\n---\n\n```\n@Sponsors\n```", slug: "supporters")
		}

		#expect(error.reason.contains("@Sponsors"))
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
		let errors = try await #require(throws: ContentErrors.self) {
			try await MarkdownPage(markdown: "---\ntitle: 'Supporters'\nsponsorTiers: [{title: 'Sponsor', price: '$100/month', sponsors: [{name: 'Logo', url: 'https://example.com', logo: {path: '/logo.png', width: 100}}, {name: 'Someone'}]}]\n---\n\n@Sponsors\n", slug: "supporters")
		}

		#expect(errors.errors.map(\.reason) == ["The sponsor “Someone” is in a tier with logos, which is a list of links, so it needs `url`."])
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

	/**
	The content errors of loading an app with the frontmatter that every app needs (``App/testMarkdown(title:publicationDate:platforms:frontmatter:body:)``).
	*/
	private func loadingErrors(title: String = "Test", frontmatter: String = "", body: String = "Text.", project: Project = .empty) async -> [ContentError] {
		await loadingErrors(App.testMarkdown(title: title, frontmatter: frontmatter, body: body), project: project)
	}

	@Test
	func `an app reports all the mistakes of its text at once`() async {
		let errors = await loadingErrors(frontmatter: "script: '/missing.js'", body: "# Title\n\n## Frequently Asked Questions\n\n### Question\n\nAnswer.")

		#expect(errors.count == 3)
		#expect(errors.contains { $0.reason.contains("level 1 heading") })
		#expect(errors.contains { $0.reason.contains("needs the ID `faq`") })
		#expect(errors.contains { $0.reason.contains("does not exist in `public`") })
	}

	@Test
	func `a free app downloaded from its own site gets an offer with the price 0`() async throws {
		let app = try await App(frontmatter: "repositoryURL: 'https://github.com/sindresorhus/test'")
		let offer = try #require(Schema.SoftwareApplication(listing: AppListing(app: app)).offers)

		#expect(offer.price == 0)
		#expect(offer.url.absoluteString == "https://github.com/sindresorhus/test")
	}

	@Test
	func `a paid app without App Store info gets no offer`() async throws {
		let app = try await App(frontmatter: "isPaid: true\nrepositoryURL: 'https://github.com/sindresorhus/test'")

		#expect(Schema.SoftwareApplication(listing: AppListing(app: app)).offers == nil)
	}

	@Test
	func `the feedback scripts read every key of their data`() async throws {
		let app = try await App(frontmatter: "repositoryURL: 'https://github.com/sindresorhus/test'\nfeedbackNote: 'A note.'", body: "Text.\n\n## Frequently Asked Questions {#faq}\n\n### Why?\n\nBecause.")

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
		let app = try await App(frontmatter: "isPaid: true\nsetappID: 1\ngumroad: {id: 'test', price: 4.99}")
		let offer = try #require(Schema.SoftwareApplication(listing: AppListing(app: app)).offers)

		#expect(AppListing(app: app).priceText == "$4.99, one-time purchase, plus tax where applicable")
		#expect(offer.price == Decimal(string: "4.99"))
		#expect(offer.priceCurrency == "USD")
		// The product page, not the checkout of the Buy button, and the plain pages of the stores, not the referral link of Setapp.
		#expect(offer.url.absoluteString == "https://sindresorhus.gumroad.com/l/test")
		#expect(app.gumroadURL?.absoluteString == "https://sindresorhus.gumroad.com/l/test?wanted=true")
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app)).sameAs == [#URL("https://sindresorhus.gumroad.com/l/test"), #URL("https://setapp.com/apps/1")])
	}

	@Test(arguments: [("4.999", false), ("0", false), ("20", true)])
	func `a price in frontmatter has at most two decimals`(price: String, isValid: Bool) async {
		#expect(await loadingErrors(frontmatter: "isPaid: true\ngumroad: {id: 'test', price: \(price)}").isEmpty == isValid)
	}

	@Test
	func `the reviews show the rounded App Store rating, and the hero does not`() async throws {
		let app = try await App(platforms: [.iOS], frontmatter: "appStoreID: 123")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#)
		let review = AppStoreReview(
			title: "Great",
			text: "A review.",
			author: "A reviewer",
			rating: .five,
			date: .now
		)

		#expect(AppReviews(reviews: [review], rating: info.rating.map(AppRating.store)).render().contains(">Rated 4.6 out of 5 from 1,563 ratings on the App Store</p>"))
		#expect(!AppHero(listing: AppListing(app: app, appStoreInfo: info), buildDate: .now).render().contains("Rated"))
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: info)).aggregateRating?.ratingValue == 4.6)
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
		let app = try await App(platforms: [.iOS], frontmatter: "appStoreID: 123")
		let rated = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5, "userRatingCount": 10}"#)
		let unrated = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD"}"#)
		let reviews = [
			AppStoreReview(
				title: "Great",
				text: "A review.",
				author: "A reviewer",
				rating: .five,
				date: .now
			),
			AppStoreReview(
				title: "Nice",
				text: "Another review.",
				author: "Another reviewer",
				rating: .five,
				date: .now
			),
		]

		#expect(Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: rated, appStoreReviews: reviews)).review?.count == 2)
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: unrated, appStoreReviews: reviews)).review == nil)
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app, appStoreReviews: reviews)).review == nil)
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: rated, appStoreReviews: [])).review == nil)
	}

	/**
	The rating is in the structured data, so the page shows it too, also when there are no reviews to show.
	*/
	@Test
	func `an app page shows the rating without reviews`() async throws {
		let app = try await App(platforms: [.iOS], frontmatter: "appStoreID: 123", slug: "test")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "averageUserRating": 4.5623, "userRatingCount": 1563}"#)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appStoreInfo: [123: info]),
			buildDate: .now,
			project: .empty
		)

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
	func `the price shows cents only when it has them`() async throws {
		let app = try await App(frontmatter: "isPaid: true")

		func priceText(_ price: String) throws -> String? {
			AppListing(app: app, appStoreInfo: try AppStoreInfo(json: #"{"trackId": 123, "price": \#(price), "currency": "USD"}"#)).priceText
		}

		#expect(try priceText("4.99") == "$4.99, one-time purchase")
		#expect(try priceText("4.00") == "$4, one-time purchase")
		#expect(try priceText("0.00") == "Free to download, with an in-app purchase")
	}

	@Test
	func `price wording follows the source of the resolved price`() async throws {
		let app = try await App(frontmatter: "gumroad: {id: 'test', price: 6}")
		let storeInfo = try AppStoreInfo(json: #"{"trackId": 123, "price": 4.99, "currency": "USD"}"#)
		let incompleteStoreInfo = try AppStoreInfo(json: #"{"trackId": 123, "price": 4.99}"#)
		let store = AppListing(app: app, appStoreInfo: storeInfo)
		let gumroad = AppListing(app: app, appStoreInfo: incompleteStoreInfo)
		#expect(store.price == storeInfo.price)
		#expect(store.priceText == "$4.99, one-time purchase")
		#expect(gumroad.price == app.frontmatter.gumroad?.price)
		#expect(gumroad.priceText == "$6, one-time purchase, plus tax where applicable")

		let free = AppListing(app: try await App())
		let unknown = AppListing(app: try await App(frontmatter: "isPaid: true"))
		#expect(free.price == .free)
		#expect(free.priceText == "Free")
		#expect(unknown.price == nil)
		#expect(unknown.priceText == nil)
	}

	@Test
	func `the privacy note replaces the statement that no data is collected`() async throws {
		let app = try await App(frontmatter: "hasSentry: true\nprivacyNote: 'Your questions are sent to OpenAI.'")
		let page = PrivacyPolicyPage(app: app)
		let html = page.body.render()

		#expect(html.contains("<p>Your questions are sent to OpenAI.</p>"))
		#expect(!html.contains("No personal information"))
		#expect(html.contains("without your name or email"))
		#expect(page.metadata.description == "The privacy policy of the Test app. Your questions are sent to OpenAI. Crash reports in Sentry have no name, email, or IP address.")
	}

	@Test
	func `the examples of a list of apps say “like” only when the list has more apps`() async throws {
		var apps = [App]()
		for title in ["One", "Two", "Three", "Four", "Five"] {
			apps.append(try await App(title: title, slug: title.lowercased()))
		}

		#expect(Array(apps.prefix(4)).examples(featuring: []) == ": One, Two, Three, and Four")
		#expect(apps.examples(featuring: []) == ", like One, Two, Three, and Four")
	}

	@Test
	func `the availability leaves out the platforms only when the requirement already names the one platform`() async throws {
		func availabilityFacts(_ platforms: [Platform], frontmatter: String = "") async throws -> [String] {
			let app = try await App(platforms: platforms, frontmatter: frontmatter)
			return AppListing(app: app).availabilityFacts
		}

		#expect(try await availabilityFacts([.macOS], frontmatter: "minimumOSVersion: '26.1'") == ["Requires macOS 26.1 or later"])
		#expect(try await availabilityFacts([.iOS, .macOS, .visionOS], frontmatter: "minimumOSVersion: '27'") == ["Available on macOS, iOS, and visionOS", "Requires version 27 or later"])
		#expect(try await availabilityFacts([.macOS]) == ["Available on macOS"])
		#expect(try await availabilityFacts([.iOS], frontmatter: "minimumOSVersion: '27'") == ["Requires iOS 27 or later"])
	}

	@Test
	func `the requirement comes from the App Store, then the appcast, then the frontmatter`() async throws {
		let app = try await App(frontmatter: "minimumOSVersion: '26.1'")
		let appcast = try Appcast(xml: Data("<rss><channel><item><sparkle:version>26</sparkle:version><sparkle:minimumSystemVersion>26.4</sparkle:minimumSystemVersion></item><item><sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion></item></channel></rss>".utf8))
		let info = try AppStoreInfo(json: #"{"trackId": 123, "minimumOsVersion": "27.0"}"#)
		let olderInfo = try AppStoreInfo(json: #"{"trackId": 123, "minimumOsVersion": "18.0"}"#)

		#expect(appcast.minimumSystemVersion == OSVersion("26.4"))
		#expect(AppListing(app: app, appStoreInfo: info, appcast: appcast).minimumOSVersion == OSVersion("27"))
		#expect(AppListing(app: app, appStoreInfo: olderInfo, appcast: appcast).minimumOSVersion == OSVersion("26.4"))
		#expect(AppListing(app: app, appStoreInfo: olderInfo).minimumOSVersion == OSVersion("26.1"))
		#expect(throws: ResponseCache.ReadError.self) {
			try Appcast(xml: Data("<rss><channel><item><sparkle:version>2</sparkle:version></item><item><sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion></item></channel></rss>".utf8))
		}
	}

	/**
	The first item of the appcast of Supercharge, as the workflow writes it.
	*/
	@Test
	func `an app that is not on the App Store gets its version, its date, and its size from the appcast`() async throws {
		let appcast = try Appcast(xml: Data("""
			<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0"><channel><title>Supercharge</title>
			<item>
				<title>1.30.1</title>
				<pubDate>Mon, 28 Sep 2026 04:33:04 +0000</pubDate>
				<sparkle:version>55</sparkle:version>
				<sparkle:shortVersionString>1.30.1</sparkle:shortVersionString>
				<sparkle:minimumSystemVersion>26.4</sparkle:minimumSystemVersion>
				<enclosure url="https://github.com/sindresorhus/supercharge-meta/releases/download/v1.30.1/Supercharge.zip" length="16227548" type="application/octet-stream" sparkle:edSignature="x"/>
			</item>
			<item><pubDate>Mon, 01 Sep 2026 04:33:04 +0000</pubDate><sparkle:shortVersionString>1.30.0</sparkle:shortVersionString><sparkle:minimumSystemVersion>26.4</sparkle:minimumSystemVersion></item>
			</channel></rss>
			""".utf8))

		#expect(appcast.version == "1.30.1")
		#expect(appcast.releaseDate == Date(timeIntervalSince1970: 1_790_569_984))
		#expect(appcast.fileSize == 16_227_548)

		let app = try await App()
		let schema = Schema.SoftwareApplication(listing: AppListing(app: app, appcast: appcast))
		#expect(schema.softwareVersion == "1.30.1")
		let modifiedDay = try #require(SOML.Date("2026-09-28"))
		#expect(schema.dateModified == modifiedDay)
		#expect(schema.fileSize == "16.2 MB")

		// The other values are extra facts, so an item without them still gives the requirement.
		let minimal = try Appcast(xml: Data("<item><sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion></item>".utf8))
		#expect(minimal.version == nil)
		#expect(minimal.releaseDate == nil)
		#expect(minimal.fileSize == nil)
	}

	/**
	The versions come from the App Store, the appcasts, and the frontmatter, so they are compared by their numbers, not as text or as decimal numbers, where 26.10 would be before 26.9.
	*/
	@Test
	func `an OS version is compared by its numbers and written like Apple writes it`() throws {
		#expect(OSVersion("26.1.2") == OSVersion(major: 26, minor: 1))
		#expect(OSVersion("26.0")?.description == "26")
		#expect(OSVersion("26.1")?.description == "26.1")
		#expect(try #require(OSVersion("26.10")) > #require(OSVersion("26.9")))
		#expect(try #require(OSVersion("27")) > #require(OSVersion("26.9")))

		for text in ["", "26.", ".1", "-1", "+26", "26.+1", " 26", "26.x", "26.1.2.3"] {
			#expect(OSVersion(text) == nil, "\(text)")
		}
	}

	@Test
	func `only an app that is not on the App Store has an appcast, in the pages of its releases repo or of its download`() async throws {
		func appcastURL(_ frontmatter: String) async throws -> URL? {
			try await App(frontmatter: frontmatter).appcastURL
		}

		#expect(try await appcastURL("releasesRepository: 'sindresorhus/test-meta'") == #URL("https://sindresorhus.com/test-meta/appcast.xml"))
		#expect(try await appcastURL("gitHubDownload: {repository: 'sindresorhus/download-meta', file: 'Test.zip'}") == #URL("https://sindresorhus.com/download-meta/appcast.xml"))
		#expect(try await appcastURL("appStoreID: 123\nreleasesRepository: 'sindresorhus/test-meta'") == nil)
		#expect(try await appcastURL("isArchived: true\nreleasesRepository: 'sindresorhus/test-meta'") == nil)
		#expect(try await appcastURL("redirectURL: 'https://example.com'\nreleasesRepository: 'sindresorhus/test-meta'") == nil)
		#expect(try await appcastURL("") == nil)
	}

	@Test
	func `a paid app on the Mac and iOS is one purchase for all platforms`() async throws {
		func priceText(platforms: [Platform]) async throws -> String? {
			let app = try await App(platforms: platforms, frontmatter: "isPaid: true\nappStoreID: 123")
			return AppListing(app: app, appStoreInfo: try AppStoreInfo(json: #"{"trackId": 123, "price": 4.99, "currency": "USD"}"#)).priceText
		}

		#expect(try await priceText(platforms: [.macOS, .iOS]) == "$4.99, one-time purchase for all platforms")
		#expect(try await priceText(platforms: [.macOS]) == "$4.99, one-time purchase")
		#expect(try await priceText(platforms: [.iOS, .watchOS]) == "$4.99, one-time purchase")
	}

	@Test
	func `an app that is two years old says since when it is available`() async throws {
		let app = try await App(publicationDate: "2020-06-01")

		#expect(app.availableSinceText(at: try Date("2026-01-01T00:00:00Z", strategy: .iso8601)) == "Since 2020")
		#expect(app.availableSinceText(at: try Date("2021-06-01T00:00:00Z", strategy: .iso8601)) == nil)
	}

	@Test
	func `the trial of an app page shows the requirement, how to install it, and Setapp`() async throws {
		let app = try await App(frontmatter: "isPaid: true\nsetappID: 1", body: "## Trial {#trial}\n\n@Trial(url: \"https://example.com/App-trial.zip\", macOS: \"26\") {\n  Try it.\n}\n")

		#expect(app.markdown.html.contains("Requires macOS 26 or later</span>"))
		#expect(app.markdown.html.contains("Download it to the Downloads folder, double-click to unzip, and then move it to the <code translate=\"no\">/Applications</code> folder.</p>"))
		#expect(app.markdown.html.contains(#"<p>You can also <a href="https://go.setapp.com/stp181?refAppID=1&amp;utm_medium=vendor_program&amp;utm_content=button">try it on Setapp</a> for 7 days for free.</p>"#))
	}

	/**
	The Markdown arguments of the directives get the checks of the file, like the names of keys and the links, at the line of the directive.
	*/
	@Test
	func `the Markdown arguments of directives are checked like the file`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(body: "@Feature(title: \"Press ++Cmd+K++\") {\nText.\n}\n\n@Details(summary: \"See [the FAQ](/apps/faq)\") {\nText.\n}\n\n@Details(summary: \"Read [this](missing.md)\") {\nText.\n}\n")
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == [
			"8: `@Feature`: Write the key `Cmd` of the keyboard shortcut `Cmd+K` as `Command`, its name on the keyboard of a Mac.",
			"12: `@Details`: The `summary` cannot have links, as a click on it opens the section. Put the link in the section.",
			"16: `@Details`: The link `missing.md` goes to a content file that does not exist.",
		])
	}

	/**
	The text of a trial does not name the app, so it is only for the app pages.
	*/
	@Test
	func `a trial is an error outside an app page`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Post'\ndescription: 'A post.'\npublicationDate: 2026-01-01\n---\n\n@Trial(url: \"https://example.com/App-trial.zip\", macOS: \"26\")\n")
		}

		#expect(errors.errors.map { "\($0.line ?? 0): \($0.reason)" } == ["7: `@Trial`: It is only for app pages, below the “Trial” heading (`{#trial}`), as it does not name the app."])
	}

	@Test
	func `a trial without content gets the standard text, which names the App Store for an app that is there`() async throws {
		let body = "## Trial {#trial}\n\n@Trial(url: \"https://example.com/App-trial.zip\", macOS: \"26\")\n"
		let appStoreApp = try await App(platforms: [.macOS, .iOS], frontmatter: "isPaid: true\nappStoreID: 123", body: body)
		let gumroadApp = try await App(frontmatter: "isPaid: true\ngumroad: {id: 'test', price: 6}", body: body)

		#expect(appStoreApp.markdown.html.contains("<p>The trial of the macOS app is fully functional. The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it on the App Store.</p>"))
		#expect(gumroadApp.markdown.html.contains("<p>The trial is fully functional. The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it.</p>"))
	}

	@Test
	func `a platform badge must be for a platform of the app`() async throws {
		func load(platforms: [Platform]) async throws -> App {
			try await App(platforms: platforms, body: "Works ^[iOS only](platform: \"iOS\").")
		}

		let error = await #expect(throws: (any Error).self) {
			try await load(platforms: [.macOS])
		}

		#expect(String(describing: error).contains("The platform badge is for iOS, but the app is not on it."))
		#expect(try await load(platforms: [.macOS, .iOS]).markdown.html.contains(#"data-platform="iOS">iOS only</span>"#))

		// The Markdown arguments of the directives get the check too.
		let featureError = await #expect(throws: (any Error).self) {
			try await App(platforms: [.macOS], body: "@Feature(title: \"Widgets ^[iOS only](platform: 'iOS')\") {\nText.\n}\n")
		}

		#expect(String(describing: featureError).contains("The platform badge is for iOS, but the app is not on it."))
	}

	@Test
	func `the facts at the end of an app page have the platforms, the requirement, the category, the release, the privacy, and the developer`() async throws {
		let app = try await App(publicationDate: "2019-07-13", platforms: [.macOS, .iOS], frontmatter: "appStoreID: 123\nminimumOSVersion: '26'", slug: "test")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "primaryGenreName": "Productivity"}"#)
		let html = AppFacts(listing: AppListing(app: app, appStoreInfo: info)).render()

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
	func `a press quote shows its year and the language of a translated article`() async throws {
		let app = try await App(publicationDate: "2020-01-01", frontmatter: "pressQuotes: [{quote: 'Good', source: 'ifun.de', translatedFrom: 'German', year: 2021}, {quote: 'Nice', source: 'Mom'}]")
		let html = PressQuotes(quotes: app.pressQuotes).render()

		#expect(html.contains("ifun.de"))
		#expect(html.contains("<span>2021</span><span>Translated from German</span>"))
		#expect(html.contains("Mom</span></figcaption>"))
	}

	@Test
	func `the highlight of a press quote must be in the quote`() async {
		await #expect(throws: ContentErrors.self) {
			try await App(frontmatter: "pressQuotes: [{quote: 'A great app', source: 'Example', highlight: 'A good app'}]", body: "")
		}
	}

	@Test
	func `a press quote marks its highlight`() async throws {
		let app = try await App(frontmatter: "pressQuotes: [{quote: 'It is simple. It has stuck around.', source: 'MacStories', highlight: 'It has stuck around'}]")

		#expect(PressQuotes(quotes: app.pressQuotes).render().contains(#"<p>It is simple. <mark class="quote-figure-highlight">It has stuck around</mark>.</p>"#))
	}

	@Test
	func `a Gumroad product gives the rating and the price of an app that is sold there`() throws {
		let product = try GumroadProduct(json: #"{"price_cents": 2000, "ratings": {"count": 283, "average": 4.96}}"#)

		#expect(try product.price == Price(amount: 20))
		#expect(product.rating?.text == "Rated 5.0 out of 5 from 283 ratings on Gumroad")
		#expect(try GumroadProduct(json: #"{"price_cents": 600, "ratings": {"count": 0, "average": 0}}"#).rating == nil)
	}

	@Test
	func `an app card is a heading with a link, at the level of its place on the page`() async throws {
		let app = try await App()

		#expect(AppCard(app: app, isNew: false).render().contains(#"<h3 translate="no""#))
		#expect(AppCard(app: app, isNew: false, headingLevel: .h2).render().contains(#"<h2 translate="no""#))
		#expect(AppCard(app: app, isNew: false).render().contains(#"<a href="/test""#))
	}

	@Test
	func `the privacy summary links to the policy`() async throws {
		func privacySummary(_ frontmatter: String) async throws -> String {
			try await App(frontmatter: frontmatter).privacySummary
		}

		#expect(try await privacySummary("") == "No data collected")
		#expect(try await privacySummary("hasSentry: true") == "No personal data collected")
		#expect(try await privacySummary("privacyNote: 'Your questions are sent to OpenAI.'") == "Privacy details")
	}

	@Test
	func `the structured data has the category, the requirement, the release notes, the size, and the other pages`() async throws {
		let app = try await App(platforms: [.iOS], frontmatter: "appStoreID: 123\nrepositoryURL: 'https://github.com/sindresorhus/test'\nminimumOSVersion: '26'")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "currentVersionReleaseDate": "2026-09-10T22:21:32Z", "fileSizeBytes": "19244046", "primaryGenreName": "Developer Tools"}"#)
		let schema = Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: info))

		#expect(schema.type == .mobileApplication)
		#expect(schema.applicationCategory == .developer)
		#expect(Schema.SoftwareApplication(listing: AppListing(app: app)).applicationCategory == .utilities)
		#expect(schema.softwareRequirements == "iOS 26 or later")
		let modifiedDay = try #require(SOML.Date("2026-09-10"))
		#expect(schema.dateModified == modifiedDay)
		#expect(schema.fileSize == "19.2 MB")
		#expect(schema.sameAs == [#URL("https://apps.apple.com/app/id123"), #URL("https://github.com/sindresorhus/test")])

		let html = JSONScript(schema: schema).render()
		#expect(html.contains(#""@type":"MobileApplication""#))
		#expect(html.contains(#""applicationCategory":"DeveloperApplication""#))
		#expect(html.contains(#""dateModified":"2026-09-10""#))
	}

	@Test(arguments: [
		("Developer Tools", "DeveloperApplication"),
		("Graphics & Design", "DesignApplication"),
		("Photo & Video", "MultimediaApplication"),
		("Music", "MultimediaApplication"),
		("Games", "GameApplication"),
		("Entertainment", "EntertainmentApplication"),
		("Lifestyle", "LifestyleApplication"),
		("Health & Fitness", "HealthApplication"),
		("Medical", "HealthApplication"),
		("Education", "EducationalApplication"),
		("Finance", "FinanceApplication"),
		("Business", "BusinessApplication"),
		("Reference", "ReferenceApplication"),
		("Travel", "TravelApplication"),
		("Social Networking", "SocialNetworkingApplication"),
		("Sports", "SportsApplication"),
		("Productivity", "UtilitiesApplication"),
		("An unknown category", "UtilitiesApplication"),
	])
	func `the App Store categories keep their structured data names and utilities fallback`(genre: String, expected: String) throws {
		let info = try AppStoreInfo(json: #"{"trackId": 123, "primaryGenreName": "\#(genre)"}"#)
		let category = info.schemaApplicationCategory ?? .utilities
		#expect(try JSONDecoder().decode(String.self, from: JSONEncoder().encode(category)) == expected)
	}

	/**
	An app can launch on the App Store a day before its page, but the structured data must not say that it changed before it was published.
	*/
	@Test
	func `the structured data of an app is never modified before it is published`() async throws {
		let app = try await App(publicationDate: "2026-10-28", frontmatter: "appStoreID: 123")
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 0, "currency": "USD", "currentVersionReleaseDate": "2026-10-27T07:00:00Z"}"#)
		let schema = Schema.SoftwareApplication(listing: AppListing(app: app, appStoreInfo: info))

		let publicationDay = try #require(SOML.Date("2026-10-28"))
		#expect(schema.datePublished == publicationDay)
		#expect(schema.dateModified == publicationDay)
	}

	/**
	Safari shows the App Store banner on the device that runs the app, but an Apple Watch app is installed from the iPhone, so it gets a QR code.
	*/
	@Test
	func `only apps that run on iOS or visionOS get the App Store banner, and watch apps also get a QR code`() async throws {
		func app(_ platforms: [Platform], frontmatter: String = "") async throws -> App {
			try await App(platforms: platforms, frontmatter: "appStoreID: 123\n\(frontmatter)")
		}

		let watchApp = try await app([.watchOS])
		#expect(!watchApp.showsAppStoreBanner)
		#expect(watchApp.qrCodeURL != nil)

		let macApp = try await app([.macOS])
		#expect(!macApp.showsAppStoreBanner)
		#expect(macApp.qrCodeURL == nil)

		#expect(try await app([.visionOS]).showsAppStoreBanner)
		#expect(try await !app([.iOS], frontmatter: "isArchived: true").showsAppStoreBanner)
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
	private let markdown = App.testMarkdown(frontmatter: "repositoryURL: 'https://github.com/test/repo?view=readme#old'")

	@Test
	func `new app badges begin before the publication day and end thirty days after it`() async throws {
		let app = try await App(markdown: markdown)
		#expect(app.isNew(at: app.publicationDate.foundationDate.addingTimeInterval(-30 * 86400)))
		#expect(app.isNew(at: app.publicationDate.foundationDate.addingTimeInterval(-1)))
		#expect(app.isNew(at: app.publicationDate.foundationDate))
		#expect(app.isNew(at: app.publicationDate.foundationDate.addingTimeInterval(30 * 86400 - 1)))
		#expect(!app.isNew(at: app.publicationDate.foundationDate.addingTimeInterval(30 * 86400)))
	}

	@Test
	func `link merging preserves order while the final replacement wins`() {
		let original = [LabeledLink("A", path: #path("/a")), LabeledLink("B", path: #path("/b"))]
		let additions = [LabeledLink("A", path: #path("/first")), LabeledLink("C", path: #path("/c")), LabeledLink("A", path: #path("/last")), LabeledLink("C", path: #path("/latest"))]
		let merged = original.merging(additions)
		#expect(merged.map(\.title) == ["A", "B", "C"])
		#expect(merged.map(\.destination) == [.path(#path("/last")), .path(#path("/b")), .path(#path("/latest"))])
	}

	/**
	The other categories come from fields, like `isMenuBarApp`, so in `categories` they would silently do nothing.
	*/
	@Test
	func `only hand-picked categories are allowed in the frontmatter`() async throws {
		await #expect(throws: ContentErrors.self) {
			try await App(markdown: markdown.replacing("---\n\nText.", with: "categories: ['menu-bar']\n---\n\nText."))
		}

		let app = try await App(markdown: markdown.replacing("---\n\nText.", with: "categories: ['shortcuts']\n---\n\nText."))
		#expect(app.categories == [.shortcuts])
	}
}
