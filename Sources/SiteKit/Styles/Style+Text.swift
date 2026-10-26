extension Style {
	/**
	The font size, and the line height as a multiple of it.
	*/
	public func font(size: Length, lineHeight: Double? = nil) -> Self {
		let style = declaration(.fontSize, size)

		guard let lineHeight else {
			return style
		}

		return style.lineHeight(lineHeight)
	}

	public func lineHeight(_ multiple: Double) -> Self {
		declaration(.lineHeight, CSSValue(multiple))
	}

	public func fontWeight(_ weight: FontWeight) -> Self {
		declaration(.fontWeight, CSSValue(weight.value))
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
		declaration(.fontVariantNumeric, "tabular-nums")
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
	public func verticalAlign(_ offset: Length) -> Self {
		declaration(.verticalAlign, offset)
	}

	/**
	Keeps the line breaks of the text, like in an App Store review, but still wraps long lines.
	*/
	public func preservesLineBreaks() -> Self {
		declaration(.whiteSpace, "pre-line")
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
	The font of the parent, with its size, line height, and weight, like for a heading that looks like the text around it.
	*/
	public func inheritsFont() -> Self {
		declaration(.font, .inherit)
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
	Underlines the text, or removes the underline, like of a link, with `underline(false)`.
	*/
	public func underline(
		_ isActive: Bool = true,
		style: UnderlineStyle? = nil,
		color: Color? = nil,
		thickness: Length? = nil,
		offset: Length? = nil
	) -> Self {
		guard isActive else {
			return declaration(.textDecoration, .none)
		}

		return declaration(.textDecoration, "underline")
			.declaration(.textDecorationStyle, ifPresent: style)
			.declaration(.textDecorationColor, ifPresent: color)
			.declaration(.textDecorationThickness, ifPresent: thickness)
			.declaration(.textUnderlineOffset, ifPresent: offset)
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

	public func underlineThickness(_ thickness: Length) -> Self {
		declaration(.textDecorationThickness, thickness)
	}

	public func underlineOffset(_ offset: Length) -> Self {
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
		let slope = (maximum - minimum) / (end.minimumWidthInRem - start.minimumWidthInRem)
		let intercept = minimum - (slope * start.minimumWidthInRem)
		return declaration(.fontSize, Length.clamp(.rootEm(minimum), .rootEm(intercept) + .viewportWidth(slope * 100), .rootEm(maximum)))
	}

	/**
	Trims the space above the capital letters and below the baseline, so the text looks centered in a badge or a button. The vertical padding grows by the trimmed space, so the size stays the same.

	The element must be a block container, like `inline-block`, as `text-box` does not trim the text of a flex container.
	*/
	public func trimmedText(verticalPadding: Length = 0) -> Self {
		declaration(.textBox, "trim-both cap alphabetic")
			.padding(.vertical, verticalPadding + .lineHeight(0.5) - .capitalHeight(0.5))
	}

	/**
	Shadows of the text, like a glow. Text shadows have no spread and cannot be inset, so the spread and ``Shadow/isInset`` of the shadows are not used.
	*/
	public func textShadow(_ shadows: Shadow...) -> Self {
		declaration(.textShadow, shadows.isEmpty ? .none : CSSValue(shadows.map(\.descriptionWithoutSpread), separator: ", "))
	}

	/**
	An outline around the letters (`-webkit-text-stroke` in CSS). It is drawn below the letters (`paint-order: stroke fill`), so only the outer half of its width shows. A stroke on top would also draw lines inside the letters of a variable font, like the system font, as the shapes of a letter overlap.
	*/
	public func textStroke(_ color: Color, width: Length = .pixels(1)) -> Self {
		declaration(.webkitTextStroke, CSSValue("\(width) \(color)"))
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
	The value of a counter as the text of a `::before` or `::after` pseudo-element, like the number of a list item.

	```swift
	Style()
		.counterIncrement("step")
		.before {
			$0.content(counter: "step", style: .decimalLeadingZero)
		}
	```

	- Parameter alternativeText: What screen readers say instead, like an empty string for a number that only decorates a heading.
	*/
	public func content(counter name: String, style: CounterStyle = .decimal, alternativeText: String? = nil) -> Self {
		let counter = CSSValue("counter(\(name), \(style.rawValue))")

		guard let alternativeText else {
			return declaration(.content, counter)
		}

		return declaration(.content, CSSValue([counter, .string(alternativeText)], separator: " / "))
	}

	/**
	Adds 1 to the counter for each element with the style, like for each item of a list. A counter that no element resets starts at 0 for the page.
	*/
	public func counterIncrement(_ name: String) -> Self {
		declaration(.counterIncrement, CSSValue(name))
	}

	/**
	Starts the counter at 0 for the element, so the counter of each list starts over.
	*/
	public func counterReset(_ name: String) -> Self {
		declaration(.counterReset, CSSValue(name))
	}

	/**
	The marker of the items of a list, like `.none` for a list without bullets, or `.decimal` for numbers. It is the `list-style` shorthand, so it also resets the position and the image of the marker.
	*/
	public func listStyle(_ style: ListStyle) -> Self {
		declaration(.listStyle, style)
	}
}
