/**
A CSS value for ``Style/declaration(_:_:)``, like `1rem`, `auto`, or `var(--accent)`.

Typed modifiers take typed values, like ``Length`` and ``Color``. Use a `CSSValue` for the rest: a string literal, an array for space-separated values, or a constructor:

```swift
Style()
	.declaration(.gridTemplateColumns, "repeat(auto-fill, minmax(16rem, 1fr))")
	.declaration(.transformOrigin, [.percent(50), .percent(85)])
	.declaration(.scrollSnapAlign, .center)
```
*/
public struct CSSValue: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByArrayLiteral {
	public let description: String

	public init(_ value: String) {
		self.description = value
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	public init(integerLiteral value: Int) {
		self.init(String(value))
	}

	public init(floatLiteral value: Double) {
		self.init(Self.format(value))
	}

	/**
	Space-separated values, like `[.rem(1), .rem(2)]` for `1rem 2rem`.
	*/
	public init(arrayLiteral elements: CSSValue...) {
		self.init(elements.map(\.description).joined(separator: " "))
	}

	/**
	A number without unneeded digits, like `.5` for 0.5 and `2` for 2.0.
	*/
	static func format(_ number: Double) -> String {
		let string = number.rounded() == number ? String(Int(number)) : String(number)
		return string.hasPrefix("0.") ? String(string.dropFirst()) : string.hasPrefix("-0.") ? "-" + string.dropFirst(2) : string
	}
}

// MARK: Lengths

extension CSSValue {
	public static func rem(_ value: Double) -> Self {
		Self(format(value) + "rem")
	}

	public static func em(_ value: Double) -> Self {
		Self(format(value) + "em")
	}

	public static func px(_ value: Double) -> Self {
		Self(format(value) + "px")
	}

	public static func percent(_ value: Double) -> Self {
		Self(format(value) + "%")
	}

	public static func vh(_ value: Double) -> Self {
		Self(format(value) + "vh")
	}

	public static func vw(_ value: Double) -> Self {
		Self(format(value) + "vw")
	}
}

// MARK: Functions

extension CSSValue {
	/**
	A custom property reference, like `var(--text)`.
	*/
	public static func variable(_ name: String, fallback: Self? = nil) -> Self {
		Self("var(\(name)\(fallback.map { ", \($0)" } ?? ""))")
	}

	/**
	A linear gradient, like `linearGradient("to right", .blue, .pink)`.

	- Parameter colorSpace: The color space the colors are mixed in, like `oklch`, which avoids the gray middle of gradients between distant colors.
	*/
	public static func linearGradient(_ direction: String, _ colors: Color..., in colorSpace: String? = nil) -> Self {
		let direction = colorSpace.map { "\(direction) in \($0)" } ?? direction
		return Self("linear-gradient(\(([direction] + colors.map(\.description)).joined(separator: ", ")))")
	}

	public static func important(_ value: Self) -> Self {
		Self("\(value) !important")
	}
}

// MARK: Keywords

extension CSSValue {
	public static let auto: Self = "auto"
	public static let none: Self = "none"
	public static let inherit: Self = "inherit"
	public static let transparent: Self = "transparent"
	public static let currentColor: Self = "currentColor"
	public static let center: Self = "center"
}
