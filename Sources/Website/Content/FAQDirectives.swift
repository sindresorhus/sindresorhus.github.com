import SiteKit

/**
The heading directives of the FAQ questions, like `<!-- @faq.keywords launch open -->` below a question. The feedback page uses them to suggest questions.
*/
enum FAQDirectives {
	/**
	Extra words that find the question, like `<!-- @faq.keywords launch open -->`.
	*/
	enum Keywords: HeadingDirective {
		static let name: HeadingDirectiveName = "faq.keywords"
		typealias Value = [String]
	}

	/**
	The platforms the question applies to, like `<!-- @faq.platforms macOS iOS -->`. Without it, the question applies to all apps.
	*/
	enum Platforms: HeadingDirective {
		static let name: HeadingDirectiveName = "faq.platforms"
		typealias Value = [Platform]
	}

	/**
	The place of the question among the questions that the feedback page suggests first, like `<!-- @faq.pinned 1 -->`. Lower ranks come first.
	*/
	enum Pinned: HeadingDirective {
		static let name: HeadingDirectiveName = "faq.pinned"
		typealias Value = Int
	}

	/**
	The question is useful for every app, so the feedback page suggests it for all apps, like `<!-- @faq.general -->`. Only the general FAQ page (`/apps/faq`) has it.
	*/
	enum General: HeadingDirective {
		static let name: HeadingDirectiveName = "faq.general"
		typealias Value = HeadingDirectiveFlag
	}

	/**
	The directives of the FAQ questions of all content files. The general FAQ page also has ``General``.
	*/
	static let all: [any HeadingDirective.Type] = [Keywords.self, Platforms.self, Pinned.self]
}

extension Heading {
	/**
	Whether the heading has a directive of the feedback page (``FAQDirectives/all``), like `@faq.keywords`.
	*/
	var hasFAQDirective: Bool {
		FAQDirectives.all.contains { contains($0) }
	}

	/**
	The keywords of a question that the feedback page suggests that have no effect (`@faq.keywords`): a keyword with a comma, as the keywords are separated by spaces, a keyword that is given twice, and a keyword that matches nothing more, as it is a word of the question, a stopword, or shorter than three letters (``SuggestedQuestion/words(in:)``).
	*/
	var faqKeywordMistakes: [String] {
		let keywordsName = "`@\(FAQDirectives.Keywords.name)`"
		let questionWords = Set(SuggestedQuestion.words(in: text))
		var seenKeywords = Set<String>()
		var mistakes = [String]()

		for keyword in self[FAQDirectives.Keywords.self] ?? [] {
			let words = SuggestedQuestion.words(in: keyword)

			if keyword.contains(",") {
				mistakes.append("\(keywordsName) has “\(keyword)”. Separate the keywords with spaces, without commas.")
			} else if !seenKeywords.insert(keyword.lowercased()).inserted {
				mistakes.append("\(keywordsName) has “\(keyword)” twice.")
			} else if words.isEmpty {
				mistakes.append("\(keywordsName) has “\(keyword)”, which matches nothing, as it is a stopword or shorter than three letters.")
			} else if words.allSatisfy(questionWords.contains) {
				mistakes.append("\(keywordsName) has “\(keyword)”, which is already a word of the question.")
			}
		}

		return mistakes
	}
}
