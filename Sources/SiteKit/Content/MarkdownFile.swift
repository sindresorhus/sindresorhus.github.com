import Foundation
import Markdown
import SOML

/**
A Markdown file split into its SOML frontmatter and body.
*/
public struct MarkdownFile: SOMLValueFile, Sendable {
	public let url: URL

	/**
	The path relative to the content directory without extension, like `dato` for `dato.md` or `apps/faq` for `apps/faq.md`. The `index.md` of a page bundle has the path of its directory, like `dato` for `dato/index.md`.
	*/
	public let slug: String

	/**
	The SOML between the `---` lines. Empty when the file has no frontmatter.
	*/
	public let frontmatter: String

	/**
	The parsed ``frontmatter``, read once for decoding and for the lines of its keys, or the mistake when it is not valid SOML, which decoding throws (``decodeFrontmatter(as:)``).
	*/
	private let parsedFrontmatter: ParsedFrontmatter

	/**
	The result of parsing the ``frontmatter``.
	*/
	private enum ParsedFrontmatter {
		case document(SOML.Document)
		case error(SOML.ParseError)

		init(parsing frontmatter: String) {
			do {
				// A frontmatter with only blank lines is empty too, but SOML needs a value.
				self = .document(try SOML.Document(parsing: frontmatter.allSatisfy(\.isWhitespace) ? "{}" : frontmatter))
			} catch {
				self = .error(error)
			}
		}
	}

	public let body: String

	/**
	The line of the file where the body starts, starting at 1.
	*/
	public let bodyStartLine: Int

	/**
	The lines of the body, the first at ``bodyStartLine``.
	*/
	public var bodyLines: [Substring] {
		body.split(separator: "\n", omittingEmptySubsequences: false)
	}

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
		self.slug = Self.slug(of: url, relativeTo: directory ?? url.deletingLastPathComponent())

		// A byte order mark, which editors on Windows can add, is already removed when the file is read as UTF-8.
		let contents = contents.normalizingWindowsLineEndings
		let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

		guard lines.first?.isFrontmatterFence == true else {
			self.frontmatter = ""
			self.parsedFrontmatter = ParsedFrontmatter(parsing: frontmatter)
			self.body = contents
			self.bodyStartLine = 1
			return
		}

		guard let closingIndex = lines.dropFirst().firstIndex(where: \.isFrontmatterFence) else {
			throw ContentError(file: url, reason: "The frontmatter is missing its closing `---`.")
		}

		self.frontmatter = lines[1..<closingIndex].joined(separator: "\n")
		self.parsedFrontmatter = ParsedFrontmatter(parsing: frontmatter)
		let bodyLines = lines[(closingIndex + 1)...].drop { $0.isEmpty }
		self.body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .newlines)
		self.bodyStartLine = (bodyLines.startIndex - lines.startIndex) + 1
	}

	/**
	Formats fenced SOML frontmatter, expanding containers and ordering the root properties by the given coding keys. Other keys keep their relative order after those keys. Comments and value spelling are preserved, and the Markdown body and fence lines stay byte-identical. Missing or blank frontmatter stays unchanged.
	*/
	public static func formattingFrontmatter(in contents: String, orderedKeys: [any CodingKey] = []) throws -> String {
		let lines = contents.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

		guard lines.first?.isFrontmatterFence == true else {
			return contents
		}

		guard let closingIndex = lines.dropFirst().firstIndex(where: \.isFrontmatterFence) else {
			throw ContentError(reason: "The frontmatter is missing its closing `---`.")
		}

		let start = contents.index(after: lines[0].endIndex)
		let end = lines[closingIndex].startIndex
		let frontmatter = String(contents[start..<end]).normalizingWindowsLineEndings

		guard !frontmatter.allSatisfy(\.isWhitespace) else {
			return contents
		}

		do {
			let document = try SOML.Document(parsing: frontmatter)
			let formatted = try document.formatted(orderedKeys: orderedKeys.map(\.stringValue))
			return String(contents[..<start]) + formatted + contents[end...]
		} catch let error as SOML.ParseError {
			throw ContentError(line: error.location.line + 1, reason: error.message)
		}
	}

	/**
	The path of a file relative to the directory, without the extension, like `apps/faq` for `apps/faq.md`. The `index.md` of a page bundle has the path of its directory, like `dato` for `dato/index.md`.
	*/
	public static func slug(of url: URL, relativeTo directory: URL) -> String {
		url.path(relativeTo: directory)
			.replacing(fileExtension, with: "")
			.replacing(indexComponent, with: "")
	}

	/**
	The extension of a file, and the `index` of a page bundle, after it. Not literals in ``slug(of:relativeTo:)``, as Swift parses a regex literal each time the code runs, and loading computes the slug of each file several times.
	*/
	nonisolated(unsafe) private static let fileExtension = /\.[^.\/]+$/
	nonisolated(unsafe) private static let indexComponent = /\/index$/

	/**
	A valid slug: lowercase letters, digits, and hyphens, in each component of the path, like `apps/faq`.
	*/
	nonisolated(unsafe) static let slugPattern = /[a-z0-9-]+(?:\/[a-z0-9-]+)*/

	/**
	Decodes and validates the frontmatter.
	*/
	public func decodeFrontmatter<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentErrors) -> Value {
		let document: SOML.Document

		switch parsedFrontmatter {
		case .document(let parsedDocument):
			document = parsedDocument
		case .error(let error):
			// The frontmatter starts on the line after the opening `---`.
			throw ContentErrors([ContentError(file: url, line: error.location.line + 1, reason: error.message + apostropheHint(for: error))])
		}

		do {
			return try Value.decode(from: document.value, root: "frontmatter") { Self.line(ofValueAt: $0, in: document) }
		} catch {
			throw ContentErrors(converting: error, file: url)
		}
	}

	/**
	Explains a straight apostrophe in a single-quoted string, like `'Sindre's app'`. It ends the string, so the parser only says that the letter after it is unexpected.
	*/
	private func apostropheHint(for error: SOML.ParseError) -> String {
		let utf8 = frontmatter.utf8

		guard
			error.message.hasSuffix(" after a value"),
			let index = utf8.index(utf8.startIndex, offsetBy: error.location.offset, limitedBy: utf8.endIndex),
			index != frontmatter.endIndex,
			frontmatter[index].isLetter,
			let quoteIndex = frontmatter.index(index, offsetBy: -1, limitedBy: frontmatter.startIndex),
			frontmatter[quoteIndex] == "'",
			let letterIndex = frontmatter.index(quoteIndex, offsetBy: -1, limitedBy: frontmatter.startIndex),
			frontmatter[letterIndex].isLetter
		else {
			return ""
		}

		return ". A straight apostrophe ends a single-quoted string, so write it as ’, like 'Sindre’s app'."
	}

	public func line(ofValueAt codingPath: [any CodingKey]) -> Int? {
		guard case .document(let document) = parsedFrontmatter else {
			return nil
		}

		return Self.line(ofValueAt: codingPath, in: document)
	}

	private static func line(ofValueAt codingPath: [any CodingKey], in frontmatter: SOML.Document) -> Int {
		// The frontmatter starts on the line after the opening `---`.
		frontmatter.location(of: codingPath).line + 1
	}

	/**
	The line in the file of parsed Markdown of the body.
	*/
	public func line(of markup: any Markup) -> Int {
		bodyStartLine + (markup.range?.lowerBound.line ?? 1) - 1
	}
}

extension SOML.Document {
	/**
	Formats frontmatter and orders its root properties with SOML's validated moves, which preserve scalar spelling and keep attached comments with their values. Nested property and item order stays unchanged. A document comment is separated from the first key by a blank line.
	*/
	fileprivate func formatted(orderedKeys: [String]) throws -> String {
		let formatted = formatted(expandingContainers: true)

		guard
			!orderedKeys.isEmpty,
			let object = value.objectValue,
			!object.isEmpty
		else {
			return formatted
		}

		let document = try Self(parsing: formatted)
		// Listed keys first in their editorial order, then the unlisted keys in their authored order.
		let keys = orderedKeys.filter { object.keys.contains($0) } + object.keys.filter { !orderedKeys.contains($0) }
		return try document.reordering(keys.map { SOML.KeyPath([.key($0)]) }).formatted(expandingContainers: true)
	}
}

extension MarkdownDocument {
	/**
	Renders a parsed content file and reports its mistakes at their original lines, without parsing it again.
	*/
	public init(rendering document: Document, of file: MarkdownFile, options: Options) throws(ContentErrors) {
		self.init(rendering: document, source: file.body, firstLine: file.bodyStartLine, options: options)
		try checkProblems(in: file)
	}

	/**
	Renders the body of a content file, and throws its problems, with their lines in the file.

	The lines of the headings and links are lines in the file too.
	*/
	public init(parsing file: MarkdownFile, options: Options) throws(ContentErrors) {
		self.init(parsing: file.body, firstLine: file.bodyStartLine, options: options)
		try checkProblems(in: file)
	}

	/**
	Reports rendered problems at their original lines in the content file.
	*/
	private func checkProblems(in file: MarkdownFile) throws(ContentErrors) {
		guard problems.isEmpty else {
			throw ContentErrors(problems.map { file.error(line: $0.line, $0.reason) })
		}
	}
}

/**
A mistake in the content, like an invalid frontmatter value or a broken link, with the file and line where it is.

Throw it for every content mistake, so all of them are reported the same way. A check that does not know the file, like ``ValidatedValue/init(validating:)``, leaves it out, and loading adds it.
*/
public struct ContentError: Error, CustomStringConvertible {
	public var file: URL?

	/**
	The line in the file, starting at 1.
	*/
	public let line: Int?

	public let reason: String

	public init(file: URL? = nil, line: Int? = nil, reason: String) {
		self.file = file
		self.line = line
		self.reason = reason
	}

	/**
	Orders diagnostics by optional file path and then optional line, preserving the order of ties.
	*/
	public static var locationOrder: [KeyPathComparator<Self>] {
		[KeyPathComparator(\.file?.path, comparator: String.StandardComparator.lexical), KeyPathComparator(\.line)]
	}

	/**
	The file and the line. `nil` when the file is not known, like in a check that does not know it.
	*/
	public var location: SourceLocation? {
		file.map { .file($0, line: line) }
	}

	/**
	The mistake after where it is, like `content/apps/dato/index.md:12: …` (see ``SourceLocation/description``).
	*/
	public var description: String {
		guard let location = location?.description ?? line.map(String.init) else {
			return reason
		}

		return "\(location): \(reason)"
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
	The content errors in any error, in the file unless they name another file. Other errors become an error of the file, so nothing is lost.
	*/
	public init(converting error: any Error, file: URL) {
		let errors = switch error {
		case let error as ContentErrors:
			error.errors
		case let error as ContentError:
			[error]
		default:
			// The localized description of a Foundation error, like a file error, is a sentence that names the file, without the details of the error. Swift errors keep their own description.
			[ContentError(reason: error.descriptiveMessage)]
		}

		self.init(errors.map { error in
			var error = error
			error.file = error.file ?? file
			return error
		})
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
