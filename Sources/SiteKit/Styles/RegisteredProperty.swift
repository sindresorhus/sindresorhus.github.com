/**
A custom property with a type (`@property`). Unlike a plain custom property, the browser can animate and transition it, like a hue that turns. A stylesheet with a style that sets it also registers it.

```swift
static let gradientStart = RegisteredProperty<Color>("--gradient-start", syntax: .color, initialValue: .black)

Style()
	.setting(gradientStart, to: .primary(500))
	.backgroundImage(.linearGradient("to right", gradientStart.value, .white))
```
*/
public struct RegisteredProperty<Value: StyleValue>: Sendable {
	/**
	The custom property, which gives the name and the current value.
	*/
	let variable: StyleVariable<Value>
	let syntax: PropertySyntax
	let initialValue: Value
	let inherits: Bool

	/**
	- Parameter syntax: The type of the values, like ``PropertySyntax/number``, ``PropertySyntax/color``, or ``PropertySyntax/angle``.
	- Parameter inherits: Whether descendants get the value, like for a hue that letters inside use.
	*/
	public init(
		_ name: String,
		syntax: PropertySyntax,
		initialValue: Value,
		inherits: Bool = true
	) {
		self.variable = StyleVariable(name)
		self.syntax = syntax
		self.initialValue = initialValue
		self.inherits = inherits
	}

	public var name: String {
		variable.name
	}

	/**
	The current value, for other properties, like `hsl(var(--hue) 100% 65%)`.
	*/
	public var value: Value {
		variable.value
	}

	var node: StyleNode {
		StyleNode(kind: .property(name: variable.name, declarations: [
			Declaration(property: Property("syntax"), value: .string(syntax.description)),
			Declaration(property: Property("inherits"), value: CSSValue(inherits ? "true" : "false")),
			Declaration(property: Property("initial-value"), value: CSSValue(initialValue)),
		]))
	}
}

/**
The type of the values of a ``RegisteredProperty``, like `<color>`. The common types are static members, so a misspelled type does not compile, as the browser ignores a registration with an invalid type.
*/
public struct PropertySyntax: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	A type without a static member, like `<length> | auto`.
	*/
	public init(_ syntax: String) {
		self.description = syntax
	}

	public static let angle = Self("<angle>")
	public static let color = Self("<color>")
	public static let length = Self("<length>")
	public static let number = Self("<number>")
	public static let percentage = Self("<percentage>")
}

extension Style {
	/**
	Sets a registered custom property.
	*/
	public func setting<Value>(_ property: RegisteredProperty<Value>, to value: Value) -> Self {
		var copy = setting(property.variable, to: value)
		copy.definitions.append(property.node)
		return copy
	}
}
