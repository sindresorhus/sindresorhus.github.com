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
