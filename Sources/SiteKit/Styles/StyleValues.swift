import Foundation

// MARK: Lengths and colors

/**
A unitless CSS number, kept distinct from lengths, percentages, colors, and images. Raw expressions are explicitly unchecked.
*/
public struct CSSNumber: StyleValue, Hashable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
	public let description: String

	/**
	A finite number, rounded with the same rules as other CSS numbers.
	*/
	public init(_ value: Double) {
		self.description = CSSValue.format(value)
	}

	/**
	A whole number without a floating-point conversion.
	*/
	public init(_ value: Int) {
		self.description = String(value)
	}

	/**
	An explicit unchecked number-valued CSS expression.
	*/
	public init(raw css: String) {
		self.description = css
	}

	public init(integerLiteral value: Int) {
		self.init(value)
	}

	public init(floatLiteral value: Double) {
		self.init(value)
	}

	/**
	The sum of two number-valued expressions, as a `calc` function.
	*/
	public static func + (lhs: Self, rhs: Self) -> Self {
		Self(raw: "calc(\(lhs) + \(rhs))")
	}

	/**
	The difference of two number-valued expressions.
	*/
	public static func - (lhs: Self, rhs: Self) -> Self {
		Self(raw: "calc(\(lhs) - \(rhs))")
	}

	/**
	The product of two number-valued expressions.
	*/
	public static func * (lhs: Self, rhs: Self) -> Self {
		Self(raw: "calc(\(lhs) * \(rhs))")
	}

	/**
	The quotient of two number-valued expressions, evaluated by the browser.
	*/
	public static func / (lhs: Self, rhs: Self) -> Self {
		Self(raw: "calc(\(lhs) / \(rhs))")
	}

	/**
	The negation of a number-valued expression.
	*/
	public static prefix func - (value: Self) -> Self {
		value * -1
	}

	/**
	The one-based position of the element among its element siblings (`sibling-index()` in CSS).
	*/
	public static let siblingIndex = Self(raw: "sibling-index()")

	/**
	The number of element siblings, including the element itself (`sibling-count()` in CSS).
	*/
	public static let siblingCount = Self(raw: "sibling-count()")
}

/**
A CSS percentage, like `35%`, kept distinct from physical lengths and unitless numbers.
*/
public struct Percentage: StyleValue, Hashable {
	public let description: String

	/**
	An explicit unchecked percentage-valued CSS expression.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	A percentage, like `.percent(35)` for `35%`. The argument is a percentage, not a fraction.
	*/
	public static func percent(_ value: Double) -> Self {
		Self(raw: CSSValue.format(value) + "%")
	}
}

/**
A CSS length with a unit, like `1rem` or `2px`. Percentages and mixed calculations belong to ``LengthPercentage``. This type is used where CSS does not accept percentages, like border widths, shadow offsets, and blur radii.
*/
public struct Length: StyleValue, Hashable {
	fileprivate let value: LengthPercentage

	private init(_ value: LengthPercentage) {
		self.value = value
	}

	/**
	An explicit unchecked CSS expression, like a length-valued custom property reference.
	*/
	public init(raw css: String) {
		self.value = LengthPercentage(raw: css)
	}

	public var description: String {
		value.description
	}

	/**
	The unitless length zero.
	*/
	public static let zero = Self(.zero)

	/**
	A multiple of the font size of the root element (`rem` in CSS).
	*/
	public static func rootEm(_ value: Double) -> Self {
		Self(.rootEm(value))
	}

	/**
	A multiple of the font size of the element (`em` in CSS).
	*/
	public static func em(_ value: Double) -> Self {
		Self(.em(value))
	}

	/**
	Pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(.pixels(value))
	}

	/**
	A multiple of the advance width of the `0` glyph of the font (`ch` in CSS).
	*/
	public static func characterWidth(_ value: Double) -> Self {
		Self(.characterWidth(value))
	}

	/**
	A percentage of the viewport height (`vh` in CSS).
	*/
	public static func viewportHeight(_ value: Double) -> Self {
		Self(.viewportHeight(value))
	}

	/**
	A percentage of the viewport width (`vw` in CSS).
	*/
	public static func viewportWidth(_ value: Double) -> Self {
		Self(.viewportWidth(value))
	}

	/**
	A percentage of the dynamic viewport height, which follows the browser toolbars on phones (`dvh` in CSS).
	*/
	public static func dynamicViewportHeight(_ value: Double) -> Self {
		Self(.dynamicViewportHeight(value))
	}

	/**
	A percentage of the small viewport height, which is the height with the browser toolbars shown (`svh` in CSS).
	*/
	public static func smallViewportHeight(_ value: Double) -> Self {
		Self(.smallViewportHeight(value))
	}

	/**
	A multiple of the line height of the element (`lh` in CSS), like `.lineHeight(1)` for the height of one line of text.
	*/
	public static func lineHeight(_ value: Double) -> Self {
		Self(.lineHeight(value))
	}

	/**
	A multiple of the height of the capital letters of the font of the element (`cap` in CSS), like `.capitalHeight(1)` to line up an icon with the top of the capital letters.
	*/
	public static func capitalHeight(_ value: Double) -> Self {
		Self(.capitalHeight(value))
	}

	/**
	A percentage of the inline size of the nearest container (`cqi` in CSS), which is the width for horizontal text, like `.containerInlineSize(100)` for the width of the content of a card with ``Style/containerType(_:)``. Unlike a percentage, it is the same for all descendants of the container, and it works in properties where a percentage is of something else, like `translate`, where it is of the element itself, and `font-size`.

	Without a container, the container units use the small viewport, like ``smallViewportHeight(_:)``.
	*/
	public static func containerInlineSize(_ value: Double) -> Self {
		Self(.containerInlineSize(value))
	}

	/**
	A percentage of the block size of the nearest container with ``ContainerType/size`` (`cqb` in CSS), which is the height for horizontal text. See ``containerInlineSize(_:)``.
	*/
	public static func containerBlockSize(_ value: Double) -> Self {
		Self(.containerBlockSize(value))
	}

	/**
	A percentage of the width of the nearest container (`cqw` in CSS). See ``containerInlineSize(_:)``.
	*/
	public static func containerWidth(_ value: Double) -> Self {
		Self(.containerWidth(value))
	}

	/**
	A percentage of the height of the nearest container with ``ContainerType/size`` (`cqh` in CSS). See ``containerInlineSize(_:)``.
	*/
	public static func containerHeight(_ value: Double) -> Self {
		Self(.containerHeight(value))
	}

	/**
	A percentage of the smaller of ``containerInlineSize(_:)`` and ``containerBlockSize(_:)`` (`cqmin` in CSS). Its block size needs a container with ``ContainerType/size``, like ``containerBlockSize(_:)``.
	*/
	public static func containerMinimum(_ value: Double) -> Self {
		Self(.containerMinimum(value))
	}

	/**
	A percentage of the larger of ``containerInlineSize(_:)`` and ``containerBlockSize(_:)`` (`cqmax` in CSS). Its block size needs a container with ``ContainerType/size``, like ``containerBlockSize(_:)``.
	*/
	public static func containerMaximum(_ value: Double) -> Self {
		Self(.containerMaximum(value))
	}

	/**
	The preferred length within the minimum and maximum.
	*/
	public static func clamp(_ minimum: Self, _ preferred: Self, _ maximum: Self) -> Self {
		Self(.clamp(minimum.value, preferred.value, maximum.value))
	}

	/**
	The smallest of one or more lengths.
	*/
	public static func min(_ first: Self, _ remaining: Self...) -> Self {
		Self(.function("min", ([first] + remaining).map(\.value)))
	}

	/**
	The largest of one or more lengths.
	*/
	public static func max(_ first: Self, _ remaining: Self...) -> Self {
		Self(.function("max", ([first] + remaining).map(\.value)))
	}

	public static func + (lhs: Self, rhs: Self) -> Self {
		Self(lhs.value + rhs.value)
	}

	public static func - (lhs: Self, rhs: Self) -> Self {
		Self(lhs.value - rhs.value)
	}

	public static func * (lhs: Self, rhs: Double) -> Self {
		Self(lhs.value * rhs)
	}

	/**
	Scales a length by a number-valued CSS expression, like a pointer strength custom property.
	*/
	public func scaled(by number: CSSNumber) -> Self {
		Self(value.scaled(by: number))
	}

	public static func / (lhs: Self, rhs: Double) -> Self {
		Self(lhs.value / rhs)
	}

	public static prefix func - (value: Self) -> Self {
		Self(-value.value)
	}
}

/**
A CSS length or percentage, like `1rem` or `50%`: a number and a unit, or a CSS expression. Sizing keywords belong to ``BoxSize`` and automatic margins and insets to ``AutoLength``.

`LengthPercentage.zero` is a length without a unit. Lengths with the same unit add up to one length, and other lengths add up to a `calc()` expression.
*/
public struct LengthPercentage: StyleValue, Hashable {
	/**
	A length promoted to the percentage-capable dimension domain.
	*/
	public init(_ length: Length) {
		self = length.value
	}

	/**
	A percentage promoted to the dimension domain, including a percentage-valued custom property reference.
	*/
	public init(_ percentage: Percentage) {
		self.init(storage: .expression(percentage.description))
	}

	private enum Unit: String {
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
		The advance width of the `0` glyph of the font (`ch` in CSS).
		*/
		case characterWidth = "ch"

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

	private enum Storage: Hashable {
		case value(Double, Unit)

		/**
		A length written as CSS, like `var(--size)`.
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
	A length or percentage written as CSS, like `var(--size)`. Prefer the typed lengths and functions, like ``clamp(_:_:_:)``.
	*/
	public init(raw css: String) {
		self.init(storage: .expression(css))
	}

	/**
	The length `0`. Another number needs a unit, like `.pixels(1)`, as the browser ignores a length like `1`.
	*/
	public static let zero = Self(0, .unitless)

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
	A multiple of the advance width of the `0` glyph of the font (`ch` in CSS).
	*/
	public static func characterWidth(_ value: Double) -> Self {
		Self(value, .characterWidth)
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

	/**
	The preferred length, but not less than the minimum or more than the maximum, like `clamp()` in CSS. Good for sizes that follow the viewport within limits.

	```swift
	LengthPercentage.clamp(.rootEm(2), .viewportWidth(10), .rootEm(4))
	//=> clamp(2rem, 10vw, 4rem)
	```
	*/
	public static func clamp(_ minimum: Self, _ preferred: Self, _ maximum: Self) -> Self {
		function("clamp", [minimum, preferred, maximum])
	}

	/**
	The smallest of the lengths, like `min()` in CSS.

	```swift
	LengthPercentage.min(.rootEm(24), .viewportWidth(100) - .rootEm(2))
	//=> min(24rem, 100vw - 2rem)
	```
	*/
	public static func min(_ first: Self, _ remaining: Self...) -> Self {
		function("min", [first] + remaining)
	}

	/**
	The largest of the lengths, like `max()` in CSS.

	```swift
	LengthPercentage.max(.percent(100), .rootEm(2.75))
	//=> max(100%, 2.75rem)
	```
	*/
	public static func max(_ first: Self, _ remaining: Self...) -> Self {
		function("max", [first] + remaining)
	}

	/**
	A CSS function of lengths, like `min(1rem, 5vw)`. An argument is a sum without `calc()` around it, like `min(24rem, 100vw - 2rem)`, as the arguments of the math functions are calculations.
	*/
	fileprivate static func function(_ name: String, _ arguments: [Self]) -> Self {
		Self(raw: "\(name)(\(arguments.map(\.calculationSum).joined(separator: ", ")))")
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
	The length in a calculation without `calc()` around it: as the first operand of an addition or a subtraction, which needs no parentheses, as they are evaluated from left to right, or as an argument of a math function, like `min()`.
	*/
	fileprivate var calculationSum: String {
		// In a math function, a unitless zero is a number rather than a length.
		if isUnitlessZero {
			return "0px"
		}

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
	private static func combine(
		_ lhs: Self,
		_ rhs: Self,
		operator: String,
		_ operation: (Double, Double) -> Double
	) -> Self {
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

		return Self(storage: .calculation("\(lhs.calculationSum) \(`operator`) \(rhs.calculationOperand)"))
	}

	public static func + (lhs: Self, rhs: Self) -> Self {
		guard !lhs.isUnitlessZero else {
			return rhs
		}

		return combine(
			lhs,
			rhs,
			operator: "+",
			+
		)
	}

	public static func - (lhs: Self, rhs: Self) -> Self {
		guard !lhs.isUnitlessZero else {
			return -rhs
		}

		return combine(
			lhs,
			rhs,
			operator: "-",
			-
		)
	}

	public static func * (lhs: Self, rhs: Double) -> Self {
		guard case .value(let value, let unit) = lhs.storage else {
			return Self(storage: .calculation("\(lhs.calculationOperand) * \(CSSValue.format(rhs))"))
		}

		return Self(value * rhs, unit)
	}

	/**
	Scales a length or a percentage by a number-valued CSS expression, like a pointer strength custom property.
	*/
	public func scaled(by number: CSSNumber) -> Self {
		Self(storage: .calculation("\(isUnitlessZero ? "0px" : calculationOperand) * \(number)"))
	}

	/**
	The length divided by a number, like `(100% - 1rem) / 3`. Exact, unlike multiplying by a rounded fraction.
	*/
	public static func / (lhs: Self, rhs: Double) -> Self {
		guard case .value(let value, let unit) = lhs.storage else {
			return Self(storage: .calculation("\(lhs.calculationOperand) / \(CSSValue.format(rhs))"))
		}

		return Self(value / rhs, unit)
	}

	public static prefix func - (length: Self) -> Self {
		length * -1
	}
}

/**
A value that can express a measurable length. ``AutoLength`` and ``BoxSize`` share the length constructors while keeping their keywords out of length arithmetic.
*/
public protocol LengthValue: StyleValue {
	/**
	Wraps a measurable length or calculation.
	*/
	init(_ length: LengthPercentage)
}

extension LengthValue {
	/**
	An existing length or calculation, serialized identically for automatic lengths and box sizes.
	*/
	public init(_ length: LengthPercentage) {
		self.init(raw: length.description)
	}

	/**
	An existing length or calculation.
	*/
	public static func length(_ length: LengthPercentage) -> Self {
		Self(length)
	}

	/**
	The unitless length zero.
	*/
	public static var zero: Self {
		Self(.zero)
	}

	/**
	A multiple of the root font size (`rem` in CSS).
	*/
	public static func rootEm(_ value: Double) -> Self {
		Self(.rootEm(value))
	}

	/**
	A multiple of the element font size (`em` in CSS).
	*/
	public static func em(_ value: Double) -> Self {
		Self(.em(value))
	}

	/**
	Pixels (`px` in CSS).
	*/
	public static func pixels(_ value: Double) -> Self {
		Self(.pixels(value))
	}

	/**
	A multiple of the advance width of the `0` glyph of the font (`ch` in CSS).
	*/
	public static func characterWidth(_ value: Double) -> Self {
		Self(.characterWidth(value))
	}

	/**
	A percentage (`%` in CSS).
	*/
	public static func percent(_ value: Double) -> Self {
		Self(.percent(value))
	}

	/**
	A percentage of viewport height (`vh` in CSS).
	*/
	public static func viewportHeight(_ value: Double) -> Self {
		Self(.viewportHeight(value))
	}

	/**
	A percentage of viewport width (`vw` in CSS).
	*/
	public static func viewportWidth(_ value: Double) -> Self {
		Self(.viewportWidth(value))
	}

	/**
	A percentage of dynamic viewport height (`dvh` in CSS).
	*/
	public static func dynamicViewportHeight(_ value: Double) -> Self {
		Self(.dynamicViewportHeight(value))
	}

	/**
	A percentage of small viewport height (`svh` in CSS).
	*/
	public static func smallViewportHeight(_ value: Double) -> Self {
		Self(.smallViewportHeight(value))
	}

	/**
	A multiple of the line height (`lh` in CSS).
	*/
	public static func lineHeight(_ value: Double) -> Self {
		Self(.lineHeight(value))
	}

	/**
	A multiple of capital-letter height (`cap` in CSS).
	*/
	public static func capitalHeight(_ value: Double) -> Self {
		Self(.capitalHeight(value))
	}

	/**
	A percentage of container inline size (`cqi` in CSS).
	*/
	public static func containerInlineSize(_ value: Double) -> Self {
		Self(.containerInlineSize(value))
	}

	/**
	A percentage of container block size (`cqb` in CSS).
	*/
	public static func containerBlockSize(_ value: Double) -> Self {
		Self(.containerBlockSize(value))
	}

	/**
	A percentage of container width (`cqw` in CSS).
	*/
	public static func containerWidth(_ value: Double) -> Self {
		Self(.containerWidth(value))
	}

	/**
	A percentage of container height (`cqh` in CSS).
	*/
	public static func containerHeight(_ value: Double) -> Self {
		Self(.containerHeight(value))
	}

	/**
	A percentage of the smaller container dimension (`cqmin` in CSS).
	*/
	public static func containerMinimum(_ value: Double) -> Self {
		Self(.containerMinimum(value))
	}

	/**
	A percentage of the larger container dimension (`cqmax` in CSS).
	*/
	public static func containerMaximum(_ value: Double) -> Self {
		Self(.containerMaximum(value))
	}

	/**
	The preferred length within the minimum and maximum (`clamp()` in CSS).
	*/
	public static func clamp(_ minimum: LengthPercentage, _ preferred: LengthPercentage, _ maximum: LengthPercentage) -> Self {
		Self(.clamp(minimum, preferred, maximum))
	}
}

/**
A margin or positional inset: a measurable length or `auto`. Keywords cannot participate in length arithmetic; wrap a calculation with ``length(_:)``.
*/
public struct AutoLength: LengthValue, Hashable {
	public let description: String

	/**
	A raw CSS value. Prefer the typed constructors.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	The automatic margin or position (`auto` in CSS).
	*/
	public static let auto = Self(raw: "auto")
}

/**
A width or height: a measurable length, an automatic size, or a size determined by the content. Keywords cannot participate in length arithmetic; wrap a calculation with ``length(_:)``.
*/
public struct BoxSize: LengthValue, Hashable {
	public let description: String

	/**
	A raw CSS value. Prefer the typed constructors.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	The automatic width or height (`auto` in CSS).
	*/
	public static let auto = Self(raw: "auto")

	/**
	As wide as the content, but not wider than the space, like a label that is a block of its own line but has its background only behind its text (`fit-content` in CSS).
	*/
	public static let fitContent = Self(raw: "fit-content")

	/**
	The smallest intrinsic size (`min-content` in CSS).
	*/
	public static let minimumContent = Self(raw: "min-content")

	/**
	The preferred intrinsic size (`max-content` in CSS).
	*/
	public static let maximumContent = Self(raw: "max-content")
}

/**
A maximum width or height: a measurable length, an intrinsic size, or `none` for no limit. Unlike ``BoxSize``, it cannot be `auto`.
*/
public struct MaximumBoxSize: LengthValue, Hashable {
	public let description: String

	/**
	An explicit unchecked CSS maximum size. Prefer the typed constructors.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	No maximum size (`none` in CSS). Named `unlimited` to distinguish it from an omitted optional maximum.
	*/
	public static let unlimited = Self(raw: "none")

	/**
	The available size, limited by the content (`fit-content` in CSS).
	*/
	public static let fitContent = Self(raw: "fit-content")

	/**
	The smallest intrinsic size (`min-content` in CSS).
	*/
	public static let minimumContent = Self(raw: "min-content")

	/**
	The preferred intrinsic size (`max-content` in CSS).
	*/
	public static let maximumContent = Self(raw: "max-content")
}

/**
The rendered size of a background or mask image: its dimensions, or the image scaled to cover or fit within the area.
*/
public enum ImageSize: Hashable, Sendable, CustomStringConvertible {
	case cover
	case contain
	case dimensions(width: AutoLength, height: AutoLength)

	public var description: String {
		switch self {
		case .cover:
			"cover"
		case .contain:
			"contain"
		case .dimensions(let width, let height):
			"\(width) \(height)"
		}
	}
}

/**
An aspect ratio that preserves width and height as number-valued CSS expressions. Components must resolve to nonnegative values; a zero component is a degenerate ratio, which CSS treats as automatic sizing.
*/
public enum AspectRatio: Hashable, Sendable, CustomStringConvertible {
	case auto
	case ratio(width: CSSNumber, height: CSSNumber)

	/**
	Uses an image's intrinsic ratio when available, with the given ratio as its fallback (`auto <ratio>` in CSS).
	*/
	case automatic(width: CSSNumber, height: CSSNumber)

	public var description: String {
		switch self {
		case .auto:
			"auto"
		case .ratio(let width, let height):
			"\(width) / \(height)"
		case .automatic(let width, let height):
			"auto \(width) / \(height)"
		}
	}
}

/**
A line height: the font's normal spacing, a unitless multiplier, or a length or percentage. Multipliers and percentages remain distinct because their inheritance differs.
*/
public enum LineHeight: Hashable, Sendable, CustomStringConvertible {
	case normal
	case multiple(CSSNumber)
	case length(LengthPercentage)

	public var description: String {
		switch self {
		case .normal:
			"normal"
		case .multiple(let value):
			value.description
		case .length(let value):
			value.description
		}
	}
}

/**
A CSS color, like `#2563eb` or `oklch(55.1% .027 264.364)`.
*/
public struct Color: StyleValue, Hashable, ExpressibleByStringLiteral {
	public let description: String

	public init(raw css: String) {
		self.description = css
	}

	public init(stringLiteral value: String) {
		self.init(raw: value)
	}

	/**
	The color with transparency, where `1` is opaque.
	*/
	public func opacity(_ opacity: Double) -> Self {
		let percent = Self.percentage(ofFraction: opacity)

		// Black and white are plain `rgb()`, which is shorter and easier to read.
		switch self {
		case .black:
			return Self(raw: "rgb(0 0 0 / \(percent))")
		case .white:
			return Self(raw: "rgb(255 255 255 / \(percent))")
		default:
			return Self(raw: "color-mix(in oklab, \(self) \(percent), transparent)")
		}
	}

	/**
	A color from a hue, a saturation, and a lightness, like `hsl(200 100% 65%)`. The saturation and the lightness are percentages. The hue is in degrees, and can be a CSS value, like a custom property, so it can change in CSS.
	*/
	public static func hsl(hue: CSSNumber, saturation: Percentage, lightness: Percentage) -> Self {
		Self(raw: "hsl(\(hue) \(saturation) \(lightness))")
	}

	/**
	A color with an angle-valued hue, including an angle custom property. Unitless hues use the numeric overload.
	*/
	public static func hsl(hue: Angle, saturation: Percentage, lightness: Percentage) -> Self {
		Self(raw: "hsl(\(hue) \(saturation) \(lightness))")
	}

	/**
	A color in OKLCH. The lightness is a percentage, chroma is a unitless number, and hue is an angle. Each component may be a typed CSS expression.
	*/
	public static func oklch(lightness: Percentage, chroma: CSSNumber, hue: Angle) -> Self {
		Self(raw: "oklch(\(lightness) \(chroma) \(hue))")
	}

	/**
	An opaque RGB color, with components bounded to bytes.
	*/
	public static func rgb(red: UInt8, green: UInt8, blue: UInt8) -> Self {
		Self(raw: "rgb(\(red) \(green) \(blue))")
	}

	/**
	A fraction from 0 to 1 as a percentage, like `3.5%` for 0.035. The number is rounded when it is written (``CSSValue/format(_:)``), as `0.035 * 100` is `3.5000000000000004`.
	*/
	private static func percentage(ofFraction fraction: Double) -> CSSValue {
		.percent(fraction * 100)
	}

	/**
	The color mixed with another color in OKLCH, like `color-mix(in oklch, blue, pink 30%)`. The amount is how much of the other color there is, like `.percent(30)`, or a custom property.
	*/
	public func mix(with other: Self, amount: Percentage) -> Self {
		Self(raw: "color-mix(in oklch, \(self), \(other) \(amount))")
	}

	/**
	The color, with another color in dark mode, like `light-dark()` in CSS.
	*/
	public static func lightDark(_ light: Self, _ dark: Self) -> Self {
		Self(raw: "light-dark(\(light), \(dark))")
	}

	/**
	The color made lighter (positive amount) or darker (negative amount) in OKLCH, where the lightness goes from 0 to 1. Good for hover shades.
	*/
	public func lighter(_ amount: Double) -> Self {
		Self(raw: "oklch(from \(self) calc(l + \(CSSValue.format(amount))) c h)")
	}

	/**
	The color at a position of a gradient, like `Color.white.at(.percent(40))`, instead of colors that are spread evenly.
	*/
	public func at(_ position: LengthPercentage) -> GradientStop {
		GradientStop(color: self, position: position)
	}

	/**
	A solid color between two positions of a gradient, like `.black.at(.zero, through: .pixels(12))`.
	*/
	public func at(_ position: LengthPercentage, through endPosition: LengthPercentage) -> GradientStop {
		GradientStop(color: self, position: position, endPosition: endPosition)
	}

	/**
	White. Its ``opacity(_:)`` is plain `rgb()`.
	*/
	public static let white = Self(raw: "#fff")

	/**
	Black. Its ``opacity(_:)`` is plain `rgb()`.
	*/
	public static let black = Self(raw: "#000")
	public static let transparent = Self(raw: "transparent")
	public static let currentColor = Self(raw: "currentColor")

	/**
	The color of links in forced colors, like Windows High Contrast (`LinkText` in CSS), for something that forced colors would otherwise paint in the background color.
	*/
	public static let linkText = Self(raw: "LinkText")

	/**
	The background color of forced colors, like Windows High Contrast (`Canvas` in CSS).
	*/
	public static let canvas = Self(raw: "Canvas")

	/**
	The text color of forced colors, like Windows High Contrast (`CanvasText` in CSS).
	*/
	public static let canvasText = Self(raw: "CanvasText")
}

/**
A color at a position of a gradient, like `Color.white.at(.percent(40))`. See ``Color/at(_:)``.
*/
public struct GradientStop: Hashable, Sendable, CustomStringConvertible {
	public let color: Color
	public let position: LengthPercentage
	public let endPosition: LengthPercentage?

	/**
	A color at one position, or solid between two positions.
	*/
	public init(color: Color, position: LengthPercentage, endPosition: LengthPercentage? = nil) {
		self.color = color
		self.position = position
		self.endPosition = endPosition
	}

	public var description: String {
		"\(color) \(position)" + (endPosition.map { " \($0)" } ?? "")
	}
}

/**
A two-dimensional CSS position, measured from the top-left corner of its positioning area. The meaning of percentages depends on the property, such as the element’s dimensions for a gradient.
*/
public struct CSSPosition: Hashable, Sendable, CustomStringConvertible {
	/**
	The center of the positioning area.
	*/
	public static let center = Self(x: .percent(50), y: .percent(50))

	public let x: LengthPercentage
	public let y: LengthPercentage

	/**
	A position in lengths or percentages, like `.init(x: .percent(20), y: .percent(40))`.
	*/
	public init(x: LengthPercentage, y: LengthPercentage) {
		self.x = x
		self.y = y
	}

	public var description: String {
		"\(x) \(y)"
	}
}

/**
The size keywords of a radial gradient, measured from its center to the sides or corners of the element.
*/
public enum RadialGradientExtent: String, CSSKeyword {
	case closestSide = "closest-side"
	case closestCorner = "closest-corner"
	case farthestSide = "farthest-side"
	case farthestCorner = "farthest-corner"
}

/**
The shape, size, and center of a radial gradient. A circle has one radius and an ellipse has two. Without a radius or extent, it reaches the farthest corner; without a position, it is centered.
*/
public struct RadialGradientShape: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	An explicit escape for uncommon CSS shapes that the typed constructors cannot express.
	*/
	public init(raw: String) {
		self.description = raw
	}

	public static let circle = Self.circle()
	public static let ellipse = Self.ellipse()

	/**
	A circle, optionally with an explicit radius and center. A circle radius is a length, not a percentage.
	*/
	public static func circle(radius: Length? = nil, at position: CSSPosition? = nil) -> Self {
		shape("circle", size: radius?.description, position: position)
	}

	/**
	An ellipse with horizontal and vertical radii and an optional center. Radii may be percentages.
	*/
	public static func ellipse(radiusX: LengthPercentage, radiusY: LengthPercentage, at position: CSSPosition? = nil) -> Self {
		shape("ellipse", size: "\(radiusX) \(radiusY)", position: position)
	}

	/**
	An ellipse, optionally sized to a side or corner, with an optional center.
	*/
	public static func ellipse(extent: RadialGradientExtent? = nil, at position: CSSPosition? = nil) -> Self {
		shape("ellipse", size: extent?.rawValue, position: position)
	}

	/**
	A circle sized to a side or corner, with an optional center.
	*/
	public static func circle(extent: RadialGradientExtent, at position: CSSPosition? = nil) -> Self {
		shape("circle", size: extent.rawValue, position: position)
	}

	/**
	The shape with its optional size and position as CSS.
	*/
	private static func shape(_ name: String, size: String?, position: CSSPosition?) -> Self {
		Self(raw: [name, size, position.map { "at \($0)" }].compactMap(\.self).joined(separator: " "))
	}
}

/**
The color space that a gradient mixes its colors in, like `in oklch` in `linear-gradient(to right in oklch, blue, pink)`.
*/
public enum ColorSpace: String, CSSKeyword {
	/**
	Mixes the hues, so a gradient between distant colors has no gray middle.
	*/
	case oklch

	case oklab
}

/**
A shadow of text or the shape of content, for `text-shadow` and `drop-shadow()`, which have no spread and cannot be inset. A ``BoxShadow`` is a shadow of an element's box.
*/
public struct Shadow: Hashable, Sendable, CustomStringConvertible {
	public let x: Length
	public let y: Length
	public let blur: Length
	public let color: Color

	/**
	A shadow offset from the text or content, with a blur radius and color.
	*/
	public init(x: Length = .zero, y: Length, blur: Length = .zero, color: Color) {
		self.x = x
		self.y = y
		self.blur = blur
		self.color = color
	}

	public var description: String {
		"\(x) \(y) \(blur) \(color)"
	}
}

/**
A box shadow, with a spread radius and an optional inset inside the element. Text and drop shadows use ``Shadow``, which does not have these box-only values.
*/
public struct BoxShadow: Hashable, Sendable, CustomStringConvertible {
	public let x: Length
	public let y: Length
	public let blur: Length
	public let spread: Length
	public let color: Color
	public let isInset: Bool

	/**
	A shadow offset from the box, with blur and spread radii, a color, and whether it is inset.
	*/
	public init(
		x: Length = .zero,
		y: Length,
		blur: Length = .zero,
		spread: Length = .zero,
		color: Color,
		isInset: Bool = false
	) {
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
}

// MARK: Conditions

/**
A minimum screen width for styles, like `.tablet` for screens at least as wide as a tablet.
*/
public struct Breakpoint: Hashable, Sendable {
	/**
	The minimum screen width, in rem.
	*/
	public let minimumWidthInRem: Double

	/**
	Creates a breakpoint at a finite nonnegative width in root-font units.
	*/
	public init(minimumWidthInRem: Double) {
		precondition(minimumWidthInRem.isFinite && minimumWidthInRem >= 0, "A breakpoint width must be finite and nonnegative.")
		self.minimumWidthInRem = minimumWidthInRem
	}

	public var minimumWidth: LengthPercentage {
		.rootEm(minimumWidthInRem)
	}
}

/**
A feature that some browsers do not support yet, for ``Style/supports(_:_:)``.
*/
public struct BrowserFeature: Hashable, Sendable, CustomStringConvertible {
	/**
	The condition of `@supports`, like `(position-area: top)`.
	*/
	public let description: String

	/**
	An explicit unchecked `@supports` condition.
	*/
	public init(raw condition: String) {
		self.description = condition
	}

	/**
	Checks the single declaration produced by a typed modifier, like `.declaration { $0.interpolateSize(.allowKeywords) }`. Conditions, registrations, multiple declarations, and `!important` are not support tests.
	*/
	public static func declaration(_ content: (Style) -> Style) -> Self {
		let style = content(Style())
		precondition(style.declarations.count == 1 && style.children.isEmpty && style.definitions.isEmpty, "A support test requires exactly one plain declaration.")
		let declaration = style.declarations[0]
		precondition(!declaration.isImportant, "A support test cannot use !important.")
		return Self(raw: "(\(declaration.property): \(declaration.value))")
	}

	/**
	Checks a selector's syntax, including pseudo-elements.
	*/
	public static func selector(_ selector: CSSSelector) -> Self {
		Self(raw: "selector(\(selector))")
	}

	/**
	Transitions to and from keywords like `auto`, like the height of the content of a `details` element.
	*/
	public static let interpolateSize = Self.declaration {
		$0.interpolateSize(.allowKeywords)
	}

	/**
	Animations that follow the scrolling of the page.
	*/
	public static let scrollTimeline = Self(raw: "(animation-timeline: scroll())")

	/**
	Animations that follow an element through the view.
	*/
	public static let viewTimeline = Self(raw: "(animation-timeline: view())")

	/**
	Trimming the space above the capital letters and below the baseline with `text-box`.
	*/
	public static let textBoxTrim = Self(raw: "(text-box: trim-both cap alphabetic)")

	/**
	Styles for the parts of scroll bars, like ``Style/scrollbar(_:_:)``, which Chrome and Safari have.
	*/
	public static let webKitScrollbar = Self.selector("::-webkit-scrollbar")

	/**
	Checks that both conditions hold, preserving their grouping.
	*/
	public static func && (lhs: Self, rhs: Self) -> Self {
		Self(raw: "(\(lhs)) and (\(rhs))")
	}

	/**
	Checks that at least one condition holds, preserving its grouping.
	*/
	public static func || (lhs: Self, rhs: Self) -> Self {
		Self(raw: "(\(lhs)) or (\(rhs))")
	}

	/**
	The browser does not support the feature, like `.supports(!.webKitScrollbar)`.
	*/
	public static prefix func ! (feature: Self) -> Self {
		Self(raw: "not (\(feature))")
	}
}

// MARK: Stacks and grids

public enum Display: String, CSSKeyword {
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

public enum FlexDirection: String, CSSKeyword {
	case row
	case column
}

/**
Whether the items of a flex container wrap onto more lines when they do not fit (`flex-wrap` in CSS).
*/
public enum FlexWrap: String, CSSKeyword {
	case wrap

	/**
	Each new line goes above the last one instead of below it, like a pile that grows from the bottom.
	*/
	case wrapReversed = "wrap-reverse"

	/**
	Keeps the items on one line, like a row that scrolls sideways, also inside an element that wraps them.
	*/
	case nowrap
}

public enum Alignment: String, CSSKeyword {
	case start = "flex-start"
	case center
	case end = "flex-end"
	case baseline

	/**
	Fills the cross axis, like cards of one height in a row.
	*/
	case stretch
}

public enum Justification: String, CSSKeyword {
	case start = "flex-start"
	case center
	case end = "flex-end"
	case spaceBetween = "space-between"
}

/**
The size of the rows or the columns of a grid, for ``Style/gridRows(_:size:)`` and ``Style/gridAutoColumns(_:)``.
*/
public struct GridTrack: StyleValue, Hashable {
	public let description: String

	/**
	A grid track written as CSS, like `minmax(0, 1fr)`.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	The size of the content.
	*/
	public static let auto = Self(raw: "auto")

	/**
	A fixed size, like `.fixed(.rootEm(0.625))`.
	*/
	public static func fixed(_ size: LengthPercentage) -> Self {
		Self(raw: size.description)
	}

	/**
	A share of the free space, like `.fraction(1)` for tracks that share it equally (`1fr`).
	*/
	public static func fraction(_ share: Double) -> Self {
		precondition(share.isFinite && share >= 0, "A grid fraction must be finite and nonnegative.")
		return Self(raw: CSSValue.format(share) + "fr")
	}

	/**
	A flexible track with a length-or-percentage minimum and a fractional share of the remaining space, like `minmax(0, 1fr)`. Other valid track grammars remain available with `init(raw:)`.
	*/
	public static func flexible(minimum: LengthPercentage = .zero, fraction: Double = 1) -> Self {
		Self(raw: "minmax(\(minimum), \(Self.fraction(fraction)))")
	}
}

/**
A list of grid tracks. Fixed repeats accept tracks rather than lists, so typed composition cannot accidentally nest `repeat()`. Raw CSS remains an explicit escape for other grid grammars.
*/
public struct GridTrackList: StyleValue, Hashable {
	public let description: String

	/**
	A track list written as unchecked CSS.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	One or more tracks in their written order.
	*/
	public init(_ first: GridTrack, _ remaining: GridTrack...) {
		self.init([first] + remaining)
	}

	/**
	A nonempty collection of tracks, such as a grid assembled from data.
	*/
	public init(_ tracks: [GridTrack]) {
		precondition(!tracks.isEmpty, "A grid track list must not be empty.")
		self.description = tracks.map(\.description).joined(separator: " ")
	}

	/**
	A positive fixed number of copies of a track.
	*/
	public static func repeating(_ track: GridTrack, count: Int) -> Self {
		precondition(count > 0, "A repeated grid track needs a positive count.")
		return Self(raw: "repeat(\(count), \(track))")
	}

	/**
	A leading track followed by fixed repetitions, such as a row label and its data columns. Keeping this constructor separate from adaptive lists avoids combining incompatible automatic repetitions.
	*/
	public init(_ leading: GridTrack, repeating track: GridTrack, count: Int) {
		self.init(raw: "\(leading) \(Self.repeating(track, count: count))")
	}

	/**
	As many flexible columns as fit, each at least the minimum width and never wider than the container. The fixed minimum keeps automatic repetition valid CSS.
	*/
	public static func adaptive(minimum: LengthPercentage) -> Self {
		Self(raw: "repeat(auto-fill, minmax(\(LengthPercentage.min(.percent(100), minimum)), 1fr))")
	}

	/**
	Adaptive tracks with a column limit. Their minimum accounts for the gaps, so the maximum number fits exactly without introducing another column.
	*/
	public static func adaptive(minimum: LengthPercentage, maximumColumns: Int, spacing: LengthPercentage) -> Self {
		precondition(maximumColumns > 0, "A grid or column count must be positive.")
		let narrowestColumn = LengthPercentage.max(.min(.percent(100), minimum), (.percent(100) - spacing * Double(maximumColumns - 1)) / Double(maximumColumns))
		return Self(raw: "repeat(auto-fill, minmax(\(narrowestColumn), 1fr))")
	}
}

/**
The direction in which the items without a cell fill a grid, for ``Style/gridAutoFlow(_:)``.
*/
public enum GridAutoFlow: String, CSSKeyword {
	case row
	case column
}

// MARK: Size and position

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
		public static let right = Self(rawValue: 1 << 1)
		public static let bottom = Self(rawValue: 1 << 2)
		public static let left = Self(rawValue: 1 << 3)
		public static let horizontal: Self = [.left, .right]
		public static let vertical: Self = [.top, .bottom]
		public static let all: Self = [.horizontal, .vertical]

		/**
		The start of the inline axis (`inline-start`), following the writing mode and text direction.
		*/
		public static let leading = Self(rawValue: 1 << 4)

		/**
		The end of the inline axis (`inline-end`), following the writing mode and text direction.
		*/
		public static let trailing = Self(rawValue: 1 << 5)

		/**
		The start of the block axis (`block-start`), following the writing mode.
		*/
		public static let blockStart = Self(rawValue: 1 << 6)

		/**
		The end of the block axis (`block-end`), following the writing mode.
		*/
		public static let blockEnd = Self(rawValue: 1 << 7)

		/**
		Both edges of the inline axis, following the writing mode and text direction.
		*/
		public static let inline: Self = [.leading, .trailing]

		/**
		Both edges of the block axis, following the writing mode.
		*/
		public static let block: Self = [.blockStart, .blockEnd]
	}
}

/**
How an image or a video fills its frame. See ``Style/objectFit(_:)``.
*/
public enum ObjectFit: String, CSSKeyword {
	case fill
	case contain
	case cover
	case none
	case scaleDown = "scale-down"
}

/**
What a container measures for the container units of its descendants, like ``LengthPercentage/containerInlineSize(_:)``. See ``Style/containerType(_:)``.
*/
public enum ContainerType: String, CSSKeyword {
	/**
	The inline size, which is the width for horizontal text. The inline size of the element does not depend on its content, so it must get it from its parent, like a block.
	*/
	case inlineSize = "inline-size"

	/**
	The inline size and the block size. The size of the element does not depend on its content, so it needs a height.
	*/
	case size
}

/**
Whether a declared size includes padding and borders (`box-sizing` in CSS).
*/
public enum BoxSizing: String, CSSKeyword {
	case contentBox = "content-box"
	case borderBox = "border-box"
}

public enum Position: String, CSSKeyword {
	/**
	The normal flow, like for an element that is positioned only on some screens.
	*/
	case `static`
	case relative
	case absolute
	case fixed
	case sticky
}

/**
An element that other elements are positioned next to, like a menu below the header. Give it to the element with ``Style/anchorName(_:)``, and position the other elements with ``Style/positionAnchor(_:)`` and ``Style/positionArea(_:)``, or with ``Style/top(anchor:side:)``.
*/
public struct Anchor: Hashable, Sendable {
	let name: DashedIdentifier

	/**
	- Parameter name: The name without the CSS `--` prefix, like `site-header`.
	*/
	public init(_ name: DashedIdentifier) {
		self.name = name
	}
}

/**
A side of an anchor, for ``Style/top(anchor:side:)``.
*/
public enum AnchorSide: String, CSSKeyword {
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
public enum PositionArea: String, CSSKeyword {
	/**
	Above the anchor, centered on it, like a tooltip. It can be wider than the anchor, as the area spans the whole width (`top span-all`).
	*/
	case top

	/**
	Below the anchor, centered on it. It can be wider than the anchor, as the area spans the whole width (`bottom span-all`).
	*/
	case bottom

	/**
	Below the anchor, from its left edge to the right, like a preview that starts where its link starts (`bottom span-right` in CSS). With ``PositionTryFallback/flipInline``, it ends at the right edge of the anchor when there is no space to the right.
	*/
	case bottomSpanRight = "bottom span-right"

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
public enum PositionTryFallback: String, CSSKeyword {
	/**
	The other side of the anchor in the block direction, like below it instead of above it.
	*/
	case flipBlock = "flip-block"

	/**
	The other side of the anchor in the inline direction, like after it instead of before it.
	*/
	case flipInline = "flip-inline"

	/**
	The other side of the anchor in the two directions, like above it and to the left instead of below it and to the right (`flip-block flip-inline` in CSS).
	*/
	case flipBlockAndInline = "flip-block flip-inline"

	/**
	The position mirrored across the diagonal from the start corner to the end corner, like before the anchor instead of above it.
	*/
	case flipStart = "flip-start"

	/**
	Centered below the anchor, for when no position at an edge of the anchor fits, like in a narrow window.
	*/
	case bottom

	/**
	Centered above the anchor.
	*/
	case top
}

public enum Overflow: String, CSSKeyword {
	case visible
	case hidden
	case clip
	case auto
}

/**
A leading or trailing edge, which follows the writing direction, for ``Style/float(_:)``.
*/
public enum HorizontalEdge: String, CSSKeyword {
	case leading = "inline-start"
	case trailing = "inline-end"
}

/**
Whether a scrolling element shows its scroll bars.
*/
public enum ScrollIndicatorVisibility: String, CSSKeyword {
	case automatic = "auto"
	case hidden = "none"
}

public enum Overscroll: String, CSSKeyword {
	case auto
	case contain
	case none
}

/**
The direction of the scrolling that snaps, for ``Style/scrollSnapType(_:isMandatory:)``.
*/
public enum ScrollSnapAxis: String, CSSKeyword {
	case horizontal = "x"
	case vertical = "y"
	case both
}

/**
Where an element stops when the scrolling snaps, for ``Style/scrollSnapAlign(_:)``.
*/
public enum ScrollSnapAlignment: String, CSSKeyword {
	case start
	case center
	case end
}

/**
Whether an element keeps the space of a classic scroll bar, for ``Style/scrollbarGutter(_:)``.
*/
public enum ScrollbarGutter: String, CSSKeyword {
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
public enum ScrollBehavior: String, CSSKeyword {
	case auto
	case smooth
}

// MARK: Text

/**
The weight of a font, like ``bold`` or `650` for a weight between two named ones.
*/
public struct FontWeight: StyleValue, Hashable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
	public let description: String

	/**
	A weight written as CSS, like `var(--weight)`.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	A numeric weight in the CSS range from 1 through 1000, including fractional variable-font weights.
	*/
	public init(_ value: Double) {
		precondition(value.isFinite && (1...1000).contains(value), "A font weight must be finite and between 1 and 1000.")
		self.init(raw: CSSValue.format(value))
	}

	public init(integerLiteral value: Int) {
		self.init(Double(value))
	}

	public init(floatLiteral value: Double) {
		self.init(value)
	}

	public static let regular: Self = 400
	public static let medium: Self = 500
	public static let semibold: Self = 600
	public static let bold: Self = 700
	public static let heavy: Self = 800

	/**
	A weight bolder than the weight of the parent (`bolder` in CSS), like the default weight of `<b>` and `<strong>`.
	*/
	public static let bolder = Self(raw: "bolder")

	/**
	The weight of the parent (`inherit` in CSS), like for a link in a bold summary.
	*/
	public static let inherit = Self(raw: "inherit")
}

/**
The style of the digits, for ``Style/fontVariantNumeric(_:)``.
*/
public struct FontVariantNumeric: OptionSet, Hashable, Sendable, CustomStringConvertible {
	public let rawValue: Int

	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	/**
	Digits with the same width, so the digits of numbers in a column line up (`tabular-nums` in CSS).
	*/
	public static let tabularNumbers = Self(rawValue: 1 << 0)

	/**
	Digits with ascenders and descenders, like lowercase letters, so numbers blend into running text (`oldstyle-nums` in CSS).
	*/
	public static let oldstyleNumbers = Self(rawValue: 1 << 1)

	public var description: String {
		let keywords = [
			contains(.tabularNumbers) ? "tabular-nums" : nil,
			contains(.oldstyleNumbers) ? "oldstyle-nums" : nil
		]
		.compactMap(\.self)

		return keywords.isEmpty ? "normal" : keywords.joined(separator: " ")
	}
}

/**
The punctuation that hangs outside the box of the text, for ``Style/hangingPunctuation(_:)``.
*/
public struct HangingPunctuation: OptionSet, Hashable, Sendable, CustomStringConvertible {
	public let rawValue: Int

	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	/**
	An opening quote or bracket at the start of the first line.
	*/
	public static let first = Self(rawValue: 1 << 0)

	/**
	A closing quote or bracket at the end of the last line.
	*/
	public static let last = Self(rawValue: 1 << 1)

	public var description: String {
		let keywords = [
			contains(.first) ? "first" : nil,
			contains(.last) ? "last" : nil
		]
		.compactMap(\.self)

		return keywords.isEmpty ? "none" : keywords.joined(separator: " ")
	}
}

/**
A font stack, like `ui-monospace, monospace`.
*/
public struct FontFamily: StyleValue, Hashable {
	public let description: String

	/**
	A font stack written as CSS.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	A named font, quoted and escaped as a CSS string.
	*/
	public static func named(_ name: String) -> Self {
		Self(raw: CSSValue.string(name).description)
	}

	/**
	One or more fallback families in preference order. Generic families stay unquoted.
	*/
	public static func stack(_ first: Self, _ remaining: Self...) -> Self {
		Self(raw: ([first] + remaining).map(\.description).joined(separator: ", "))
	}

	/**
	The generic serif family (`serif` in CSS).
	*/
	public static let genericSerif = Self(raw: "serif")

	/**
	The generic sans-serif family (`sans-serif` in CSS).
	*/
	public static let genericSansSerif = Self(raw: "sans-serif")

	/**
	The generic monospaced family (`monospace` in CSS).
	*/
	public static let genericMonospace = Self(raw: "monospace")

	/**
	The generic cursive family (`cursive` in CSS).
	*/
	public static let genericCursive = Self(raw: "cursive")

	/**
	The default user-interface font (`system-ui` in CSS).
	*/
	public static let systemUI = Self(raw: "system-ui")

	/**
	The sans-serif user-interface font (`ui-sans-serif` in CSS).
	*/
	public static let uiSansSerif = Self(raw: "ui-sans-serif")

	/**
	The serif user-interface font (`ui-serif` in CSS).
	*/
	public static let uiSerif = Self(raw: "ui-serif")

	/**
	The monospaced user-interface font (`ui-monospace` in CSS).
	*/
	public static let uiMonospace = Self(raw: "ui-monospace")

	/**
	The rounded user-interface font (`ui-rounded` in CSS).
	*/
	public static let uiRounded = Self(raw: "ui-rounded")
}

/**
A generated-content keyword for a pseudo-element, kept distinct from literal text.
*/
public enum ContentKeyword: String, CSSKeyword {
	case none
	case normal
	case openQuote = "open-quote"
	case closeQuote = "close-quote"
	case noOpenQuote = "no-open-quote"
	case noCloseQuote = "no-close-quote"
}

public enum FontWidth: String, CSSKeyword {
	case standard = "normal"
	case expanded
}

public enum TextAlignment: String, CSSKeyword {
	case leading = "start"
	case center
	case trailing = "end"
}

/**
How an inline element lines up with the text of its line, for ``Style/verticalAlign(_:)``.
*/
public enum VerticalTextAlignment: String, CSSKeyword {
	case baseline
	case top
	case middle
	case bottom
}

public enum TextCase: String, CSSKeyword {
	case uppercase
	case none
}

/**
The direction of the lines of text. See ``Style/writingMode(_:)``.
*/
public enum WritingMode: String, CSSKeyword {
	case horizontal = "horizontal-tb"

	/**
	Lines from top to bottom, like a label on the side of a box. Rotate it by 180 degrees to read it from the bottom up.
	*/
	case verticalRightToLeft = "vertical-rl"
}

/**
The direction of text and inline layout (`direction` in CSS).
*/
public enum TextDirection: String, CSSKeyword {
	case leftToRight = "ltr"
	case rightToLeft = "rtl"
}

public enum TextSelection: String, CSSKeyword {
	case enabled = "auto"
	case disabled = "none"
}

public enum TextWrap: String, CSSKeyword {
	case balance
	case pretty

	/**
	Keeps the text on one line.
	*/
	case nowrap

	/**
	Wraps the text again, like inside an element that keeps its text on one line.
	*/
	case wrap
}

/**
Where a long word, like a URL, can break when it does not fit on a line.
*/
public enum OverflowWrap: String, CSSKeyword {
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
How clipped inline text is marked (`text-overflow` in CSS).
*/
public enum TextOverflow: String, CSSKeyword {
	case clip
	case ellipsis
}

/**
How an underline is drawn (`text-decoration-style` in CSS), like a dotted line under a term that has a note.
*/
public enum UnderlineStyle: String, CSSKeyword {
	case solid
	case double
	case dotted
	case dashed
	case wavy
}

/**
How a counter is written, for ``Style/content(counter:style:)``.
*/
public enum CounterStyle: String, CSSKeyword {
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
The marker of the items of a list, for ``Style/listStyle(_:)``.
*/
public enum ListStyle: String, CSSKeyword {
	/**
	No marker, like for a list of links in a navigation.
	*/
	case none

	/**
	A bullet.
	*/
	case disc

	/**
	The number of the item, like “1.” and “12.”.
	*/
	case decimal
}

// MARK: Background, border, and shadow

/**
The ends of the lines of SVG shapes, for ``Style/strokedShapes(_:lineCap:lineJoin:)``.
*/
public enum LineCap: String, CSSKeyword {
	case butt
	case round
	case square
}

/**
The corners of the lines of SVG shapes, for ``Style/strokedShapes(_:lineCap:lineJoin:)``.
*/
public enum LineJoin: String, CSSKeyword {
	case miter
	case round
	case bevel
}

/**
Whether forced colors change the colors of an element, for ``Style/forcedColorAdjust(_:)``.
*/
public enum ForcedColorAdjust: String, CSSKeyword {
	case auto
	case none
	case preserveParentColor = "preserve-parent-color"
}

/**
How an image repeats in its area, like for ``Style/maskRepeat(_:)``.
*/
public enum ImageRepeat: String, CSSKeyword {
	case `repeat`

	/**
	Repeats only whole images, with even gaps between them, and the first and the last at the edges.
	*/
	case space

	/**
	Repeats only whole images, scaled to fill the area.
	*/
	case round

	case noRepeat = "no-repeat"
}

/**
What a background is drawn in, for ``Style/backgroundClip(_:)``. `text` draws it only in the letters, like for gradient text.
*/
public enum BackgroundClip: String, CSSKeyword {
	case borderBox = "border-box"
	case paddingBox = "padding-box"
	case contentBox = "content-box"
	case text
}

/**
How a border is drawn. The 3D styles, like `outset`, draw the edges in lighter and darker shades of the color.
*/
public enum BorderStyle: String, CSSKeyword {
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
Whether adjacent table-cell borders merge (`border-collapse` in CSS).
*/
public enum BorderCollapse: String, CSSKeyword {
	case separate
	case collapse
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

	var radius: LengthPercentage {
		switch self {
		case .capsule:
			.pixels(9999)
		case .circle:
			.percent(50)
		}
	}
}

/**
How an element blends with what is behind it. See ``Style/blendMode(_:)``.
*/
public enum BlendMode: String, CSSKeyword {
	case normal
	case multiply
	case screen
	case overlay
	case darken
	case lighten
}

public enum Cursor: String, CSSKeyword {
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

/**
What a touch on the element does by default. See ``Style/touchAction(_:)``.
*/
public enum TouchAction: String, CSSKeyword {
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
How an image is scaled. See ``Style/imageRendering(_:)``.
*/
public enum ImageRendering: String, CSSKeyword {
	case auto

	/**
	Large square pixels instead of a blur, for pixel art.
	*/
	case pixelated
}

/**
The color schemes that an element supports, for ``Style/colorScheme(_:)``.
*/
public enum ColorScheme: String, CSSKeyword {
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
public enum FieldSizing: String, CSSKeyword {
	/**
	The default size of the field, like the number of rows of a text area.
	*/
	case fixed

	/**
	The size of its content, so a text area grows with its text.
	*/
	case content
}

// MARK: Effects

/**
An angle, like for ``Style/rotationEffect(_:)``.
*/
public struct Angle: StyleValue, Hashable {
	public let description: String

	/**
	An angle written as CSS, like a custom property reference.
	*/
	public init(raw css: String) {
		self.description = css
	}

	public static func degrees(_ degrees: Double) -> Self {
		Self(raw: CSSValue.format(degrees) + "deg")
	}

	/**
	Scales an angle by a number-valued CSS expression, like the tilt strength of an element.
	*/
	public func scaled(by number: CSSNumber) -> Self {
		Self(raw: "calc(\(self) * \(number))")
	}
}

/**
One transform function. A list retains function order, which affects the result. The raw initializer is an explicit escape for uncommon functions.
*/
public struct Transform: StyleValue, Hashable {
	public let description: String

	/**
	An explicit unchecked transform function, such as a matrix that code computes elsewhere.
	*/
	public init(raw css: String) {
		self.description = css
	}

	/**
	The distance of the viewer from a three-dimensional scene.
	*/
	public static func perspective(_ distance: Length) -> Self {
		Self(raw: "perspective(\(distance))")
	}

	/**
	Moves horizontally by a length or a percentage of the element's width.
	*/
	public static func translateX(_ distance: LengthPercentage) -> Self {
		Self(raw: "translateX(\(distance))")
	}

	/**
	Moves vertically by a length or a percentage of the element's height.
	*/
	public static func translateY(_ distance: LengthPercentage) -> Self {
		Self(raw: "translateY(\(distance))")
	}

	/**
	Moves in depth by a length, without a percentage.
	*/
	public static func translateZ(_ distance: Length) -> Self {
		Self(raw: "translateZ(\(distance))")
	}

	/**
	Rotates in the plane of the element.
	*/
	public static func rotate(_ angle: Angle) -> Self {
		Self(raw: "rotate(\(angle))")
	}

	/**
	Rotates about the horizontal axis.
	*/
	public static func rotateX(_ angle: Angle) -> Self {
		Self(raw: "rotateX(\(angle))")
	}

	/**
	Rotates about the vertical axis.
	*/
	public static func rotateY(_ angle: Angle) -> Self {
		Self(raw: "rotateY(\(angle))")
	}

	/**
	Scales both axes equally by a number-valued expression.
	*/
	public static func scale(_ number: CSSNumber) -> Self {
		Self(raw: "scale(\(number))")
	}
}

/**
Which sizes transitions and animations can go between, for ``Style/interpolateSize(_:)``.
*/
public enum SizeInterpolation: String, CSSKeyword {
	/**
	Only between numbers, like `0` and `20rem`. The default.
	*/
	case numericOnly = "numeric-only"

	/**
	Also to and from size keywords, like `auto` and `fit-content`.
	*/
	case allowKeywords = "allow-keywords"
}

/**
The direction of a linear gradient, like ``toBottom`` or `.angle(.degrees(135))`. The sides are physical, like in CSS, so a gradient to the right goes to the right also in right-to-left text.
*/
public enum GradientDirection: Hashable, Sendable, CustomStringConvertible {
	case toTop
	case toBottom
	case toLeft
	case toRight
	case toTopLeft
	case toTopRight
	case toBottomLeft
	case toBottomRight

	/**
	The angle of the gradient line, clockwise from the top, so `.degrees(90)` is the same as ``toRight``.
	*/
	case angle(Angle)

	public var description: String {
		switch self {
		case .toTop:
			"to top"
		case .toBottom:
			"to bottom"
		case .toLeft:
			"to left"
		case .toRight:
			"to right"
		case .toTopLeft:
			"to top left"
		case .toTopRight:
			"to top right"
		case .toBottomLeft:
			"to bottom left"
		case .toBottomRight:
			"to bottom right"
		case .angle(let angle):
			angle.description
		}
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
	public init(raw css: String) {
		self.description = css
	}

	/**
	Blurs the element, like SwiftUI's `blur(radius:)`.
	*/
	public static func blur(radius: Length) -> Self {
		Self(raw: "blur(\(radius))")
	}

	/**
	Brightens (above 1) or darkens (below 1) the element, with 1 as no change, as in CSS.
	*/
	public static func brightness(_ amount: CSSNumber) -> Self {
		Self(raw: "brightness(\(amount))")
	}

	/**
	Makes the colors more (above 1) or less (below 1) intense, like SwiftUI's `saturation(_:)`.
	*/
	public static func saturation(_ amount: CSSNumber) -> Self {
		Self(raw: "saturate(\(amount))")
	}

	/**
	Turns the colors around the color wheel by the angle, like SwiftUI's `hueRotation(_:)`.
	*/
	public static func hueRotation(_ angle: Angle) -> Self {
		Self(raw: "hue-rotate(\(angle))")
	}

	/**
	Removes the colors (1) or part of them (between 0 and 1), like SwiftUI's `grayscale(_:)`.
	*/
	public static func grayscale(_ amount: CSSNumber) -> Self {
		Self(raw: "grayscale(\(amount))")
	}

	/**
	Makes the difference between light and dark larger (above 1) or smaller (below 1), like SwiftUI's `contrast(_:)`.
	*/
	public static func contrast(_ amount: CSSNumber) -> Self {
		Self(raw: "contrast(\(amount))")
	}

	/**
	Inverts the colors (1) or part of the way (between 0 and 1), like SwiftUI's `colorInvert()`, where black becomes white.
	*/
	public static func invert(_ amount: CSSNumber) -> Self {
		Self(raw: "invert(\(amount))")
	}

	/**
	Tints the colors brown like an old photo (1), or part of the way (between 0 and 1).
	*/
	public static func sepia(_ amount: CSSNumber) -> Self {
		Self(raw: "sepia(\(amount))")
	}

	/**
	Makes the element transparent, where `1` is opaque. Unlike the `opacity` property, it can be in a list of filters.
	*/
	public static func opacity(_ opacity: CSSNumber) -> Self {
		Self(raw: "opacity(\(opacity))")
	}

	/**
	A shadow that follows the shape of the content, like transparent parts of an image.
	*/
	public static func dropShadow(_ shadow: Shadow) -> Self {
		Self(raw: "drop-shadow(\(shadow.description))")
	}
}

/**
Whether transformed children remain in three dimensions (`transform-style` in CSS).
*/
public enum TransformStyle: String, CSSKeyword {
	case flat
	case preserveDepth = "preserve-3d"
}

// MARK: Transitions and animations

/**
The properties a transition animates. The effects are named like the modifiers that set them, like ``scaleEffect`` for ``Style/scaleEffect(_:)``, so a transition lists only the property that changes.
*/
public struct TransitionProperty: Hashable, Sendable {
	let properties: [Property]
	let registration: RegisteredPropertyDefinition?

	/**
	Whether the property switches between values instead of changing gradually, which needs `allow-discrete`.
	*/
	let isDiscrete: Bool

	public init(_ property: Property) {
		self.init(properties: [property])
	}

	/**
	A registered custom property, which can transition, as the browser knows its type. The transition brings its registration into the stylesheet.
	*/
	public init(_ property: RegisteredProperty<some StyleValue>) {
		self.properties = [Property(property.name.description)]
		self.registration = property.definition
		self.isDiscrete = false
	}

	private init(properties: [Property], isDiscrete: Bool = false) {
		self.properties = properties
		self.registration = nil
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

/**
How animation progress changes over time, independently of its duration. Reuse one curve in transitions and animations with different durations.
*/
public struct EasingFunction: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	An explicit unchecked easing expression, like a piecewise `linear()` spring.
	*/
	public init(raw css: String) {
		self.description = css
	}

	public static let ease = Self(raw: "ease")
	public static let linear = Self(raw: "linear")
	public static let easeIn = Self(raw: "ease-in")
	public static let easeOut = Self(raw: "ease-out")
	public static let easeInOut = Self(raw: "ease-in-out")

	/**
	A step easing function. The count must be positive, or at least two for `jump-none`.
	*/
	public static func steps(_ count: Int, position: StepPosition = .end) -> Self {
		precondition(count > (position == .jumpNone ? 1 : 0), "A step timing function needs a positive count, or at least two steps for jump-none.")
		return Self(raw: "steps(\(count), \(position.rawValue))")
	}

	/**
	A cubic Bézier curve. The x coordinates stay within 0...1; the y coordinates may overshoot, like a spring.
	*/
	public static func cubicBezier(_ firstX: Double, _ firstY: Double, _ secondX: Double, _ secondY: Double) -> Self {
		precondition((0...1).contains(firstX) && (0...1).contains(secondX), "The x coordinates of a cubic Bézier curve must be between 0 and 1.")
		return Self(raw: "cubic-bezier(\([firstX, firstY, secondX, secondY].map(CSSValue.format).joined(separator: ", ")))")
	}
}

/**
How long one run of an animation or a transition takes, and how it speeds up and slows down:

```swift
.easeInOut(duration: .seconds(18))
```
*/
public struct AnimationTiming: Hashable, Sendable, CustomStringConvertible {
	let duration: Duration

	/**
	The timing function, or `nil` for the CSS default, `ease`.
	*/
	private let timingFunction: EasingFunction?

	/**
	Combines a duration with a reusable easing function. The CSS default `ease` is omitted from the shorthand.
	*/
	public init(duration: Duration, curve: EasingFunction = .ease) {
		precondition(duration >= .zero, "An animation duration must be nonnegative.")
		self.duration = duration
		self.timingFunction = curve == .ease ? nil : curve
	}

	/**
	The CSS default, `ease`, which starts a little slowly, is fastest early on, and slows down gently at the end.
	*/
	public static func `default`(duration: Duration) -> Self {
		Self(duration: duration)
	}

	public static func linear(duration: Duration) -> Self {
		Self(duration: duration, curve: .linear)
	}

	public static func easeIn(duration: Duration) -> Self {
		Self(duration: duration, curve: .easeIn)
	}

	public static func easeOut(duration: Duration) -> Self {
		Self(duration: duration, curve: .easeOut)
	}

	public static func easeInOut(duration: Duration) -> Self {
		Self(duration: duration, curve: .easeInOut)
	}

	/**
	A timing function that advances in discrete steps. The count must be positive, or at least two for `.jumpNone`.
	*/
	public static func steps(_ count: Int, position: StepPosition = .end, duration: Duration) -> Self {
		Self(duration: duration, curve: .steps(count, position: position))
	}

	/**
	A cubic Bézier timing curve with two control points, like SwiftUI’s `timingCurve(_:_:_:_:duration:)`. The y coordinates may overshoot, like a spring; the x coordinates stay within 0...1.
	*/
	public static func timingCurve(
		_ c0x: Double,
		_ c0y: Double,
		_ c1x: Double,
		_ c1y: Double,
		duration: Duration
	) -> Self {
		Self(duration: duration, curve: .cubicBezier(c0x, c0y, c1x, c1y))
	}

	/**
	A timing function written as CSS, like `linear(0, .5 7.7%, 1.06 23.7%, 1)` for a spring that bounces.
	*/
	public static func timingCurve(raw timingFunction: String, duration: Duration) -> Self {
		Self(duration: duration, curve: EasingFunction(raw: timingFunction))
	}

	/**
	The duration and the timing function, like `.2s ease-out`.
	*/
	public var description: String {
		[duration.cssValue, timingFunction?.description].compactMap(\.self).joined(separator: " ")
	}
}

/**
An animation’s one-run timing together with its repeat and direction configuration. Transitions accept only ``AnimationTiming``.
*/
public struct Animation: Hashable, Sendable {
	private let timing: AnimationTiming

	/**
	These are the supported combinations; an alternating animation that runs only once is not representable.
	*/
	private enum Repetition: String {
		case once = ""
		case forever = "infinite"
		case alternating = "infinite alternate"
	}

	private var repetition = Repetition.once

	/**
	An animation with the given one-run timing.
	*/
	public init(timing: AnimationTiming) {
		self.timing = timing
	}

	/**
	An animation with the default timing curve.
	*/
	public static func `default`(duration: Duration) -> Self {
		Self(timing: .`default`(duration: duration))
	}

	/**
	An animation with the linear timing curve.
	*/
	public static func linear(duration: Duration) -> Self {
		Self(timing: .linear(duration: duration))
	}

	/**
	An animation that eases in.
	*/
	public static func easeIn(duration: Duration) -> Self {
		Self(timing: .easeIn(duration: duration))
	}

	/**
	An animation that eases out.
	*/
	public static func easeOut(duration: Duration) -> Self {
		Self(timing: .easeOut(duration: duration))
	}

	/**
	An animation that eases in and out.
	*/
	public static func easeInOut(duration: Duration) -> Self {
		Self(timing: .easeInOut(duration: duration))
	}

	/**
	An animation that advances in discrete steps. The count must be positive, or at least two for `.jumpNone`.
	*/
	public static func steps(_ count: Int, position: StepPosition = .end, duration: Duration) -> Self {
		Self(timing: .steps(count, position: position, duration: duration))
	}

	/**
	An animation with a cubic Bézier curve. Only the y coordinates may overshoot outside 0...1.
	*/
	public static func timingCurve(_ c0x: Double, _ c0y: Double, _ c1x: Double, _ c1y: Double, duration: Duration) -> Self {
		Self(timing: .timingCurve(c0x, c0y, c1x, c1y, duration: duration))
	}

	/**
	An animation with an explicitly unchecked CSS timing function.
	*/
	public static func timingCurve(raw timingFunction: String, duration: Duration) -> Self {
		Self(timing: .timingCurve(raw: timingFunction, duration: duration))
	}

	/**
	Repeats the animation forever, optionally alternating its direction.
	*/
	public func repeatForever(autoreverses: Bool = true) -> Self {
		var copy = self
		copy.repetition = autoreverses ? .alternating : .forever
		return copy
	}

	/**
	The animation shorthand. Placement under the reduced-motion condition and registration of keyframes remain responsibilities of the style.
	*/
	func cssValue(name: String, fillMode: AnimationFillMode?) -> CSSValue {
		CSSValue([name, timing.description, repetition.rawValue.nilIfEmpty, fillMode?.rawValue].compactMap(\.self), separator: " ")
	}
}

extension Duration {
	/**
	The duration in seconds, like `.15s`.
	*/
	var cssValue: String {
		CSSValue.format(self / .seconds(1)) + "s"
	}
}

/**
Where the jumps of a step easing function occur (`<step-position>` in CSS).
*/
public enum StepPosition: String, CSSKeyword {
	case start
	case end
	case jumpStart = "jump-start"
	case jumpEnd = "jump-end"
	case jumpNone = "jump-none"
	case jumpBoth = "jump-both"
}

/**
A boundary of a scroll-driven animation: a plain offset or an offset within a named view-timeline range.
*/
public enum AnimationRangeBoundary: Hashable, Sendable, CustomStringConvertible {
	case offset(LengthPercentage)
	case entry(LengthPercentage)
	case exit(LengthPercentage)
	case cover(LengthPercentage)
	case contain(LengthPercentage)
	case entryCrossing(LengthPercentage)
	case exitCrossing(LengthPercentage)

	public var description: String {
		switch self {
		case .offset(let offset):
			offset.description
		case .entry(let offset):
			"entry \(offset)"
		case .exit(let offset):
			"exit \(offset)"
		case .cover(let offset):
			"cover \(offset)"
		case .contain(let offset):
			"contain \(offset)"
		case .entryCrossing(let offset):
			"entry-crossing \(offset)"
		case .exitCrossing(let offset):
			"exit-crossing \(offset)"
		}
	}
}

public enum AnimationFillMode: String, CSSKeyword {
	case forwards
	case both
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
			timeline.name.description
		}
	}
}

/**
The progress of an element through the view, which scroll-driven animations of other elements can follow. Give it to the element with ``Style/viewTimeline(_:)``.
*/
public struct ViewTimeline: Hashable, Sendable {
	let name: DashedIdentifier

	/**
	- Parameter name: The name without the CSS `--` prefix, like `hero`.
	*/
	public init(_ name: DashedIdentifier) {
		self.name = name
	}
}
