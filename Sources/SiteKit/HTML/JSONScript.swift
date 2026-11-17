import Elementary
import Foundation

/**
Embeds an encodable value as JSON in a `<script>` element, either as data for a page script or an element, or as schema.org structured data.

```swift
JSONScript(id: ElementID("app-data"), appData)
JSONScript(part: Parts.questions, questions)
JSONScript(structuredData: person)
```
*/
public struct JSONScript: HTML, Sendable {
	private let type: HTMLAttribute<HTMLTag.script>.ScriptType
	private let attribute: HTMLAttribute<HTMLTag.script>?
	private let json: String

	/**
	Data for a page script to read with `scriptData('id')` of `/scripts/dom.js`.
	*/
	public init(id: ElementID, _ value: some Encodable) {
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
	Data for a service that reads the page, in the media type of the service, like the link preview of Discord (`application/vnd.discord.component-embed+json`), so it is not the data of a page script.
	*/
	public init(id: ElementID, type: HTMLAttribute<HTMLTag.script>.ScriptType, _ value: some Encodable) {
		self.type = type
		self.attribute = .id(id)
		self.json = Self.encode(value)
	}

	/**
	Schema.org structured data (JSON-LD) for search engines. The JSON-LD keywords are the same in every model, so a property named `type`, `id`, or `context` is written as `@type`, `@id`, or `@context`, at every level. The other keys are the names of the properties.
	*/
	public init(structuredData value: some Encodable) {
		self.type = "application/ld+json"
		self.attribute = nil
		self.json = Self.encode(
			value,
			keyEncodingStrategy: .custom { codingPath in
				// The last key of the path is the key that the encoder writes.
				let key = codingPath.last!

				guard ["type", "id", "context"].contains(key.stringValue) else {
					return key
				}

				return AnyCodingKey(stringValue: "@\(key.stringValue)")
			}
		)
	}

	/**
	Speculation rules, which tell the browser which pages to prefetch or prerender. The model owns the API's wire keys, like `href_matches` for `hrefMatches`.
	*/
	public init(speculationRules value: SpeculationRules) {
		self.type = .speculationrules
		self.attribute = nil
		self.json = Self.encode(value)
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
		JSONEncoder.pageJSON(value, keyEncodingStrategy: keyEncodingStrategy).replacing("<", with: #"\u003C"#)
	}
}

/**
Document-based speculation rules for prefetching or prerendering links that match a condition. This models the subset of the Speculation Rules API used by SiteKit, rather than arbitrary JSON.
*/
public struct SpeculationRules: Encodable, Sendable {
	/**
	A condition on links and when the browser may speculate about them.
	*/
	public struct Rule: Encodable, Sendable {
		/**
		Conditions that must all match a link.
		*/
		public struct Condition: Encodable, Sendable {
			/**
			One predicate: a URL pattern to include, patterns to exclude, or a CSS selector of the links to exclude.
			*/
			public enum Clause: Encodable, Sendable {
				case hrefMatches(String)
				case notMatching([String])
				case notSelector(String)

				private enum CodingKeys: String, CodingKey {
					case hrefMatches = "href_matches"
					case selectorMatches = "selector_matches"
					case not
				}

				public func encode(to encoder: any Encoder) throws {
					var container = encoder.container(keyedBy: CodingKeys.self)
					switch self {
					case .hrefMatches(let pattern):
						try container.encode(pattern, forKey: .hrefMatches)
					case .notMatching(let patterns):
						var excluded = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .not)
						try excluded.encode(patterns, forKey: .hrefMatches)
					case .notSelector(let selector):
						var excluded = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .not)
						try excluded.encode(selector, forKey: .selectorMatches)
					}
				}
			}

			private let and: [Clause]

			/**
			Matches links that satisfy every clause.
			*/
			public init(all clauses: [Clause]) {
				self.and = clauses
			}
		}

		/**
		When the browser speculates.
		*/
		public enum Eagerness: String, Encodable, Sendable {
			/**
			When the pointer rests on the link, or on a phone, for a large link near the last tap when the scrolling stops.
			*/
			case moderate

			/**
			When the link is pressed.
			*/
			case conservative
		}

		private let `where`: Condition
		private let eagerness: Eagerness

		/**
		Creates a document rule with a condition and the interaction that permits speculation.
		*/
		public init(condition: Condition, eagerness: Eagerness) {
			self.where = condition
			self.eagerness = eagerness
		}
	}

	private let prefetch: [Rule]
	private let prerender: [Rule]

	/**
	Creates rules for either kind of speculative navigation. Empty lists disable that kind.
	*/
	public init(prefetch: [Rule] = [], prerender: [Rule] = []) {
		self.prefetch = prefetch
		self.prerender = prerender
	}
}
