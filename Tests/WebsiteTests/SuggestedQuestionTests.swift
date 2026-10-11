import SiteKit
import Testing
@testable import Website

@Suite
struct SuggestedQuestionTests {
	@Test
	func `words are lowercase, at least three letters, and without stopwords or apostrophes`() {
		#expect(SuggestedQuestion.words(in: "Why doesn't the iCloud-sync work on my iPhone?") == ["doesnt", "icloud", "sync", "work", "iphone"])
		#expect(SuggestedQuestion.words(in: "The widget can’t load") == ["widget", "cant", "load"])
	}

	@Test
	func `words leave out “app” and “mac”, which almost every question has`() {
		#expect(SuggestedQuestion.words(in: "The Mac app does not show up in the macOS menu bar") == ["show", "menu", "bar"])
		#expect(SuggestedQuestion.words(in: "Application settings for all apps") == ["settings"])
	}

	@Test
	func `question words leave out keywords and synonyms, which only the matching words have`() {
		let question = SuggestedQuestion(question: "iCloud sync stopped", url: .path("/app", fragment: "icloud"), keywords: ["backup"])

		#expect(question.questionWords == ["icloud", "sync", "stopped"])
		#expect(question.extraWords == ["syncing", "backup"])
	}

	@Test
	func `one-way synonyms only match in their direction`() {
		#expect(SuggestedQuestion(question: "The app is broken", url: .path("/a")).extraWords.contains("bug"))
		#expect(!SuggestedQuestion(question: "Found a bug", url: .path("/b")).extraWords.contains("broken"))
	}

	@Test
	func `every word of a synonym group matches the others`() {
		#expect(SuggestedQuestion(question: "Wrong display", url: .path("/a")).extraWords == ["screen", "monitor"])
		#expect(SuggestedQuestion(question: "Wrong monitor", url: .path("/b")).extraWords == ["screen", "display"])
	}

	@Test
	func `words keep digits and underscores, and a keyword that is in the question is not repeated`() {
		#expect(SuggestedQuestion.words(in: "Error 404 for .DS_Store on macOS 15") == ["error", "404", "ds_store"])
		#expect(SuggestedQuestion(question: "Export a video", url: .path("/a"), keywords: ["video", "movie"]).extraWords == ["movie"])
	}

	@Test
	func `plurals get the synonyms of the singular`() {
		#expect(SuggestedQuestion(question: "The images are blurry", url: .path("/a")).extraWords.contains("photo"))
		#expect(SuggestedQuestion(question: "The app crashes", url: .path("/b")).extraWords.contains("freeze"))
	}

	@Test
	func `questions get their keywords, platforms, and pinned rank from the heading directives`() {
		let headings = MarkdownDocument(parsing: """
		### Refund {#refund}
		<!-- @faq.keywords money -->
		<!-- @faq.platforms macOS -->
		<!-- @faq.pinned 2 -->

		### Other {#other}
		""", options: .init(headingDirectives: FAQDirectives.all)).headings

		let pinned = SuggestedQuestion(headings[0], url: .path("/apps/faq", fragment: "refund"))
		#expect(pinned.extraWords == ["money"])
		#expect(pinned.platforms == [.macOS])
		#expect(pinned.pinnedRank == 2)

		let other = SuggestedQuestion(headings[1], url: .path("/apps/faq", fragment: "other"))
		#expect(other.platforms == nil)
		#expect(other.pinnedRank == nil)
	}
}
