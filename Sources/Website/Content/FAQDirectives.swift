import Foundation
import SiteKit

/**
The heading directives of the FAQ questions, like `<!-- @faq.keywords launch open -->` below a question. The feedback page uses them to suggest questions, and the app page uses ``Compares``.
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
	The other app or feature that the question compares the app with, like `<!-- @faq.compares iStat Menus -->` below “How is this different from iStat Menus?”. The app page links to each such question with a chip after the features (``AppPage``), so a visitor who already uses the other app finds the answer. When the name is the title of another of my active apps, the page of that app also has a chip, with the title of this app, unless it has its own question about this app. It is not for the feedback page.
	*/
	enum Compares: HeadingDirective {
		static let name: HeadingDirectiveName = "faq.compares"
		typealias Value = String

		/**
		The name, with the words of the directive, like “iStat Menus”. The chip shows it as it is written, so it is plain text (``PlainTextString``), and a word without a letter or a digit is a leftover, like the `-` of a comment that ends with `--->`. The renderer reports a directive without words.
		*/
		static func decode(values: [String]) throws(ContentError) -> String {
			for value in values where !value.contains(where: { $0.isLetter || $0.isNumber }) {
				throw ContentError(reason: "The name has “\(value)”, which is not a word. Remove it, and end the comment with `-->`.")
			}

			return try PlainTextString(validating: values.joined(separator: " ")).value
		}
	}

	/**
	The directives of the FAQ questions of all content files. The general FAQ page also has ``General``.
	*/
	static let all: [any HeadingDirective.Type] = [Keywords.self, Platforms.self, Pinned.self, Compares.self]
}

extension Heading {
	/**
	Whether the heading has a directive of the FAQ questions (``FAQDirectives/all``), like `@faq.keywords`.
	*/
	var hasFAQDirective: Bool {
		FAQDirectives.all.contains { contains($0) }
	}

	/**
	The keywords of a question that the feedback page suggests that have no effect (`@faq.keywords`): a keyword with a comma, as the keywords are separated by spaces, a keyword that is given twice, and a keyword that matches nothing more, as it is a stopword or shorter than three letters (``SuggestedQuestion/words(in:)``), or as the question already matches it and its synonyms: a word of the question or of its synonyms, or another form of one (``SuggestedQuestion/isForm(_:of:)``), like “sort” for “sorted”.
	*/
	var faqKeywordMistakes: [String] {
		let keywordsName = "`@\(FAQDirectives.Keywords.name)`"
		let questionWords = SuggestedQuestion.matchableWords(of: SuggestedQuestion.words(in: text))
		var seenKeywords = Set<String>()
		var mistakes = [String]()
		// In one message, as they need one fix.
		var matchedKeywords = [String]()

		for keyword in self[FAQDirectives.Keywords.self] ?? [] {
			let words = SuggestedQuestion.words(in: keyword)

			if keyword.contains(",") {
				mistakes.append("\(keywordsName) has “\(keyword)”. Separate the keywords with spaces, without commas.")
			} else if !seenKeywords.insert(keyword.lowercased()).inserted {
				mistakes.append("\(keywordsName) has “\(keyword)” twice.")
			} else if words.isEmpty {
				mistakes.append("\(keywordsName) has “\(keyword)”, which matches nothing, as it is a stopword or shorter than three letters.")
			} else if SuggestedQuestion.matchableWords(of: words).allSatisfy({ word in questionWords.contains { SuggestedQuestion.isForm(word, of: $0) } }) {
				matchedKeywords.append(keyword)
			}
		}

		if !matchedKeywords.isEmpty {
			mistakes.append("\(keywordsName) has \(matchedKeywords.map { "“\($0)”" }.formattedList(.and)), which the question already matches, as a word of the question, a synonym, or another form of one, like “sort” for “sorted”.")
		}

		return mistakes
	}
}
