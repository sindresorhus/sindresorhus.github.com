/**
A custom property with a type (`@property`). Unlike a plain custom property, the browser can animate and transition it, like a hue that turns. A stylesheet with a style that sets it also registers it.

```swift
static let gradientStart = RegisteredProperty<Color>("--gradient-start", syntax: "<color>", initialValue: .black)

Style()
	.setting(gradientStart, to: .primary(500))
	.backgroundImage(.linearGradient("to right", gradientStart.value, .white))
```
*/
public struct RegisteredProperty<Value: StyleValue>: Sendable {
	public let name: String
	let syntax: String
	let initialValue: Value
	let inherits: Bool

	/**
	- Parameter syntax: The type of the values, like `<number>`, `<color>`, or `<angle>`.
	- Parameter inherits: Whether descendants get the value, like for a hue that letters inside use.
	*/
	public init(_ name: String, syntax: String, initialValue: Value, inherits: Bool = true) {
		precondition(name.hasPrefix("--"), "A custom property name starts with two hyphens: \(name)")
		self.name = name
		self.syntax = syntax
		self.initialValue = initialValue
		self.inherits = inherits
	}

	/**
	The current value, for other properties, like `hsl(var(--hue) 100% 65%)`.
	*/
	public var value: Value {
		Value(CSSValue.variable(name).description)
	}

	var node: StyleNode {
		StyleNode(kind: .property(name: name, declarations: [
			Declaration(property: Property("syntax"), value: CSSValue("\"\(syntax)\"")),
			Declaration(property: Property("inherits"), value: CSSValue(inherits ? "true" : "false")),
			Declaration(property: Property("initial-value"), value: CSSValue(initialValue)),
		]))
	}
}

extension Style {
	/**
	Sets a registered custom property.
	*/
	public func setting<Value>(_ property: RegisteredProperty<Value>, to value: Value) -> Self {
		var copy = declaration(Property(property.name), CSSValue(value))
		copy.definitions.append(property.node)
		return copy
	}
}
