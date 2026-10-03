import Foundation
import Yams

/**
A Markdown file split into its YAML frontmatter and body.
*/
public struct MarkdownFile: Sendable {
	public let url: URL

	/**
	The path relative to the content directory without extension, like `dato` for `dato.md` or `apps/faq` for `apps/faq.md`.
	*/
	public let slug: String

	/**
	The YAML between the `---` lines. Empty when the file has no frontmatter.
	*/
	public let frontmatter: String

	public let body: String

	/**
	The line of the file where the body starts, starting at 1.
	*/
	public let bodyStartLine: Int

	/**
	When a commit last changed the file. `nil` outside a git repository and for files without commits.
	*/
	public var lastCommitDate: Date?

	/**
	- Parameter directory: The directory the slug is relative to. Defaults to the directory of the file.
	*/
	public init(url: URL, relativeTo directory: URL? = nil) throws(ContentError) {
		let contents: String

		do {
			contents = try String(contentsOf: url, encoding: .utf8)
		} catch {
			throw ContentError(file: url, reason: "Could not read the file: \(error.localizedDescription)")
		}

		try self.init(contents: contents, url: url, relativeTo: directory)
	}

	public init(contents: String, url: URL, relativeTo directory: URL? = nil) throws(ContentError) {
		self.url = url
		self.slug = url.path(relativeTo: directory ?? url.deletingLastPathComponent()).replacing(/\.[^.\/]+$/, with: "")

		// Editors on Windows can add a byte order mark.
		let contents = contents.unicodeScalars.first == "\u{FEFF}" ? String(contents.unicodeScalars.dropFirst()) : contents
		let lines = contents.replacing("\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false)

		guard lines.first?.isFrontmatterFence == true else {
			self.frontmatter = ""
			self.body = contents
			self.bodyStartLine = 1
			return
		}

		guard let closingIndex = lines.dropFirst().firstIndex(where: \.isFrontmatterFence) else {
			throw ContentError(file: url, reason: "The frontmatter is missing its closing `---`.")
		}

		self.frontmatter = lines[1..<closingIndex].joined(separator: "\n")
		let bodyLines = lines[(closingIndex + 1)...].drop { $0.isEmpty }
		self.body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .newlines)
		self.bodyStartLine = (bodyLines.startIndex - lines.startIndex) + 1
	}

	/**
	Decodes and validates the frontmatter.
	*/
	public func decodeFrontmatter<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentError) -> Value {
		try checkDays()

		do {
			let value = try YAMLDecoder().decode(Value.self, from: frontmatter.isEmpty ? "{}" : frontmatter)
			try value.validate()
			return value
		} catch let error as DecodingError {
			throw ContentError(file: url, line: frontmatterLine(of: error.codingPath), reason: error.readableDescription)
		} catch {
			throw ContentError(file: url, reason: "\(error)")
		}
	}

	/**
	YAML turns an impossible day, like `2026-02-30`, into a later day without an error, so the days of the top-level values are checked against the calendar.
	*/
	private func checkDays() throws(ContentError) {
		guard let mapping = (try? Yams.compose(yaml: frontmatter))?.mapping else {
			return
		}

		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = .gmt

		for (key, value) in mapping {
			guard
				let text = value.string,
				let match = text.prefixMatch(of: /(\d{4})-(\d{2})-(\d{2})/),
				let year = Int(match.1),
				let month = Int(match.2),
				let day = Int(match.3)
			else {
				continue
			}

			let components = DateComponents(year: year, month: month, day: day)

			guard
				let date = calendar.date(from: components),
				calendar.dateComponents([.year, .month, .day], from: date) == components
			else {
				throw ContentError(file: url, line: key.mark.map { $0.line + 1 }, reason: "`\(key.string ?? "")` is not a real day: \(text)")
			}
		}
	}

	/**
	The line in the file of the key or item at the coding path, or of the closest container that exists, like the mapping of a missing key.
	*/
	private func frontmatterLine(of codingPath: [any CodingKey]) -> Int? {
		guard var node = try? Yams.compose(yaml: frontmatter) else {
			return nil
		}

		var line = node.mark?.line

		for key in codingPath {
			if let index = key.intValue {
				guard
					let sequence = node.sequence,
					index < sequence.count
				else {
					break
				}

				node = sequence[index]
				line = node.mark?.line
			} else {
				guard let (keyNode, value) = node.mapping?.first(where: { $0.key.string == key.stringValue }) else {
					break
				}

				node = value
				line = keyNode.mark?.line
			}
		}

		// The YAML starts on the line after the opening `---`.
		return line.map { $0 + 1 }
	}

	/**
	A line of the body as a location in the file, like `content/apps/dato.md:12` (relative to the directory).
	*/
	public func location(ofBodyLine line: Int?, relativeTo directory: URL) -> String {
		let path = url.path(relativeTo: directory)
		return line.map { "\(path):\($0 + bodyStartLine - 1)" } ?? path
	}

	/**
	Throws the problems of the Markdown of the body, with their lines in the file.
	*/
	public func validate(_ document: MarkdownDocument) throws(ContentErrors) {
		guard !document.problems.isEmpty else {
			return
		}

		throw ContentErrors(document.problems.map { problem in
			ContentError(file: url, line: problem.line.map { $0 + bodyStartLine - 1 }, reason: problem.message)
		})
	}
}

/**
A content file that could not be loaded, or a mistake in it.
*/
public struct ContentError: Error, CustomStringConvertible {
	public let file: URL

	/**
	The line in the file, starting at 1.
	*/
	public let line: Int?

	public let reason: String

	public init(file: URL, line: Int? = nil, reason: String) {
		self.file = file
		self.line = line
		self.reason = reason
	}

	public var description: String {
		"\(file.path(percentEncoded: false))\(line.map { ":\($0)" } ?? ""): \(reason)"
	}
}

/**
All the mistakes in the content, so they can be fixed at once.
*/
public struct ContentErrors: Error, CustomStringConvertible {
	public let errors: [ContentError]

	public init(_ errors: [ContentError]) {
		self.errors = errors
	}

	/**
	The content errors in any error. Other errors become an error of the file, so nothing is lost.
	*/
	public init(converting error: any Error, file: URL) {
		switch error {
		case let error as ContentErrors:
			self = error
		case let error as ContentError:
			self.init([error])
		default:
			self.init([ContentError(file: file, reason: "\(error)")])
		}
	}

	public var description: String {
		errors.map(\.description).joined(separator: "\n")
	}
}

extension Substring {
	/**
	A `---` line. Trailing whitespace is allowed, as it is invisible in editors.
	*/
	fileprivate var isFrontmatterFence: Bool {
		hasPrefix("---") && dropFirst(3).allSatisfy(\.isWhitespace)
	}
}

extension DecodingError {
	fileprivate var codingPath: [any CodingKey] {
		switch self {
		case .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			context.codingPath
		@unknown default:
			[]
		}
	}

	fileprivate var readableDescription: String {
		func path(_ context: Context, droppingLast: Bool = false) -> String {
			let path = context.codingPath.dropLast(droppingLast ? 1 : 0).map { key in
				key.intValue.map { "[\($0)]" } ?? key.stringValue
			}
			.joined(separator: ".")

			return path.isEmpty ? "frontmatter" : "`\(path)`"
		}

		switch self {
		case .keyNotFound(let key, let context):
			let parent = context.codingPath.isEmpty ? "" : " in \(path(context))"
			return "Missing required key `\(key.stringValue)`\(parent)."
		case .dataCorrupted(let context) where context.debugDescription.hasPrefix("Unknown key"):
			// The path ends at the unknown key, for the line number.
			return "\(context.debugDescription) in \(path(context, droppingLast: true))."
		case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			return "Invalid \(path(context)): \(context.debugDescription)"
		@unknown default:
			return "\(self)"
		}
	}
}
