/**
A CSS value for ``Style/declaration(_:_:)``, like `1rem`, `auto`, or `var(--accent)`.

Typed modifiers take typed values, like ``Length`` and ``Color``. Use a `CSSValue` for the rest: a string literal, an array for space-separated values, or a constructor:

```swift
Style()
	.declaration(.gridTemplateColumns, "repeat(auto-fill, minmax(16rem, 1fr))")
	.declaration(.transformOrigin, [.percent(50), .percent(85)])
	.declaration(.backgroundPosition, .center)
```
*/
public struct CSSValue: StyleValue, Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByArrayLiteral {
	public let description: String

	public init(_ value: String) {
		self.description = value
	}

	/**
	A typed value, like a ``Length`` or a ``Color``.
	*/
	public init(_ value: some StyleValue) {
		self.init(value.description)
	}

	/**
	A keyword, like ``Display/grid``.
	*/
	public init(_ keyword: some CSSKeyword) {
		self.init(keyword.rawValue)
	}

	/**
	A number, like `1.5` for a line height, without unneeded digits. A number that is not whole is rounded to 4 decimals.
	*/
	public init(_ number: Double) {
		self.init(Self.format(number))
	}

	/**
	A whole number, like `700` for a font weight.
	*/
	public init(_ number: Int) {
		self.init(String(number))
	}

	/**
	Values with the separator between them, like `", "` for the layers of a background.
	*/
	public init(_ values: [some CustomStringConvertible], separator: String) {
		self.init(values.map(\.description).joined(separator: separator))
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	public init(integerLiteral value: Int) {
		self.init(value)
	}

	public init(floatLiteral value: Double) {
		self.init(value)
	}

	/**
	Space-separated values, like `[.rootEm(1), .rootEm(2)]` for `1rem 2rem`.
	*/
	public init(arrayLiteral elements: CSSValue...) {
		self.init(elements, separator: " ")
	}

	/**
	A number without unneeded digits, like `.5` for 0.5 and `2` for 2.0. A number that is not whole is rounded to 4 decimals, as arithmetic adds noise, like `106.24999999999999` for 106.25.
	*/
	static func format(_ number: Double) -> String {
		// CSS has no infinity or NaN, so a number like that is a mistake in the code, like a division by zero.
		precondition(number.isFinite, "A CSS number must be finite, but it is \(number).")

		// A whole number is not rounded, as a large one, like `1e19`, would lose digits.
		let rounded = number.rounded() == number ? number : (number * 10_000).rounded() / 10_000

		// A whole number that is too large for `Int` is written with an exponent, like `1e+19`, which CSS reads too. A rounded `-0` is `0`, as `Int` has no negative zero.
		let string = Int(exactly: rounded).map { String($0) } ?? String(rounded)
		return string.hasPrefix("0.") ? String(string.dropFirst()) : string.hasPrefix("-0.") ? "-" + string.dropFirst(2) : string
	}
}

// MARK: Lengths

extension CSSValue {
	/**
	A multiple of the font size of the root element (`rem` in CSS).
	*/
	public static func rootEm(_ value: Double) -> Self {
		Self(Length.rootEm(value))
	}

	/**
	A multiple of the font size of the element (`em` in CSS).
	*/
	public static func em(_ value: Double) -> Self {
		Self(Length.em(value))
	}

	/**
	Pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(Length.pixels(value))
	}

	/**
	A percentage (`%` in CSS).
	*/
	public static func percent(_ value: Double) -> Self {
		Self(Length.percent(value))
	}

	/**
	A percentage of the viewport height (`vh` in CSS).
	*/
	public static func viewportHeight(_ value: Double) -> Self {
		Self(Length.viewportHeight(value))
	}

	/**
	A percentage of the viewport width (`vw` in CSS).
	*/
	public static func viewportWidth(_ value: Double) -> Self {
		Self(Length.viewportWidth(value))
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

	- Parameter colorSpace: The color space the colors are mixed in, like ``ColorSpace/oklch``, which avoids the gray middle of gradients between distant colors.
	*/
	public static func linearGradient(_ direction: String, _ colors: Color..., in colorSpace: ColorSpace? = nil) -> Self {
		gradient("linear-gradient", direction, colors.map(\.description), in: colorSpace)
	}

	/**
	A linear gradient with the colors at positions, like `linearGradient("175deg", Color.white.at(.percent(0)), Color.transparent.at(.percent(70)))`.
	*/
	public static func linearGradient(_ direction: String, _ stops: GradientStop..., in colorSpace: ColorSpace? = nil) -> Self {
		gradient("linear-gradient", direction, stops.map(\.description), in: colorSpace)
	}

	/**
	A radial gradient, like `radialGradient("circle at 20% 40%", .blue, .transparent)`. The colors are spread evenly, so a color twice in a row is solid between them, like `.black, .black, .transparent` for a shape that is solid to the middle of its radius and then fades.
	*/
	public static func radialGradient(_ shape: String, _ colors: Color..., in colorSpace: ColorSpace? = nil) -> Self {
		gradient("radial-gradient", shape, colors.map(\.description), in: colorSpace)
	}

	/**
	A radial gradient with the colors at positions, like `radialGradient("circle", Color.black.at(.percent(80)), Color.transparent.at(.percent(100)))` for a shape that fades at its edge.
	*/
	public static func radialGradient(_ shape: String, _ stops: GradientStop..., in colorSpace: ColorSpace? = nil) -> Self {
		gradient("radial-gradient", shape, stops.map(\.description), in: colorSpace)
	}

	/**
	A conic gradient, with the colors around the center, like `conicGradient(.blue, .pink, .blue)` for a ring. The colors are spread evenly.

	- Parameter angle: Where the first color is, clockwise from the top.
	*/
	public static func conicGradient(_ colors: Color..., from angle: Angle? = nil, in colorSpace: ColorSpace? = nil) -> Self {
		gradient("conic-gradient", angle.map { "from \($0)" }, colors.map(\.description), in: colorSpace)
	}

	/**
	A gradient function, like `linear-gradient(to right in oklch, blue, pink)`. The shape and the color space are the first argument, which is left out when there are none.
	*/
	private static func gradient(_ name: String, _ shape: String?, _ colors: [String], in colorSpace: ColorSpace?) -> Self {
		let prelude = [shape, colorSpace.map { "in \($0.rawValue)" }].compactMap(\.self).joined(separator: " ")
		let arguments = prelude.isEmpty ? colors : [prelude] + colors
		return Self("\(name)(\(arguments.joined(separator: ", ")))")
	}

	/**
	A file of the site, like an image for a background or a cursor: `url("/images/star.png")`. The path is escaped as a CSS string.
	*/
	public static func url(_ path: RoutePath) -> Self {
		Self("url(\(string(path.description)))")
	}

	/**
	A quoted CSS string, escaping quotes, backslashes, and control characters by Unicode scalar. The trailing space ends each hexadecimal escape.
	*/
	public static func string(_ text: String) -> Self {
		var result = "\""
		result.reserveCapacity(text.utf8.count + 2)

		// A line break ends a CSS string, so it is the escape `\A`, with a space that ends the escape. A Windows line break (`\r\n`) is one line break.
		for scalar in text.replacing("\r\n", with: "\n").unicodeScalars {
			switch scalar {
			case "\"", "\\":
				result.append("\\")
				result.unicodeScalars.append(scalar)
			case "\r", "\n":
				result += "\\A "
			case "\0":
				result.unicodeScalars.append("\u{FFFD}")
			case _ where scalar.value < 0x20 || scalar.value == 0x7F:
				result += "\\" + String(scalar.value, radix: 16) + " "
			default:
				result.unicodeScalars.append(scalar)
			}
		}

		result.append("\"")
		return Self(result)
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

/**
A typed CSS value, like a ``Length`` or a ``Color``, which can also be written as CSS, like a reference to a ``StyleVariable``.
*/
public protocol StyleValue: Sendable, CustomStringConvertible {
	/**
	A value written as CSS, like `var(--size)` or `calc(1rem + 2px)`.
	*/
	init(_ css: String)
}

/**
A CSS keyword, like ``Display/grid``, whose raw value is how it is written in CSS. Enums of keywords conform, not enums of selectors, like ``ScrollbarPart``.
*/
public protocol CSSKeyword: RawRepresentable<String>, Sendable {}
