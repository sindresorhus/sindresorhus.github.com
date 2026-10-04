import Foundation
import Testing
@testable import SiteCore

@Test func snippetShortening() {
	#expect(TextUtilities.shortenForSnippet("Short text") == "Short text")
	let long = String(repeating:"word ", count:50)
	#expect(TextUtilities.shortenForSnippet(long).count <= 160)
}

@Test func markdownIntroduction() {
	let markdown = MarkdownProcessor.process("Use [Dato](/dato) to see the **date** with `npx`.\n\n## Heading")
	#expect(markdown.introduction == "Use Dato to see the date with npx.")
}

@Test func customHeadingID() {
	let markdown = MarkdownProcessor.process("## Hello World {#custom-id}\n\nText")
	#expect(markdown.headings.first?.id == "custom-id")
	#expect(markdown.html.contains("id=\"custom-id\""))
	#expect(!markdown.html.contains("{#custom-id}"))
}

@Test func headingMetadata() {
	let markdown = MarkdownProcessor.process("### Test {#test}\n<!-- @faq.keywords launch open -->\n<!-- @faq.platforms macOS -->")
	#expect(markdown.headingMetadata["test"]?["faq"]?.keywords == ["launch", "open"])
	#expect(markdown.headingMetadata["test"]?["faq"]?.platforms == ["macOS"])
}

@Test func feedbackFAQInjection() {
	let markdown = MarkdownProcessor.process("## Frequently Asked Questions {#faq}\n\n#### Some question\n\nAnswer.", appContext:.init(title:"My App", platforms:["macOS"]))
	#expect(markdown.headings.contains { $0.id == "feedback" })
	#expect(markdown.html.contains("feedback?product=My%20App"))
}


@Test func kbdPlusKeyDoesNotLoopOrRewriteTheLiteralKey() {
	let markdown = MarkdownProcessor.process("<kbd>Command+</kbd> and <kbd>+</kbd>")
	#expect(markdown.html.contains("<kbd>Command</kbd>"))
	#expect(markdown.html.contains("<kbd>+</kbd>"))
}

@Test func unrestrictedFAQMetadataDoesNotInventPlatformRestrictions() {
	let markdown = MarkdownProcessor.process("### General Question {#general}\n<!-- @faq.keywords open launch -->")
	let metadata = markdown.headingMetadata["general"]?["faq"]
	#expect(metadata?.keywords == ["open", "launch"])
	#expect(metadata?.platforms == [])
}


@Test func markdownIntroductionIgnoresOnlyHTMLComments() {
	#expect(MarkdownProcessor.process("<!-- Hidden. -->\n\nVisible.").introduction == "Visible.")
	#expect(MarkdownProcessor.process("<br>\n\nParagraph.").introduction == nil)
	#expect(MarkdownProcessor.process("## Heading\n\nParagraph.").introduction == nil)
	#expect(MarkdownProcessor.process("![Screenshot](screenshot.png)\n\nParagraph.").introduction == nil)
}


@Test func multiParagraphGitHubAlertKeepsAllContent() {
	let markdown = MarkdownProcessor.process("""
	> [!IMPORTANT]
	> First paragraph.
	>
	> Second paragraph.
	""")
	#expect(markdown.html.contains("markdown-alert-important"))
	#expect(markdown.html.contains("First paragraph."))
	#expect(markdown.html.contains("Second paragraph."))
	#expect(!markdown.html.contains("<blockquote>"))
}


@Test func introductionPreservesSourceApostrophes() {
	let markdown = MarkdownProcessor.process("Instant access to your Mac's camera feed.")
	#expect(markdown.introduction == "Instant access to your Mac's camera feed.")
}

@Test func footnotesNumberByFirstReferenceAndRenderDefinitions() {
	let markdown = MarkdownProcessor.process("""
	First[^second], then[^first].

	[^first]: First definition.
	[^second]: Second definition.
	""")

	#expect(markdown.html.contains("href=\"#user-content-fn-second\""))
	#expect(markdown.html.contains(#">1</a></sup>"#))
	#expect(markdown.html.contains("href=\"#user-content-fn-first\""))
	#expect(markdown.html.contains(#">2</a></sup>"#))
	#expect(markdown.html.contains("Second definition."))
	#expect(markdown.html.contains("First definition."))
	#expect(markdown.html.contains(">Footnotes</h2>"))
}


@Test func introductionPreservesIntrawordUnderscores() {
	let markdown = MarkdownProcessor.process("A read-only viewer for Finder metadata stored in .DS_Store files.")
	#expect(markdown.introduction == "A read-only viewer for Finder metadata stored in .DS_Store files.")
}


@Test func strictAppFrontmatterValidationRejectsWrongTypesAndUnknownKeys() throws {
	let root = try makeTemporarySiteRoot()
	defer { try? FileManager.default.removeItem(at: root) }

	let appDirectory = root.appending(path: "source/content/apps")
	try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

	let source = """
	---
	title: Test
	subtitle: Test app
	pubDate: 2026-01-01
	platforms:
	  - macOS
	draft: "false"
	unexpected: true
	---

	Test app.
	"""
	try source.write(to: appDirectory.appending(path: "test.md"), atomically: true, encoding: .utf8)

	do {
		_ = try ContentLoader.loadApps(root: root)
		Issue.record("Expected strict frontmatter validation to fail.")
	} catch let error as ContentError {
		#expect(error.description.contains("unknown key") || error.description.contains("draft"))
	}
}

@Test func validMinimalAppFrontmatterLoads() throws {
	let root = try makeTemporarySiteRoot()
	defer { try? FileManager.default.removeItem(at: root) }

	let appDirectory = root.appending(path: "source/content/apps")
	try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

	let source = """
	---
	title: Test
	subtitle: Test app
	pubDate: 2026-01-01
	platforms:
	  - macOS
	---

	Test app.
	"""
	try source.write(to: appDirectory.appending(path: "test.md"), atomically: true, encoding: .utf8)

	let apps = try ContentLoader.loadApps(root: root)
	#expect(apps.count == 1)
	#expect(apps.first?.title == "Test")
}

private func makeTemporarySiteRoot() throws -> URL {
	let root = FileManager.default.temporaryDirectory
		.appending(path: "SiteCoreTests-\(UUID().uuidString)")
	try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
	return root
}


@Test func markdownListsRenderWithoutParagraphWrappers() {
	let markdown = MarkdownProcessor.process("""
	- First
	- Second
	  - Nested
	""")

	#expect(markdown.html.contains("<li>First</li>"))
	#expect(markdown.html.contains("<li>Second"))
	#expect(markdown.html.contains("<li>Nested</li>"))
	#expect(!markdown.html.contains("<li><p>"))
}


@Test func releaseNotesLinkifyBareEmailWithoutKbdTransformation() {
	let html = MarkdownProcessor.renderReleaseNotes(
		"Contact support@example.com. <kbd>Command+Delete</kbd>"
	)
	#expect(html.contains(#"<a href="mailto:support@example.com">support@example.com</a>"#))
	#expect(html.contains("<kbd>Command+Delete</kbd>"))
	#expect(!html.contains("kbd-sep"))
}

@Test func releaseFeedSanitizerMatchesExpectedSafetyBasics() {
	let html = """
	<!-- private -->
	<p>Hello <a href="https://example.com" class="x">site</a>.</p>
	<img src="https://example.com/a.png">
	<script>alert(1)</script>
	<a href="javascript:alert(1)">bad</a>
	"""
	let sanitized = FeedHTMLSanitizer.sanitize(html)
	#expect(!sanitized.contains("private"))
	#expect(sanitized.contains(#"<a href="https://example.com">site</a>"#))
	#expect(!sanitized.contains("<img"))
	#expect(!sanitized.contains("alert(1)</script>"))
	#expect(!sanitized.contains("javascript:"))
}
