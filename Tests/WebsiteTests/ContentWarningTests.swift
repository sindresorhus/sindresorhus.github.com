import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

struct ContentWarningTests {
	@Test
	func `finds spelling mistakes, vague links, links to the site, and facts that the App Store does not agree with`() async throws {
		let source = App.testMarkdown(platforms: [.macOS, .iOS], frontmatter: "appStoreID: 123\nminimumOSVersion: '26'", body: "The app has a shorcut. Read more [here](https://example.com) or `in` in the code. See [Velja](https://sindresorhus.com/velja#faq).\n\n*Requires macOS 15 or later*\n")
		let app = try await App(markdown: source)
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 5, "currency": "USD", "kind": "mac-software", "minimumOsVersion": "27.0"}"#)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appStoreInfo: [123: info]),
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts()

		#expect(warnings == [
			"content/apps/test.md: The App Store price is $5, but `isPaid` is false.",
			"content/apps/test.md: `platforms` has iOS, but the App Store version is a Mac app.",
			"content/apps/test.md:12: Mentions macOS 15, but the App Store version needs macOS 27.",
			"content/apps/test.md: The app has no `icon.png` next to it, so it shows a placeholder icon.",
			"content/apps/test.md: The app has no screenshots (`screenshot*.png/jpg`) or videos (`video*.mp4`) next to it, so its page shows none.",
			"content/apps/test.md:7: `minimumOSVersion` is not needed, as the page shows the version of the App Store instead, 27. Remove it.",
			"content/apps/test.md:10: The link text “here” does not say where the link goes.",
			"content/apps/test.md:10: Link to the site with a site path, like `/velja#faq`, so the build checks the link.",
			"content/apps/test.md:10: Unknown word: “shorcut”.",
		])
	}

	/**
	The spelling check reads the text of the parsed Markdown, so code, HTML, and comments are left out, also in `~~~` code blocks and HTML tags that span lines.
	*/
	@Test
	func `the spelling check reads only text`() async throws {
		let source = App.testMarkdown(body: "~~~\nsdfgh qwerty\n~~~\n\n<div\n  class=\"xyzzyq\">Text</div>\n\nThe app has a shorcut, see https://example.com/abcdefgh.\n")
		let app = try await App(markdown: source)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .unknownWord, .repeatedWord)

		#expect(warnings == ["content/apps/test.md:15: Unknown word: “shorcut”."])
	}

	@Test(.temporaryDirectory)
	func `shared answers are checked once at their source lines`() async throws {
		let project = Project.site(
			root: try URL.temporaryDirectory(
				files: [
					"content/shared-questions.md": "### Shared question {#shared}\n\nThe the app has a shorcut. Read [here](https://example.com).\n",
				]
			)
		)
		var apps = [App]()

		for slug in ["first", "second"] {
			apps.append(try await App(frontmatter: "sharedQuestions: ['shared']", body: "## Frequently Asked Questions {#faq}\n", slug: slug, project: project))
		}

		let content = SiteContent(
			apps: apps,
			posts: [],
			pages: [],
			sharedQuestions: try App.SharedQuestions.Library(project: project),
			buildDate: .now,
			project: project
		)
		let warnings = await content.warningTexts(of: .vagueLinkText, .repeatedWord, .unknownWord)

		#expect(warnings == [
			"content/shared-questions.md:3: The link text “here” does not say where the link goes.",
			"content/shared-questions.md:3: Repeated word: “The the”.",
			"content/shared-questions.md:3: Unknown word: “shorcut”.",
		])
	}

	/**
	The texts of a file are checked in one string, so each unknown word must still get the line of its own text, also after characters that are two UTF-16 code units, like an emoji.
	*/
	@Test
	func `an unknown word is reported at the line of its text`() async throws {
		let source = App.testMarkdown(body: "It is “fast” and *has a shorcut*.\n\n- One\n- Two mispeled\n\n🎉🎉🎉🎉🎉🎉 wrod\n\nA speling.\n")
		let app = try await App(markdown: source)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .unknownWord, .repeatedWord)

		#expect(warnings == [
			"content/apps/test.md:8: Unknown word: “shorcut”.",
			"content/apps/test.md:11: Unknown word: “mispeled”.",
			"content/apps/test.md:13: Unknown word: “wrod”.",
			"content/apps/test.md:15: Unknown word: “speling”.",
		])
	}

	@Test
	func `the requirement of an app that is not on the App Store comes from its appcast, or from the frontmatter`() async throws {
		func app(_ slug: String, _ frontmatter: String) async throws -> App {
			try await App(frontmatter: frontmatter, slug: slug)
		}

		let fetched = try await app("fetched", "releasesRepository: 'sindresorhus/fetched-meta'\nminimumOSVersion: '26'")
		let content = SiteContent(
			apps: [
				fetched,
				try await app("missing", "isPaid: false"),
				try await app("unloaded", "releasesRepository: 'sindresorhus/unloaded-meta'"),
				try await app("redirect", "redirectURL: 'https://github.com/sindresorhus/redirect'"),
				try await app("manual", "minimumOSVersion: '26'"),
				try await app("archived", "isArchived: true"),
			],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appcasts: [#URL("https://sindresorhus.com/fetched-meta/appcast.xml"): try Appcast(xml: Data("<item><sparkle:minimumSystemVersion>26.4</sparkle:minimumSystemVersion></item>".utf8))]),
			buildDate: .now,
			project: .empty
		)

		#expect(content.listing(of: fetched).minimumOSVersion == OSVersion("26.4"))
		#expect(await content.warningTexts(of: .requirement) == [
			"content/apps/fetched.md:7: `minimumOSVersion` is not needed, as the page shows the version of the appcast instead, 26.4. Remove it.",
			"content/apps/missing.md: The page shows no requirement, as the app is not on the App Store and has no appcast. Add `minimumOSVersion`.",
		])
	}

	@Test
	func `a raw image with only one of its width and height is a warning`() async throws {
		let source = App.testMarkdown(body: "<img src=\"https://example.com/a.png\" alt=\"A\" width=\"230\">\n\n<img src=\"b.png\" alt=\"B\" height=\"100\">\n\n<img src=\"https://example.com/c.png\" alt=\"C\">\n\n<img src=\"d.png\" alt=\"D\">\n\n<img src=\"https://example.com/e.png\" alt=\"E\" width=\"230\" height=\"100\">\n")
		let content = SiteContent(
			apps: [try await App(markdown: source)],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .imageWithoutAspectRatio, .remoteImageWithoutSize) == [
			"content/apps/test.md:8: The image has `width` but no `height`, so it has no aspect ratio before it loads, and the page shifts. Add `height`.",
			"content/apps/test.md:10: The image has `height` but no `width`, so it has no aspect ratio before it loads, and the page shifts. Add `width`.",
			"content/apps/test.md:12: The remote image has no `width` and `height`, so the page shifts while it loads.",
		])
	}

	/**
	The warnings read the parsed Markdown, so code that shows a link is not a link, and a link text can span lines.
	*/
	@Test
	func `vague link texts and remote images in code are not warnings`() async throws {
		let source = App.testMarkdown(body: "Write `[here](/a)` and `![](https://example.com/a.png)`.\n\n~~~\n[here](/b)\n~~~\n\nOr [learn\nmore](/c).\n")
		let app = try await App(markdown: source)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .vagueLinkText, .absoluteSiteLink, .headingLinkWithoutID, .remoteImageWithoutSize, .imageWithoutAspectRatio)

		#expect(warnings == ["content/apps/test.md:14: The link text “learn more” does not say where the link goes."])
	}

	@Test
	func `finds vague link texts with trailing punctuation, but not link texts that say where the link goes`() async throws {
		let source = App.testMarkdown(body: "[Try this.](/a) [this shortcut](/b) [Download](/c) [Screenshot.](/d) [Learn more ›](/e) [More…](/f)\n\n[Download the older version](/g) [Learn more about Shortcuts](/h) [Try this shortcut](/i)\n")
		let app = try await App(markdown: source)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .vagueLinkText)

		#expect(warnings == ["Try this", "this shortcut", "Download", "Screenshot", "Learn more", "More"].map { "content/apps/test.md:8: The link text “\($0)” does not say where the link goes." })
	}

	@Test
	func `repeated words are warnings, also in other case, except a repeated “a”`() async throws {
		let source = App.testMarkdown(body: "The app is is fast. Press a a b.\n\nIt syncs the the settings.\n\nThe the app is a b b c.\n")
		let app = try await App(markdown: source)
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .repeatedWord)

		#expect(warnings == [
			"content/apps/test.md:8: Repeated word: “is is”.",
			"content/apps/test.md:10: Repeated word: “the the”.",
			"content/apps/test.md:12: Repeated word: “The the”.",
			"content/apps/test.md:12: Repeated word: “b b”.",
		])
	}

	/**
	An Apple Watch app is listed with iPhone devices on the App Store, as it comes with an iPhone app.
	*/
	@Test
	func `a platform that the App Store lists but the frontmatter does not is a warning, except iOS for a watch app`() async throws {
		func warnings(platforms: [Platform], devices: String) async throws -> [String] {
			let app = try await App(platforms: platforms, frontmatter: "appStoreID: 123")
			let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "kind": "software", "supportedDevices": \#(devices)}"#.utf8))
			let content = SiteContent(
				apps: [app],
				posts: [],
				pages: [],
				appData: SiteContent.AppData(appStoreInfo: [123: info]),
				buildDate: .now,
				project: .empty
			)
			return await content.warningTexts(of: .appStoreMismatch)
		}

		#expect(try await warnings(platforms: [.watchOS], devices: #"["iPhone15-iPhone15", "Watch8-Watch8"]"#).isEmpty)
		#expect(try await warnings(platforms: [.macOS], devices: #"["iPhone15-iPhone15"]"#) == ["content/apps/test.md: The App Store version supports iOS, but `platforms` does not have it."])
	}

	/**
	The App Store gives the lowest visionOS version for an app that is only for Apple Vision.
	*/
	@Test
	func `the lowest OS version of an Apple Vision app is for visionOS`() async throws {
		let app = try await App(platforms: [.visionOS], frontmatter: "appStoreID: 123", body: "Requires visionOS 2 or later, like the widgets of iOS 18.\n")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "kind": "software", "minimumOsVersion": "26.0", "supportedDevices": ["AppleVisionPro-AppleVisionPro"]}"#.utf8))
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appStoreInfo: [123: info]),
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .oldOSVersionMention)

		#expect(warnings == ["content/apps/test.md:9: Mentions visionOS 2, but the App Store version needs visionOS 26."])
	}

	@Test
	func `a question with the same answer in several apps is a warning, but not one with another answer`() async throws {
		func app(slug: String, answer: String) async throws -> App {
			try await App(body: "## Frequently Asked Questions {#faq}\n\n### Can it sync?\n<!-- @faq.keywords icloud -->\n\n\(answer)\n\n### Can you support iOS?\n\nNo, as \(slug) needs the Mac.\n", slug: slug)
		}

		let apps = [
			try await app(slug: "first", answer: "No."),
			try await app(slug: "second", answer: "No."),
			try await app(slug: "third", answer: "Yes."),
		]

		let content = SiteContent(
			apps: apps,
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)
		let warnings = await content.warningTexts(of: .sharedAnswer)

		#expect(warnings == [
			"content/apps/first.md:10: The question “Can it sync?” has the same answer in `second`. Move it to `content/shared-questions.md`, so the answer is in one place.",
			"content/apps/second.md:10: The question “Can it sync?” has the same answer in `first`. Move it to `content/shared-questions.md`, so the answer is in one place.",
		])
	}

	/**
	A `<kbd>` with glyphs has one warning, which corrects the glyphs, and a `<kbd>` without plain text is a warning too. An array, not a set, so a second warning on the line shows.
	*/
	@Test
	func `each raw key has one warning, also with glyphs or without plain text`() async throws {
		let app = try await App(body: "Press <kbd>⌘⇧K</kbd> or <kbd>**K**</kbd>. Works on Mac <sup>macOS only</sup>.\n")
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .rawKeyboardShortcut, .modifierGlyph, .rawPlatformBadge) == [
			"content/apps/test.md:8: Write the keyboard shortcut “⌘⇧K” as `++Shift+Command+K++`, not with `<kbd>`.",
			"content/apps/test.md:8: Write the keyboard shortcut as `++…++`, like `++Command+K++`, not with `<kbd>`.",
			"content/apps/test.md:8: Write the platform “macOS only” as a platform badge, like `^[macOS only](platform: \"macOS\")`, not with `<sup>`.",
		])
	}

	/**
	A shortcut as plain text is shown as text, not as keys. A heading, a link text, a raw `<kbd>`, and a click with a modifier are left out.
	*/
	@Test
	func `keyboard shortcuts as plain text and raw links are warnings`() async throws {
		let app = try await App(body: "Press Command+N, or Option-Command-V, not ++Command+R++. Shift-click, Shift-JIS, <kbd>Command+C</kbd>, and [Command+K](/apps).\n\n## Use Command+Q\n\nSee <a href=\"/datto\">Datto</a>.\n")
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .plainTextShortcut, .rawLink) == [
			"content/apps/test.md:8: Write the keyboard shortcut “Command+N” as `++Command+N++`, so the page shows its keys.",
			"content/apps/test.md:8: Write the keyboard shortcut “Option-Command-V” as `++Option+Command+V++`, so the page shows its keys.",
			"content/apps/test.md:12: Write the link as a Markdown link, like `[Dato](/dato)`, not with `<a>`, so the build checks it.",
		])
	}

	@Test
	func `a question that one app has twice is not a shared answer`() async throws {
		let app = try await App(body: "## Frequently Asked Questions {#faq}\n\n### Can it sync?\n\nNo, it cannot sync at all.\n\n### Can it sync?\n\nNo, it cannot sync at all.\n")
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .sharedAnswer).isEmpty)
	}

	@Test
	func `raw keys and platforms, links to headings without their own ID, the feedback note, and the versions of downloads are checked`() async throws {
		let first = try await App(frontmatter: "feedbackNote: 'See [this](/apps).'\nolderVersions: [{version: '1.4.9', macOS: '14', url: 'https://example.com/App.1.14.9.zip'}]", body: "Press <kbd>Command+C</kbd>, or <kbd>Command+</kbd> to zoom, or <kbd>cmd+k</kbd>, not `⌘C`. Works on Mac <sup>(macOS-only)</sup>.\n\n### Can it sync?\n\nNo.\n", slug: "first")
		let second = try await App(body: "See [the sync answer](/first#can-it-sync).\n", slug: "second")
		let content = SiteContent(
			apps: [first, second],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = Set(await content.warningTexts(of: .rawKeyboardShortcut, .modifierGlyph, .rawPlatformBadge, .headingLinkWithoutID, .vagueLinkText, .downloadVersion))

		#expect(warnings == [
			"content/apps/first.md:10: Write the keyboard shortcut “Command+C” as `++Command+C++`, not with `<kbd>`.",
			"content/apps/first.md:10: Write the keyboard shortcut “Command+” as `++Command+Plus++`, not with `<kbd>`.",
			"content/apps/first.md:10: Write the keyboard shortcut “cmd+k” as `++Command+K++`, not with `<kbd>`.",
			"content/apps/first.md:10: Write a keyboard shortcut with the names of its keys, like `++Option+Shift+Command+V++`, not with modifier glyphs, like “⌥⇧⌘V”.",
			"content/apps/first.md:10: Write the platform “(macOS-only)” as a platform badge, like `^[macOS only](platform: \"macOS\")`, not with `<sup>`.",
			"content/apps/first.md:6: The link text “this” does not say where the link goes.",
			"content/apps/first.md:7: The version 1.4.9 is not the version in the name of its download, App.1.14.9.zip.",
			"content/apps/second.md:8: The link goes to the heading “Can it sync?”, whose ID comes from its text, so changing the text breaks the link. Give the heading its ID: `{#can-it-sync}` (content/apps/first.md:12).",
		])
	}

	/**
	The questions that the build adds, like the localization question, have their IDs in their source, so only the questions of the file are checked.
	*/
	@Test
	func `a question of the FAQ section without its own ID is checked`() async throws {
		let app = try await App(body: "## Frequently Asked Questions {#faq}\n\n### Can it sync?\n\nNo.\n\n### Is it free? {#free}\n\nYes.\n")
		// The general FAQ, whose questions the apps and the support emails link to the most.
		let generalFAQ = try await MarkdownPage(markdown: "---\ntitle: 'FAQ'\n---\n\n## Purchases {#purchases}\n\n### How can I get a refund?\n\nAsk.\n\n### Is there a trial? {#trial}\n\nYes.\n", slug: "apps/faq")
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [generalFAQ],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .questionWithoutID)
		#expect(warnings == [
			"content/apps/test.md:10: The question “Can it sync?” has no ID of its own, so changing its text breaks the links to it, like in support emails. Give it its ID: `{#can-it-sync}`.",
			"content/pages/apps/faq.md:7: The question “How can I get a refund?” has no ID of its own, so changing its text breaks the links to it, like in support emails. Give it its ID: `{#how-can-i-get-a-refund}`.",
		])
	}

	/**
	The feedback page finds the app by its title or a name of `feedbackNames` in any case, or by its slug, so only another name is a mistake.
	*/
	@Test
	func `a feedback link with a product that is not an app of the feedback page is checked`() async throws {
		let dato = try await App(title: "Dato", frontmatter: "feedbackNames: ['Dato Calendar']", slug: "dato")
		let other = try await App(frontmatter: "feedbackNote: '[Tell me](/feedback?product=Datto).'", body: "[Send it](/feedback?product=Datto&referrer=Website-FAQ), [this](/feedback?product=dato), [the name](/feedback?product=dato%20calendar), and [that](/feedback?product=Dato%20App).\n", slug: "other")
		let content = SiteContent(
			apps: [dato, other],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(Set(await content.warningTexts(of: .unknownFeedbackProduct)) == [
			"content/apps/other.md:6: The feedback link has the product “Datto”, which is not an app of the feedback page, so the form opens without the app. Did you mean “Dato”?",
			"content/apps/other.md:9: The feedback link has the product “Datto”, which is not an app of the feedback page, so the form opens without the app. Did you mean “Dato”?",
			"content/apps/other.md:9: The feedback link has the product “Dato App”, which is not an app of the feedback page, so the form opens without the app. Did you mean “Dato”?",
		])
	}

	@Test
	func `promises, tracking parameters, http links, copied answer blocks, and trials without a requirement are checked`() async throws {
		// Two copied blocks in one answer still give one warning for it.
		let steps = "- Open the settings of the app, and go to the “Calls” tab.\n- Click the plus button.\n- Choose the service in the list, and enter the link of the meeting room that you use for your calls.\n\nThe service then shows up in the list of services of the app, and the app opens the link of the meeting room when you join a call from the menu bar.\n"
		let first = try await App(frontmatter: "pressQuotes: [{quote: 'Love it', source: 'Buyer', url: 'https://sindresorhus.gumroad.com/l/test'}]", body: "See [the guide](https://example.com/guide?utm_source=chatgpt.com&ref=sponsor), not `https://example.com?fbclid=1`. The [old site](http://example.com) and [the preview](http://localhost:3000).\n\n## Trial {#trial}\n\n@Trial(url: \"https://example.com/Test.zip\", macOS: \"26\") {\n\tTry it.\n}\n\n## Frequently Asked Questions {#faq}\n\n### Can you add iOS?\n\nI plan to do it at some point.\n\n### Can you add widgets?\n\nIt’s not something I plan to add in the future.\n\n### How do I add a call service?\n\n\(steps)", slug: "first")
		let second = try await App(frontmatter: "minimumOSVersion: '27'", body: "## Trial {#trial}\n\n@Details(summary: \"Older Macs\") {\n\t@Trial(url: \"https://example.com/Test.zip\", macOS: \"26\") {\n\t\tTry it.\n\t}\n}\n\n## Frequently Asked Questions {#faq}\n\n### My call service is missing\n\nTell me which one.\n\n\(steps)", slug: "second")
		let content = SiteContent(
			apps: [first, second],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .copiedAnswerBlock, .promise, .trackingParameter, .insecureLink, .trialRequirement)

		#expect(warnings == [
			"content/apps/first.md:27: The answer of “How do I add a call service?” has a list or paragraph that is also in the FAQ of `second`. Move the question to `content/shared-questions.md`, or link to one answer, so the copies do not get out of sync.",
			"content/apps/second.md:19: The answer of “My call service is missing” has a list or paragraph that is also in the FAQ of `first`. Move the question to `content/shared-questions.md`, or link to one answer, so the copies do not get out of sync.",
			"content/apps/first.md:21: The answer of “Can you add iOS?” promises something: “I plan to”. Remove the promise when the plan changed, or answer what the app does now.",
			"content/apps/first.md:9: The link https://example.com/guide?utm_source=chatgpt.com&ref=sponsor has the tracking parameter `utm_source`. Remove it.",
			"content/apps/first.md:9: The link http://example.com uses `http://`. Use `https://` when the site supports it.",
			"content/apps/first.md:13: The trial needs macOS 26, but the page shows no requirement for the app. Add `minimumOSVersion`.",
			"content/apps/second.md:12: The trial says macOS 26, but the app needs macOS 27.",
		])
	}

	@Test
	func `a long introduction is a warning, as the app page shows it under the name`() async throws {
		func warnings(introduction: String) async throws -> [String] {
			let app = try await App(body: "\(introduction)\n\nMore text.\n")
			let content = SiteContent(
				apps: [app],
				posts: [],
				pages: [],
				buildDate: .now,
				project: .empty
			)
			return await content.warningTexts(of: .longIntroduction)
		}

		#expect(try await warnings(introduction: String(repeating: "Word ", count: 33)) == ["content/apps/test.md:8: The introduction is 164 characters. The app page shows it under the name, so keep it at most 160 characters, which is two lines."])
		#expect(try await warnings(introduction: "Open each link in the right browser.").isEmpty)
	}

	/**
	The projects of the open source page are a list in the code, so a repo that was archived, renamed, or moved, or a wrong language, is only found by comparing with the repos of GitHub.
	*/
	@Test
	func `open source projects that GitHub does not agree with are warnings`() async throws {
		let got = try GitHubRepository(json: #"{"name": "got", "description": "HTTP", "full_name": "sindresorhus/got", "html_url": "https://github.com/sindresorhus/got", "created_at": "2020-01-01T00:00:00Z", "archived": true, "fork": false, "stargazers_count": 1, "language": "JavaScript"}"#)
		let content = SiteContent(
			apps: [],
			posts: [],
			pages: [],
			gitHubAccount: GitHub.Account(
				repositoryCount: 1,
				followerCount: 1,
				starCount: 1,
				maintenance: GitHub.Maintenance(closedIssueCount: 1, mergedPullRequestCount: 1),
				repositories: [got]
			),
			buildDate: .now,
			project: .empty
		)

		let warnings = await content.warningTexts(of: .openSourceProject)
		#expect(warnings.filter { $0.contains("(`sindresorhus/got`)") } == [
			"/open-source: Got (`sindresorhus/got`) is archived on GitHub. Remove it from the page, or unarchive the repo.",
			"/open-source: Got (`sindresorhus/got`) has the language `JavaScript` on GitHub, but `TypeScript` on the page. Fix its `language` in `OpenSourcePage.swift`.",
		])
		#expect(warnings.contains("/open-source: Ky (`sindresorhus/ky`) is not a repo on GitHub. Maybe it was renamed or moved. Fix its `repository` in `OpenSourcePage.swift`."))

		// Without the repos, like when the request failed, nothing is checked.
		#expect(await SiteContent(apps: [], posts: [], pages: [], buildDate: .now, project: .empty).warningTexts(of: .openSourceProject).isEmpty)
	}

	/**
	A social card only shows three lines of a text, so a text that it cuts off is a warning, at the key of the text, which the author can shorten.
	*/
	@Test
	func `a social card that cuts off its subtitle is a warning`() async throws {
		let longSubtitle = String(repeating: "A sentence that is much too long for the card. ", count: 6)
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: '\(longSubtitle)'\npublicationDate: 2026-01-01\nplatforms: ['macOS']\n---\n\nText.")
		let content = SiteContent(apps: [app], posts: [], pages: [], buildDate: .now, project: .empty)

		#expect(await content.warningTexts(of: .cutSocialCardText) == ["content/apps/test.md:3: The social card cuts off `subtitle` after three lines. Shorten it."])

		let shortApp = try await App(slug: "short")
		#expect(await SiteContent(apps: [shortApp], posts: [], pages: [], buildDate: .now, project: .empty).warningTexts(of: .cutSocialCardText).isEmpty)
	}

	@Test
	func `a published page is named by its site path`() async throws {
		let published = PublishedSite(routeTexts: ["apps.html": "<h1>Title</h1><h3>Skipped</h3>"])
		let content = SiteContent(
			apps: [],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warnings(published: published, routes: Site(content: content).routes()).warnings == [Warning(.skippedHeadingLevel, at: .page(.apps), "The level 3 heading “Skipped” follows a level 1 heading.")])
	}

	/**
	Only the pages of the routes are checked for skipped heading levels, by the kind of their route, so a page that shows a redirect in a code sample is still checked, and a redirect page is not. The HTML files in `public` are not files of the routes.
	*/
	@Test
	func `skipped heading levels are checked on the pages of the routes`() async throws {
		let skippedHeadings = "<h1>Title</h1><h3>Skipped</h3>"
		let published = PublishedSite(
			routeTexts: [
				"code.html": #"<pre>&lt;meta http-equiv="refresh"&gt;</pre>"# + skippedHeadings,
				"old.html": skippedHeadings,
			]
		)
		let content = SiteContent(
			apps: [],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)
		let routes: [Route] = [
			.page(#path("/code")) { "" },
			.redirect(#path("/old"), to: #path("/code")),
		]

		#expect(await content.warnings(published: published, routes: routes).warnings.filter { $0.kind == .skippedHeadingLevel } == [Warning(.skippedHeadingLevel, at: .page(#path("/code")), "The level 3 heading “Skipped” follows a level 1 heading.")])
	}

	/**
	The description of an app page cannot use `##`, which starts a section of the page, so its first heading can be of any level. A skipped level after it, or on another page, is still a warning.
	*/
	@Test(.temporaryDirectory)
	func `the first heading of the description of an app page can skip levels`() async throws {
		let published = PublishedSite(
			routeTexts: [
				"test.html": "<h1>App</h1><h4>Description</h4><h3>More</h3><h2>Section</h2><h4>Skipped</h4>",
				"apps.html": "<h1>Apps</h1><h4>Skipped</h4>",
			]
		)
		let content = SiteContent(
			apps: [try await App(body: "## Section\n\n#### Skipped", slug: "test")],
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		// At the line of the heading in the content file, when the content has it.
		#expect(Set(await content.warningTexts(of: .skippedHeadingLevel, published: published)) == [
			"/apps: The level 4 heading “Skipped” follows a level 1 heading.",
			"content/apps/test.md:10: The level 4 heading “Skipped” follows a level 2 heading.",
		])
	}

	/**
	The older versions of an app need older OS versions, so text about them is not a warning: a list of them to download and its requirement, and a line that links to them. Other lines are.
	*/
	@Test
	func `text about the older versions of an app may mention older OS versions`() async throws {
		let app = try await App(frontmatter: "appStoreID: 123", body: "- [Old](https://example.com/Old.zip)\n\n*Requires macOS 15 or later*\n\nThis is a macOS 14 bug, so it only affects the [older version](#older-versions). It started in macOS 12.\n\n*Requires macOS 13 or later*\n")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "kind": "mac-software", "minimumOsVersion": "26.0"}"#.utf8))
		let content = SiteContent(
			apps: [app],
			posts: [],
			pages: [],
			appData: SiteContent.AppData(appStoreInfo: [123: info]),
			buildDate: .now,
			project: .empty
		)

		// A line is a paragraph, so only the sentence with the link is left out.
		#expect(await content.warningTexts(of: .oldOSVersionMention) == ["content/apps/test.md:13: Mentions macOS 12, but the App Store version needs macOS 26.", "content/apps/test.md:15: Mentions macOS 13, but the App Store version needs macOS 26."])
	}

	/**
	A question with the title of a question that the build adds replaces it, so several apps can replace it with the same answer.
	*/
	@Test
	func `an answer that replaces an added question is not a shared answer`() async throws {
		var apps = [App]()

		for slug in ["first", "second"] {
			apps.append(try await App(frontmatter: "isMenuBarApp: true", body: "## Frequently Asked Questions {#faq}\n\n### \(App.Section.menuBarQuestion.title)\n\nLaunch the app again.\n", slug: slug))
		}

		let content = SiteContent(
			apps: apps,
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .sharedAnswer).isEmpty)
	}

	/**
	Search engines show pages with the same title or description as the same result, so each page with one is a warning at its content file.
	*/
	@Test(.temporaryDirectory)
	func `indexed pages with the same description are warnings at their files`() async throws {
		var apps = [App]()

		for slug in ["first", "second"] {
			apps.append(try await App(title: slug, slug: slug))
		}

		let published = PublishedSite(
			routeTexts: [
				"first.html": #"<title>First</title><meta name="description" content="Same &amp; more.">"#,
				"second.html": #"<title>Second</title><meta name="description" content="Same &amp; more.">"#,
			]
		)
		let content = SiteContent(
			apps: apps,
			posts: [],
			pages: [],
			buildDate: .now,
			project: .empty
		)

		#expect(await content.warningTexts(of: .duplicateTitle, .duplicateDescription, published: published) == [
			"content/apps/first.md: The page has the same description as `/second`: “Same & more.”. Give each page its own description.",
			"content/apps/second.md: The page has the same description as `/first`: “Same & more.”. Give each page its own description.",
		])
	}

	/**
	The files of a draft are only published with its page, so they are not unused.
	*/
	@Test(.temporaryDirectory)
	func `a published file that nothing uses is a warning, but a file that is not published is not`() async throws {
		let root = try URL.temporaryDirectory(
			files: [
				"public/used.txt": "",
				"public/unused.txt": "",
				"content/apps/draft/index.md": "",
				"content/apps/draft/screenshot.jpg": "",
			]
		)
		let published = PublishedSite(routeTexts: ["index.html": #"<a href="/used.txt">Used</a>"#], publicFiles: ["used.txt", "unused.txt"])
		let project = Project.site(root: root)
		let content = SiteContent(
			apps: [],
			posts: [],
			pages: [],
			buildDate: .now,
			project: project
		)

		#expect(await content.warningTexts(published: published) == ["public/unused.txt: No published page, stylesheet, or script uses the file."])
	}

	/**
	A screenshot needs about two pixels for each CSS pixel at its largest size, which is at most 640 pixels high and as wide as the carousel.
	*/
	@Test(arguments: [
		(PixelSize(width: 1440, height: 900), false),
		(PixelSize(width: 2000, height: 1125), true),
		(PixelSize(width: 2880, height: 1800), true),
		(PixelSize(width: 1066, height: 1102), false),
	])
	func `a screenshot is sharp on Retina screens when it has two pixels for each shown pixel`(size: PixelSize?, isSharp: Bool) throws {
		let size = try #require(size)
		let screenshot = ScreenshotAsset(path: #path("/app/screenshot1.jpg"), size: size, jpegXL: nil)
		#expect(screenshot.isSharpOnRetina == isSharp)
	}

	/**
	`website check content/apps/dato` shows only the warnings of the files that are being edited, so `--strict` passes for them.
	*/
	@Test
	func `a warning is at a file when it is at the file, at its page, or at a directory with the file, or the file is in its directory`() async throws {
		let app = try await App(slug: "dato")
		let content = SiteContent(apps: [app], posts: [], pages: [], buildDate: .now, project: .empty)
		let appFile = app.file.url
		let appsDirectory = appFile.deletingLastPathComponent()
		let otherFile = appsDirectory.appending(path: "other.md")

		let pageWarning = Warning(.skippedHeadingLevel, at: .page(app.path), "A warning of the page.")
		#expect(content.warning(pageWarning, isAtAnyOf: [appFile]))
		#expect(content.warning(pageWarning, isAtAnyOf: [otherFile, appsDirectory]))
		#expect(!content.warning(pageWarning, isAtAnyOf: [otherFile]))

		// A warning at a directory, like the screenshots of an app, is at the files in it.
		let directoryWarning = Warning(.blurryScreenshot, at: .file(appsDirectory), "A warning of the directory.")
		#expect(content.warning(directoryWarning, isAtAnyOf: [appFile]))

		// A page without a content file and a warning without a location are at no file.
		#expect(!content.warning(Warning(.skippedHeadingLevel, at: .page(.apps), "A warning of a page without a file."), isAtAnyOf: [appsDirectory]))
		#expect(!content.warning(Warning(.skippedHeadingLevel, at: nil, "A warning without a location."), isAtAnyOf: [appsDirectory]))
	}
}
