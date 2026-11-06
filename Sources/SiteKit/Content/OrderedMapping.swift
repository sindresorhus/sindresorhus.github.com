/**
An object that keeps the order of its keys, like a list of labeled links.

```soml
links: {
	Download: 'https://example.com/download',
	TestFlight: 'https://testflight.apple.com/join/abc',
}
```
*/
public struct OrderedMapping<Value>: RandomAccessCollection {
	public typealias Element = (key: String, value: Value)

	private let elements: [Element]

	/**
	Creates a mapping with the elements in their given order. The keys must be unique.
	*/
	public init(_ elements: [Element] = []) {
		precondition(Set(elements.map(\.key)).count == elements.count, "An ordered mapping must have unique keys.")
		self.elements = elements
	}

	public var startIndex: Int {
		elements.startIndex
	}

	public var endIndex: Int {
		elements.endIndex
	}

	public subscript(position: Int) -> Element {
		elements[position]
	}

	public subscript(key: String) -> Value? {
		elements.first { $0.key == key }?.value
	}
}

/**
An ordered mapping keeps the order of dictionary-literal pairs and requires unique keys.
*/
extension OrderedMapping: ExpressibleByDictionaryLiteral {
	public init(dictionaryLiteral elements: (String, Value)...) {
		self.init(elements)
	}
}

/**
An ordered mapping can be sent between isolation domains when its values can.
*/
extension OrderedMapping: Sendable where Value: Sendable {}

/**
An ordered mapping decodes its values without requiring them to be sendable.
*/
extension OrderedMapping: Decodable where Value: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: AnyCodingKey.self)
		self.elements = try container.allKeys.map { key in
			(key.stringValue, try container.decode(Value.self, forKey: key))
		}
	}
}
