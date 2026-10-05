/**
An object that keeps the order of its keys, like a list of labeled links.

```soml
links: {
	Download: 'https://example.com/download',
	TestFlight: 'https://testflight.apple.com/join/abc',
}
```
*/
public struct OrderedMapping<Value: Decodable & Sendable>: Decodable, Sendable, RandomAccessCollection {
	public typealias Element = (key: String, value: Value)

	private let elements: [Element]

	public init(_ elements: [Element] = []) {
		self.elements = elements
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: AnyCodingKey.self)
		self.elements = try container.allKeys.map { key in
			(key.stringValue, try container.decode(Value.self, forKey: key))
		}
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
