import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct ContentWarningTests {
	@Test
	@MainActor
	func `finds spelling mistakes, vague links, and facts that the App Store does not agree with`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS', 'iOS']\nappStoreID: 123\n---\n\nThe app has a shorcut. Read more [here](https://example.com) or `in` in the code.\n\n*Requires macOS 15 or later*\n"
		let app = try await App(markdown: source)
		let info = AppStoreInfo(id: 123, version: nil, currentVersionReleaseDate: nil, priceAmount: 5, currencyCode: "USD", averageUserRating: nil, userRatingCount: nil, kind: "mac-software", minimumOsVersion: "26.0", supportedDevices: nil)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [123: info], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description)

		#expect(warnings == [
			"content/apps/test.md: The App Store price is $5, but `isPaid` is false.",
			"content/apps/test.md: `platforms` has iOS, but the App Store version is a Mac app.",
			"content/apps/test.md:11: Mentions macOS 15, but the App Store version needs macOS 26.0.",
			"content/apps/test.md: The app has no `icon.png` next to it, so it shows a placeholder icon.",
			"content/apps/test.md:9: The link text “here” does not say where the link goes.",
			"content/apps/test.md:9: Unknown word: “shorcut”.",
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

		let warnings = content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description).filter { $0.contains("word") }

		#expect(warnings == ["content/apps/test.md:15: Unknown word: “shorcut”."])
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

		let warnings = content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description).filter { $0.contains("link") || $0.contains("image") }

		#expect(warnings == ["content/apps/test.md:14: The link text “learn more” does not say where the link goes."])
	}

	@Test
	@MainActor
	func `finds vague link texts with trailing punctuation, but not link texts that say where the link goes`() async throws {
		let source = "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n[Try this.](/a) [this shortcut](/b) [Download](/c) [Screenshot.](/d) [Learn more ›](/e) [More…](/f)\n\n[Download the older version](/g) [Learn more about Shortcuts](/h) [Try this shortcut](/i)\n"
		let app = try await App(markdown: source)
		let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		let warnings = content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description).filter { $0.contains("does not say where the link goes") }

		#expect(warnings == ["Try this", "this shortcut", "Download", "Screenshot", "Learn more", "More"].map { "content/apps/test.md:8: The link text “\($0)” does not say where the link goes." })
	}

	@Test
	@MainActor
	func `a long introduction is a warning, as the app page shows it under the name`() async throws {
		func warnings(introduction: String) async throws -> [String] {
			let app = try await App(markdown: "---\ntitle: 'Test'\nsubtitle: 'Test app'\npublicationDate: '2026-01-01'\nplatforms: ['macOS']\n---\n\n\(introduction)\n\nMore text.\n")
			let content = SiteContent(apps: [app], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)
			return content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description).filter { $0.contains("introduction") }
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

		let warnings = content.warnings(project: .empty, output: Project.empty.root.appending(path: "dist")).map(\.description).filter { $0.contains("featured") }
		#expect(warnings == ["content/apps/echo.md:6: More than 4 apps are featured, so the apps page leaves out this one. Remove `isFeatured` from one of them."])
	}

	@Test(.temporaryDirectory)
	@MainActor
	func `a published page is named by its site path`() throws {
		let output = try URL.temporaryDirectory(files: ["apps/test.html": "<h1>Title</h1><h3>Skipped</h3>"])
		let content = SiteContent(apps: [], posts: [], pages: [], appStoreInfo: [:], releases: [:], recentRepositories: [], buildDate: .now, project: .empty)

		#expect(content.warnings(project: .empty, output: output).map(\.description) == ["/apps/test.html: A level 3 heading follows a level 1 heading."])
	}
}
