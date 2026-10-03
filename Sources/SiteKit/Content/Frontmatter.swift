import Foundation

/**
Makes a struct decode strictly from YAML frontmatter.

It generates the coding keys and an initializer that rejects unknown keys and uses the default value of a property when its key is missing. Rename a key with `@Key`. Every stored property needs a type annotation.

```swift
@Frontmatter
struct PostFrontmatter {
	var title: String
	var description: String?
	var tags = [String]()

	@Key("pubDate")
	var publicationDate: Date
}
```
*/
@attached(member, names: named(CodingKeys), named(init(from:)))
@attached(extension, conformances: Frontmatter)
public macro Frontmatter() = #externalMacro(module: "SiteKitMacros", type: "FrontmatterMacro")

/**
The YAML key of a `@Frontmatter` property, when it differs from the property name.
*/
@attached(peer)
public macro Key(_ name: String) = #externalMacro(module: "SiteKitMacros", type: "KeyMacro")

/**
Typed frontmatter of a content file. Use the `@Frontmatter` macro to conform.

Decoding is strict: unknown keys are rejected (see ``Swift/Decoder/rejectUnknownKeys(_:)``), and ``validate()`` checks the rules that types cannot express.
*/
public protocol Frontmatter: Decodable, Sendable {
	/**
	Checks requirements that the types cannot express, like a value being an absolute URL.
	*/
	func validate() throws(FrontmatterError)
}

extension Frontmatter {
	public func validate() throws(FrontmatterError) {}
}

/**
A frontmatter value that breaks a content rule.
*/
public struct FrontmatterError: Error, CustomStringConvertible {
	public let description: String

	public init(_ description: String) {
		self.description = description
	}
}

/**
An absolute URL in frontmatter, like `https://github.com/sindresorhus/dato`.

Decoding throws for a relative URL, which is a common mistake in links. The error includes the key path.
*/
public struct AbsoluteURL: Decodable, Hashable, Sendable, CustomStringConvertible {
	public let url: URL

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let url = try container.decode(URL.self)

		guard let scheme = url.scheme, !scheme.isEmpty else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must be an absolute URL, got “\(url)”.")
		}

		self.url = url
	}

	public var absoluteString: String {
		url.absoluteString
	}

	public var description: String {
		absoluteString
	}
}

/**
Text in frontmatter that is not empty or only whitespace, like a title.
*/
public struct NonEmptyString: Decodable, Hashable, Sendable, CustomStringConvertible {
	public let value: String

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		guard !value.allSatisfy(\.isWhitespace) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must not be empty.")
		}

		self.value = value
	}

	public var description: String {
		value
	}
}

/**
A positive integer in frontmatter that JavaScript can represent exactly (at most 2⁵³ − 1), like an App Store ID that a script reads.
*/
public struct SafeInteger: Decodable, Hashable, Sendable, CustomStringConvertible {
	public let value: Int

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(Int.self)

		guard (1...9_007_199_254_740_991).contains(value) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must be a positive integer of at most 2⁵³ − 1, got \(value).")
		}

		self.value = value
	}

	public var description: String {
		String(value)
	}
}

/**
Where a link goes: an absolute URL, like `https://example.com`, a path on the site, like `/apps/faq`, or a fragment of the same page, like `#faq`.

Decoding throws for anything else, like a relative path, which would resolve differently on each page.
*/
public enum LinkDestination: Decodable, Hashable, Sendable, CustomStringConvertible {
	case url(URL)
	case path(RoutePath)

	/**
	A section of the same page, like `faq` for `#faq`.
	*/
	case fragment(String)

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)

		if string.hasPrefix("#") {
			self = .fragment(String(string.dropFirst()))
			return
		}

		if string.hasPrefix("/"), !string.hasPrefix("//") {
			self = .path(RoutePath(string))
			return
		}

		guard
			let url = URL(string: string),
			url.scheme?.isEmpty == false
		else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Must be an absolute URL, a path that starts with “/”, or a fragment that starts with “#”, got “\(string)”.")
		}

		self = .url(url)
	}

	/**
	The link for an `href` attribute.
	*/
	public var description: String {
		switch self {
		case .url(let url):
			url.absoluteString
		case .path(let path):
			path.description
		case .fragment(let fragment):
			"#\(fragment)"
		}
	}
}

extension Decoder {
	/**
	Throws if the keyed container contains keys that the type does not declare.

	Swift's synthesized decoding silently ignores unknown keys, which hides typos in frontmatter.
	*/
	public func rejectUnknownKeys<Key: CodingKey & CaseIterable>(_ keys: Key.Type) throws {
		let known = Set(Key.allCases.map(\.stringValue))
		let unknown = try container(keyedBy: AnyCodingKey.self).allKeys
			.map(\.stringValue)
			.filter { !known.contains($0) }

		guard let first = unknown.sorted().first else {
			return
		}

		// The path ends at the first unknown key, so the error can point to its line.
		throw DecodingError.dataCorrupted(.init(
			codingPath: codingPath + [AnyCodingKey(stringValue: first)],
			debugDescription: "Unknown key(s): \(unknown.sorted().joined(separator: ", "))"
		))
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
