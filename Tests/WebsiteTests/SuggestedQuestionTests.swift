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
		let questions = FAQSuggestions.Questions(apps: content.maintainedApps, faq: content.page(.faq), guides: content.guides.map(\.guide))
		let source = try FAQSuggestions.script.source
		// Only the matching, without the custom element, which needs a page, and without the imports, which a script that is not a module cannot have.
		let matcherSource = source[..<(try #require(source.range(of: "class FAQSuggestions")).lowerBound)]
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		// The word rules that the script imports, as a function of the context, as a script that is not a module cannot export.
		let wordsSource = try String(contentsOf: Project.website.publicFile(#path("/scripts/words.js")), encoding: .utf8)
			.replacing("export function", with: "function")
		let context = try #require(JSContext())
		context.evaluateScript(wordsSource)
		context.evaluateScript(matcherSource)
		context.setObject(String(decoding: try JSONEncoder().encode(questions), as: UTF8.self), forKeyedSubscript: "data" as NSString)

		func suggestions(for message: String, app: String) -> [String] {
			context.setObject(message, forKeyedSubscript: "message" as NSString)
			context.setObject(app, forKeyedSubscript: "app" as NSString)
			return context.evaluateScript("(questions => questionMatcher(questions, questions.apps.find(candidate => candidate.title === app)))(JSON.parse(data))(message).map(question => question.url)")?.toArray() as? [String] ?? []
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
			(message: "Sync between my iPhone and iPad does not work", app: "Any Text", answer: "/apps/faq#icloud-sync"),
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

	/**
	The search of the site has the apps, the pages, the guides, the sections, the questions, the tips, and the open-source projects with their paths, and the real script of `SiteSearch` finds them with the word rules of the related help, run with JavaScriptCore, the engine of Safari.
	*/
	@Test
	func `the search finds the apps, the guides, and the questions`() async throws {
		let content = try await SiteContent.website
		let site = Site(content: content)
		let index = SiteSearch.Index(site: site)
		let entries = Dictionary(uniqueKeysWithValues: index.groups.map { group in (group.title, group.entries.map(\.url.description)) })

		#expect(entries["Guides"]?.contains("/guides/open-files-with-enter-finder-mac") == true)
		#expect(entries["Questions"]?.contains("/dato#missing-calendars") == true)
		#expect(entries["Questions"]?.contains("/apps/faq#refund") == true)
		// A question with the own answer of an app is there for each app, not only for the first app with the same question.
		#expect(entries["Questions"]?.contains("/dato#can-you-localize-the-app-into-my-language") == true)
		#expect(entries["Pages"]?.contains("/apps/discounts") == true)
		#expect(entries["Sections"]?.contains("/actions#url-scheme") == true)
		#expect(entries["Tips"]?.contains("/aiko#batch") == true)
		#expect(entries["Open Source"]?.contains("https://github.com/chalk/chalk") == true)
		// The questions and the tips are in their own groups, not in the sections.
		#expect(entries["Sections"]?.contains("/dato#missing-calendars") == false)
		#expect(entries["Sections"]?.contains("/aiko#batch") == false)

		let source = try SiteSearch.script.source
		// Only the matching, without the custom element, which needs a page, and without the imports, which a script that is not a module cannot have.
		let matcherSource = source[..<(try #require(source.range(of: "class SiteSearch")).lowerBound)]
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		// The modules without `export`, as a script that is not a module cannot have it.
		let moduleSources = try [#path("/scripts/words.js"), #path("/scripts/edit-distance.js")].map { path in
			try String(contentsOf: Project.website.publicFile(path), encoding: .utf8)
				.replacing("export function", with: "function")
				.replacing("export const", with: "const")
		}
		let context = try #require(JSContext())

		for moduleSource in moduleSources {
			context.evaluateScript(moduleSource)
		}

		context.evaluateScript(matcherSource)
		context.setObject(String(decoding: SiteSearch.index(for: site), as: UTF8.self), forKeyedSubscript: "data" as NSString)
		context.evaluateScript("const index = JSON.parse(data); const search = searchMatcher(index, {...wordMatcher(index), closest, searchKey});")

		func results(for query: String, in group: String, on page: String = "/") -> [String] {
			context.setObject(query, forKeyedSubscript: "query" as NSString)
			context.setObject(group, forKeyedSubscript: "group" as NSString)
			context.setObject(page, forKeyedSubscript: "page" as NSString)
			return context.evaluateScript("search(query, page).find(candidate => candidate.title === group)?.entries.map(entry => entry.url) ?? []")?.toArray() as? [String] ?? []
		}

		// A title that starts with the query comes first, also for a word that is too short to be a word of the index.
		#expect(results(for: "ai", in: "Apps").first == "/ai-actions", "\(results(for: "ai", in: "Apps"))")
		// The name of the app and another form of a word of the question, and the start of a word that the visitor is still typing.
		#expect(results(for: "dato missing calend", in: "Questions").contains("/dato#missing-calendars"))
		#expect(results(for: "open files enter", in: "Guides").contains("/guides/open-files-with-enter-finder-mac"))
		#expect(results(for: "zzzqqq", in: "Apps").isEmpty)
		for query in ["-", "+", "/", "..."] {
			context.setObject(query, forKeyedSubscript: "query" as NSString)
			#expect(context.evaluateScript("search(query, '/').length")?.toInt32() == 0, "\(query)")
		}
		// A whole match in the title of a later group is the top hit, before the app that only matches by its subtitle.
		#expect(results(for: "convert a video to a gif", in: "Top Hit") == ["/guides/convert-video-to-gif-mac"])
		// On an app page, its own questions come first in their group.
		#expect(results(for: "missing", in: "Questions", on: "/dato").first?.hasPrefix("/dato#") == true)
		// Without a match, the app with the closest name, for a word too short to correct.
		#expect(results(for: "daot", in: "App with the Closest Name") == ["/dato"])
		// A typo in a word of 5 or more letters is corrected to the closest word of the index, but not a word that the visitor is still typing.
		#expect(results(for: "calender", in: "Apps").contains("/menu-bar-calendar"))
		#expect(results(for: "gifksi", in: "Apps").first == "/gifski")
		// A name with a hyphen or a short part in any spelling.
		#expect(results(for: "p limit", in: "Top Hit") == ["https://github.com/sindresorhus/p-limit"])
		#expect(results(for: "ds store", in: "Apps").first == "/ds-store-inspector")
		#expect(results(for: "browser_default", in: "Guides").contains("/guides/change-default-browser-mac"))
		// A word with a short part is the joined word of the index, not its long part, so “e-mail” finds a title with only “email”.
		#expect(results(for: "e-mail", in: "Pages").contains("/guides/browsers-links-and-email"))
		// A word that the query does not have as it is, like a word without its apostrophe, is not corrected, as the text of the correction would not show it.
		context.setObject("calender's", forKeyedSubscript: "query" as NSString)
		#expect(context.evaluateScript("search(query, '/').some(group => group.correctedQuery !== undefined)")?.toBool() == false)
		// A correction is kept only when the corrected query matches, so “water” is not “later” in results of some of the words.
		context.setObject("remind me to drink water", forKeyedSubscript: "query" as NSString)
		#expect(context.evaluateScript("search(query, '/').some(group => group.correctedQuery !== undefined)")?.toBool() == false)
		// A joined name in a title is a title match, like a plain word, so “wifi” finds the guides with “Wi-Fi” in their titles first.
		#expect(results(for: "wifi", in: "Guides").first?.contains("wi-fi") == true, "\(results(for: "wifi", in: "Guides"))")
		// The marks in the titles allow a hyphen between the letters, like the joined words.
		#expect(context.evaluateScript("highlightPattern('wifi', ['wifi']).test('Wi-Fi') && highlightPattern('e-mail', ['email']).test('Email')")?.toBool() == true)
		// A question of the general FAQ also matches a query that names an app.
		#expect(results(for: "supercharge refund", in: "Questions").first == "/apps/faq#refund")
		#expect(results(for: "DS_Store Inspector refund", in: "Questions").contains("/apps/faq#refund"))
		// Search can open the FAQ section itself by its acronym or its full name, in either word order and with a typo.
		for query in ["velja faq", "faq for velja", "velja frequently asked questions", "vleja faq"] {
			context.setObject(query, forKeyedSubscript: "query" as NSString)
			#expect(context.evaluateScript("search(query, '/')[0]?.entries[0]?.url")?.toString() == "/velja#faq", "\(query)")
		}

		#expect(results(for: "faq for ai actions", in: "Sections", on: "/actions").first == "/ai-actions#faq")
		context.setObject("faq", forKeyedSubscript: "query" as NSString)
		#expect(context.evaluateScript("search(query, '/')[0]?.entries[0]?.url")?.toString() == "/apps/faq")
		// “Key” matches “Keys” more closely than “Keyboard”.
		#expect(results(for: "mac key keyboard", in: "Guides").first == "/guides/toggle-function-keys-shortcut-mac")
		// A guide by the name of its Terminal command, and the older versions by the number of a macOS version.
		#expect(results(for: "sips", in: "Guides").contains("/guides/convert-heic-to-jpg"))
		#expect(results(for: "macos 15", in: "Sections").first == "/apps/older-versions#macos-15")
		// All the words of a query in the title of a guide make it the top hit, before an app and a question that only have the words elsewhere or in a longer title.
		#expect(results(for: "change default browser", in: "Top Hit") == ["/guides/change-default-browser-mac"])
		// When no entry has all the words, the entries with the most of them.
		#expect(results(for: "screenshot location", in: "Guides").contains("/guides/change-screenshot-location-mac"))

		#expect(context.exception == nil, "\(context.exception?.toString() ?? "")")
	}
}
