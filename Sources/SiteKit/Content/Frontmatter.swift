import Foundation
import SOML

/**
Makes a struct decode strictly from SOML frontmatter.

It generates `CodingKeys: CaseIterable` in declaration order and an initializer that uses the default value of a property when its key is missing. Explicit null is accepted only for optional properties, and stays `nil` even when the property has a default value. Rename a key with `@Key`, and check a value with a ``Validated`` property wrapper, like `@NonEmpty`. The struct needs at least one stored property, and every stored property needs a type annotation, a literal default value (`false`, `"text"`, `1`, `1.5`), or an empty initializer that names the type (`[String]()`).

```swift
@Frontmatter
struct PostFrontmatter {
	@NonEmpty var title: String
	@NonEmpty var description: String?
	var tags = [String]()
	@TrueOrAbsent var isDraft = false

	@Key("date")
	var publicationDate: SOML.Date
}
```

Limitation: A stored property supports one validation wrapper, optionally with `@Key`. The wrapper must be generic over its wrapped value and decode it, like the aliases of ``Validated``, written without generic arguments.
*/
@attached(member, names: named(CodingKeys), named(init(from:)))
@attached(extension, conformances: Frontmatter)
public macro Frontmatter() = #externalMacro(module: "SiteKitMacros", type: "FrontmatterMacro")

/**
The SOML key of a `@Frontmatter` property, when it differs from the property name.
*/
@attached(peer)
public macro Key(_ name: String) = #externalMacro(module: "SiteKitMacros", type: "KeyMacro")

/**
Typed frontmatter of a content file. Use the `@Frontmatter` macro to conform.

Decoding is strict: unknown keys are rejected (see `SOML.Decoder.frontmatter`), and ``validate(into:)`` checks the rules that types cannot express.
*/
public protocol Frontmatter: Decodable, Sendable {
	/**
	The keys of this model, so its validation cannot report a mistake at another model’s key. The `@Frontmatter` macro generates them in declaration order, including renamed keys.
	*/
	associatedtype CodingKeys: CodingKey & CaseIterable

	/**
	Checks requirements that the types cannot express, like two keys that need each other, and adds each mistake at the key of its value, so all of them are reported at once, each at its line.

	```swift
	func validate(into problems: inout FrontmatterProblems<Self>) {
		if platforms.isEmpty {
			problems.add("`platforms` must have at least one platform.", at: .platforms)
		}

		problems.validate(pressQuotes, at: .pressQuotes)
	}
	```

	It runs after decoding, and only for the decoded value, like the frontmatter of a file. A nested `@Frontmatter` value, like an item of a list, is checked by the value that contains it, with ``FrontmatterProblems/validate(_:at:)``, so its mistakes are at its key path, like `pressQuotes[2]`. It does not run during decoding, because then a failed check would hide an unknown key, which is often the cause, like a misspelled key.
	*/
	func validate(into problems: inout FrontmatterProblems<Self>)
}

extension Frontmatter {
	public func validate(into problems: inout FrontmatterProblems<Self>) {}

	/**
	Decodes and validates a value, like the frontmatter of a file, or the arguments of a Markdown directive.

	- Parameter root: What the value is, like `arguments`, for the messages.
	- Parameter line: The line of the key or item at the coding path of a decoding error, for the error.
	*/
	static func decode(from somlValue: SOML.Value, root: String, line: ([any CodingKey]) -> SourceLocation.Line? = { _ in nil }) throws(ContentErrors) -> Self {
		let value: Self

		do {
			value = try SOML.Decoder.frontmatter.decode(Self.self, from: somlValue)
		} catch let error as DecodingError {
			throw ContentErrors([error.misspelledKeyError(in: somlValue, line: line) ?? ContentError(line: line(error.codingPath), reason: error.readableDescription(root: root))])
		} catch {
			throw ContentErrors([ContentError(reason: "\(error)")])
		}

		var problems = FrontmatterProblems<Self>()
		value.validate(into: &problems)

		guard problems.all.isEmpty else {
			throw ContentErrors(problems.all.map { ContentError(line: line($0.codingPath), reason: $0.reason) })
		}

		return value
	}
}

/**
A SOML file of the content that is one value, like the settings of the whole site, decoded and validated like frontmatter (``Frontmatter``). It keeps the lines of its values, so a mistake that loading finds later, like a slug of an app that does not exist, is at its line too.

```swift
let settings = try SOMLFile<SiteSettings>(url: project.root.appending(path: "content/site.soml"))
```
*/
public struct SOMLFile<Value: Frontmatter>: SOMLValueFile, Sendable {
	public let url: URL
	public let value: Value
	private let document: SOML.Document

	/**
	Reads, decodes, and validates the file. All its mistakes are thrown together, with their lines.
	*/
	public init(url: URL) throws(ContentErrors) {
		self.url = url

		do {
			let contents = try String(contentsOf: url, encoding: .utf8)

			// Before the parser, whose error for a conflict marker is about a key.
			if let error = contents.conflictMarkerError(file: url) {
				throw ContentErrors([error])
			}

			self.document = try SOML.Document(parsing: contents)
		} catch let error as SOML.ParseError {
			throw ContentErrors([ContentError(file: url, line: SourceLocation.Line(error.location.line), reason: error.readableMessage)])
		} catch let errors as ContentErrors {
			throw errors
		} catch {
			throw ContentErrors([ContentError(file: url, reason: "Could not read the file: \(error.localizedDescription)")])
		}

		let document = document

		do {
			self.value = try Value.decode(from: document.value, root: "the file") { SourceLocation.Line(document.location(of: $0).line) }
		} catch {
			throw ContentErrors(converting: error, file: url)
		}
	}

	public func line(ofValueAt codingPath: [any CodingKey]) -> SourceLocation.Line? {
		SourceLocation.Line(document.location(of: codingPath).line)
	}
}

/**
A file with SOML values, like the frontmatter of a content file or `content/site.soml`, so an error or a warning can point at the line of a key, or of an item of its list, the same way in each kind of file.
*/
public protocol SOMLValueFile {
	var url: URL { get }

	/**
	The line in the file of the key or item at the coding path, or of the closest one that exists, like the parent of a missing key. `nil` when the file has no valid SOML, which decoding reports.
	*/
	func line(ofValueAt codingPath: [any CodingKey]) -> SourceLocation.Line?
}

extension SOMLValueFile {
	/**
	An error in the file, or at a line of it.
	*/
	public func error(line: SourceLocation.Line? = nil, _ reason: String) -> ContentError {
		ContentError(file: url, line: line, reason: reason)
	}

	/**
	A warning about the file, or a line of it.
	*/
	public func warning(_ kind: Warning.Kind, line: SourceLocation.Line? = nil, _ message: String) -> Warning {
		Warning(kind, at: .file(url, line: line), message)
	}
}

extension MarkdownFile {
	/**
	The line of the value of a top-level key, like `Frontmatter.CodingKeys.script`, or of an item of its list, like the third of `featuredApps` with `index: 2`. The raw file accepts any coding key; use a decoded file for model-typed lookup.
	*/
	public func line(of key: some CodingKey, index: Int? = nil) -> SourceLocation.Line? {
		line(ofValueAt: valuePath(of: key, index: index))
	}
}

extension DecodedMarkdownFile {
	/**
	The line of the value of a top-level key, like `Frontmatter.CodingKeys.script`, or of an item of its list, like the third of `featuredApps` with `index: 2`. Only keys of the decoded model are accepted, including renamed keys (`@Key`).
	*/
	public func line(of key: Value.CodingKeys, index: Int? = nil) -> SourceLocation.Line? {
		line(ofValueAt: valuePath(of: key, index: index))
	}

	/**
	An error at the line of the value of a top-level key, or of an item of its list, so the line and the file cannot be of different files.
	*/
	public func error(at key: Value.CodingKeys, index: Int? = nil, _ reason: String) -> ContentError {
		error(line: line(of: key, index: index), reason)
	}

	/**
	A warning at the line of the value of a top-level key, like `App.Frontmatter.CodingKeys.gumroad`, or of an item of its list, so the line and the file cannot be of different files.
	*/
	public func warning(_ kind: Warning.Kind, at key: Value.CodingKeys, index: Int? = nil, _ message: String) -> Warning {
		warning(kind, line: line(of: key, index: index), message)
	}
}

extension SOMLFile {
	/**
	The line of the value of a top-level key, like `Frontmatter.CodingKeys.script`, or of an item of its list, like the third of `featuredApps` with `index: 2`. Only keys of the decoded model are accepted, including renamed keys (`@Key`).
	*/
	public func line(of key: Value.CodingKeys, index: Int? = nil) -> SourceLocation.Line? {
		line(ofValueAt: valuePath(of: key, index: index))
	}

	/**
	An error at the line of the value of a top-level key, or of an item of its list, so the line and the file cannot be of different files.
	*/
	public func error(at key: Value.CodingKeys, index: Int? = nil, _ reason: String) -> ContentError {
		error(line: line(of: key, index: index), reason)
	}

	/**
	A warning at the line of the value of a top-level key, like `App.Frontmatter.CodingKeys.gumroad`, or of an item of its list, so the line and the file cannot be of different files.
	*/
	public func warning(_ kind: Warning.Kind, at key: Value.CodingKeys, index: Int? = nil, _ message: String) -> Warning {
		warning(kind, line: line(of: key, index: index), message)
	}
}

/**
The key path of the value of a key, or of an item of its list, like `featuredApps[2]`.
*/
private func valuePath(of key: some CodingKey, index: Int?) -> [any CodingKey] {
	[key] + (index.map { [AnyCodingKey(intValue: $0)] } ?? [])
}

/**
The mistakes that ``Frontmatter/validate(into:)`` finds, addressed by the keys of its model, each at the key path of its value, like `pressQuotes[2]`, so loading reports all of them, each at the line of its value.
*/
public struct FrontmatterProblems<Owner: Frontmatter> {
	struct Problem {
		let codingPath: [any CodingKey]
		let reason: String
	}

	private(set) var all = [Problem]()

	/**
	A mistake in the value of the key, like `problems.add("…", at: .platforms)`, or in an item of its list, like the second of `olderVersions` with `index: 1`.
	*/
	public mutating func add(_ reason: String, at key: Owner.CodingKeys, index: Int? = nil) {
		all.append(Problem(codingPath: valuePath(of: key, index: index), reason: reason))
	}

	/**
	A mistake at each item of a list that an earlier item already has, like “`apps` has `gifski` twice.”, at the line of the repeated item.
	*/
	public mutating func addRepeatedItems<Item: Hashable & CustomStringConvertible>(of items: [Item], at key: Owner.CodingKeys) {
		var seen = Set<Item>()

		for (index, item) in items.enumerated() where !seen.insert(item).inserted {
			add("`\(key.stringValue)` has `\(item)` twice.", at: key, index: index)
		}
	}

	/**
	Checks a nested value with its own rules, at its key path.
	*/
	public mutating func validate(_ value: (some Frontmatter)?, at key: Owner.CodingKeys) {
		validate(value, at: [key])
	}

	/**
	Checks each item of a list with its own rules, at its key path, like `pressQuotes[2]`.
	*/
	public mutating func validate(_ values: [some Frontmatter], at key: Owner.CodingKeys) {
		for (index, value) in values.enumerated() {
			validate(value, at: [key, AnyCodingKey(intValue: index)])
		}
	}

	/**
	The key path of the value that is checked, like `pressQuotes[2]` while an item of a list checks itself, is prepended to its own typed diagnostics.
	*/
	private mutating func validate<Value: Frontmatter>(_ value: Value?, at path: [any CodingKey]) {
		guard let value else {
			return
		}

		var problems = FrontmatterProblems<Value>()
		value.validate(into: &problems)
		all += problems.all.map { Problem(codingPath: path + $0.codingPath, reason: $0.reason) }
	}
}

/**
A string enum of the content, like a platform in the frontmatter, whose invalid value is a mistake that lists the valid values, like “Must be one of `macOS`, `iOS`, or `visionOS`, not “macos”.”, instead of the error of Swift, which names the type and not the values.
*/
public protocol ContentEnum: RawRepresentable<String>, CaseIterable, Decodable {}

extension ContentEnum {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		guard let match = Self(rawValue: value) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: Self.invalidValueReason(value))
		}

		self = match
	}

	/**
	The case of the value, for a value outside the frontmatter, like the language of a code block. An invalid value is a content error that lists the valid values.
	*/
	public init(validating value: String) throws(ContentError) {
		guard let match = Self(rawValue: value) else {
			throw ContentError(reason: Self.invalidValueReason(value))
		}

		self = match
	}

	private static func invalidValueReason(_ value: String) -> String {
		let values = allCases.map(\.rawValue)
		let suggestion = value.closest(in: values).map { " Did you mean `\($0)`?" } ?? ""
		return "Must be one of \(values.map { "`\($0)`" }.formattedList(.or)), not “\(value)”.\(suggestion)"
	}
}

extension SOML.ParseError {
	/**
	The message for the writer of the content, like “Duplicate key `title`.” for SOML’s “Duplicate key title”, with code marks and a period, like the other errors. Limitation: it does not name the line of the first key.
	*/
	var readableMessage: String {
		guard case .duplicateKey(let key) = kind else {
			return message
		}

		return "Duplicate key `\(key)`."
	}
}

extension DecodingError {
	var codingPath: [any CodingKey] {
		switch self {
		case .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
			context.codingPath
		@unknown default:
			[]
		}
	}

	/**
	What is wrong, without the coding path, like “Must be one of `macOS`, `iOS`, or `visionOS`, not “Amiga”.” (``ContentEnum``).
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
	func readableDescription(root: String) -> String {
		// Written like SOML writes key paths, like `platforms[0]` and `links.'Mac App Store'`.
		func path(_ context: Context) -> String {
			// A key path needs at least one key, so a mistake at the top level, like a frontmatter that is a list, names the root.
			guard !context.codingPath.isEmpty else {
				return root
			}

			return "`\(SOML.KeyPath(codingPath: context.codingPath))`"
		}

		switch self {
		case .keyNotFound(let key, let context):
			let parent = context.codingPath.isEmpty ? "" : " in \(path(context))"
			return "Missing required key `\(key.stringValue)`\(parent)."
		case .dataCorrupted(let context):
			// The message of SOML names the Swift type too, like “Unknown key titel, which TipsArguments does not read. Did you mean title?”, which the writer of the content does not know, so the message is made from the key and the suggestion. The line of the error is the line of the key.
			guard let error = context.underlyingError as? SOML.Decoder.UnknownKeyError else {
				return "Invalid \(path(context)): \(context.debugDescription)"
			}

			// The suggestion is the key in its canonical form, with quotes around a key that is not bare, which is what to write.
			return switch error.suggestion {
			case .closest(let key):
				"Unknown key `\(error.key)`. Did you mean `\(SOML.KeyPath([key]))`?"
			case .otherUnicodeScalars(let key):
				"Unknown key `\(error.key)`. It looks like `\(SOML.KeyPath([key]))`, but it is written with other Unicode characters, so it is another key. Type the key again."
			case nil:
				"Unknown key `\(error.key)`."
			}
		case .typeMismatch(_, let context), .valueNotFound(_, let context):
			return "Invalid \(path(context)): \(context.debugDescription)"
		@unknown default:
			return "\(self)"
		}
	}

	/**
	The error of a missing key that the value has misspelled, like `Subtitle` or `titel` for `subtitle` or `title`, at the line of the misspelled key, as the reader sees the key in the file and does not see why it is missing. The decoder reports the missing key before the unknown key, so without this, the same typo gets another message by the order of the keys. A key is misspelled when it is the same in another case, or else close to the missing key (``Swift/String/closest(in:)``), like the suggestion of an unknown key. A known key can be close to the missing key, like `subtitle` for a missing `title`, as the keys that a value reads are not known here, so the message asks instead of saying that the key is unknown.
	*/
	func misspelledKeyError(in value: SOML.Value, line: ([any CodingKey]) -> SourceLocation.Line?) -> ContentError? {
		guard
			case .keyNotFound(let key, let context) = self,
			// A key path needs at least one key, so a missing key at the top level is in the value itself.
			let keys = (context.codingPath.isEmpty ? value : value[path: SOML.KeyPath(codingPath: context.codingPath)])?.objectValue?.keys
		else {
			return nil
		}

		let missingKey = key.stringValue

		func error(at writtenKey: String, _ reason: String) -> ContentError {
			ContentError(line: line(context.codingPath + [AnyCodingKey(stringValue: writtenKey)]), reason: reason)
		}

		if let writtenKey = keys.first(where: { $0.caseInsensitiveCompare(missingKey) == .orderedSame }) {
			return error(at: writtenKey, "Unknown key `\(writtenKey)`. Keys are case-sensitive: `\(missingKey)`.")
		}

		guard let writtenKey = keys.first(where: { $0.closest(in: [missingKey]) != nil }) else {
			return nil
		}

		return error(at: writtenKey, "Missing key `\(missingKey)`. Is `\(writtenKey)` a misspelling of it?")
	}
}

extension SOML.KeyPath {
	/**
	The key path of a coding path, written like SOML writes key paths, like `platforms[0]` and `links.'Mac App Store'`.
	*/
	init(codingPath: [any CodingKey]) {
		self.init(codingPath.map { key in
			key.intValue.map(Segment.index) ?? .key(key.stringValue)
		})
	}
}

/**
A frontmatter value that is decoded from a simpler value and then checked, like a URL that must be absolute.

A failed check is a decoding error, so the message names the key path, and the line of the key.
*/
public protocol ValidatedValue: Decodable {
	associatedtype RawValue: Decodable

	/**
	Throws the reason when the value breaks the rule, like `Must not be empty.`
	*/
	init(validating rawValue: RawValue) throws(ContentError)
}

extension ValidatedValue {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(RawValue.self)

		do {
			try self.init(validating: rawValue)
		} catch {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: error.reason)
		}
	}
}

/**
A ``ValidatedValue`` with a plain value that a ``Validated`` property stores, like the `String` of a `NonEmptyString`.
*/
public protocol PlainValidatedValue: ValidatedValue {
	var value: RawValue { get }
}

extension PlainValidatedValue where Self: Encodable, RawValue: Encodable {
	/**
	Encodes the plain value as a scalar, like a slug as its string, matching frontmatter and script data.
	*/
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}
}

/**
A frontmatter property that is checked when it is decoded, and stores the plain value. Use it through its aliases, like `@NonEmpty var title: String` or `@Absolute var repositoryURL: URL?`.

The wrapper decodes a `Validation` value and stores its plain value, so an invalid value has the message and the line of its key. `@Frontmatter` decodes the wrapper of the non-optional type, so an optional property can be missing.

Validation applies only during decoding. Store a refined value such as `AbsoluteURL`, `NonEmptyString`, or `SafeInteger` directly when later code relies on its invariant, so assigning a new value cannot discard that validation.
*/
@propertyWrapper
public struct Validated<Validation: PlainValidatedValue, Value> {
	public var wrappedValue: Value

	public init(wrappedValue: Value) {
		self.wrappedValue = wrappedValue
	}
}

extension Validated: Sendable where Value: Sendable {}

extension Validated: Decodable where Value == Validation.RawValue {
	public init(from decoder: any Decoder) throws {
		self.init(wrappedValue: try Validation(from: decoder).value)
	}
}

/**
An absolute URL in frontmatter, like `https://github.com/sindresorhus/dato`.

Decoding throws for a relative URL, which is a common mistake in links.
*/
public struct AbsoluteURL: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible, Encodable {
	public let value: URL

	/**
	An absolute URL owned by the code. An invalid URL is a programmer error; decode authored URLs with the throwing initializer instead.
	*/
	public init(_ url: URL) {
		do {
			try self.init(validating: url)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	public init(validating url: URL) throws(ContentError) {
		guard
			let scheme = url.scheme,
			!scheme.isEmpty
		else {
			throw ContentError(reason: "Must be an absolute URL, got “\(url)”.")
		}

		self.value = url
	}

	public var description: String {
		value.absoluteString
	}
}

/**
An absolute URL in frontmatter, like `@Absolute var repositoryURL: URL?`. See ``AbsoluteURL``.
*/
public typealias Absolute<Value> = Validated<AbsoluteURL, Value>

/**
Text in frontmatter that is not empty or only whitespace, like a title, and has no whitespace at the start or the end, which is easy to paste and not visible in the editor, like `'Dato '`, which would make the title “Dato : …”.
*/
public struct NonEmptyString: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible, Encodable {
	public let value: String

	public init(validating value: String) throws(ContentError) {
		guard !value.allSatisfy(\.isWhitespace) else {
			throw ContentError(reason: "Must not be empty.")
		}

		guard
			value.first?.isWhitespace == false,
			value.last?.isWhitespace == false
		else {
			throw ContentError(reason: "Remove the space at the start or the end.")
		}

		self.value = value
	}

	public var description: String {
		value
	}
}

/**
Text in frontmatter that is not empty or only whitespace, like `@NonEmpty var title: String`.
*/
public typealias NonEmpty<Value> = Validated<NonEmptyString, Value>

/**
A flag in frontmatter that is written only when it is set, like `isDraft: true`. A `false` flag says the same as no flag, so it is a mistake, like the line that stays after a draft is published by changing `true` to `false`.
*/
public struct TrueFlag: PlainValidatedValue, Hashable, Sendable {
	public let value: Bool

	public init(validating value: Bool) throws(ContentError) {
		guard value else {
			throw ContentError(reason: "Remove the key. A flag is `true` or not there, and `false` is the same as no flag.")
		}

		self.value = value
	}
}

/**
A flag in frontmatter that is `true` or not there, like `@TrueOrAbsent var isDraft = false`, so the property is `false` only when the file does not have the key. See ``TrueFlag``.
*/
public typealias TrueOrAbsent<Value> = Validated<TrueFlag, Value>

/**
A positive integer in frontmatter that JavaScript can represent exactly (at most 2⁵³ − 1), like an App Store ID that a script reads.
*/
public struct SafeInteger: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible, Encodable {
	public let value: Int

	public init(validating value: Int) throws(ContentError) {
		guard (1...9_007_199_254_740_991).contains(value) else {
			throw ContentError(reason: "Must be a positive integer of at most 2⁵³ − 1, got \(value).")
		}

		self.value = value
	}

	public var description: String {
		String(value)
	}
}

/**
A positive integer in frontmatter that JavaScript can represent exactly, like `@JavaScriptSafe var downloadCount: Int?`. See ``SafeInteger``.
*/
public typealias JavaScriptSafe<Value> = Validated<SafeInteger, Value>

extension SOML.Decoder {
	/**
	The decoder for frontmatter. It rejects unknown keys, as a misspelled key would otherwise be silently ignored.
	*/
	static let frontmatter: Self = {
		var decoder = Self()
		decoder.rejectsUnknownKeys = true
		return decoder
	}()
}

extension Calendar {
	/**
	The Gregorian calendar in UTC and in the language of the site, so the year or the day of a date and the names of the weekdays do not depend on the build machine.
	*/
	public static let site: Self = {
		var calendar = Self(identifier: .gregorian)
		calendar.timeZone = .gmt
		calendar.locale = .site
		return calendar
	}()
}

/**
Bridges SOML calendar dates to Foundation dates for formatting and feeds. Frontmatter uses native date values, like `publicationDate: 2026-02-23`.
*/
extension SOML.Date {
	/**
	The day containing the Foundation date in UTC. Dates outside SOML's year range of 1 through 9999 are a programmer error.
	*/
	public init(_ date: Foundation.Date) {
		// Discard the fraction before bridging, so subnanosecond rounding cannot change the day.
		let wholeSecond = Foundation.Date(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate.rounded(.down))

		guard let instant = SOML.Instant(wholeSecond) else {
			preconditionFailure("The date must be within SOML's year range of 1 through 9999.")
		}

		let components = instant.components
		// The instant already validates these components, so a second date parser is unnecessary.
		self = Self(year: components.year, month: components.month, day: components.day)!
	}

	/**
	The calendar date at midnight UTC in the proleptic Gregorian calendar.
	*/
	public var foundationDate: Foundation.Date {
		// Every SOML date is a valid date component of an instant.
		SOML.Instant(year: year, month: month, day: day)!.date
	}
}

struct AnyCodingKey: CodingKey {
	let stringValue: String
	let intValue: Int?

	init(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}

	init(intValue: Int) {
		self.stringValue = String(intValue)
		self.intValue = intValue
	}
}
