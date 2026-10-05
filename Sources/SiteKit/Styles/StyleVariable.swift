/**
A custom property that a component reads for a part of its look, so a parent can change that part without a nested selector into the component, like the size of a badge. The component gives the default.

The type of the value is part of the variable, like the type of an environment value in SwiftUI, so typed modifiers take the variable:

```swift
// In the component:
static let fontSize = StyleVariable<Length>("--badge-font-size")

Style().font(size: Badge.fontSize.value(default: .pixels(10)))

// In a parent:
Style().setting(Badge.fontSize, to: .pixels(16))
```
*/
public struct StyleVariable<Value: StyleValue>: Sendable {
	public let name: String

	public init(_ name: String) {
		precondition(name.hasPrefix("--"), "A custom property name starts with two hyphens: \(name)")
		self.name = name
	}

	/**
	The value that a parent or a script set.
	*/
	public var value: Value {
		Value(CSSValue.variable(name).description)
	}

	/**
	The value that a parent set, or the default.
	*/
	public func value(default defaultValue: Value) -> Value {
		Value(CSSValue.variable(name, fallback: CSSValue(defaultValue)).description)
	}
}

extension Style {
	/**
	Sets a variable for the element and its descendants, like the size of the badges inside.
	*/
	public func setting<Value>(_ variable: StyleVariable<Value>, to value: Value) -> Self {
		declaration(Property(variable.name), CSSValue(value))
	}
}
