/**
A custom property with a type (`@property`). Unlike a plain custom property, the browser can animate and transition it, like a hue that turns. A stylesheet with a style that sets or transitions it also registers it.

```swift
static let gradientStart = RegisteredProperty<Color>("gradient-start", initialValue: .black)

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
	The caller ensures that the initial value is computationally independent and accepted by the custom syntax. Prefer the inferred-syntax initializer for supported constant values.

	- Parameter name: The name without the CSS `--` prefix, like `gradient-start`.
	- Parameter syntax: The type of the values, like ``PropertySyntax/number``, ``PropertySyntax/color``, or ``PropertySyntax/angle``.
	- Parameter inherits: Whether descendants get the value, like for a hue that letters inside use.
	*/
	public init(
		_ name: DashedIdentifier,
		syntax: PropertySyntax<Value>,
		uncheckedInitialValue initialValue: Value,
		inherits: Bool = true
	) {
		self.variable = StyleVariable(name)
		self.syntax = syntax
		self.initialValue = initialValue
		self.inherits = inherits
	}

	/**
	Registers a supported constant value, inferring the CSS syntax from its Swift type. Relative lengths, variables, and arbitrary expressions require the explicitly unchecked initializer.
	*/
	public init(_ name: DashedIdentifier, initialValue: PropertyInitialValue<Value>, inherits: Bool = true) where Value: RegisteredStyleValue {
		self.init(name, syntax: Value.propertySyntax, uncheckedInitialValue: initialValue.value, inherits: inherits)
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
		definition.node
	}

	/**
	The registration independently of its Swift value type, for a transition that retains the property definition.
	*/
	var definition: RegisteredPropertyDefinition {
		RegisteredPropertyDefinition(
			name: name,
			declarations: [
				Declaration(property: Property("syntax"), value: .string(syntax.description)),
				Declaration(property: Property("inherits"), value: CSSValue(raw: inherits ? "true" : "false")),
				Declaration(property: Property("initial-value"), value: CSSValue(initialValue)),
			]
		)
	}
}

/**
A CSS value with a standard registration syntax. The syntax belongs to the value rather than being repeated at every registration.
*/
public protocol RegisteredStyleValue: StyleValue {
	/**
	The standard syntax accepted by a registered property of this value type.
	*/
	static var propertySyntax: PropertySyntax<Self> { get }
}

/**
A computationally independent initial value for a registered property. Only supported constant forms can be constructed; ordinary style values can contain relative units, variables, or expressions that cannot initialize a registration.
*/
public struct PropertyInitialValue<Value: StyleValue>: Sendable {
	fileprivate let value: Value

	fileprivate init(_ value: Value) {
		self.value = value
	}
}

extension PropertyInitialValue where Value == CSSNumber {
	/**
	A finite constant number.
	*/
	public static func number(_ value: Double) -> Self {
		Self(CSSNumber(value))
	}
}

extension PropertyInitialValue: ExpressibleByIntegerLiteral where Value == CSSNumber {
	public init(integerLiteral value: Int) {
		self.init(CSSNumber(value))
	}
}

extension PropertyInitialValue: ExpressibleByFloatLiteral where Value == CSSNumber {
	public init(floatLiteral value: Double) {
		self.init(CSSNumber(value))
	}
}

extension PropertyInitialValue where Value == Length {
	/**
	A constant length of zero.
	*/
	public static var zero: Self {
		Self(.zero)
	}

	/**
	A constant absolute length in pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(.pixels(value))
	}
}

extension PropertyInitialValue where Value == LengthPercentage {
	/**
	A constant length of zero.
	*/
	public static var zero: Self {
		Self(.zero)
	}

	/**
	A constant absolute length in pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(.pixels(value))
	}

	/**
	A constant percentage.
	*/
	public static func percent(_ value: Double) -> Self {
		Self(.percent(value))
	}
}

extension PropertyInitialValue where Value == Percentage {
	/**
	A constant percentage.
	*/
	public static func percent(_ value: Double) -> Self {
		Self(.percent(value))
	}
}

extension PropertyInitialValue where Value == Angle {
	/**
	A constant angle in degrees.
	*/
	public static func degrees(_ value: Double) -> Self {
		Self(.degrees(value))
	}
}

extension PropertyInitialValue where Value == Color {
	/**
	An opaque constant black.
	*/
	public static var black: Self {
		Self(.black)
	}

	/**
	An opaque constant white.
	*/
	public static var white: Self {
		Self(.white)
	}

	/**
	A constant transparent color.
	*/
	public static var transparent: Self {
		Self(.transparent)
	}

	/**
	A constant RGB color with byte-valued components.
	*/
	public static func rgb(red: UInt8, green: UInt8, blue: UInt8) -> Self {
		Self(.rgb(red: red, green: green, blue: blue))
	}

	/**
	A constant OKLCH color. Lightness is a percentage and hue is in degrees.
	*/
	public static func oklch(lightness: Double, chroma: Double, hue: Double) -> Self {
		Self(.oklch(lightness: .percent(lightness), chroma: CSSNumber(chroma), hue: .degrees(hue)))
	}
}

/**
The value of an `@property` definition, retained when a registered property is used without its generic value type.
*/
struct RegisteredPropertyDefinition: Hashable, Sendable {
	let name: DashedIdentifier
	let declarations: [Declaration]

	var node: StyleNode {
		StyleNode(kind: .property(name: name.description, declarations: declarations))
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

/**
The standard registration syntax of Angle values.
*/
extension Angle: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.angle
	}
}

/**
The standard registration syntax of Color values.
*/
extension Color: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.color
	}
}

/**
The standard registration syntax of Length values.
*/
extension Length: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.length
	}
}

/**
The standard registration syntax of Percentage values.
*/
extension Percentage: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.percentage
	}
}

/**
The standard registration syntax of LengthPercentage values.
*/
extension LengthPercentage: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.lengthPercentage
	}
}

/**
The standard registration syntax of CSSNumber values.
*/
extension CSSNumber: RegisteredStyleValue {
	public static var propertySyntax: PropertySyntax<Self> {
		.number
	}
}
