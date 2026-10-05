import Foundation
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
	The path of a file relative to the directory, without the extension, like `apps/faq` for `apps/faq.md`. The `index.md` of a page bundle has the path of its directory, like `dato` for `dato/index.md`.
	*/
	public static func slug(of url: URL, relativeTo directory: URL) -> String {
		url.path(relativeTo: directory)
			.replacing(/\.[^.\/]+$/, with: "")
			.replacing(/\/index$/, with: "")
	}

	/**
	Decodes and validates the frontmatter.
	*/
	public func decodeFrontmatter<Value: Frontmatter>(as type: Value.Type = Value.self) throws(ContentError) -> Value {
		let document = try parseFrontmatter()

		do {
			let value = try SOML.Decoder.frontmatter.decode(Value.self, from: document.value)
			try value.validate()
			return value
		} catch let error as DecodingError {
			throw ContentError(file: url, line: frontmatterLine(of: error.codingPath, in: document), reason: error.readableDescription())
		} catch var error as ContentError {
			error.file = url
			throw error
		} catch {
			throw ContentError(file: url, reason: "\(error)")
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
	The line in the file of a top-level frontmatter key, like `script`, for a mistake in its value.
	*/
	public func line(ofFrontmatterKey key: String) -> Int? {
		guard let document = try? parseFrontmatter() else {
			return nil
		}

		return frontmatterLine(of: [AnyCodingKey(stringValue: key)], in: document)
	}

	/**
	The line in the file of the key or item at the coding path, or of the closest one that exists, like the parent of a missing key.
	*/
	private func frontmatterLine(of codingPath: [any CodingKey], in document: SOML.Document) -> Int {
		// The frontmatter starts on the line after the opening `---`.
		document.location(of: codingPath).line + 1
	}

	/**
	A line of the file as a location, like `content/apps/dato/index.md:12` (relative to the directory).
	*/
	public func location(ofLine line: Int?, relativeTo directory: URL) -> String {
		let path = url.path(relativeTo: directory)
		return line.map { "\(path):\($0)" } ?? path
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
			throw ContentErrors(problems.map { ContentError(file: file.url, line: $0.line, reason: $0.message) })
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
	The mistake after where it is, like `content/apps/dato/index.md:12: …`. The path is relative to the current directory when the file is in it, like the paths of the warnings of `website check`, else it is the full path.
	*/
	public var description: String {
		let path = file.map { file in
			file.isInside(.currentDirectory()) ? file.path(relativeTo: .currentDirectory()) : file.path(percentEncoded: false)
		}

		let location = [path, line.map(String.init)].compactMap(\.self).joined(separator: ":")
		return location.isEmpty ? reason : "\(location): \(reason)"
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
			[ContentError(reason: "\(error)")]
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

extension DecodingError {
	fileprivate var codingPath: [any CodingKey] {
		switch self {
		case .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			context.codingPath
		@unknown default:
			[]
		}
	}

	/**
	What is wrong, without the coding path, like `Cannot initialize Platform from invalid String value Amiga`.
	*/
	var reason: String {
		switch self {
		case .keyNotFound(let key, _):
			"Missing required key `\(key.stringValue)`."
		case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			context.debugDescription
		@unknown default:
			"\(self)"
		}
	}

	/**
	The mistake with the key path where it is, like “Invalid `links.Docs`: Must be an absolute URL”.

	- Parameter root: What the decoded value is, for a mistake at the top level, like `frontmatter`.
	*/
	func readableDescription(root: String = "frontmatter") -> String {
		func path(_ context: Context) -> String {
			let path = context.codingPath.map { key in
				key.intValue.map { "[\($0)]" } ?? key.stringValue
			}
			.joined(separator: ".")

			return path.isEmpty ? root : "`\(path)`"
		}

		switch self {
		case .keyNotFound(let key, let context):
			let parent = context.codingPath.isEmpty ? "" : " in \(path(context))"
			return "Missing required key `\(key.stringValue)`\(parent)."
		case .dataCorrupted(let context) where context.debugDescription.hasPrefix("Unknown key"):
			// The message names the key, and the line of the error is the line of the key. SOML leaves out the period, except after its question “Did you mean …?”.
			return context.debugDescription.hasSuffix("?") ? context.debugDescription : "\(context.debugDescription)."
		case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			return "Invalid \(path(context)): \(context.debugDescription)"
		@unknown default:
			return "\(self)"
		}
	}
}
