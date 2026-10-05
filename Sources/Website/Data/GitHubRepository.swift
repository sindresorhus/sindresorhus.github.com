import Foundation

struct GitHubRepository: Decodable, Sendable {
	let name: String
	let description: String?
	let url: URL
	let createdAt: Date
	let isArchived: Bool
	let isFork: Bool
	let stars: Int

	/**
	The description as plain text: without the notes in brackets, like “[Submissions are paused]”, without emoji, including GitHub emoji codes, like `:zap:`, and without the backticks of code, which GitHub shows as code.
	*/
	var summary: String? {
		guard let description else {
			return nil
		}

		let summary = String(description.filter { !$0.isEmoji })
			.replacing(/\[[^\]]*\]/, with: "")
			// A whole word, so the `:30:` in `12:30:45` stays.
			// TODO: Use a lookbehind, `(?<!\w)`, instead of capturing the character before the code, when Swift Regex supports lookbehinds.
			// Codes next to each other, like `:unicorn::sparkles:`, are one match, as the character before the second code is the colon of the first.
			.replacing(/(^|\W)(?::[a-z0-9_+-]+:)+(?!\w)/) { $0.output.1 }
			.replacing("`", with: "")
			.replacing(/\s+/, with: " ")
			.trimmingCharacters(in: .whitespaces)

		return summary.isEmpty ? nil : summary
	}

	enum CodingKeys: String, CodingKey {
		case name
		case description
		case url = "html_url"
		case createdAt = "created_at"
		case isArchived = "archived"
		case isFork = "fork"
		case stars = "stargazers_count"
	}
}

extension Character {
	/**
	Whether the character shows as an emoji, like “🚀” or “❤️”. Digits and text symbols like “#” and “©” are emoji only with the emoji variation selector.
	*/
	fileprivate var isEmoji: Bool {
		guard let first = unicodeScalars.first else {
			return false
		}

		// Symbols from the Miscellaneous Symbols block (U+2600) on, like ✏ and 🖍, show as emoji without the variation selector too. Before it are text symbols that Unicode also counts as emoji, like digits, “#”, “©”, and “™”.
		return first.properties.isEmojiPresentation || (first.properties.isEmoji && (first.value >= 0x2600 || unicodeScalars.contains("\u{FE0F}")))
	}
}
