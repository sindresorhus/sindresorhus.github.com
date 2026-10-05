import Elementary
import Foundation

/**
Embeds an encodable value as JSON in a `<script>` element, either as data for a page script or an element, or as schema.org structured data.

```swift
JSONScript(id: "app-data", appData)
JSONScript(part: Parts.questions, questions)
JSONScript(structuredData: person)
```
*/
public struct JSONScript: HTML, Sendable {
	private let type: HTMLAttribute<HTMLTag.script>.ScriptType
	private let attribute: HTMLAttribute<HTMLTag.script>?
	private let json: String

	/**
	Data for a page script to read with `JSON.parse(document.querySelector('#id').textContent)`.
	*/
	public init(id: String, _ value: some Encodable) {
		self.type = "application/json"
		self.attribute = .id(id)
		self.json = Self.encode(value)
	}

	/**
	Data for the script of a ``ScriptedElement``, as a part of it, which the script reads with `JSON.parse(this.querySelector('[data-part="name"]').textContent)`. Use it instead of `config` for large data, as the JSON is not escaped in an attribute.
	*/
	public init(part: some ElementPartSet, _ value: some Encodable) {
		self.type = "application/json"
		self.attribute = .part(part)
		self.json = Self.encode(value)
	}

	/**
	Schema.org structured data (JSON-LD) for search engines. Properties named `type` and `context` are written as the JSON-LD keywords `@type` and `@context`.
	*/
	public init(structuredData value: some Encodable) {
		self.type = "application/ld+json"
		self.attribute = nil
		self.json = Self.encode(value, keyEncodingStrategy: .custom { codingPath in
			let key = codingPath.last?.stringValue ?? ""
			return AnyCodingKey(stringValue: ["type", "context"].contains(key) ? "@\(key)" : key)
		})
	}

	/**
	Speculation rules, which tell the browser which pages to prefetch or prerender. Property names are written in snake case, like `href_matches` for `hrefMatches`.
	*/
	public init(speculationRules value: some Encodable) {
		self.type = "speculationrules"
		self.attribute = nil
		self.json = Self.encode(value, keyEncodingStrategy: .convertToSnakeCase)
	}

	public var body: some HTML<HTMLTag.script> {
		script(.type(type)) {
			HTMLRaw(json)
		}
		.attributes(contentsOf: [attribute].compactMap(\.self))
	}

	/**
	Encodes with sorted keys. Every `<` is escaped as `\u003C`, so the JSON cannot end the script element or change how the HTML parser reads it, like with `<!--<script`. In JSON, `<` can only be in strings, where the escape is the same character.
	*/
	private static func encode(_ value: some Encodable, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
		encoder.keyEncodingStrategy = keyEncodingStrategy

		guard let data = try? encoder.encode(value) else {
			preconditionFailure("Could not encode \(Swift.type(of: value)) as JSON.")
		}

		return String(decoding: data, as: UTF8.self).replacing("<", with: #"\u003C"#)
	}
}
