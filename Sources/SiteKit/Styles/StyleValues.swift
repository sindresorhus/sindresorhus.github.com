import Foundation

/**
A CSS length, like `1rem`, `50%`, or `auto`: a number and a unit, or a CSS expression.

The integer literal `0` is a length without a unit. Lengths with the same unit add up to one length, and other lengths add up to a `calc()` expression.
*/
public struct Length: StyleValue, Hashable, ExpressibleByIntegerLiteral {
	private enum Unit: String, Sendable {
		/**
		No unit, like `0`.
		*/
		case unitless = ""

		/**
		A multiple of the font size of the root element (`rem` in CSS).
		*/
		case rootEm = "rem"

		/**
		A multiple of the font size of the element (`em` in CSS).
		*/
		case em

		/**
		Pixels (`px` in CSS).
		*/
		case pixels = "px"

		/**
		A percentage (`%` in CSS).
		*/
		case percent = "%"

		/**
		A percentage of the viewport height (`vh` in CSS).
		*/
		case viewportHeight = "vh"

		/**
		A percentage of the viewport width (`vw` in CSS).
		*/
		case viewportWidth = "vw"

		/**
		A percentage of the dynamic viewport height, which follows the browser toolbars on phones (`dvh` in CSS).
		*/
		case dynamicViewportHeight = "dvh"

		/**
		A percentage of the small viewport height, which is the height with the browser toolbars shown (`svh` in CSS).
		*/
		case smallViewportHeight = "svh"

		/**
		The line height of the element (`lh` in CSS).
		*/
		case lineHeight = "lh"

		/**
		The height of the capital letters of the font of the element (`cap` in CSS).
		*/
		case capitalHeight = "cap"

		/**
		A percentage of the inline size of the container (`cqi` in CSS). The container units use the small viewport when there is no container.
		*/
		case containerInlineSize = "cqi"

		/**
		A percentage of the block size of the container (`cqb` in CSS).
		*/
		case containerBlockSize = "cqb"

		/**
		A percentage of the width of the container (`cqw` in CSS).
		*/
		case containerWidth = "cqw"

		/**
		A percentage of the height of the container (`cqh` in CSS).
		*/
		case containerHeight = "cqh"

		/**
		A percentage of the smaller of the inline size and the block size of the container (`cqmin` in CSS).
		*/
		case containerMinimum = "cqmin"

		/**
		A percentage of the larger of the inline size and the block size of the container (`cqmax` in CSS).
		*/
		case containerMaximum = "cqmax"
	}

	private enum Storage: Hashable, Sendable {
		case value(Double, Unit)

		/**
		A length written as CSS, like `auto` or `var(--size)`.
		*/
		case expression(String)

		/**
		The expression inside `calc()` that the arithmetic operators build, like `100dvh - 4rem`.
		*/
		case calculation(String)
	}

	private let storage: Storage

	private init(storage: Storage) {
		self.storage = storage
	}

	private init(_ value: Double, _ unit: Unit) {
		self.init(storage: .value(value, unit))
	}

	/**
	A length written as CSS, like `fit-content(20rem)`. Prefer the typed lengths and functions, like ``clamp(_:_:_:)``.
	*/
	public init(_ css: String) {
		self.init(storage: .expression(css))
	}

	public init(integerLiteral value: Int) {
		self.init(Double(value), .unitless)
	}

	public var description: String {
		switch storage {
		case .value(let value, let unit):
			CSSValue.format(value) + unit.rawValue
		case .expression(let css):
			css
		case .calculation(let expression):
			"calc(\(expression))"
		}
	}

	/**
	A multiple of the font size of the root element (`rem` in CSS).
	*/
	public static func rootEm(_ value: Double) -> Self {
		Self(value, .rootEm)
	}

	/**
	A multiple of the font size of the element (`em` in CSS).
	*/
	public static func em(_ value: Double) -> Self {
		Self(value, .em)
	}

	/**
	Pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(value, .pixels)
	}

	/**
	A percentage (`%` in CSS).
	*/
	public static func percent(_ value: Double) -> Self {
		Self(value, .percent)
	}

	/**
	A percentage of the viewport height (`vh` in CSS).
	*/
	public static func viewportHeight(_ value: Double) -> Self {
		Self(value, .viewportHeight)
	}

	/**
	A percentage of the viewport width (`vw` in CSS).
	*/
	public static func viewportWidth(_ value: Double) -> Self {
		Self(value, .viewportWidth)
	}

	/**
	A percentage of the dynamic viewport height, which follows the browser toolbars on phones (`dvh` in CSS).
	*/
	public static func dynamicViewportHeight(_ value: Double) -> Self {
		Self(value, .dynamicViewportHeight)
	}

	/**
	A percentage of the small viewport height, which is the height with the browser toolbars shown (`svh` in CSS).
	*/
	public static func smallViewportHeight(_ value: Double) -> Self {
		Self(value, .smallViewportHeight)
	}

	/**
	A multiple of the line height of the element (`lh` in CSS), like `.lineHeight(1)` for the height of one line of text.
	*/
	public static func lineHeight(_ value: Double) -> Self {
		Self(value, .lineHeight)
	}

	/**
	A multiple of the height of the capital letters of the font of the element (`cap` in CSS), like `.capitalHeight(1)` to line up an icon with the top of the capital letters.
	*/
	public static func capitalHeight(_ value: Double) -> Self {
		Self(value, .capitalHeight)
	}

	/**
	A percentage of the inline size of the nearest container (`cqi` in CSS), which is the width for horizontal text, like `.containerInlineSize(100)` for the width of the content of a card with ``Style/containerType(_:)``. Unlike a percentage, it is the same for all descendants of the container, and it works in properties where a percentage is of something else, like `translate`, where it is of the element itself, and `font-size`.

	Without a container, the container units use the small viewport, like ``smallViewportHeight(_:)``.
	*/
	public static func containerInlineSize(_ value: Double) -> Self {
		Self(value, .containerInlineSize)
	}

	/**
	A percentage of the block size of the nearest container with ``ContainerType/size`` (`cqb` in CSS), which is the height for horizontal text. See ``containerInlineSize(_:)``.
	*/
	public static func containerBlockSize(_ value: Double) -> Self {
		Self(value, .containerBlockSize)
	}

	/**
	A percentage of the width of the nearest container (`cqw` in CSS). See ``containerInlineSize(_:)``.
	*/
	public static func containerWidth(_ value: Double) -> Self {
		Self(value, .containerWidth)
	}

	/**
	A percentage of the height of the nearest container with ``ContainerType/size`` (`cqh` in CSS). See ``containerInlineSize(_:)``.
	*/
	public static func containerHeight(_ value: Double) -> Self {
		Self(value, .containerHeight)
	}

	/**
	A percentage of the smaller of ``containerInlineSize(_:)`` and ``containerBlockSize(_:)`` (`cqmin` in CSS). Its block size needs a container with ``ContainerType/size``, like ``containerBlockSize(_:)``.
	*/
	public static func containerMinimum(_ value: Double) -> Self {
		Self(value, .containerMinimum)
	}

	/**
	A percentage of the larger of ``containerInlineSize(_:)`` and ``containerBlockSize(_:)`` (`cqmax` in CSS). Its block size needs a container with ``ContainerType/size``, like ``containerBlockSize(_:)``.
	*/
	public static func containerMaximum(_ value: Double) -> Self {
		Self(value, .containerMaximum)
	}

	public static let auto = Self("auto")

	/**
	The preferred length, but not less than the minimum or more than the maximum, like `clamp()` in CSS. Good for sizes that follow the viewport within limits.

	```swift
	Length.clamp(.rootEm(2), .viewportWidth(10), .rootEm(4))
	//=> clamp(2rem, 10vw, 4rem)
	```
	*/
	public static func clamp(_ minimum: Self, _ preferred: Self, _ maximum: Self) -> Self {
		function("clamp", [minimum, preferred, maximum])
	}

	/**
	The smallest of the lengths, like `min()` in CSS.

	```swift
	Length.min(.rootEm(24), .viewportWidth(100) - .rootEm(2))
	//=> min(24rem, calc(100vw - 2rem))
	```
	*/
	public static func min(_ lengths: Self...) -> Self {
		function("min", lengths)
	}

	/**
	The largest of the lengths, like `max()` in CSS.

	```swift
	Length.max(.percent(100), .rootEm(2.75))
	//=> max(100%, 2.75rem)
	```
	*/
	public static func max(_ lengths: Self...) -> Self {
		function("max", lengths)
	}

	/**
	The position of a side of an anchor, for an inset of a positioned element, like `top(.anchor(header, .bottom))` for an element that starts below the header.

	```swift
	Length.anchor(Anchor("--site-header"), .bottom)
	//=> anchor(--site-header bottom)
	```
	*/
	public static func anchor(_ anchor: Anchor, _ side: AnchorSide) -> Self {
		Self("anchor(\(anchor.name) \(side.rawValue))")
	}

	/**
	The position of a side of the default anchor of the element: the anchor of ``Style/positionAnchor(_:)``, or the button that opened a popover. See ``anchor(_:_:)``.
	*/
	public static func anchor(_ side: AnchorSide) -> Self {
		Self("anchor(\(side.rawValue))")
	}

	/**
	A CSS function of lengths, like `min(1rem, 5vw)`.
	*/
	private static func function(_ name: String, _ arguments: [Self]) -> Self {
		Self("\(name)(\(arguments.map(\.description).joined(separator: ", ")))")
	}

	/**
	The length as an operand of `calc()`, in parentheses when it is a calculation.
	*/
	private var calculationOperand: String {
		guard case .calculation(let expression) = storage else {
			return description
		}

		return "(\(expression))"
	}

	/**
	The length as the first operand of an addition or a subtraction in `calc()`, which needs no parentheses, as they are evaluated from left to right.
	*/
	private var leadingSummand: String {
		guard case .calculation(let expression) = storage else {
			return description
		}

		return expression
	}

	private var isUnitlessZero: Bool {
		storage == .value(0, .unitless)
	}

	/**
	The sum or the difference of two lengths: one length when they have the same unit, and a `calc()` expression otherwise. A unitless `0` is left out, as it is invalid next to a length in `calc()`.
	*/
	private static func combine(_ lhs: Self, _ rhs: Self, operator: String, _ operation: (Double, Double) -> Double) -> Self {
		if
			case .value(let lhsValue, let lhsUnit) = lhs.storage,
			case .value(let rhsValue, let rhsUnit) = rhs.storage,
			lhsUnit == rhsUnit
		{
			return Self(operation(lhsValue, rhsValue), lhsUnit)
		}

		if rhs.isUnitlessZero {
			return lhs
		}

		return Self(storage: .calculation("\(lhs.leadingSummand) \(`operator`) \(rhs.calculationOperand)"))
	}

	public static func + (lhs: Self, rhs: Self) -> Self {
		guard !lhs.isUnitlessZero else {
			return rhs
		}

		return combine(lhs, rhs, operator: "+", +)
	}

	public static func - (lhs: Self, rhs: Self) -> Self {
		guard !lhs.isUnitlessZero else {
			return -rhs
		}

		return combine(lhs, rhs, operator: "-", -)
	}

	public static func * (lhs: Self, rhs: Double) -> Self {
		guard case .value(let value, let unit) = lhs.storage else {
			return Self(storage: .calculation("\(lhs.calculationOperand) * \(CSSValue.format(rhs))"))
		}

		return Self(value * rhs, unit)
	}

	public static prefix func - (length: Self) -> Self {
		length * -1
	}
}

/**
A CSS color, like `#2563eb` or `oklch(55.1% .027 264.364)`.
*/
public struct Color: StyleValue, Hashable, ExpressibleByStringLiteral {
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
		let percent = Self.percentage(ofFraction: opacity)

		// Black and white are plain `rgb()`, which is shorter and easier to read.
		switch self {
		case .black:
			return Self("rgb(0 0 0 / \(percent))")
		case .white:
			return Self("rgb(255 255 255 / \(percent))")
		default:
			return Self("color-mix(in oklab, \(self) \(percent), transparent)")
		}
	}

	/**
	A color from a hue, a saturation, and a lightness, like `hsl(200 100% 65%)`. The saturation and the lightness are from 0 to 1. The hue is in degrees, and can be a CSS value, like a custom property, so it can change in CSS.
	*/
	public static func hsl(hue: CSSValue, saturation: Double, lightness: Double) -> Self {
		Self("hsl(\(hue) \(percentage(ofFraction: saturation)) \(percentage(ofFraction: lightness)))")
	}

	/**
	A fraction from 0 to 1 as a percentage, like `3.5%` for 0.035.
	*/
	private static func percentage(ofFraction fraction: Double) -> CSSValue {
		// Rounded, as `0.035 * 100` is `3.5000000000000004`.
		.percent((fraction * 100_000).rounded() / 1000)
	}

	/**
	The color mixed with another color in OKLCH, like `color-mix(in oklch, blue, pink 30%)`. The amount is how much of the other color there is, like `.percent(30)`, or a custom property.
	*/
	public func mix(with other: Self, amount: CSSValue) -> Self {
		Self("color-mix(in oklch, \(self), \(other) \(amount))")
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

	/**
	The color at a position of a gradient, like `Color.white.at(.percent(40))`, instead of colors that are spread evenly.
	*/
	public func at(_ position: Length) -> GradientStop {
		GradientStop(color: self, position: position)
	}

	/**
	White. Its ``opacity(_:)`` is plain `rgb()`.
	*/
	public static let white = Self("#fff")

	/**
	Black. Its ``opacity(_:)`` is plain `rgb()`.
	*/
	public static let black = Self("#000")
	public static let transparent = Self("transparent")
	public static let currentColor = Self("currentColor")
	public static let inherit = Self("inherit")
}

/**
A color at a position of a gradient, like `Color.white.at(.percent(40))`. See ``Color/at(_:)``.
*/
public struct GradientStop: Hashable, Sendable, CustomStringConvertible {
	public let color: Color
	public let position: Length

	public var description: String {
		"\(color) \(position)"
	}
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
	The shadow without the spread and the inset, for `text-shadow` and `drop-shadow()`, which do not have them.
	*/
	var descriptionWithoutSpread: String {
		"\(x) \(y) \(blur) \(color)"
	}
}

/**
A filter for ``Style/filter(_:)`` and ``Style/backdropFilter(_:)``, like a blur.
*/
public struct Filter: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	A filter written as CSS, like a `drop-shadow()` with `calc()`.
	*/
	public init(_ css: String) {
		self.description = css
	}

	/**
	No filters.
	*/
	public static let none = Self("none")

	/**
	Blurs the element, like SwiftUI's `blur(radius:)`.
	*/
	public static func blur(radius: Length) -> Self {
		Self("blur(\(radius))")
	}

	/**
	Brightens (above 1) or darkens (below 1) the element, with 1 as no change, as in CSS.
	*/
	public static func brightness(_ amount: Double) -> Self {
		Self("brightness(\(CSSValue.format(amount)))")
	}

	/**
	Makes the colors more (above 1) or less (below 1) intense, like SwiftUI's `saturation(_:)`.
	*/
	public static func saturation(_ amount: Double) -> Self {
		Self("saturate(\(CSSValue.format(amount)))")
	}

	/**
	Turns the colors around the color wheel by the angle, like SwiftUI's `hueRotation(_:)`.
	*/
	public static func hueRotation(_ angle: Angle) -> Self {
		Self("hue-rotate(\(angle))")
	}

	/**
	Removes the colors (1) or part of them (between 0 and 1), like SwiftUI's `grayscale(_:)`.
	*/
	public static func grayscale(_ amount: Double) -> Self {
		Self("grayscale(\(CSSValue.format(amount)))")
	}

	/**
	Makes the difference between light and dark larger (above 1) or smaller (below 1), like SwiftUI's `contrast(_:)`.
	*/
	public static func contrast(_ amount: Double) -> Self {
		Self("contrast(\(CSSValue.format(amount)))")
	}

	/**
	Inverts the colors (1) or part of the way (between 0 and 1), like SwiftUI's `colorInvert()`, where black becomes white.
	*/
	public static func invert(_ amount: Double) -> Self {
		Self("invert(\(CSSValue.format(amount)))")
	}

	/**
	Tints the colors brown like an old photo (1), or part of the way (between 0 and 1).
	*/
	public static func sepia(_ amount: Double) -> Self {
		Self("sepia(\(CSSValue.format(amount)))")
	}

	/**
	Makes the element transparent, where `1` is opaque. Unlike the `opacity` property, it can be in a list of filters.
	*/
	public static func opacity(_ opacity: Double) -> Self {
		Self("opacity(\(CSSValue.format(opacity)))")
	}

	/**
	A shadow that follows the shape of the content, like transparent parts of an image.
	*/
	public static func dropShadow(_ shadow: Shadow) -> Self {
		Self("drop-shadow(\(shadow.descriptionWithoutSpread))")
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
A minimum screen width for styles, like `.tablet` for screens at least as wide as a tablet.
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
		.rootEm(minimumWidthInRem)
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
	case inlineGrid = "inline-grid"

	/**
	No box of its own, so its children are laid out as children of its parent, like the items of a grid.
	*/
	case contents

	/**
	A block that contains its floats, so a floated image does not stick out below it.
	*/
	case flowRoot = "flow-root"
}

/**
What a container measures for the container units of its descendants, like ``Length/containerInlineSize(_:)``. See ``Style/containerType(_:)``.
*/
public enum ContainerType: String, Sendable {
	/**
	The inline size, which is the width for horizontal text. The inline size of the element does not depend on its content, so it must get it from its parent, like a block.
	*/
	case inlineSize = "inline-size"

	/**
	The inline size and the block size. The size of the element does not depend on its content, so it needs a height.
	*/
	case size
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

/**
How a counter is written, for ``Style/content(counter:style:)``.
*/
public enum CounterStyle: String, Sendable {
	/**
	Like “1” and “12”.
	*/
	case decimal

	/**
	Like “01” and “12”.
	*/
	case decimalLeadingZero = "decimal-leading-zero"
}

/**
How an inline element lines up with the text of its line, for ``Style/verticalAlign(_:)``.
*/
public enum VerticalTextAlignment: String, Sendable {
	case baseline
	case top
	case middle
	case bottom
}

/**
What a background is drawn in, for ``Style/backgroundClip(_:)``. `text` draws it only in the letters, like for gradient text.
*/
public enum BackgroundClip: String, Sendable {
	case borderBox = "border-box"
	case paddingBox = "padding-box"
	case contentBox = "content-box"
	case text
}

/**
How an element blends with what is behind it. See ``Style/blendMode(_:)``.
*/
public enum BlendMode: String, Sendable {
	case normal
	case multiply
	case screen
	case overlay
	case darken
	case lighten
}

/**
How an image or a video fills its frame. See ``Style/objectFit(_:)``.
*/
public enum ObjectFit: String, Sendable {
	case fill
	case contain
	case cover
	case none
	case scaleDown = "scale-down"
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
			.pixels(9999)
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
How long an animation or a transition takes, and how it speeds up and slows down, like SwiftUI's `Animation`:

```swift
.easeInOut(duration: .seconds(18)).repeatForever()
```
*/
public struct Animation: Hashable, Sendable {
	let duration: Duration

	/**
	The timing function, or `nil` for the CSS default, `ease`.
	*/
	let timingFunction: String?

	private(set) var repeatsForever = false
	private(set) var autoreverses = false

	private init(duration: Duration, timingFunction: String?) {
		self.duration = duration
		self.timingFunction = timingFunction
	}

	/**
	The CSS default, `ease`, which starts fast and slows down at the end.
	*/
	public static func `default`(duration: Duration) -> Self {
		Self(duration: duration, timingFunction: nil)
	}

	public static func linear(duration: Duration) -> Self {
		Self(duration: duration, timingFunction: "linear")
	}

	public static func easeIn(duration: Duration) -> Self {
		Self(duration: duration, timingFunction: "ease-in")
	}

	public static func easeOut(duration: Duration) -> Self {
		Self(duration: duration, timingFunction: "ease-out")
	}

	public static func easeInOut(duration: Duration) -> Self {
		Self(duration: duration, timingFunction: "ease-in-out")
	}

	/**
	A cubic Bézier timing curve with two control points, like SwiftUI's `timingCurve(_:_:_:_:duration:)`. Control points above 1 overshoot, like a spring.
	*/
	public static func timingCurve(_ c0x: Double, _ c0y: Double, _ c1x: Double, _ c1y: Double, duration: Duration) -> Self {
		Self(duration: duration, timingFunction: "cubic-bezier(\([c0x, c0y, c1x, c1y].map(CSSValue.format).joined(separator: ", ")))")
	}

	/**
	A timing function written as CSS, like `linear(0, .5 7.7%, 1.06 23.7%, 1)` for a spring that bounces.
	*/
	public static func timingCurve(_ timingFunction: String, duration: Duration) -> Self {
		Self(duration: duration, timingFunction: timingFunction)
	}

	/**
	The animation, repeated forever.

	- Parameter autoreverses: Whether every other run plays backwards.
	*/
	public func repeatForever(autoreverses: Bool = true) -> Self {
		var copy = self
		copy.repeatsForever = true
		copy.autoreverses = autoreverses
		return copy
	}

	/**
	The duration and the timing function, like `.2s ease-out`.
	*/
	var timing: String {
		[duration.cssValue, timingFunction].compactMap(\.self).joined(separator: " ")
	}
}

/**
The progress of an element through the view, which scroll-driven animations of other elements can follow. Give it to the element with ``Style/viewTimeline(_:)``.
*/
public struct ViewTimeline: Hashable, Sendable {
	let name: String

	/**
	- Parameter name: A custom property name, like `--hero`.
	*/
	public init(_ name: String) {
		precondition(name.hasPrefix("--"), "A timeline name starts with two hyphens: \(name)")
		self.name = name
	}
}

/**
What a scroll-driven animation follows instead of time.
*/
public enum AnimationTimeline: Hashable, Sendable, CustomStringConvertible {
	/**
	The scrolling of the nearest scroll container, like the page.
	*/
	case scroll

	/**
	The progress of another element through the view.
	*/
	case view(ViewTimeline)

	public var description: String {
		switch self {
		case .scroll:
			"scroll()"
		case .view(let timeline):
			timeline.name
		}
	}
}

/**
An element that other elements are positioned next to, like a menu below the header. Give it to the element with ``Style/anchorName(_:)``, and position the other elements with ``Style/positionAnchor(_:)`` and ``Style/positionArea(_:)``, or with ``Length/anchor(_:_:)``.
*/
public struct Anchor: Hashable, Sendable {
	let name: String

	/**
	- Parameter name: A custom property name, like `--site-header`.
	*/
	public init(_ name: String) {
		precondition(name.hasPrefix("--"), "An anchor name starts with two hyphens: \(name)")
		self.name = name
	}
}

/**
A side of an anchor, for ``Length/anchor(_:_:)``.
*/
public enum AnchorSide: String, Sendable {
	/**
	The top of the anchor, only in an inset of the vertical axis, like `top`.
	*/
	case top

	/**
	The bottom of the anchor, only in an inset of the vertical axis, like `top`.
	*/
	case bottom

	/**
	The start of the anchor in the axis of the property, like its top in `top`, and its leading edge in `inset-inline-start`.
	*/
	case start

	/**
	The end of the anchor in the axis of the property, like its bottom in `top`, and its trailing edge in `inset-inline-start`.
	*/
	case end

	case center
}

/**
Where a positioned element goes around its anchor, for ``Style/positionArea(_:)``.
*/
public enum PositionArea: String, Sendable {
	/**
	Above the anchor, centered on it, like a tooltip. It can be wider than the anchor, as the area spans the whole width (`top span-all`).
	*/
	case top

	/**
	Below the anchor, centered on it. It can be wider than the anchor, as the area spans the whole width (`bottom span-all`).
	*/
	case bottom

	/**
	Before the anchor in the writing direction, centered on it vertically.
	*/
	case inlineStart = "inline-start"

	/**
	After the anchor in the writing direction, centered on it vertically, like a submenu.
	*/
	case inlineEnd = "inline-end"
}

/**
Another position that the browser tries when a positioned element does not fit, for ``Style/positionTryFallbacks(_:_:)``.
*/
public enum PositionTryFallback: String, Sendable {
	/**
	The other side of the anchor in the block direction, like below it instead of above it.
	*/
	case flipBlock = "flip-block"

	/**
	The other side of the anchor in the inline direction, like after it instead of before it.
	*/
	case flipInline = "flip-inline"

	/**
	The position mirrored across the diagonal from the start corner to the end corner, like before the anchor instead of above it.
	*/
	case flipStart = "flip-start"
}

/**
A feature that some browsers do not support yet, for ``Style/supports(_:_:)``.
*/
public struct BrowserFeature: Hashable, Sendable, CustomStringConvertible {
	/**
	The condition of `@supports`, like `(position-area: top)`.
	*/
	public let description: String

	public init(_ condition: String) {
		self.description = condition
	}

	/**
	Transitions to and from keywords like `auto`, like the height of the content of a `details` element.
	*/
	public static let interpolateSize = Self("(interpolate-size: allow-keywords)")

	/**
	Animations that follow the scrolling of the page.
	*/
	public static let scrollTimeline = Self("(animation-timeline: scroll())")

	/**
	Animations that follow an element through the view.
	*/
	public static let viewTimeline = Self("(animation-timeline: view())")

	/**
	Trimming the space above the capital letters and below the baseline with `text-box`.
	*/
	public static let textBoxTrim = Self("(text-box: trim-both cap alphabetic)")

	/**
	Styles for the parts of scroll bars, like ``Style/scrollbar(_:_:)``, which Chrome and Safari have.
	*/
	public static let webKitScrollbar = Self("selector(::-webkit-scrollbar)")

	/**
	The browser does not support the feature, like `.supports(!.webKitScrollbar)`.
	*/
	public static prefix func ! (feature: Self) -> Self {
		Self("not (\(feature))")
	}
}

public enum AnimationFillMode: String, Sendable {
	case forwards
	case both
}

/**
The properties a transition animates. The effects are named like the modifiers that set them, like ``scaleEffect`` for ``Style/scaleEffect(_:)``, so a transition lists only the property that changes.
*/
public struct TransitionProperty: Hashable, Sendable {
	let properties: [Property]

	/**
	Whether the property switches between values instead of changing gradually, which needs `allow-discrete`.
	*/
	let isDiscrete: Bool

	public init(_ property: Property) {
		self.init(properties: [property])
	}

	private init(properties: [Property], isDiscrete: Bool = false) {
		self.properties = properties
		self.isDiscrete = isDiscrete
	}

	/**
	The text, background, and border colors.
	*/
	public static let colors = Self(properties: [.color, .backgroundColor, .borderColor])

	public static let color = Self(.color)
	public static let backgroundColor = Self(.backgroundColor)
	public static let background = Self(.background)
	public static let borderColor = Self(.borderColor)
	public static let underlineColor = Self(.textDecorationColor)
	public static let opacity = Self(.opacity)

	/**
	The scale from ``Style/scaleEffect(_:)``.
	*/
	public static let scaleEffect = Self(.scale)

	/**
	The move from ``Style/offset(x:y:)``.
	*/
	public static let offset = Self(.translate)

	/**
	The rotation from ``Style/rotationEffect(_:)``.
	*/
	public static let rotationEffect = Self(.rotate)

	/**
	The transform from ``Style/transform(_:)``.
	*/
	public static let transform = Self(.transform)

	public static let shadow = Self(.boxShadow)
	public static let textShadow = Self(.textShadow)
	public static let filter = Self(.filter)

	/**
	The switch from ``Style/visibility(_:)``. The element stays visible until a fade out ends, and is visible as soon as a fade in starts.
	*/
	public static let visibility = Self(.visibility)
	public static let height = Self(.height)

	/**
	The switch to and from `display: none`, and in and out of the top layer, so an element fades out before it is hidden.
	*/
	public static let display = Self(properties: [.display, .overlay], isDiscrete: true)

	/**
	The switch of `content-visibility`, like of the content of a `details` element, so the content stays shown while it closes.
	*/
	public static let contentVisibility = Self(properties: [.contentVisibility], isDiscrete: true)
}

extension Duration {
	/**
	The duration in seconds, like `.15s`.
	*/
	var cssValue: String {
		CSSValue.format(self / .seconds(1)) + "s"
	}
}

public enum TextWrap: String, Sendable {
	case balance
	case pretty

	/**
	Keeps the text on one line.
	*/
	case nowrap
}

/**
Where a long word, like a URL, can break when it does not fit on a line.
*/
public enum OverflowWrap: String, Sendable {
	/**
	Breaks a word that does not fit on a line of its own.
	*/
	case breakWord = "break-word"

	/**
	Breaks a word that does not fit, and the element can shrink to the width of a letter, like in a flex item or a grid cell.
	*/
	case anywhere
}

/**
Whether a scrolling element shows its scroll bars.
*/
public enum ScrollIndicatorVisibility: String, Sendable {
	case automatic = "auto"
	case hidden = "none"
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

/**
The direction of the scrolling that snaps, for ``Style/scrollSnapType(_:isMandatory:)``.
*/
public enum ScrollSnapAxis: String, Sendable {
	case horizontal = "x"
	case vertical = "y"
	case both
}

/**
Where an element stops when the scrolling snaps, for ``Style/scrollSnapAlign(_:)``.
*/
public enum ScrollSnapAlignment: String, Sendable {
	case start
	case center
	case end
}

/**
Whether an element keeps the space of a classic scroll bar, for ``Style/scrollbarGutter(_:)``.
*/
public enum ScrollbarGutter: String, Sendable {
	case auto

	/**
	The space of the scroll bar, also when the element does not scroll.
	*/
	case stable

	/**
	The space of the scroll bar on both sides, so the content stays centered.
	*/
	case stableBothEdges = "stable both-edges"
}

/**
How an element scrolls to a link or a script position, for ``Style/scrollBehavior(_:)``.
*/
public enum ScrollBehavior: String, Sendable {
	case auto
	case smooth
}

/**
The color schemes that an element supports, for ``Style/colorScheme(_:)``.
*/
public enum ColorScheme: String, Sendable {
	case light
	case dark

	/**
	Both, following the setting of the visitor.
	*/
	case lightDark = "light dark"
}

/**
How a form field is sized, for ``Style/fieldSizing(_:)``.
*/
public enum FieldSizing: String, Sendable {
	/**
	The default size of the field, like the number of rows of a text area.
	*/
	case fixed

	/**
	The size of its content, so a text area grows with its text.
	*/
	case content
}

/**
A leading or trailing edge, which follows the writing direction, for ``Style/float(_:)``.
*/
public enum HorizontalEdge: String, Sendable {
	case leading = "inline-start"
	case trailing = "inline-end"
}

/**
The size of the rows or the columns of a grid, for ``Style/gridRows(_:size:)`` and ``Style/gridAutoColumns(_:)``.
*/
public struct GridTrack: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	private init(_ css: String) {
		self.description = css
	}

	/**
	The size of the content.
	*/
	public static let auto = Self("auto")

	/**
	A fixed size, like `.fixed(.rootEm(0.625))`.
	*/
	public static func fixed(_ size: Length) -> Self {
		Self(size.description)
	}

	/**
	A share of the free space, like `.fraction(1)` for tracks that share it equally (`1fr`).
	*/
	public static func fraction(_ share: Double) -> Self {
		Self(CSSValue.format(share) + "fr")
	}
}

/**
The direction in which the items without a cell fill a grid, for ``Style/gridAutoFlow(_:)``.
*/
public enum GridAutoFlow: String, Sendable {
	case row
	case column
}

public enum Cursor: String, Sendable {
	case pointer
	case auto
	case `default`

	/**
	A cross, for drawing or picking a point.
	*/
	case crosshair

	/**
	Arrows in four directions, for something that can be dragged.
	*/
	case move

	/**
	The busy pointer, like the hourglass of Windows, while something loads and the element cannot be used.
	*/
	case wait
}

/**
What a touch on the element does by default. See ``Style/touchAction(_:)``.
*/
public enum TouchAction: String, Sendable {
	case auto

	/**
	No scrolling or zooming, so a finger draws or drags instead, like on a canvas for drawing.
	*/
	case none

	/**
	Scrolling and pinch zooming, without the delay of a double-tap zoom.
	*/
	case manipulation

	/**
	Only scrolling up and down, so a finger that moves sideways drags instead, like on a toy that steers left and right, while the page still scrolls over it.
	*/
	case panY = "pan-y"
}

/**
The direction of the lines of text. See ``Style/writingMode(_:)``.
*/
public enum WritingMode: String, Sendable {
	case horizontal = "horizontal-tb"

	/**
	Lines from top to bottom, like a label on the side of a box. Rotate it by 180 degrees to read it from the bottom up.
	*/
	case verticalRightToLeft = "vertical-rl"
}

/**
How an image is scaled. See ``Style/imageRendering(_:)``.
*/
public enum ImageRendering: String, Sendable {
	case auto

	/**
	Large square pixels instead of a blur, for pixel art.
	*/
	case pixelated
}

/**
How a border is drawn. The 3D styles, like `outset`, draw the edges in lighter and darker shades of the color.
*/
public enum BorderStyle: String, Sendable {
	case solid
	case dashed
	case dotted
	case double
	case groove
	case ridge
	case inset
	case outset
}

/**
A part of a scroll bar in Chrome and Safari, for ``Style/scrollbar(_:_:)``. A part only shows a style when the `bar` has a style too, like a width.
*/
public enum ScrollbarPart: String, Sendable {
	/**
	The whole scroll bar. Its width and height are the size of the vertical and the horizontal scroll bar.
	*/
	case bar = "::-webkit-scrollbar"

	/**
	The groove that the thumb moves in.
	*/
	case track = "::-webkit-scrollbar-track"

	/**
	The handle that shows the position, which the visitor drags.
	*/
	case thumb = "::-webkit-scrollbar-thumb"

	/**
	The arrow buttons at the ends. They are hidden until they have a size. With a size, browsers show a pair at each end, so hide them and show `upButton` and `downButton` for one button at each end.
	*/
	case button = "::-webkit-scrollbar-button"

	/**
	The button at the top of a vertical scroll bar, which scrolls up.
	*/
	case upButton = "::-webkit-scrollbar-button:vertical:start:decrement"

	/**
	The button at the bottom of a vertical scroll bar, which scrolls down.
	*/
	case downButton = "::-webkit-scrollbar-button:vertical:end:increment"

	/**
	The corner where a vertical and a horizontal scroll bar meet.
	*/
	case corner = "::-webkit-scrollbar-corner"
}

