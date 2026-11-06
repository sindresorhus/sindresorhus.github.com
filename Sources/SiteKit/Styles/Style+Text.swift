/**
The counters of a component. Nest a string-backed enum named `Counters` in the component (`enum Counters: String, CounterSet`) and declare each counter as a case, like `case step`. Names are generated from the component and case, so counters of unrelated components cannot clash.
*/
public protocol CounterSet: RawRepresentable<String>, CaseIterable, Sendable {}

extension CounterSet {
	/**
	The counter name, like `instructions-step` for `Instructions.Counters.step`.
	*/
	public var name: String {
		generatedComponentName(of: Self.self, suffix: "Counters", member: rawValue)
	}
}

extension Style {
	/**
	The font size, and the line height as a multiple of it.
	*/
	public func font(size: LengthPercentage, lineHeight: CSSNumber? = nil) -> Self {
		declaration(.fontSize, size)
			.declaration(.lineHeight, ifPresent: lineHeight)
	}

	/**
	The font size with a line height from the complete CSS value domain.
	*/
	public func font(size: LengthPercentage, lineHeight: LineHeight) -> Self {
		font(size: size).lineHeight(lineHeight)
	}

	/**
	The line height as normal font spacing, a multiplier, or a length or percentage.
	*/
	public func lineHeight(_ height: LineHeight) -> Self {
		declaration(.lineHeight, CSSValue(raw: height.description))
	}

	/**
	The line height as a multiple of the font size.
	*/
	public func lineHeight(_ multiple: CSSNumber) -> Self {
		declaration(.lineHeight, multiple)
	}

	public func fontWeight(_ weight: FontWeight) -> Self {
		declaration(.fontWeight, weight)
	}

	/**
	Bold text, like SwiftUI's `bold()`.
	*/
	public func bold() -> Self {
		fontWeight(.bold)
	}

	public func fontFamily(_ family: FontFamily) -> Self {
		declaration(.fontFamily, family)
	}

	/**
	The width of the font, like `.expanded` for SF Pro Expanded.
	*/
	public func fontWidth(_ width: FontWidth) -> Self {
		declaration(.fontStretch, width)
	}

	/**
	Makes the text italic, like SwiftUI's `italic(_:)`, or upright with `italic(false)`, like a quote that prose styles as italic.
	*/
	public func italic(_ isActive: Bool = true) -> Self {
		declaration(.fontStyle, isActive ? "italic" : "normal")
	}

	/**
	Digits with the same width, so changing numbers do not move, like SwiftUI's `monospacedDigit()`.
	*/
	public func monospacedDigit() -> Self {
		fontVariantNumeric(.tabularNumbers)
	}

	/**
	The styles of the digits, like ``FontVariantNumeric/oldstyleNumbers`` for running text in a book. Combine independent styles in a set; an empty set restores `normal`.
	*/
	public func fontVariantNumeric(_ variant: FontVariantNumeric) -> Self {
		declaration(.fontVariantNumeric, CSSValue(raw: variant.description))
	}

	/**
	Punctuation that hangs outside the box of the text, like an opening quote at the start of a paragraph, so the letters line up with the edge.
	*/
	public func hangingPunctuation(_ punctuation: HangingPunctuation) -> Self {
		declaration(.hangingPunctuation, CSSValue(raw: punctuation.description))
	}

	public func letterSpacing(_ length: Length) -> Self {
		declaration(.letterSpacing, length)
	}

	public func textAlign(_ alignment: TextAlignment) -> Self {
		declaration(.textAlign, alignment)
	}

	/**
	How an inline element, like an icon in text, lines up with the text of its line, or how the content of a table cell lines up.
	*/
	public func verticalAlign(_ alignment: VerticalTextAlignment) -> Self {
		declaration(.verticalAlign, alignment)
	}

	/**
	Raises an inline element, like an icon in text, by the length above the baseline of its line, or lowers it for a negative length, like `.verticalAlign(.capitalHeight(0.5) - .rootEm(0.5))` for an icon of `1rem` in the middle of the capital letters.
	*/
	public func verticalAlign(_ offset: LengthPercentage) -> Self {
		declaration(.verticalAlign, offset)
	}

	/**
	Keeps the line breaks of the text, like in an App Store review, but still wraps long lines.
	*/
	public func preservesLineBreaks() -> Self {
		declaration(.whiteSpace, "pre-line")
	}

	/**
	Keeps every space of the text and keeps it on one line, like a file name that is in two parts, where the space between the parts would collapse (`white-space: pre` in CSS).
	*/
	public func preservesSpaces() -> Self {
		declaration(.whiteSpace, "pre")
	}

	/**
	The letter case of the text, like SwiftUI's `textCase(_:)`.
	*/
	public func textCase(_ textCase: TextCase) -> Self {
		declaration(.textTransform, textCase)
	}

	/**
	The direction of the lines, like `.verticalRightToLeft` for text that runs down the side of a menu.
	*/
	public func writingMode(_ mode: WritingMode) -> Self {
		declaration(.writingMode, mode)
	}

	/**
	The direction of text and inline layout.
	*/
	public func direction(_ value: TextDirection) -> Self {
		declaration(.direction, value)
	}

	/**
	Whether the visitor can select the text, like SwiftUI's `textSelection(_:)`. Safari only supports `-webkit-user-select`, so both are set.
	*/
	public func textSelection(_ selection: TextSelection) -> Self {
		declaration(.webkitUserSelect, selection)
			.declaration(.userSelect, selection)
	}

	/**
	How the text wraps, like `.nowrap` to keep it on one line.
	*/
	public func textWrap(_ wrap: TextWrap) -> Self {
		declaration(.textWrap, wrap)
	}

	/**
	Where a long word, like a URL, can break, so it does not overflow.
	*/
	public func overflowWrap(_ wrap: OverflowWrap) -> Self {
		declaration(.overflowWrap, wrap)
	}

	/**
	How clipped inline text is marked.
	*/
	public func textOverflow(_ value: TextOverflow) -> Self {
		declaration(.textOverflow, value)
	}

	/**
	Whether the browser breaks long words at the end of a line with a hyphen, by the language of the page (`hyphens: auto`), like for narrow columns of text.
	*/
	public func hyphenation(_ isEnabled: Bool) -> Self {
		declaration(.hyphens, isEnabled ? .auto : .none)
	}

	/**
	Hyphenates only words of at least `minimumWordLength` letters, with at least 3 letters before and after the hyphen, so short words, like “macOS”, do not break (`hyphens: auto` with `hyphenate-limit-chars`).

	Safari has no limit for the length of a word yet, only the limits before and after the hyphen (`-webkit-hyphenate-limit-before` and `-webkit-hyphenate-limit-after`), so it does not break words of 5 letters or less.
	*/
	public func hyphenation(minimumWordLength: Int) -> Self {
		let minimumLettersAroundHyphen = 3

		return hyphenation(true)
			.declaration(.hyphenateLimitChars, CSSValue([minimumWordLength, minimumLettersAroundHyphen, minimumLettersAroundHyphen], separator: " "))
			.declaration(.webkitHyphenateLimitBefore, CSSValue(minimumLettersAroundHyphen))
			.declaration(.webkitHyphenateLimitAfter, CSSValue(minimumLettersAroundHyphen))
	}

	/**
	The font of the parent, with its size, line height, and weight, like for a heading that looks like the text around it.
	*/
	public func inheritsFont() -> Self {
		inherits(.font)
	}

	/**
	The text color.
	*/
	public func color(_ color: Color) -> Self {
		declaration(.color, color)
	}

	/**
	The text color, with another color in dark mode.
	*/
	public func color(_ color: Color, dark: Color) -> Self {
		self.color(.lightDark(color, dark))
	}

	/**
	Underlines the text, with optional styling. Use ``noUnderline()`` to remove the decoration, like of a link.
	*/
	public func underline(
		style: UnderlineStyle? = nil,
		color: Color? = nil,
		thickness: LengthPercentage? = nil,
		offset: LengthPercentage? = nil
	) -> Self {
		declaration(.textDecoration, "underline")
			.declaration(.textDecorationStyle, ifPresent: style)
			.declaration(.textDecorationColor, ifPresent: color)
			.declaration(.textDecorationThickness, ifPresent: thickness)
			.declaration(.textUnderlineOffset, ifPresent: offset)
	}

	/**
	Removes the text decoration, like the underline of a link. Uses the `text-decoration` shorthand, so its other properties reset too.
	*/
	public func noUnderline() -> Self {
		declaration(.textDecoration, .none)
	}

	/**
	The style of the underline, like dotted, without the other properties of the underline, like for a state that only changes the style.
	*/
	public func underlineStyle(_ style: UnderlineStyle) -> Self {
		declaration(.textDecorationStyle, style)
	}

	public func underlineColor(_ color: Color) -> Self {
		declaration(.textDecorationColor, color)
	}

	public func underlineThickness(_ thickness: LengthPercentage) -> Self {
		declaration(.textDecorationThickness, thickness)
	}

	public func underlineOffset(_ offset: LengthPercentage) -> Self {
		declaration(.textUnderlineOffset, offset)
	}

	/**
	A font size that grows with the screen between two screen widths, instead of jumping at a breakpoint, with `clamp()`. The size is in `rem` plus `vw`. The `rem` part follows the zoom of the browser, but the `vw` part does not, as zoom makes the screen narrower in CSS pixels. So zoomed text grows less than the zoom until it is at its minimum size, from where it follows the zoom fully. With a maximum of at most 2.5 times the minimum, the text reaches 200% within the zoom of browsers (up to 500%), as WCAG asks, unless the root size also grows with the screen.

	```swift
	// 3rem on phones, 4.5rem from tablets, and in between on screens in between.
	Style().fluidFontSize(fromRem: 3, toRem: 4.5, between: .smallTablet, and: .tablet)
	```
	*/
	public func fluidFontSize(
		fromRem minimum: Double,
		toRem maximum: Double,
		between start: Breakpoint,
		and end: Breakpoint
	) -> Self {
		precondition(start.minimumWidthInRem < end.minimumWidthInRem, "Fluid font breakpoints must have strictly increasing widths.")
		let slope = (maximum - minimum) / (end.minimumWidthInRem - start.minimumWidthInRem)
		let intercept = minimum - (slope * start.minimumWidthInRem)
		return declaration(.fontSize, LengthPercentage.clamp(.rootEm(minimum), .rootEm(intercept) + .viewportWidth(slope * 100), .rootEm(maximum)))
	}

	/**
	Trims the space above the capital letters and below the baseline, so the text looks centered in a badge or a button. The vertical padding grows by the trimmed space, so the size stays the same.

	The element must be a block container, like `inline-block`, as `text-box` does not trim the text of a flex container.
	*/
	public func trimmedText(verticalPadding: LengthPercentage = .zero) -> Self {
		declaration(.textBox, "trim-both cap alphabetic")
			.padding(.block, verticalPadding + .lineHeight(0.5) - .capitalHeight(0.5))
	}

	/**
	Shadows of the text, like a glow. Text shadows use ``Shadow``, which has no spread and cannot be inset.
	*/
	public func textShadow(_ shadows: Shadow...) -> Self {
		declaration(.textShadow, CSSValue(shadows, separator: ", ", emptyValue: .none))
	}

	/**
	An outline around the letters (`-webkit-text-stroke` in CSS). It is drawn below the letters (`paint-order: stroke fill`), so only the outer half of its width shows. A stroke on top would also draw lines inside the letters of a variable font, like the system font, as the shapes of a letter overlap.
	*/
	public func textStroke(_ color: Color, width: Length = .pixels(1)) -> Self {
		declaration(.webkitTextStroke, CSSValue(raw: "\(width) \(color)"))
			.declaration(.paintOrder, "stroke fill")
	}

	/**
	The text of a `::before` or `::after` pseudo-element.

	- Parameter alternativeText: What screen readers say instead, like an empty string for a decorative separator.
	*/
	public func content(_ text: String, alternativeText: String? = nil) -> Self {
		declaration(.content, CSSValue([text, alternativeText].compactMap(\.self).map(CSSValue.string), separator: " / "))
	}

	/**
	Generated content with CSS meaning, like a language-aware opening quote. A string passed to ``content(_:alternativeText:)`` is always literal text.
	*/
	public func content(_ keyword: ContentKeyword) -> Self {
		declaration(.content, keyword)
	}

	/**
	The value of a counter as the text of a `::before` or `::after` pseudo-element, like the number of a list item.

	```swift
	Style()
		.counterIncrement(Counters.step)
		.before {
			$0.content(counter: Counters.step, style: .decimalLeadingZero)
		}
	```

	- Parameter alternativeText: What screen readers say instead, like an empty string for a number that only decorates a heading.
	*/
	public func content(counter value: some CounterSet, style: CounterStyle = .decimal, alternativeText: String? = nil) -> Self {
		let counter = CSSValue(raw: "counter(\(value.name), \(style.rawValue))")

		guard let alternativeText else {
			return declaration(.content, counter)
		}

		return declaration(.content, CSSValue([counter, .string(alternativeText)], separator: " / "))
	}

	/**
	Adds 1 to the counter for each element with the style, like for each item of a list. A counter that no element resets starts at 0 for the page.
	*/
	public func counterIncrement(_ counter: some CounterSet) -> Self {
		declaration(.counterIncrement, CSSValue(raw: counter.name))
	}

	/**
	Starts the counter at 0 for the element, so the counter of each list starts over.
	*/
	public func counterReset(_ counter: some CounterSet) -> Self {
		declaration(.counterReset, CSSValue(raw: counter.name))
	}

	/**
	The marker of the items of a list, like `.none` for a list without bullets, or `.decimal` for numbers. It is the `list-style` shorthand, so it also resets the position and the image of the marker.
	*/
	public func listStyle(_ style: ListStyle) -> Self {
		declaration(.listStyle, style)
	}
}
