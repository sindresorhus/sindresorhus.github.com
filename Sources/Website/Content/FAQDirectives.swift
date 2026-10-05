import SiteKit

/**
The heading directives of the FAQ questions, like `<!-- @faq.keywords launch open -->` below a question. The feedback page uses them to suggest questions.
*/
enum FAQDirectives {
	/**
	Extra words that find the question, like `<!-- @faq.keywords launch open -->`.
	*/
	enum Keywords: HeadingDirective {
		static let name = "faq.keywords"
		typealias Value = [String]
	}

	/**
	The platforms the question applies to, like `<!-- @faq.platforms macOS iOS -->`. Without it, the question applies to all apps.
	*/
	enum Platforms: HeadingDirective {
		static let name = "faq.platforms"
		typealias Value = [Platform]
	}

	/**
	The place of the question among the questions that the feedback page suggests first, like `<!-- @faq.pinned 1 -->`. Lower ranks come first.
	*/
	enum Pinned: HeadingDirective {
		static let name = "faq.pinned"

		struct Value: Decodable {
			let rank: Int

			init(from decoder: any Decoder) throws {
				var values = try decoder.unkeyedContainer()

				guard values.count == 1 else {
					throw DecodingError.dataCorruptedError(in: values, debugDescription: "It needs one rank, like `<!-- @faq.pinned 1 -->`.")
				}

				let text = try values.decode(String.self)

				guard let rank = Int(text) else {
					throw DecodingError.dataCorruptedError(in: values, debugDescription: "The rank must be a number, like `<!-- @faq.pinned 1 -->`, got “\(text)”.")
				}

				self.rank = rank
			}
		}
	}

	/**
	The question is useful for every app, so the feedback page suggests it for all apps, like `<!-- @faq.general -->`. Only the general FAQ page (`/apps/faq`) has it.
	*/
	enum General: HeadingDirective {
		static let name = "faq.general"
		typealias Value = HeadingDirectiveFlag
	}

	/**
	The directives of the FAQ questions of all content files. The general FAQ page also has ``General``.
	*/
	static let all: [any HeadingDirective.Type] = [Keywords.self, Platforms.self, Pinned.self]
}
