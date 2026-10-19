import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

@Suite
struct ContentWarningTests {
	@Test
	@MainActor
	func `finds spelling mistakes, vague links, and facts that the App Store does not agree with`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS', 'iOS']\nappStoreID: 123\nrequirement: 'Requires macOS 14 or later'\n---\n\nThe app has a shorcut. Read more [here](https://example.com) or `in` in the code.\n\n*Requires macOS 15 or later*\n"
		let app = try await App(markdown: source)
		let info = AppStoreInfo(id: 123, version: nil, currentVersionReleaseDate: nil, priceAmount: 5, currencyCode: "USD", averageUserRating: nil, userRatingCount: nil, kind: "mac-software", minimumOsVersion: "26.0", supportedDevices: nil)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts()

		#expect(warnings == [
			"content/apps/test.md: The App Store price is $5, but `isPaid` is false.",
			"content/apps/test.md: `platforms` has iOS, but the App Store version is a Mac app.",
			"content/apps/test.md:7: Mentions macOS 14, but the App Store version needs macOS 26.0.",
			"content/apps/test.md:12: Mentions macOS 15, but the App Store version needs macOS 26.0.",
			"content/apps/test.md: The app has no `icon.png` next to it, so it shows a placeholder icon.",
			"content/apps/test.md:10: The link text “here” does not say where the link goes.",
			"content/apps/test.md:10: Unknown word: “shorcut”.",
		])
	}

	/**
	The spelling check reads the text of the parsed Markdown, so code, HTML, and comments are left out, also in `~~~` code blocks and HTML tags that span lines.
	*/
	@Test
	@MainActor
	func `the spelling check reads only text`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n~~~\nsdfgh qwerty\n~~~\n\n<div\n  class=\"xyzzyq\">Text</div>\n\nThe app has a shorcut, see https://example.com/abcdefgh.\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("word") }

		#expect(warnings == ["content/apps/test.md:15: Unknown word: “shorcut”."])
	}

	@Test(.temporaryDirectory)
	@MainActor
	func `shared answers are checked once at their source lines`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\nThe the app has a shorcut. Read [here](https://example.com).\n",
		]))
		var apps = [App]()

		for slug in ["first", "second"] {
			apps.append(try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nsharedQuestions: ['shared']\n---\n\n## Frequently Asked Questions {#faq}\n", slug: slug, project: project))
		}

		let content = SiteContent(apps: apps, posts: [], pages: [], buildDate: .now, project: project)
		let warnings = content.warningTexts().filter { $0.hasPrefix("content/shared-questions.md:") }

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
	@MainActor
	func `an unknown word is reported at the line of its text`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\nIt is “fast” and *has a shorcut*.\n\n- One\n- Two mispeled\n\n🎉🎉🎉🎉🎉🎉 wrod\n\nA speling.\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("word") }

		#expect(warnings == [
			"content/apps/test.md:8: Unknown word: “shorcut”.",
			"content/apps/test.md:11: Unknown word: “mispeled”.",
			"content/apps/test.md:13: Unknown word: “wrod”.",
			"content/apps/test.md:15: Unknown word: “speling”.",
		])
	}

	/**
	The warnings read the parsed Markdown, so code that shows a link is not a link, and a link text can span lines.
	*/
	@Test
	@MainActor
	func `vague link texts and remote images in code are not warnings`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\nWrite `[here](/a)` and `![](https://example.com/a.png)`.\n\n~~~\n[here](/b)\n~~~\n\nOr [learn\nmore](/c).\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("link") || $0.contains("image") }

		#expect(warnings == ["content/apps/test.md:14: The link text “learn more” does not say where the link goes."])
	}

	@Test
	@MainActor
	func `finds vague link texts with trailing punctuation, but not link texts that say where the link goes`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n[Try this.](/a) [this shortcut](/b) [Download](/c) [Screenshot.](/d) [Learn more ›](/e) [More…](/f)\n\n[Download the older version](/g) [Learn more about Shortcuts](/h) [Try this shortcut](/i)\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("does not say where the link goes") }

		#expect(warnings == ["Try this", "this shortcut", "Download", "Screenshot", "Learn more", "More"].map { "content/apps/test.md:8: The link text “\($0)” does not say where the link goes." })
	}

	@Test
	@MainActor
	func `repeated words are warnings, also in other case, except a repeated “a”`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\nThe app is is fast. Press a a b.\n\nIt syncs the the settings.\n\nThe the app is a b b c.\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("Repeated") }

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
	@MainActor
	func `a platform that the App Store lists but the frontmatter does not is a warning, except iOS for a watch app`() async throws {
		func warnings(platforms: String, devices: String) async throws -> [String] {
			let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: \(platforms)\nappStoreID: 123\n---\n\nText.\n")
			let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "kind": "software", "supportedDevices": \#(devices)}"#.utf8))
			let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)
			return content.warningTexts().filter { $0.contains("`platforms` does not have it") }
		}

		#expect(try await warnings(platforms: "['watchOS']", devices: #"["iPhone15-iPhone15", "Watch8-Watch8"]"#).isEmpty)
		#expect(try await warnings(platforms: "['macOS']", devices: #"["iPhone15-iPhone15"]"#) == ["content/apps/test.md: The App Store version supports iOS, but `platforms` does not have it."])
	}

	/**
	The App Store gives the lowest visionOS version for an app that is only for Apple Vision.
	*/
	@Test
	@MainActor
	func `the lowest OS version of an Apple Vision app is for visionOS`() async throws {
		let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['visionOS']\nappStoreID: 123\nrequirement: 'Requires visionOS 2 or later'\n---\n\nLike the widgets of iOS 18.\n")
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 123, "kind": "software", "minimumOsVersion": "26.0", "supportedDevices": ["AppleVisionPro-AppleVisionPro"]}"#.utf8))
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warningTexts().filter { $0.contains("Mentions") }

		#expect(warnings == ["content/apps/test.md:7: Mentions visionOS 2, but the App Store version needs visionOS 26.0."])
	}

	@Test
	@MainActor
	func `a long introduction is a warning, as the app page shows it under the name`() async throws {
		func warnings(introduction: String) async throws -> [String] {
			let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n\(introduction)\n\nMore text.\n")
			let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)
			return content.warningTexts().filter { $0.contains("introduction") }
		}

		#expect(try await warnings(introduction: String(repeating: "Word ", count: 33)) == ["content/apps/test.md:8: The introduction is 164 characters. The app page shows it under the name, so keep it at most 160 characters, which is two lines."])
		#expect(try await warnings(introduction: "Open each link in the right browser.").isEmpty)
	}

	@Test
	@MainActor
	func `the apps page features at most four apps, the first ones by title, and warns about the others`() async throws {
		var apps = [App]()

		for title in ["Echo", "Alpha", "Delta", "Bravo", "Charlie"] {
			apps.append(try await App(markdown: "---\ntitle: '\(title)'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\nisFeatured: true\n---\n\nText.\n", slug: title.lowercased()))
		}
		let content = SiteContent(apps: apps, posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		#expect(content.featuredApps.map(\.title).sorted(using: .localizedStandard) == ["Alpha", "Bravo", "Charlie", "Delta"])
		#expect(content.extraFeaturedApps.map(\.title) == ["Echo"])

		let warnings = content.warningTexts().filter { $0.contains("featured") }
		#expect(warnings == ["content/apps/echo.md:6: More than 4 apps are featured, so the apps page leaves out this one. Remove `isFeatured` from one of them."])
	}

	@Test(.temporaryDirectory)
	@MainActor
	func `a published page is named by its site path`() throws {
		let output = try URL.temporaryDirectory(files: ["apps/test.html": "<h1>Title</h1><h3>Skipped</h3>"])
		let content = SiteContent(apps: [], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		#expect(content.warningTexts(output: output) == ["/apps/test.html: A level 3 heading follows a level 1 heading."])
	}

	/**
	The files of a draft are only published with its page, so they are not unused.
	*/
	@Test(.temporaryDirectory)
	@MainActor
	func `a published file that nothing uses is a warning, but a file that is not published is not`() throws {
		let root = try URL.temporaryDirectory(files: [
			"public/used.txt": "",
			"public/unused.txt": "",
			"content/apps/draft/index.md": "",
			"content/apps/draft/screenshot.jpg": "",
			"dist/index.html": #"<a href="/used.txt">Used</a>"#,
			"dist/used.txt": "",
			"dist/unused.txt": "",
		])
		let project = Project.site(root: root)
		let content = SiteContent(apps: [], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: project)

		#expect(content.warningTexts() == ["public/unused.txt: No published page, stylesheet, or script uses the file."])
	}
}
