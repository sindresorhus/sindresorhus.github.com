import CoreImage
import Elementary
import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct ContentTests {
	@Test
	func `minimal app frontmatter loads with defaults`() throws {
		let app = try loadApp("""
		---
		title: Test
		subtitle: Test app
		pubDate: 2026-01-01
		platforms:
		  - macOS
		---

		Test app.
		""")

		#expect(app.title == "Test")
		#expect(app.platforms == [.macOS])
		#expect(!app.isPaid)
		#expect(app.showsSupportLink)
		#expect(app.description == "Test app. Test app.")
	}

	@Test(arguments: [
		"draft: \"false\"",
		"unexpected: true",
		"platforms:\n  - Amiga",
		"appStoreId: -1",
		"repoUrl: github.com/sindresorhus",
		"links:\n  Docs: /docs",
		"pressQuotes:\n  - quote: Great\n    source: Example\n    url: example.com",
		"olderMacOSVersions:\n  - '9'",
		"announcement:\n  text: Sale\n  url: relative/path",
		"redirectFrom:\n  - old-name",
		"script: /missing.js",
		"description: ' '",
		"downloads: 9007199254740992",
		"pressQuotes:\n  - quote: ''\n    source: Example",
	])
	func `strict app frontmatter rejects invalid values`(line: String) {
		#expect(throws: (any Error).self) {
			try loadApp("""
			---
			title: Test
			subtitle: Test app
			pubDate: 2026-01-01
			platforms:
			  - macOS
			\(line)
			---
			""")
		}
	}

	@Test
	func `subtitle must not end with punctuation`() {
		#expect(throws: ContentError.self) {
			try loadApp("---\ntitle: Test\nsubtitle: Test app.\npubDate: 2026-01-01\nplatforms: [macOS]\n---")
		}
	}

	@Test
	func `links keep their order and merge like JavaScript objects`() throws {
		let app = try loadApp("""
		---
		title: Test
		subtitle: Test app
		pubDate: 2026-01-01
		platforms: [macOS]
		repoUrl: https://github.com/sindresorhus/test
		mainLinks:
		  Zebra: https://example.com/zebra
		  Learn More: https://example.com/more
		  Apple: https://example.com/apple
		---
		""")

		#expect(app.mainLinks.map(\.href) == ["https://example.com/more", "https://example.com/zebra", "https://example.com/apple"])
		#expect(app.mainLinks.map(\.title) == ["Learn More", "Zebra", "Apple"])
	}

	@Test
	func `FAQ section gets the feedback question`() throws {
		let app = try loadApp("""
		---
		title: My App
		subtitle: Test app
		pubDate: 2026-01-01
		platforms: [macOS]
		---

		## Frequently Asked Questions {#faq}

		#### Some question

		Answer.
		""")

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback", "some-question"])
		#expect(app.markdown.html.contains("https://sindresorhus.com/feedback?product=My%20App&amp;referrer=Website-FAQ"))
		#expect(app.faqHeadings.map(\.text) == ["Some question"])
		#expect(app.links.contains(LabeledLink("FAQ", destination: .fragment("faq"))))
	}

	@Test
	func `existing feature request question gets the feedback answer`() throws {
		let app = try loadApp("""
		---
		title: My App
		subtitle: Test app
		pubDate: 2026-01-01
		platforms: [macOS]
		---

		## Frequently Asked Questions {#faq}

		#### Can I make a feature request? {#requests}

		Sure.
		""")

		#expect(app.markdown.headings.map(\.id) == ["faq", "feedback"])
		#expect(app.markdown.html.contains("send it here."))
	}

	@Test
	func `related apps are similar apps, without the app itself, and the same all day`() throws {
		let apps = try ["a", "b", "c", "d", "e", "f"].map { slug in
			try loadApp("---\ntitle: \(slug)\nsubtitle: App\npubDate: 2026-01-01\nplatforms:\n  - macOS\n---", slug: slug)
		}

		let morning = Date(timeIntervalSince1970: 1_800_000_000)
		let related = apps[0].relatedApps(from: apps, on: morning)

		#expect(related.count == 3)
		#expect(!related.map(\.slug).contains("a"))
		#expect(related.map(\.slug) == apps[0].relatedApps(from: apps, on: morning.addingTimeInterval(60)).map(\.slug))
	}

	@Test
	func `an impossible day is rejected instead of moved`() {
		#expect(throws: ContentError.self) {
			try loadApp("---\ntitle: Test\nsubtitle: Test app\npubDate: 2026-02-30\nplatforms:\n  - macOS\n---\n\nText.")
		}
	}

	@Test
	func `the FAQ heading needs its ID`() {
		#expect(throws: (any Error).self) {
			try loadApp("---\ntitle: Test\nsubtitle: Test app\npubDate: 2026-01-01\nplatforms:\n  - macOS\n---\n\n## Frequently Asked Questions\n\n### A question\n\nAn answer.")
		}
	}

	@Test
	func `an app needs a platform`() {
		#expect(throws: ContentError.self) {
			try loadApp("---\ntitle: Test\nsubtitle: Test app\npubDate: 2026-01-01\nplatforms: []\n---\n\nText.")
		}
	}

	private func loadApp(_ source: String, slug: String = "test") throws -> App {
		let project = Project(root: FileManager.default.temporaryDirectory.appending(path: "website-tests-\(UUID().uuidString)"))
		let file = try MarkdownFile(contents: source, url: project.root.appending(path: "content/apps/\(slug).md"))
		return try App(file: file, frontmatter: file.decodeFrontmatter(), project: project)
	}
}

@Suite
struct SuggestedQuestionTests {
	@Test
	func `words are lowercase, at least three letters, and without stopwords or apostrophes`() {
		#expect(SuggestedQuestion.words(in: "Why doesn't the iCloud-sync work on my Mac?") == ["doesnt", "icloud", "sync", "work", "mac"])
	}

	@Test
	func `question words leave out keywords and synonyms, which only the matching words have`() {
		let question = SuggestedQuestion(question: "iCloud sync stopped", url: "/app#icloud", keywords: ["backup"])

		#expect(question.questionWords == ["icloud", "sync", "stopped"])
		#expect(question.extraWords == ["syncing", "backup"])
	}

	@Test
	func `one-way synonyms only match in their direction`() {
		#expect(SuggestedQuestion(question: "The app is broken", url: "/a").extraWords.contains("bug"))
		#expect(!SuggestedQuestion(question: "Found a bug", url: "/b").extraWords.contains("broken"))
	}

	@Test
	func `pinned questions get their rank`() {
		#expect(SuggestedQuestion(question: "Refund", url: "/apps/faq#app-problem").pinnedRank == 1)
		#expect(SuggestedQuestion(question: "Other", url: "/apps/faq#other").pinnedRank == nil)
	}
}

@Suite
struct QRCodeTests {
	@Test
	func `the modules read back as the URL`() throws {
		let url = try #require(URL(string: "https://apps.apple.com/app/id1234567890"))
		let code = QRCode(url: url, label: "QR code")
		let size = code.modules.count
		#expect(size > 20)
		#expect(code.modules.allSatisfy { $0.count == size })

		// The modules drawn large, as a scanner sees them.
		let scale = 8
		var pixels = [UInt8](repeating: 255, count: size * scale * size * scale)

		for (y, row) in code.modules.enumerated() {
			for (x, isDark) in row.enumerated() where isDark {
				for pixelY in (y * scale)..<((y + 1) * scale) {
					for pixelX in (x * scale)..<((x + 1) * scale) {
						pixels[(pixelY * size * scale) + pixelX] = 0
					}
				}
			}
		}

		let image = try #require(pixels.withUnsafeMutableBytes { buffer in
			CGContext(data: buffer.baseAddress, width: size * scale, height: size * scale, bitsPerComponent: 8, bytesPerRow: size * scale, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)?.makeImage()
		})

		let detector = try #require(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
		let messages = detector.features(in: CIImage(cgImage: image)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
		#expect(messages == [url.absoluteString])
	}

	@Test
	func `the SVG draws the dark modules in the current color`() throws {
		let html = QRCode(url: try #require(URL(string: "https://sindresorhus.com")), label: "QR code for “Dato”").render()

		#expect(html.hasPrefix(#"<div><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 "#))
		#expect(html.contains(#"aria-label="QR code for “Dato”""#))
		#expect(html.contains(#"<path fill="currentColor" d="M"#))
	}
}
