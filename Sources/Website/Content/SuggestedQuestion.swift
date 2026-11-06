import Foundation
import SiteKit

/**
A question that the feedback form suggests when the message is about it. The words to match are prepared here, so the script of ``FAQSuggestions`` only splits the message into words and scores the questions.
*/
struct SuggestedQuestion: Encodable {
	let question: String
	let url: LinkDestination

	/**
	What the link opens when it is not an answer of a FAQ, which the suggestion shows before its text, like “Guide: Open Files with Enter in Finder on Mac”.
	*/
	let label: Label?

	enum Label: String, Encodable {
		case guide = "Guide"
		case tip = "Tip"
	}

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
	The words of the keywords, the synonyms, and the words without their last “s”, like “quit” for “quits”, that are not in ``questionWords``. Together, they are the words that a message can match.
	*/
	let extraWords: [String]

	init(
		question: String,
		url: LinkDestination,
		label: Label? = nil,
		keywords: [String] = [],
		platforms: [Platform]? = nil,
		pinnedRank: Int? = nil
	) {
		self.question = question
		self.url = url
		self.label = label
		self.platforms = platforms
		self.pinnedRank = pinnedRank
		let questionWords = Self.words(in: question)
		self.questionWords = questionWords

		var words = [String]()
		var seenWords = Set<String>()

		for word in questionWords + Self.words(in: keywords.joined(separator: " ")) {
			// A plural, like “images” or “crashes”, gets the synonyms of the singular.
			let singulars = word.singulars
			let synonyms = Self.synonyms[word] ?? singulars.lazy.compactMap { Self.synonyms[$0] }.first ?? []

			// A plural, like “quits”, also gets the word without the “s”, so its other forms match, like “quitting”.
			for match in [word] + singulars.prefix(1) + synonyms where seenWords.insert(match).inserted {
				words.append(match)
			}
		}

		// Only the words that are not already in the question, so the page does not repeat them.
		let questionWordSet = Set(questionWords)
		self.extraWords = words.filter { !questionWordSet.contains($0) }
	}

	/**
	The words of the text that can match: lowercase, with at least three letters, and no stopwords. Apostrophes, straight and typographic, are removed first, so “doesn't” and “doesn’t” become “doesnt” instead of “doesn”. “Menu bar” is one word, “menubar”, as many questions are about the menu bar, and its two words would be the two matching words that a question needs. The script of ``FAQSuggestions`` does the same with the message.
	*/
	static func words(in text: String) -> [String] {
		text
			.lowercased()
			.replacing(apostrophe, with: "")
			.replacing(menuBar, with: "menubar")
			.matches(of: word)
			.map { String($0.output) }
			.filter { !stopwords.contains($0) }
	}

	/**
	The apostrophes, the menu bar, and the words for ``words(in:)``. Not literals in the function, as Swift parses a regex literal each time the code runs, and it runs for each question.
	*/
	nonisolated(unsafe) private static let apostrophe = /['’]/
	nonisolated(unsafe) private static let menuBar = /\bmenu\s+bar/
	nonisolated(unsafe) private static let word = /[a-z0-9_]{3,}/

	/**
	Common English words that carry no meaning for finding a support question, and the words that almost every question is about (“app”, “Mac”). With prefix matching, those would also match words like “apple”, “appearing”, and “macOS”.
	*/
	static let stopwords: Set = [
		"ago", "all", "also", "and", "any", "app", "application", "apps", "are", "about", "after", "again", "back",
		"been", "being", "both", "but", "can",
		"come", "could", "day", "did", "does", "done", "each", "even", "ever", "every",
		"far", "feel", "few", "find", "first", "for", "from", "get", "give", "got",
		"had", "has", "have", "her", "here", "his", "how", "into", "its",
		"just", "keep", "know", "last", "let", "like", "look", "mac", "macos", "made", "make",
		"many", "may", "more", "most", "much", "need", "never", "new", "not", "now",
		"off", "often", "old", "onto", "other", "our", "over", "own", "past",
		"please", "quite", "said", "same", "say", "says", "see", "seem", "should", "since",
		"some", "still", "such", "take", "tell", "than", "that", "the",
		"their", "them", "then", "there", "these", "they", "thing", "think", "this", "those",
		"too", "try", "turn", "upon", "use", "used", "uses", "using", "very",
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
			["missing", "disappear", "gone"],
			["wrong", "incorrect"],
			["order", "sort", "reorder", "rearrange"],
			["share", "sharing", "collaborate"],
			["suggestion", "autocomplete"],
			["quantity", "amount"],
			["haptic", "vibration", "vibrate"],
			["internet", "online", "offline"],
		]

		var synonyms = [
			"broken": ["bug", "error", "crash"],
			"slow": ["performance", "battery"],
			"buy": ["purchase", "subscription"],
			// A widget that is stuck or needs a refresh does not update.
			"stuck": ["freeze", "update"],
			"refresh": ["update"],
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
	A FAQ question, with the words, the platforms, and the pinned rank from the directives of its heading. Also a tip of an app (``App/tipHeadings``), with its label.
	*/
	init(_ heading: Heading, url: LinkDestination, label: Label? = nil) {
		self.init(
			question: heading.text,
			url: url,
			label: label,
			keywords: heading[FAQDirectives.Keywords.self] ?? [],
			platforms: heading[FAQDirectives.Platforms.self]?.nilIfEmpty,
			pinnedRank: heading[FAQDirectives.Pinned.self]
		)
	}
}

extension SuggestedQuestion {
	/**
	A guide, as a suggestion for the apps that it is about: its title without “How to”, as the label already says that it is a guide.
	*/
	init(_ guide: Guide) {
		self.init(
			question: String(guide.frontmatter.title.trimmingPrefix("How to ")),
			url: .path(guide.path),
			label: .guide
		)
	}
}

extension String {
	/**
	The word without the ending of a plural, like “image” for “images”, and “crashe” and “crash” for “crashes”, as a plural can end in “s” or “es”. Empty for a word that is not a plural: one without an “s” at the end, one that ends in “ss”, like “access”, or a word of 3 letters or fewer, like “bus”.
	*/
	fileprivate var singulars: [String] {
		guard
			count > 3,
			hasSuffix("s"),
			!hasSuffix("ss")
		else {
			return []
		}

		return hasSuffix("es") ? [String(dropLast()), String(dropLast(2))] : [String(dropLast())]
	}
}
