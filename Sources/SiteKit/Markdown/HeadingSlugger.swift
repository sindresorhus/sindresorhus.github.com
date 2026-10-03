/**
Creates unique heading IDs the same way as GitHub (and `github-slugger`).

Each call with the same text returns a new ID, like `faq`, `faq-1`, `faq-2`.
*/
struct HeadingSlugger {
	private var occurrences = [String: Int]()

	mutating func slug(for text: String) -> String {
		let base = Self.slug(text)
		var result = base

		while let count = occurrences[base], occurrences[result] != nil {
			occurrences[base] = count + 1
			result = "\(base)-\(count + 1)"
		}

		occurrences[result] = 0
		return result
	}

	/**
	Lowercases the text, removes everything except letters, marks, digits, connector punctuation, spaces, and hyphens, then replaces spaces with hyphens.

	This works on Unicode scalars because a space followed by a combining mark (like an emoji variation selector) is a single `Character`.
	*/
	static func slug(_ text: String) -> String {
		let scalars = text.lowercased().unicodeScalars.compactMap { scalar -> Unicode.Scalar? in
			if scalar == " " {
				return "-"
			}

			return scalar.isKeptInSlug ? scalar : nil
		}

		return String(String.UnicodeScalarView(scalars))
	}
}

extension Unicode.Scalar {
	fileprivate var isKeptInSlug: Bool {
		if self == "-" || properties.isAlphabetic {
			return true
		}

		switch properties.generalCategory {
		case .nonspacingMark, .spacingMark, .enclosingMark, .decimalNumber, .connectorPunctuation:
			return true
		default:
			return false
		}
	}
}
