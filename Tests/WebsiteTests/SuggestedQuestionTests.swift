import Foundation
import JavaScriptCore
import SiteKit
import Testing
@testable import Website

struct SuggestedQuestionTests {
	@Test
	func `words are lowercase, at least three letters, and without stopwords or apostrophes`() {
		#expect(SuggestedQuestion.words(in: "Why doesn't the iCloud-sync work on my iPhone?") == ["doesnt", "icloud", "sync", "work", "iphone"])
		#expect(SuggestedQuestion.words(in: "The widget can’t load") == ["widget", "cant", "load"])
	}

	@Test
	func `words leave out “app” and “mac”, which almost every question has`() {
		#expect(SuggestedQuestion.words(in: "The Mac app does not show up in the macOS menu bar") == ["show", "menubar"])
		#expect(SuggestedQuestion.words(in: "Application settings for all apps") == ["settings"])
	}

	@Test
	func `question words leave out keywords and synonyms, which only the matching words have`() {
		let question = SuggestedQuestion(question: "iCloud sync stopped", url: .path(#path("/app"), fragment: "icloud"), keywords: ["backup"])

		#expect(question.questionWords == ["icloud", "sync", "stopped"])
		#expect(question.extraWords == ["syncing", "backup"])
	}

	/**
	A plural gets its singular and the synonyms of the singular, but a word that ends in “ss” is not a plural.
	*/
	@Test
	func `a plural gets its singular, but not a word that ends in “ss”`() {
		#expect(SuggestedQuestion(question: "The app quits", url: .path(#path("/a"))).extraWords == ["quit"])
		#expect(SuggestedQuestion(question: "Random crashes", url: .path(#path("/a"))).extraWords == ["crashe", "freeze", "hang"])
		#expect(SuggestedQuestion(question: "Full disk access", url: .path(#path("/a"))).extraWords.isEmpty)
	}

	@Test
	func `one-way synonyms only match in their direction`() {
		#expect(SuggestedQuestion(question: "The app is broken", url: .path(#path("/a"))).extraWords.contains("bug"))
		#expect(!SuggestedQuestion(question: "Found a bug", url: .path(#path("/b"))).extraWords.contains("broken"))
	}

	@Test
	func `every word of a synonym group matches the others`() {
		#expect(SuggestedQuestion(question: "Blurry display", url: .path(#path("/a"))).extraWords == ["screen", "monitor"])
		#expect(SuggestedQuestion(question: "Blurry monitor", url: .path(#path("/b"))).extraWords == ["screen", "display"])
	}

	@Test
	func `words keep digits and underscores, and a keyword that is in the question is not repeated`() {
		#expect(SuggestedQuestion.words(in: "Error 404 for .DS_Store on macOS 15") == ["error", "404", "ds_store"])
		#expect(SuggestedQuestion(question: "Export a video", url: .path(#path("/a")), keywords: ["video", "movie"]).extraWords == ["movie"])
	}

	@Test
	func `plurals get the synonyms of the singular`() {
		#expect(SuggestedQuestion(question: "The images are blurry", url: .path(#path("/a"))).extraWords.contains("photo"))
		#expect(SuggestedQuestion(question: "The app crashes", url: .path(#path("/b"))).extraWords.contains("freeze"))
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

		let pinned = SuggestedQuestion(headings[0], url: .path(#path("/apps/faq"), fragment: "refund"))
		#expect(pinned.extraWords == ["money"])
		#expect(pinned.platforms == [.macOS])
		#expect(pinned.pinnedRank == 2)

		let other = SuggestedQuestion(headings[1], url: .path(#path("/apps/faq"), fragment: "other"))
		#expect(other.platforms == nil)
		#expect(other.pinnedRank == nil)
	}

	/**
	The matching runs in the browser, so this runs the real script of `FAQSuggestions` with JavaScriptCore, the engine of Safari, on the real questions, with messages like the ones visitors write. A new synonym or keyword that pushes a good answer out of the first four fails it.
	*/
	@Test
	func `the script of the feedback page suggests the right answers for real messages`() async throws {
		let content = try await SiteContent.website
		let questions = FAQSuggestions.Questions(apps: content.maintainedApps, faq: content.page(.faq), guides: content.resolvedGuides.map(\.guide))
		let source = try FAQSuggestions.script.source
		// Only the matching, without the custom element, which needs a page, and without the imports, which a script that is not a module cannot have.
		let matcherSource = source[..<(try #require(source.range(of: "class FAQSuggestions")).lowerBound)]
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		let context = try #require(JSContext())
		context.evaluateScript(matcherSource)
		context.setObject(String(decoding: try JSONEncoder().encode(questions), as: UTF8.self), forKeyedSubscript: "data" as NSString)

		func suggestions(for message: String, app: String) -> [String] {
			context.setObject(message, forKeyedSubscript: "message" as NSString)
			context.setObject(app, forKeyedSubscript: "app" as NSString)
			return context.evaluateScript("questionMatcher(JSON.parse(data), app)(message).map(question => question.url)")?.toArray() as? [String] ?? []
		}

		let cases = [
			(message: "Dato does not show up in my menu bar anymore after updating", app: "Dato", answer: "#app-not-showing-in-menu-bar"),
			(message: "I bought the app by mistake and want a refund please", app: "Dato", answer: "/apps/faq#refund"),
			(message: "The week number shown is wrong, it says week 1 in December", app: "Dato", answer: "#december-week-1"),
			// The app has its own answer, which comes before the general one.
			(message: "How can I export my settings and move them to a new Mac?", app: "Velja", answer: "/velja#how-can-i-export-import-sync-transfer-or-back-up-the-settings"),
			// Other forms of a word match, like “quitting” for “quits”, and “updating” for “update”.
			(message: "The app keeps quitting by itself.", app: "Dato", answer: "#randomly-quits"),
			(message: "The widget is not updating", app: "Bare", answer: "#widget-not-updating"),
			// Two other forms of a word match each other, like “crashed” and “crashing”, and “worked” and “working”.
			(message: "the app crashed while I recorded", app: "Recordia", answer: "#recover"),
			(message: "AirDrop worked before but stopped", app: "Menu Drop", answer: "#airdrop-is-not-working"),
			// A guide about the app and a tip of the app are suggested like its questions.
			(message: "How do I make Finder open files when I press Enter, instead of renaming them?", app: "Supercharge", answer: "/guides/open-files-with-enter-finder-mac"),
			(message: "How can I batch transcribe a folder of audio files?", app: "Aiko", answer: "/aiko#batch"),
			(message: "Sync between my iPhone and iPad does not work", app: "Any Text", answer: "/any-text#troubleshoot-syncing"),
		]

		for (message, app, answer) in cases {
			let urls = suggestions(for: message, app: app)
			#expect(urls.contains { $0.contains(answer) }, "“\(message)” suggests \(urls), not \(answer).")
		}

		// The pinned menu bar question matches fewer words than the questions about the upcoming event, so they come first.
		let urls = suggestions(for: "The upcoming event in the menu bar shows the wrong meeting", app: "Dato")
		#expect(urls.first?.contains("upcoming-event") == true, "\(urls)")

		// A word that only has the same start is not another form of it, like “freezing” and “free”.
		let freezingURLs = suggestions(for: "The app keeps freezing.", app: "Dato")
		#expect(!freezingURLs.contains { $0.contains("#free-trial") }, "\(freezingURLs)")

		#expect(context.exception == nil, "\(context.exception?.toString() ?? "")")
	}
}
