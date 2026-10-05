import Foundation
import SiteKit

/**
A question that the feedback form suggests when the message is about it. The words to match are prepared here, so the script of ``FAQSuggestions`` only splits the message into words and scores the questions.
*/
struct SuggestedQuestion: Encodable {
	let question: String
	let url: LinkDestination

	/**
	The platforms the question applies to. All platforms when `nil`.
	*/
	let platforms: [Platform]?

	/**
	The place of the question among the questions that are suggested first. They need as many matching words as other questions.
	*/
	let pinnedRank: Int?

	/**
	The words of the question, for how rare a word is among the questions.
	*/
	let questionWords: [String]

	/**
	The words of the keywords and the synonyms that are not in ``questionWords``. Together, they are the words that a message can match.
	*/
	let extraWords: [String]

	init(question: String, url: LinkDestination, keywords: [String] = [], platforms: [Platform]? = nil, pinnedRank: Int? = nil) {
		self.question = question
		self.url = url
		self.platforms = platforms
		self.pinnedRank = pinnedRank
		let questionWords = Self.words(in: question)
		self.questionWords = questionWords

		var words = [String]()

		for word in questionWords + Self.words(in: keywords.joined(separator: " ")) {
			// A plural, like “images” or “crashes”, gets the synonyms of the singular.
			let singulars = word.hasSuffix("s") ? [String(word.dropLast()), word.hasSuffix("es") ? String(word.dropLast(2)) : nil].compactMap(\.self) : []
			let synonyms = Self.synonyms[word] ?? singulars.lazy.compactMap { Self.synonyms[$0] }.first ?? []

			for match in [word] + synonyms where !words.contains(match) {
				words.append(match)
			}
		}

		// Only the words that are not already in the question, so the page does not repeat them.
		self.extraWords = words.filter { !questionWords.contains($0) }
	}

	/**
	The words of the text that can match: lowercase, with at least three letters, and no stopwords. Apostrophes, straight and typographic, are removed first, so “doesn't” and “doesn’t” become “doesnt” instead of “doesn”.
	*/
	static func words(in text: String) -> [String] {
		text
			.lowercased()
			.replacing(/['’]/, with: "")
			.matches(of: /[a-z0-9_]{3,}/)
			.map { String($0.output) }
			.filter { !stopwords.contains($0) }
	}

	/**
	Common English words that carry no meaning for finding a support question, and the words that almost every question is about (“app”, “Mac”). With prefix matching, those would also match words like “apple”, “appearing”, and “macOS”.
	*/
	static let stopwords: Set<String> = [
		"ago", "all", "also", "and", "any", "app", "application", "apps", "are", "about", "after", "again", "back",
		"been", "being", "both", "but", "can",
		"come", "could", "day", "did", "does", "done", "each", "even", "ever", "every",
		"far", "feel", "few", "find", "first", "for", "from", "get", "give", "got",
		"had", "has", "have", "her", "here", "his", "how", "into", "its",
		"just", "keep", "know", "last", "let", "like", "look", "mac", "macos", "made", "make",
		"many", "may", "more", "most", "much", "need", "never", "new", "not", "now",
		"off", "often", "old", "onto", "other", "our", "over", "own",
		"please", "said", "same", "say", "see", "seem", "should", "since",
		"some", "still", "such", "take", "tell", "than", "that", "the",
		"their", "them", "then", "there", "these", "they", "thing", "think", "this", "those",
		"too", "try", "turn", "upon", "use", "used", "using", "very",
		"want", "was", "way", "were", "what", "when", "where", "which",
		"while", "who", "why", "will", "with", "would", "yet", "you", "your",
	]

	/**
	The words that a word also matches. In a group, every word matches the others. A one-way synonym only matches in its direction: a question about a “broken” app matches a message about a bug, but not the other way around.
	*/
	private static let synonyms: [String: [String]] = {
		let groups = [
			["icloud", "sync", "syncing"],
			["screen", "display", "monitor"],
			["crash", "freeze", "hang"],
			["delete", "remove"],
			["settings", "preferences"],
			["notification", "alert", "banner"],
			["shortcut", "hotkey"],
			["update", "upgrade"],
			["storage", "space"],
			["account", "profile"],
			["theme", "appearance"],
			["location", "gps"],
			["picture", "image", "photo"],
		]

		var synonyms = [
			"broken": ["bug", "error", "crash"],
			"slow": ["performance", "battery"],
			"buy": ["purchase", "subscription"],
			"stuck": ["freeze"],
			"wifi": ["network", "connection"],
			"password": ["authentication"],
		]

		for group in groups {
			for word in group {
				synonyms[word] = group.filter { $0 != word }
			}
		}

		return synonyms
	}()
}

extension SuggestedQuestion {
	/**
	A FAQ question, with the words, the platforms, and the pinned rank from the directives of its heading.
	*/
	init(_ heading: Heading, url: LinkDestination) {
		self.init(question: heading.text, url: url, keywords: heading.faqKeywords, platforms: heading.faqPlatforms, pinnedRank: heading.faqPinnedRank)
	}
}

extension Heading {
	/**
	Extra words that match the question (`<!-- @faq.keywords … -->`).
	*/
	fileprivate var faqKeywords: [String] {
		self[FAQDirectives.Keywords.self] ?? []
	}

	/**
	The platforms the question applies to (`<!-- @faq.platforms … -->`). All platforms when `nil`.
	*/
	fileprivate var faqPlatforms: [Platform]? {
		self[FAQDirectives.Platforms.self]?.nilIfEmpty
	}

	/**
	The place of the question among the questions that are suggested first (`<!-- @faq.pinned 1 -->`). Lower ranks come first.
	*/
	fileprivate var faqPinnedRank: Int? {
		self[FAQDirectives.Pinned.self]?.rank
	}
}
