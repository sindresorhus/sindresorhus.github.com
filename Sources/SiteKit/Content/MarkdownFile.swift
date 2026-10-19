import Foundation
import Markdown
import SOML

/**
A Markdown file split into its SOML frontmatter and body.
*/
public struct MarkdownFile: Sendable {
	public let url: URL

	/**
	The path relative to the content directory without extension, like `dato` for `dato.md` or `apps/faq` for `apps/faq.md`. The `index.md` of a page bundle has the path of its directory, like `dato` for `dato/index.md`.
	*/
	public let slug: String

	/**
	The SOML between the `---` lines. Empty when the file has no frontmatter.
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
		self.slug = Self.slug(of: url, relativeTo: directory ?? url.deletingLastPathComponent())

		// A byte order mark, which editors on Windows can add, is already removed when the file is read as UTF-8.
		let contents = contents.replacing("\r\n", with: "\n")
		let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

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
	public func decodeFrontmatter<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentError) -> Value {
		let document = try parseFrontmatter()

		do {
			return try Value.decode(from: document.value, root: "frontmatter") { frontmatterLine(of: $0, in: document) }
		} catch var error {
			error.file = url
			throw error
		}
	}

	private func parseFrontmatter() throws(ContentError) -> SOML.Document {
		do {
			// A frontmatter with only blank lines is empty too, but SOML needs a value.
			return try SOML.Document(parsing: frontmatter.allSatisfy(\.isWhitespace) ? "{}" : frontmatter)
		} catch {
			// The frontmatter starts on the line after the opening `---`.
			throw ContentError(file: url, line: error.location.line + 1, reason: error.message)
		}
	}

	/**
	The line in the file of a top-level frontmatter key, like `Frontmatter.CodingKeys.script`, for a mistake in its value. The key is a coding key of the frontmatter type, so a renamed key (`@Key`) cannot silently miss.
	*/
	public func line(of key: some CodingKey) -> Int? {
		guard let document = try? parseFrontmatter() else {
			return nil
		}

		return frontmatterLine(of: [key], in: document)
	}

	/**
	The line in the file of parsed Markdown of the body.
	*/
	public func line(of markup: any Markup) -> Int {
		bodyStartLine + (markup.range?.lowerBound.line ?? 1) - 1
	}

	/**
	The line in the file of the key or item at the coding path, or of the closest one that exists, like the parent of a missing key.
	*/
	private func frontmatterLine(of codingPath: [any CodingKey], in document: SOML.Document) -> Int {
		// The frontmatter starts on the line after the opening `---`.
		document.location(of: codingPath).line + 1
	}
}

extension URL {
	/**
	A line of the file as a location in a message, like `content/apps/dato/index.md:12`, or the file alone without a line. The path is relative to the current directory when the file is in it, else it is the full path. The site is built in its project root, so the paths are relative to the project, for the content errors, the warnings, and the broken links.
	*/
	public func location(ofLine line: Int?) -> String {
		let shownPath = isInside(.currentDirectory()) ? path(relativeTo: .currentDirectory()) : path(percentEncoded: false)
		return line.map { "\(shownPath):\($0)" } ?? shownPath
	}
}

extension MarkdownDocument {
	/**
	Renders the body of a content file, and throws its problems, with their lines in the file.

	The lines of the headings and links are lines in the file too.
	*/
	public init(parsing file: MarkdownFile, options: Options) throws(ContentErrors) {
		self.init(parsing: file.body, firstLine: file.bodyStartLine, options: options)

		guard problems.isEmpty else {
			throw ContentErrors(problems.map { ContentError(file: file.url, line: $0.line, reason: $0.reason) })
		}
	}
}

/**
A mistake in the content, like an invalid frontmatter value or a broken link, with the file and line where it is.

Throw it for every content mistake, so all of them are reported the same way. A check that does not know the file, like ``Frontmatter/validate()``, leaves it out, and loading adds it.
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
	The mistake after where it is, like `content/apps/dato/index.md:12: …` (see ``Foundation/URL/location(ofLine:)``).
	*/
	public var description: String {
		guard let location = file?.location(ofLine: line) ?? line.map(String.init) else {
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
