import Foundation

struct GitHubRepository: Decodable {
	let name: String
	let description: String?
	let url: URL
	let createdAt: Date
	let isArchived: Bool
	let isFork: Bool
	let stars: Int

	/**
	The main language of the code, like `TypeScript`. `nil` for a repo without code, like a list of links.
	*/
	let language: String?

	/**
	The owner and the name, like `sindresorhus/ky`.
	*/
	var nameWithOwner: GitHubRepositoryName {
		GitHubRepositoryName(owner: url.deletingLastPathComponent().lastPathComponent, name: name)
	}

	/**
	The name to show, with the owner only when it is not the account, like `ky` or `chalk/chalk` (``GitHubRepositoryName/displayName``).
	*/
	var displayName: String {
		nameWithOwner.displayName
	}

	/**
	The description as plain text: without the notes in brackets, like “[Submissions are paused]”, without emoji, including GitHub emoji codes, like `:zap:`, and without the backticks of code, which GitHub shows as code.
	*/
	var summary: String? {
		guard let description else {
			return nil
		}

		let summary = String(description.filter { !$0.isEmoji })
			// One or more brackets, so a note in double brackets, like `[[Slow to reply]]`, is removed whole.
			.replacing(/\[+[^\]]*\]+/, with: "")
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
		case language
	}
}

/**
The owner and the name of a GitHub repo, like `sindresorhus/ky`. GitHub ignores their case, so equality does too, as the link of an npm package can have capitals, like `SindreSorhus/ky`.
*/
struct GitHubRepositoryName: Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
	/**
	The owner and the name in the link of an npm package, and the `.git` extension after the name. Not literals in ``init(npmRepositoryLink:)``, as Swift parses a regex literal each time the code runs, and it runs for each package.
	*/
	nonisolated(unsafe) private static let npmRepositoryPattern = /github\.com[\/:]([^\/]+)\/([^\/#?]+)/
	nonisolated(unsafe) private static let gitExtension = /\.git$/

	let owner: String
	let name: String

	init(owner: String, name: String) {
		self.owner = owner
		self.name = name
	}

	/**
	The repo of the owner and the name with a slash, like `sindresorhus/ky`. `nil` without exactly one slash between them.
	*/
	init?(nameWithOwner: String) {
		let parts = nameWithOwner.split(separator: "/", omittingEmptySubsequences: false)

		guard
			parts.count == 2,
			!parts[0].isEmpty,
			!parts[1].isEmpty
		else {
			return nil
		}

		self.init(owner: String(parts[0]), name: String(parts[1]))
	}

	init(stringLiteral value: String) {
		guard let repository = Self(nameWithOwner: value) else {
			preconditionFailure("A GitHub repo is an owner and a name, like `sindresorhus/ky`, got `\(value)`.")
		}

		self = repository
	}

	/**
	The repo in the link of an npm package, which can be written in several ways, like `git+https://github.com/owner/name.git`. `nil` for a link that is not to a GitHub repo.
	*/
	init?(npmRepositoryLink link: String) {
		guard let match = link.firstMatch(of: Self.npmRepositoryPattern) else {
			return nil
		}

		self.init(owner: String(match.1), name: String(match.2).replacing(Self.gitExtension, with: ""))
	}

	var description: String {
		"\(owner)/\(name)"
	}

	/**
	The name to show, with the owner only when it is not `sindresorhus`, like `ky` for `sindresorhus/ky`, or `chalk/chalk`.
	*/
	var displayName: String {
		owner.lowercased() == GitHub.account ? name : description
	}

	/**
	Whether the repo is of one of the ``GitHub/owners``, like `chalk/chalk`.
	*/
	var isOwners: Bool {
		GitHub.owners.contains(owner.lowercased())
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.owner.lowercased() == rhs.owner.lowercased()
			&& lhs.name.lowercased() == rhs.name.lowercased()
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(owner.lowercased())
		hasher.combine(name.lowercased())
	}
}

extension GitHubRepositoryName: Decodable {
	/**
	From a string like `sindresorhus/ky`, like the `nameWithOwner` of the GraphQL API.
	*/
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		guard let repository = Self(nameWithOwner: value) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "A GitHub repo is an owner and a name, like `sindresorhus/ky`, got `\(value)`.")
		}

		self = repository
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
