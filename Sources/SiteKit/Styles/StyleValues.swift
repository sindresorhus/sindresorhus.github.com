import Foundation

/**
A CSS length, like `1rem`, `50%`, or `auto`.

The integer literal `0` is a length without a unit.
*/
public struct Length: Hashable, Sendable, CustomStringConvertible, ExpressibleByIntegerLiteral {
	public let description: String

	/**
	A length written as CSS, like `calc(100dvh - 4rem)`.
	*/
	public init(_ css: String) {
		self.description = css
	}

	public init(integerLiteral value: Int) {
		self.init(String(value))
	}

	public static func rem(_ value: Double) -> Self {
		Self(CSSValue.rem(value).description)
	}

	public static func em(_ value: Double) -> Self {
		Self(CSSValue.em(value).description)
	}

	public static func px(_ value: Double) -> Self {
		Self(CSSValue.px(value).description)
	}

	public static func percent(_ value: Double) -> Self {
		Self(CSSValue.percent(value).description)
	}

	public static func vh(_ value: Double) -> Self {
		Self(CSSValue.vh(value).description)
	}

	public static func vw(_ value: Double) -> Self {
		Self(CSSValue.vw(value).description)
	}

	/**
	A percentage of the dynamic viewport height, which follows the browser toolbars on phones.
	*/
	public static func dvh(_ value: Double) -> Self {
		Self(CSSValue.format(value) + "dvh")
	}

	/**
	A percentage of the small viewport height, which is the height with the browser toolbars shown.
	*/
	public static func svh(_ value: Double) -> Self {
		Self(CSSValue.format(value) + "svh")
	}

	/**
	A custom property, like `var(--header-height, 0px)`.
	*/
	public static func variable(_ name: String, fallback: Self? = nil) -> Self {
		Self(CSSValue.variable(name, fallback: fallback.map { CSSValue($0.description) }).description)
	}

	public static let auto = Self("auto")

	/**
	The number and unit of a simple length, like `1.5` and `rem` for `1.5rem`.
	*/
	private var numberAndUnit: (number: Double, unit: String)? {
		guard
			let match = description.wholeMatch(of: /(-?\d*\.?\d+)([a-z%]*)/),
			let number = Double(match.1)
		else {
			return nil
		}

		return (number, String(match.2))
	}

	/**
	The length as an operand of `calc()`, in parentheses unless it is a single value.
	*/
	private var calculationOperand: String {
		description.hasPrefix("calc(") ? String(description.dropFirst(4)) : description
	}

	public static func + (lhs: Self, rhs: Self) -> Self {
		if
			let lhs = lhs.numberAndUnit,
			let rhs = rhs.numberAndUnit,
			lhs.unit == rhs.unit
		{
			return Self(CSSValue.format(lhs.number + rhs.number) + lhs.unit)
		}

		return Self("calc(\(lhs.calculationOperand) + \(rhs.calculationOperand))")
	}

	public static func - (lhs: Self, rhs: Self) -> Self {
		if
			let lhs = lhs.numberAndUnit,
			let rhs = rhs.numberAndUnit,
			lhs.unit == rhs.unit
		{
			return Self(CSSValue.format(lhs.number - rhs.number) + lhs.unit)
		}

		return Self("calc(\(lhs.calculationOperand) - \(rhs.calculationOperand))")
	}

	public static func * (lhs: Self, rhs: Double) -> Self {
		if let lhs = lhs.numberAndUnit {
			return Self(CSSValue.format(lhs.number * rhs) + lhs.unit)
		}

		return Self("calc(\(lhs.calculationOperand) * \(CSSValue.format(rhs)))")
	}

	public static prefix func - (length: Self) -> Self {
		length * -1
	}
}

/**
A CSS color, like `#2563eb` or `oklch(55.1% .027 264.364)`.
*/
public struct Color: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
	public let description: String

	public init(_ css: String) {
		self.description = css
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	/**
	The color with transparency, where `1` is opaque.
	*/
	public func opacity(_ opacity: Double) -> Self {
		// Rounded, as `0.035 * 100` is `3.5000000000000004`.
		Self("color-mix(in oklab, \(self) \(CSSValue.percent((opacity * 100_000).rounded() / 1000)), transparent)")
	}

	/**
	The color, with another color in dark mode, like `light-dark()` in CSS.
	*/
	public static func lightDark(_ light: Self, _ dark: Self) -> Self {
		Self("light-dark(\(light), \(dark))")
	}

	/**
	The color made lighter (positive amount) or darker (negative amount) in OKLCH, where the lightness goes from 0 to 1. Good for hover shades.
	*/
	public func lighter(_ amount: Double) -> Self {
		Self("oklch(from \(self) calc(l + \(CSSValue.format(amount))) c h)")
	}

	public static let transparent = Self("transparent")
	public static let currentColor = Self("currentColor")
	public static let inherit = Self("inherit")
}

/**
A box shadow.
*/
public struct Shadow: Hashable, Sendable, CustomStringConvertible {
	public let x: Length
	public let y: Length
	public let blur: Length
	public let spread: Length
	public let color: Color
	public let isInset: Bool

	public init(x: Length = 0, y: Length, blur: Length = 0, spread: Length = 0, color: Color, isInset: Bool = false) {
		self.x = x
		self.y = y
		self.blur = blur
		self.spread = spread
		self.color = color
		self.isInset = isInset
	}

	public var description: String {
		"\(isInset ? "inset " : "")\(x) \(y) \(blur) \(spread) \(color)"
	}

	/**
	A ring around the element, like a focus ring.
	*/
	public static func ring(_ width: Length, _ color: Color) -> Self {
		Self(y: 0, spread: width, color: color)
	}
}

public struct FontWeight: Hashable, Sendable, ExpressibleByIntegerLiteral {
	public let value: Int

	public init(integerLiteral value: Int) {
		self.value = value
	}

	public static let regular: Self = 400
	public static let medium: Self = 500
	public static let semibold: Self = 600
	public static let bold: Self = 700
	public static let heavy: Self = 800
}

/**
A font stack, like `ui-monospace, monospace`.
*/
public struct FontFamily: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
	public let description: String

	public init(stringLiteral value: String) {
		self.description = value
	}
}

/**
A minimum screen width for styles, like a Tailwind breakpoint.
*/
public struct Breakpoint: Hashable, Sendable {
	/**
	The minimum screen width, in rem.
	*/
	public let minimumWidthInRem: Double

	public init(minimumWidthInRem: Double) {
		self.minimumWidthInRem = minimumWidthInRem
	}

	public var minimumWidth: Length {
		.rem(minimumWidthInRem)
	}
}

/**
The edges of a box. The leading and trailing edges follow the writing direction, like in SwiftUI.
*/
public enum Edge {
	public struct Set: OptionSet, Hashable, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		public static let top = Self(rawValue: 1 << 0)
		public static let trailing = Self(rawValue: 1 << 1)
		public static let bottom = Self(rawValue: 1 << 2)
		public static let leading = Self(rawValue: 1 << 3)
		public static let horizontal: Self = [.leading, .trailing]
		public static let vertical: Self = [.top, .bottom]
		public static let all: Self = [.horizontal, .vertical]
	}
}

public enum Display: String, Sendable {
	case none
	case block
	case inline
	case inlineBlock = "inline-block"
	case flex
	case inlineFlex = "inline-flex"
	case grid
}

public enum Position: String, Sendable {
	/**
	The normal flow, like for an element that is positioned only on some screens.
	*/
	case `static`
	case relative
	case absolute
	case fixed
	case sticky
}

public enum FlexDirection: String, Sendable {
	case row
	case column
}

public enum Alignment: String, Sendable {
	case start = "flex-start"
	case center
	case end = "flex-end"
	case baseline
}

public enum Justification: String, Sendable {
	case start = "flex-start"
	case center
	case end = "flex-end"
	case spaceBetween = "space-between"
}

public enum TextAlignment: String, Sendable {
	case leading = "start"
	case center
	case trailing = "end"
}

public enum TextCase: String, Sendable {
	case uppercase
	case none
}

public enum TextSelection: String, Sendable {
	case enabled = "auto"
	case disabled = "none"
}

public enum FontWidth: String, Sendable {
	case standard = "normal"
	case expanded
}

/**
A shape for ``Style/cornerRadius(_:)-(RoundedShape)``.
*/
public enum RoundedShape: Sendable {
	/**
	Fully rounded ends, like a pill.
	*/
	case capsule

	case circle

	var radius: Length {
		switch self {
		case .capsule:
			.px(9999)
		case .circle:
			.percent(50)
		}
	}
}

/**
An angle, like for ``Style/rotationEffect(_:)``.
*/
public struct Angle: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	public static func degrees(_ degrees: Double) -> Self {
		Self(description: CSSValue.format(degrees) + "deg")
	}
}

/**
How an animation or a transition speeds up and slows down.
*/
public struct AnimationCurve: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	A timing function written as CSS, like `linear(0, .5 7.7%, 1)`.
	*/
	public init(_ css: String) {
		self.description = css
	}

	public static let ease = Self("ease")
	public static let easeIn = Self("ease-in")
	public static let easeOut = Self("ease-out")
	public static let easeInOut = Self("ease-in-out")
	public static let linear = Self("linear")

	public static func cubicBezier(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Self {
		Self("cubic-bezier(\([x1, y1, x2, y2].map(CSSValue.format).joined(separator: ", ")))")
	}
}

public enum AnimationFillMode: String, Sendable {
	case forwards
	case both
}

/**
The properties a transition animates.
*/
public struct TransitionProperty: Hashable, Sendable {
	let properties: [String]

	public init(_ property: Property) {
		self.properties = [property.description]
	}

	private init(properties: [String]) {
		self.properties = properties
	}

	/**
	The text, background, and border colors.
	*/
	public static let colors = Self(properties: ["color", "background-color", "border-color"])

	public static let color = Self(.color)
	public static let backgroundColor = Self(.backgroundColor)
	public static let background = Self(.background)
	public static let borderColor = Self(.borderColor)
	public static let underlineColor = Self(.textDecorationColor)
	public static let opacity = Self(.opacity)
	/**
	The transform, and the separate properties of the effect modifiers, like ``Style/scaleEffect(_:)``.
	*/
	public static let transform = Self(properties: ["transform", "translate", "scale", "rotate"])
	public static let shadow = Self(.boxShadow)
	public static let textShadow = Self(.textShadow)
	public static let filter = Self(.filter)
	public static let height = Self(.height)

	/**
	The switch to and from `display: none`, and in and out of the top layer, so an element fades out before it is hidden. It needs `transition-behavior: allow-discrete`.
	*/
	public static let display = Self(properties: ["display", "overlay"])
}

extension Duration {
	/**
	The duration in seconds, like `.15s`.
	*/
	var cssValue: String {
		let (seconds, attoseconds) = components
		return CSSValue.format(Double(seconds) + Double(attoseconds) / 1e18) + "s"
	}
}

public enum TextWrap: String, Sendable {
	case balance
	case pretty
}

public enum Overflow: String, Sendable {
	case visible
	case hidden
	case clip
	case auto
}

public enum Overscroll: String, Sendable {
	case auto
	case contain
	case none
}

public enum Cursor: String, Sendable {
	case pointer
	case auto
	case `default`
}

extension CSSValue {
	public init(_ length: Length) {
		self.init(length.description)
	}

	public init(_ color: Color) {
		self.init(color.description)
	}
}
