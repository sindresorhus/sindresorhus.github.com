/**
A custom property with a type (`@property`). Unlike a plain custom property, the browser can animate and transition it, like a hue that turns. A stylesheet with a style that sets it also registers it.

```swift
static let hue = RegisteredProperty("--hue", syntax: "<number>", initialValue: 0)

Style()
	.setting(hue, to: 0)
	.animation(Animations.turnHue, duration: .seconds(6), curve: .linear, repeats: true)
```
*/
public struct RegisteredProperty: Sendable {
	public let name: String
	let syntax: String
	let initialValue: CSSValue
	let inherits: Bool

	/**
	- Parameter syntax: The type of the values, like `<number>`, `<color>`, or `<angle>`.
	- Parameter inherits: Whether descendants get the value, like for a hue that letters inside use.
	*/
	public init(_ name: String, syntax: String, initialValue: CSSValue, inherits: Bool = true) {
		precondition(name.hasPrefix("--"), "A custom property name starts with two hyphens: \(name)")
		self.name = name
		self.syntax = syntax
		self.initialValue = initialValue
		self.inherits = inherits
	}

	/**
	The current value, for other properties, like `hsl(var(--hue) 100% 65%)`.
	*/
	public var value: CSSValue {
		.variable(name)
	}

	var node: StyleNode {
		StyleNode(kind: .property(name: name, declarations: [
			Declaration(property: "syntax", value: CSSValue("\"\(syntax)\"")),
			Declaration(property: "inherits", value: CSSValue(inherits ? "true" : "false")),
			Declaration(property: "initial-value", value: initialValue),
		]))
	}
}

extension Style {
	/**
	Sets a registered custom property.
	*/
	public func setting(_ property: RegisteredProperty, to value: CSSValue) -> Self {
		var copy = declaration(Property(property.name), value)
		copy.definitions.append(property.node)
		return copy
	}
}
