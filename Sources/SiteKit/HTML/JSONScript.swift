import Elementary
import Foundation

/**
Embeds an encodable value as JSON in a `<script>` element, either as data for a page script or as schema.org structured data.

```swift
JSONScript(id: "app-data", appData)
JSONScript(structuredData: person)
```
*/
public struct JSONScript: HTML, Sendable {
	private let type: String
	private let id: String?
	private let json: String

	/**
	Data for a page script to read with `JSON.parse(document.querySelector('#id').textContent)`.
	*/
	public init(id: String, _ value: some Encodable) {
		self.type = "application/json"
		self.id = id
		self.json = Self.encode(value)
	}

	/**
	Schema.org structured data (JSON-LD) for search engines. Properties named `type` and `context` are written as the JSON-LD keywords `@type` and `@context`.
	*/
	public init(structuredData value: some Encodable) {
		self.type = "application/ld+json"
		self.id = nil
		self.json = Self.encode(value, keywords: ["type", "context"])
	}

	public var body: some HTML {
		if let id {
			HTMLRaw(#"<script type="\#(type)" id="\#(id)">\#(json)</script>"#)
		} else {
			HTMLRaw(#"<script type="\#(type)">\#(json)</script>"#)
		}
	}

	/**
	Encodes with sorted keys. `</` is escaped so the JSON cannot end the script element.
	*/
	private static func encode(_ value: some Encodable, keywords: Set<String> = []) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

		if !keywords.isEmpty {
			encoder.keyEncodingStrategy = .custom { codingPath in
				let key = codingPath.last?.stringValue ?? ""
				return JSONKeyword(stringValue: keywords.contains(key) ? "@\(key)" : key)
			}
		}

		guard let data = try? encoder.encode(value) else {
			preconditionFailure("Could not encode \(Swift.type(of: value)) as JSON.")
		}

		return String(decoding: data, as: UTF8.self).replacing("</", with: #"<\/"#)
	}
}

private struct JSONKeyword: CodingKey {
	let stringValue: String
	let intValue: Int? = nil

	init(stringValue: String) {
		self.stringValue = stringValue
	}

	init?(intValue: Int) {
		nil
	}
}
