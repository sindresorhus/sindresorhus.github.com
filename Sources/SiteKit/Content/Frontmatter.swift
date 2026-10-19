import Foundation
import SOML

/**
Makes a struct decode strictly from SOML frontmatter.

It generates the coding keys and an initializer that uses the default value of a property when its key is missing. Rename a key with `@Key`, and check a value with a ``Validated`` property wrapper, like `@NonEmpty`. The struct needs at least one stored property, and every stored property needs a type annotation, a literal default value (`false`, `"text"`, `1`, `1.5`), or an empty initializer that names the type (`[String]()`).

```swift
@Frontmatter
struct PostFrontmatter {
	@NonEmpty var title: String
	@NonEmpty var description: String?
	var tags = [String]()
	var isDraft = false

	@Key("date")
	@CalendarDay var publicationDate: Date
}
```

Limitation: Every attribute of a stored property, other than `@Key`, must be a property wrapper that is generic over its wrapped value and decodes it, like the aliases of ``Validated``, written without generic arguments.
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

Decoding is strict: unknown keys are rejected (see `SOML.Decoder.frontmatter`), and ``validate()`` checks the rules that types cannot express.
*/
public protocol Frontmatter: Decodable, Sendable {
	/**
	Checks requirements that the types cannot express, like two keys that need each other.

	It runs after decoding, and only for the decoded value, like the frontmatter of a file, not for the values in it: decoding does not call it for a nested `@Frontmatter` value, like an item of a list, so the type that contains the value checks it. It does not run during decoding, because then a failed check would hide an unknown key, which is often the cause, like a misspelled key.
	*/
	func validate() throws(ContentError)
}

extension Frontmatter {
	public func validate() throws(ContentError) {}

	/**
	Decodes and validates a value, like the frontmatter of a file, or the arguments of a Markdown directive.

	- Parameter root: What the value is, like `arguments`, for the messages.
	- Parameter line: The line of the key or item at the coding path of a decoding error, for the error.
	*/
	static func decode(from somlValue: SOML.Value, root: String, line: ([any CodingKey]) -> Int? = { _ in nil }) throws(ContentError) -> Self {
		let value: Self

		do {
			value = try SOML.Decoder.frontmatter.decode(Self.self, from: somlValue)
		} catch let error as DecodingError {
			throw ContentError(line: line(error.codingPath), reason: error.readableDescription(root: root))
		} catch {
			throw ContentError(reason: "\(error)")
		}

		try value.validate()
		return value
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
	func readableDescription(root: String) -> String {
		// Written like SOML writes key paths, like `platforms[0]` and `links.'Mac App Store'`.
		func path(_ context: Context) -> String {
			// A key path needs at least one key, so a mistake at the top level, like a frontmatter that is a list, names the root.
			guard !context.codingPath.isEmpty else {
				return root
			}

			let path = SOML.KeyPath(context.codingPath.map { key in
				key.intValue.map(SOML.KeyPath.Segment.index) ?? .key(key.stringValue)
			})

			return "`\(path)`"
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
	associatedtype Value

	var value: Value { get }
}

/**
A frontmatter property that is checked when it is decoded, and stores the plain value. Use it through its aliases, like `@NonEmpty var title: String` or `@Absolute var repositoryURL: URL?`.

The wrapper decodes a `Validation` value and stores its plain value, so an invalid value has the message and the line of its key. `@Frontmatter` decodes the wrapper of the non-optional type, so an optional property can be missing.
*/
@propertyWrapper
public struct Validated<Validation: PlainValidatedValue, Value> {
	public var wrappedValue: Value

	public init(wrappedValue: Value) {
		self.wrappedValue = wrappedValue
	}
}

extension Validated: Sendable where Value: Sendable {}

extension Validated: Decodable where Value == Validation.Value {
	public init(from decoder: any Decoder) throws {
		self.init(wrappedValue: try Validation(from: decoder).value)
	}
}

/**
An absolute URL in frontmatter, like `https://github.com/sindresorhus/dato`.

Decoding throws for a relative URL, which is a common mistake in links.
*/
public struct AbsoluteURL: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible {
	public let value: URL

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
Text in frontmatter that is not empty or only whitespace, like a title.
*/
public struct NonEmptyString: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible {
	public let value: String

	public init(validating value: String) throws(ContentError) {
		guard !value.allSatisfy(\.isWhitespace) else {
			throw ContentError(reason: "Must not be empty.")
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
A positive integer in frontmatter that JavaScript can represent exactly (at most 2⁵³ − 1), like an App Store ID that a script reads.
*/
public struct SafeInteger: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible {
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
A positive integer in frontmatter that JavaScript can represent exactly, like `@JavaScriptSafe var setappID: Int?`. See ``SafeInteger``.
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

/**
A day in frontmatter, like `publicationDate: '2026-02-23'`, at midnight UTC.

SOML has no value for a day without a time, so it is a string. An impossible day, like `'2026-02-30'`, is an error.
*/
public struct Day: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible {
	public let value: Date

	public init(validating text: String) throws(ContentError) {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = .gmt

		guard
			let match = text.wholeMatch(of: Self.pattern),
			let year = Int(match.1),
			let month = Int(match.2),
			let day = Int(match.3)
		else {
			throw ContentError(reason: "Must be a day, like '2026-02-23', got “\(text)”.")
		}

		let components = DateComponents(year: year, month: month, day: day)

		guard
			let date = calendar.date(from: components),
			calendar.dateComponents([.year, .month, .day], from: date) == components
		else {
			throw ContentError(reason: "“\(text)” is not a real day.")
		}

		self.value = date
	}

	/**
	Not a literal in the initializer, as Swift parses a regex literal each time the code runs, and every post and app has a day.
	*/
	nonisolated(unsafe) private static let pattern = /(\d{4})-(\d{2})-(\d{2})/

	public var description: String {
		value.isoDay
	}
}

/**
A day in frontmatter, like `@CalendarDay var publicationDate: Date`, at midnight UTC. See ``Day``.
*/
public typealias CalendarDay<Value> = Validated<Day, Value>

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
