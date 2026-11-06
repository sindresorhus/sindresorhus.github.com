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
	public let slug: ContentSlug

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
	Whether the frontmatter has `isDraft: true`, the key of the drafts of every content type (``ContentEntry/isDraft``), without decoding the rest, like for a path that `website check` gets, which loads no drafts. A frontmatter that is not valid SOML is not a draft, as decoding reports it.
	*/
	public var isDraft: Bool {
		guard case .document(let document) = parsedFrontmatter else {
			return false
		}

		return document.value[path: ["isDraft"]]?.boolValue == true
	}

	/**
	The line of the file where the body starts, starting at 1.
	*/
	public let bodyStartLine: SourceLocation.Line

	/**
	The lines of the body, the first at ``bodyStartLine``.
	*/
	public let bodyLines: [Substring]

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
		if let error = contents.windowsLineEndingError(file: url) {
			throw error
		}

		if let error = contents.conflictMarkerError(file: url) {
			throw error
		}

		self.url = url
		do {
			self.slug = try ContentSlug(validating: Self.slug(of: url, relativeTo: directory ?? url.deletingLastPathComponent()))
		} catch {
			throw ContentError(file: url, reason: error.reason)
		}

		// A byte order mark, which editors on Windows can add, is already removed when the file is read as UTF-8.
		let lines: [Substring]
		let closingIndex: Int?
		do {
			(lines, closingIndex) = try contents.frontmatterLines()
		} catch {
			throw ContentError(file: url, reason: error.reason)
		}

		guard let closingIndex else {
			self.frontmatter = ""
			self.parsedFrontmatter = ParsedFrontmatter(parsing: frontmatter)
			self.body = contents
			self.bodyLines = lines
			self.bodyStartLine = 1
			return
		}

		self.frontmatter = lines[1..<closingIndex].joined(separator: "\n")
		self.parsedFrontmatter = ParsedFrontmatter(parsing: frontmatter)
		let bodyLines = lines[(closingIndex + 1)...].drop { $0.isEmpty }
		self.body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .newlines)
		self.bodyLines = body.split(separator: "\n", omittingEmptySubsequences: false)
		self.bodyStartLine = SourceLocation.Line((bodyLines.startIndex - lines.startIndex) + 1)
	}

	/**
	Formats fenced SOML frontmatter, expanding containers and ordering the root properties by the given coding keys. Other keys keep their relative order after those keys. Comments and value spelling are preserved, and the Markdown body and fence lines stay byte-identical. Missing or blank frontmatter stays unchanged.
	*/
	public static func formattingFrontmatter(in contents: String, orderedKeys: [any CodingKey] = []) throws -> String {
		if let error = contents.windowsLineEndingError() {
			throw error
		}

		if let error = contents.conflictMarkerError() {
			throw error
		}

		let (lines, closingIndex) = try contents.frontmatterLines()

		guard let closingIndex else {
			return contents
		}

		let start = contents.index(after: lines[0].endIndex)
		let end = lines[closingIndex].startIndex
		let frontmatter = String(contents[start..<end])

		guard !frontmatter.allSatisfy(\.isWhitespace) else {
			return contents
		}

		do {
			let document = try SOML.Document(parsing: frontmatter)
			let formatted = try document.formatted(orderedKeys: orderedKeys.map(\.stringValue))
			return String(contents[..<start]) + formatted + contents[end...]
		} catch let error as SOML.ParseError {
			throw ContentError(line: lineInFile(ofFrontmatterLine: error.location.line), reason: error.readableMessage)
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
	Decodes and validates the frontmatter.
	*/
	public func decodeFrontmatter<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentErrors) -> Value {
		let document: SOML.Document

		switch parsedFrontmatter {
		case .document(let parsedDocument):
			document = parsedDocument
		case .error(let error):
			// The frontmatter starts on the line after the opening `---`.
			throw ContentErrors([ContentError(file: url, line: Self.lineInFile(ofFrontmatterLine: error.location.line), reason: error.readableMessage + apostropheHint(for: error))])
		}

		do {
			return try Value.decode(from: document.value, root: "frontmatter") { Self.line(ofValueAt: $0, in: document) }
		} catch {
			throw ContentErrors(converting: error, file: url)
		}
	}

	/**
	Decodes and validates the frontmatter, retaining it with this file so content and keyed diagnostics cannot use another model's values.
	*/
	public func decoded<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentErrors) -> DecodedMarkdownFile<Value> {
		try DecodedMarkdownFile(source: self, frontmatter: decodeFrontmatter(as: type))
	}

	/**
	Explains a straight apostrophe in a single-quoted string, like `'Sindre's app'`. It ends the string, so the parser only says that the letter after it is unexpected.
	*/
	private func apostropheHint(for error: SOML.ParseError) -> String {
		let utf8 = frontmatter.utf8

		guard
			error.kind == .unexpectedCharacterAfterValue,
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

	public func line(ofValueAt codingPath: [any CodingKey]) -> SourceLocation.Line? {
		guard case .document(let document) = parsedFrontmatter else {
			return nil
		}

		return Self.line(ofValueAt: codingPath, in: document)
	}

	private static func line(ofValueAt codingPath: [any CodingKey], in frontmatter: SOML.Document) -> SourceLocation.Line {
		// The frontmatter starts on the line after the opening `---`.
		lineInFile(ofFrontmatterLine: frontmatter.location(of: codingPath).line)
	}

	/**
	The line in the file of a line of the frontmatter, like 2 for its first line, as the frontmatter starts on the line after the opening `---`.
	*/
	public static func lineInFile(ofFrontmatterLine line: Int) -> SourceLocation.Line {
		SourceLocation.Line(line + 1)
	}

	/**
	The line in the file of parsed Markdown of the body.
	*/
	public func line(of markup: any Markup) -> SourceLocation.Line {
		bodyStartLine.offset(by: (markup.range?.lowerBound.line ?? 1) - 1)
	}
}

/**
A Markdown file with its decoded and validated frontmatter. Create it with ``MarkdownFile/decoded(as:)`` so its values and source always belong together.
*/
public struct DecodedMarkdownFile<Value: Frontmatter>: SOMLValueFile, Sendable {
	public let source: MarkdownFile
	public let frontmatter: Value

	fileprivate init(source: MarkdownFile, frontmatter: Value) {
		self.source = source
		self.frontmatter = frontmatter
	}

	public var url: URL {
		source.url
	}

	/**
	The original line of a frontmatter value, including the opening fence of the file.
	*/
	public func line(ofValueAt codingPath: [any CodingKey]) -> SourceLocation.Line? {
		source.line(ofValueAt: codingPath)
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

extension MarkdownFile {
	/**
	Parses the body with its original file and lines, keeping the tree, source, and options together for inspection and rendering.
	*/
	public func parsedMarkdown(options: MarkdownDocument.Options) -> ParsedMarkdown {
		ParsedMarkdown(parsing: body, file: url, firstLine: bodyStartLine, options: options)
	}
}

extension MarkdownDocument {
	/**
	Renders the body of a content file, and throws its problems, with their lines in the file.

	The lines of the headings and links are lines in the file too.
	*/
	public init(parsing file: MarkdownFile, options: Options) throws(ContentErrors) {
		self = try file.parsedMarkdown(options: options).rendered()
	}
}

/**
A mistake in the content, like an invalid frontmatter value or a broken link, with the file and line where it is.

Throw it for every content mistake, so all of them are reported the same way. A check that does not know the file, like ``ValidatedValue/init(validating:)``, leaves it out, and loading adds it.
*/
public struct ContentError: Error, CustomStringConvertible, LocalizedError {
	public var file: URL?

	/**
	The line in the file, starting at 1.
	*/
	public let line: SourceLocation.Line?

	public let reason: String

	public init(file: URL? = nil, line: SourceLocation.Line? = nil, reason: String) {
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

	public var errorDescription: String? {
		description
	}

	/**
	The mistake after where it is, like `content/apps/dato/index.md:12: …` (see ``SourceLocation/description``).
	*/
	public var description: String {
		guard let location = location?.description ?? line.map(\.description) else {
			return reason
		}

		return "\(location): \(reason)"
	}
}

/**
All the mistakes in the content, so they can be fixed at once.
*/
public struct ContentErrors: Error, CustomStringConvertible, LocalizedError {
	public let errors: [ContentError]

	/**
	Creates an aggregate of at least one mistake. An empty array represents successful validation, not an error.
	*/
	public init(_ errors: [ContentError]) {
		precondition(!errors.isEmpty, "Content errors must contain at least one mistake.")
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

	public var errorDescription: String? {
		description
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

extension String {
	/**
	The lines of a content file, and the index of the line of the closing `---` of the frontmatter, or `nil` when the file has no frontmatter. The loader and the formatter both use it, so they always find the same frontmatter.
	*/
	fileprivate func frontmatterLines() throws(ContentError) -> (lines: [Substring], closingIndex: Int?) {
		let lines = split(separator: "\n", omittingEmptySubsequences: false)

		guard lines.first?.isFrontmatterFence == true else {
			return (lines, nil)
		}

		guard let closingIndex = lines.dropFirst().firstIndex(where: \.isFrontmatterFence) else {
			throw ContentError(reason: "The frontmatter is missing its closing `---`.")
		}

		return (lines, closingIndex)
	}
}

/**
A validated content identity: lowercase letters, digits, and hyphens in each path component, like `dato` or `apps/faq`. Raw filename-derived strings are validated before they enter loaded content or references.
*/
public struct ContentSlug: PlainValidatedValue, Hashable, Sendable, Comparable, CustomStringConvertible, ExpressibleByStringLiteral, Encodable {
	public let value: String

	/**
	Checks a code-owned content slug. Use `init(validating:)` for external input.
	*/
	public init(_ value: String) {
		do {
			try self.init(validating: value)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Checks a literal content slug.
	*/
	public init(stringLiteral value: String) {
		self.init(value)
	}

	/**
	Validates the existing URL-safe content-name grammar.
	*/
	public init(validating value: String) throws(ContentError) {
		guard value.wholeMatch(of: Self.pattern) != nil else {
			throw ContentError(reason: "Must contain only lowercase letters, digits, and hyphens in each path component, got “\(value)”.")
		}

		self.value = value
	}

	/**
	A valid slug: lowercase letters, digits, and hyphens, in each component of the path, like `apps/faq`. Shared by loaded slugs and filename diagnostics.
	*/
	nonisolated(unsafe) static let pattern = /[a-z0-9-]+(?:\/[a-z0-9-]+)*/

	public var description: String {
		value
	}

	/**
	Orders slugs by their case-sensitive URL spelling.
	*/
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.value < rhs.value
	}
}
