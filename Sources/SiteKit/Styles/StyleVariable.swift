/**
A custom property that a component reads for a part of its look, so a parent can change that part without a nested selector into the component, like the size of a badge. The component gives the default.

```swift
// In the component:
static let fontSize = StyleVariable("--badge-font-size")

Style().declaration(.fontSize, Badge.fontSize.value(default: .px(10)))

// In a parent:
Style().setting(Badge.fontSize, to: .px(16))
```
*/
public struct StyleVariable: Sendable {
	public let name: String

	public init(_ name: String) {
		precondition(name.hasPrefix("--"), "A custom property name starts with two hyphens: \(name)")
		self.name = name
	}

	/**
	The value that a parent set, or the default.
	*/
	public func value(default defaultValue: CSSValue) -> CSSValue {
		CSSValue("var(\(name), \(defaultValue))")
	}
}

extension Style {
	/**
	Sets a variable of a component for the descendants, like the size of the badges inside.
	*/
	public func setting(_ variable: StyleVariable, to value: CSSValue) -> Self {
		declaration(Property(variable.name), value)
	}
}
