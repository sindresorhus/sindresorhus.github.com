/**
A custom property with a type (`@property`). Unlike a plain custom property, the browser can animate and transition it, like a hue that turns. A stylesheet with a style that sets it also registers it.

```swift
static let gradientStart = RegisteredProperty<Color>("gradient-start", syntax: .color, initialValue: .black)

Style()
	.setting(gradientStart, to: .primary(500))
	.backgroundImage(.linearGradient(.toRight, gradientStart.value, .white))
```
*/
public struct RegisteredProperty<Value: StyleValue>: Sendable {
	/**
	The custom property, which gives the name and the current value.
	*/
	let variable: StyleVariable<Value>
	let syntax: PropertySyntax<Value>
	let initialValue: Value
	let inherits: Bool

	/**
	- Parameter name: The name without the CSS `--` prefix, like `gradient-start`.
	- Parameter syntax: The type of the values, like ``PropertySyntax/number``, ``PropertySyntax/color``, or ``PropertySyntax/angle``.
	- Parameter inherits: Whether descendants get the value, like for a hue that letters inside use.
	*/
	public init(
		_ name: DashedIdentifier,
		syntax: PropertySyntax<Value>,
		initialValue: Value,
		inherits: Bool = true
	) {
		self.variable = StyleVariable(name)
		self.syntax = syntax
		self.initialValue = initialValue
		self.inherits = inherits
	}

	public var name: DashedIdentifier {
		variable.name
	}

	/**
	The current value, for other properties, like `hsl(var(--hue) 100% 65%)`.
	*/
	public var value: Value {
		variable.value
	}

	var node: StyleNode {
		StyleNode(
			kind: .property(
				name: variable.name.description,
				declarations: [
					Declaration(property: Property("syntax"), value: .string(syntax.description)),
					Declaration(property: Property("inherits"), value: CSSValue(raw: inherits ? "true" : "false")),
					Declaration(property: Property("initial-value"), value: CSSValue(initialValue)),
				]
			)
		)
	}
}

/**
The type of the values of a ``RegisteredProperty``, like `<color>`. The common types are static members constrained to their Swift value type, so a color property cannot accidentally register as a number. The raw initializer is an explicit escape for other CSS syntax.
*/
public struct PropertySyntax<Value: StyleValue>: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	A type without a static member, like `<length> | auto`. The caller ensures that the syntax accepts the Swift value type.
	*/
	public init(raw syntax: String) {
		self.description = syntax
	}
}

extension PropertySyntax where Value == Angle {
	/**
	An angle (`<angle>` in CSS).
	*/
	public static let angle = Self(raw: "<angle>")
}

extension PropertySyntax where Value == Color {
	/**
	A color (`<color>` in CSS).
	*/
	public static let color = Self(raw: "<color>")
}

extension PropertySyntax where Value == Length {
	/**
	A length with a unit (`<length>` in CSS), without percentages.
	*/
	public static let length = Self(raw: "<length>")
}

extension PropertySyntax where Value == Percentage {
	/**
	A percentage (`<percentage>` in CSS), without other lengths.
	*/
	public static let percentage = Self(raw: "<percentage>")
}

extension PropertySyntax where Value == LengthPercentage {
	/**
	A length, a percentage, or a calculation mixing both (`<length-percentage>` in CSS).
	*/
	public static let lengthPercentage = Self(raw: "<length-percentage>")
}

extension PropertySyntax where Value == CSSNumber {
	/**
	A number (`<number>` in CSS).
	*/
	public static let number = Self(raw: "<number>")
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
