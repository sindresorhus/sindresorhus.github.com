extension Style {
	/**
	The font size, and the line height as a multiple of it.
	*/
	public func font(size: Length, lineHeight: Double? = nil) -> Self {
		let style = declaration(.fontSize, CSSValue(size))

		guard let lineHeight else {
			return style
		}

		return style.lineHeight(lineHeight)
	}

	public func lineHeight(_ multiple: Double) -> Self {
		declaration(.lineHeight, CSSValue(floatLiteral: multiple))
	}

	public func fontWeight(_ weight: FontWeight) -> Self {
		declaration(.fontWeight, CSSValue(integerLiteral: weight.value))
	}

	/**
	Bold text, like SwiftUI's `bold()`.
	*/
	public func bold() -> Self {
		fontWeight(.bold)
	}

	public func fontFamily(_ family: FontFamily) -> Self {
		declaration(.fontFamily, CSSValue(family.description))
	}

	/**
	The width of the font, like `.expanded` for SF Pro Expanded.
	*/
	public func fontWidth(_ width: FontWidth) -> Self {
		declaration(.fontStretch, CSSValue(width.rawValue))
	}

	public func italic() -> Self {
		declaration(.fontStyle, "italic")
	}

	/**
	Digits with the same width, so changing numbers do not move, like SwiftUI's `monospacedDigit()`.
	*/
	public func monospacedDigit() -> Self {
		declaration(.fontVariantNumeric, "tabular-nums")
	}

	public func letterSpacing(_ length: Length) -> Self {
		declaration(.letterSpacing, CSSValue(length))
	}

	public func textAlign(_ alignment: TextAlignment) -> Self {
		declaration(.textAlign, CSSValue(alignment.rawValue))
	}

	/**
	How an inline element, like an icon in text, lines up with the text of its line, or how the content of a table cell lines up.
	*/
	public func verticalAlign(_ alignment: VerticalTextAlignment) -> Self {
		declaration(.verticalAlign, CSSValue(alignment.rawValue))
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
		declaration(.textTransform, CSSValue(textCase.rawValue))
	}

	/**
	The direction of the lines, like `.verticalRightToLeft` for text that runs down the side of a menu.
	*/
	public func writingMode(_ mode: WritingMode) -> Self {
		declaration(.writingMode, CSSValue(mode.rawValue))
	}

	/**
	Whether the visitor can select the text, like SwiftUI's `textSelection(_:)`.
	*/
	public func textSelection(_ selection: TextSelection) -> Self {
		declaration(.userSelect, CSSValue(selection.rawValue))
	}

	/**
	How the text wraps, like `.nowrap` to keep it on one line.
	*/
	public func textWrap(_ wrap: TextWrap) -> Self {
		declaration(.textWrap, CSSValue(wrap.rawValue))
	}

	/**
	Where a long word, like a URL, can break, so it does not overflow.
	*/
	public func overflowWrap(_ wrap: OverflowWrap) -> Self {
		declaration(.overflowWrap, CSSValue(wrap.rawValue))
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
		declaration(.color, CSSValue(color))
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
	public func underline(_ isActive: Bool = true, color: Color? = nil, thickness: Length? = nil, offset: Length? = nil) -> Self {
		guard isActive else {
			return declaration(.textDecoration, .none)
		}

		var style = declaration(.textDecoration, "underline")

		if let color {
			style = style.underlineColor(color)
		}

		if let thickness {
			style = style.underlineThickness(thickness)
		}

		if let offset {
			style = style.underlineOffset(offset)
		}

		return style
	}

	public func underlineColor(_ color: Color) -> Self {
		declaration(.textDecorationColor, CSSValue(color))
	}

	public func underlineThickness(_ thickness: Length) -> Self {
		declaration(.textDecorationThickness, CSSValue(thickness))
	}

	public func underlineOffset(_ offset: Length) -> Self {
		declaration(.textUnderlineOffset, CSSValue(offset))
	}

	/**
	A font size that grows with the screen between two screen widths, instead of jumping at a breakpoint, with `clamp()`. The size is in `rem` plus `vw`, so it still follows the zoom of the browser.

	```swift
	// 3rem on phones, 4.5rem from tablets, and in between on screens in between.
	Style().fluidFontSize(fromRem: 3, toRem: 4.5, between: .smallTablet, and: .tablet)
	```
	*/
	public func fluidFontSize(fromRem minimum: Double, toRem maximum: Double, between start: Breakpoint, and end: Breakpoint) -> Self {
		let slope = (maximum - minimum) / (end.minimumWidthInRem - start.minimumWidthInRem)
		let intercept = minimum - (slope * start.minimumWidthInRem)
		return declaration(.fontSize, CSSValue("clamp(\(CSSValue.format(minimum))rem, \(CSSValue.format(intercept))rem + \(CSSValue.format(slope * 100))vw, \(CSSValue.format(maximum))rem)"))
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
	Shadows of the text, like a glow. Text shadows have no spread, so the spread of the shadows is not used.
	*/
	public func textShadow(_ shadows: Shadow...) -> Self {
		declaration(.textShadow, CSSValue(shadows.isEmpty ? "none" : shadows.map(\.descriptionWithoutSpread).joined(separator: ", ")))
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
		// A line break ends a CSS string, so it is the escape `\A`, with a space that ends the escape.
		let quoted = [text, alternativeText].compactMap(\.self).map { "\"\($0.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"").replacing("\r\n", with: "\\A ").replacing("\n", with: "\\A ").replacing("\r", with: "\\A "))\"" }
		return declaration(.content, CSSValue(quoted.joined(separator: " / ")))
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
	*/
	public func content(counter name: String, style: CounterStyle = .decimal) -> Self {
		declaration(.content, CSSValue("counter(\(name), \(style.rawValue))"))
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
}
