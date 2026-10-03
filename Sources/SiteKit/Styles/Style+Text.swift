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
	The letter case of the text, like SwiftUI's `textCase(_:)`.
	*/
	public func textCase(_ textCase: TextCase) -> Self {
		declaration(.textTransform, CSSValue(textCase.rawValue))
	}

	/**
	Whether the visitor can select the text, like SwiftUI's `textSelection(_:)`.
	*/
	public func textSelection(_ selection: TextSelection) -> Self {
		declaration(.userSelect, CSSValue(selection.rawValue))
	}

	/**
	Keeps the text on one line.
	*/
	public func noWrap() -> Self {
		declaration(.whiteSpace, "nowrap")
	}

	public func textWrap(_ wrap: TextWrap) -> Self {
		declaration(.textWrap, CSSValue(wrap.rawValue))
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

	public func underline(color: Color? = nil, thickness: Length? = nil, offset: Length? = nil) -> Self {
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

	public func noUnderline() -> Self {
		declaration(.textDecoration, "none")
	}

	/**
	A font size that grows with the screen between two screen widths, instead of jumping at a breakpoint, with `clamp()`. The size is in `rem` plus `vw`, so it still follows the zoom of the browser.

	```swift
	// 3rem on small screens, 4.5rem from the medium breakpoint, and in between on screens in between.
	Style().fluidFontSize(fromRem: 3, toRem: 4.5, between: .sm, and: .md)
	```
	*/
	public func fluidFontSize(fromRem minimum: Double, toRem maximum: Double, between start: Breakpoint, and end: Breakpoint) -> Self {
		let slope = (maximum - minimum) / (end.minimumWidthInRem - start.minimumWidthInRem)
		let intercept = minimum - (slope * start.minimumWidthInRem)
		return declaration(.fontSize, CSSValue("clamp(\(CSSValue.format(minimum))rem, \(CSSValue.format(intercept))rem + \(CSSValue.format(slope * 100))vw, \(CSSValue.format(maximum))rem)"))
	}

	/**
	Trims the space above the capital letters and below the baseline, so the text looks centered in a badge or a button. The vertical padding grows by the trimmed space, so the size stays the same. Browsers without `text-box` keep the normal text box.

	The element must be a block container, like `inline-block`, as `text-box` does not trim the text of a flex container.
	*/
	public func trimmedText(verticalPadding: Length = 0) -> Self {
		let trimmedSpace = "(1lh - 1cap) / 2"

		return supports("(text-box: trim-both cap alphabetic)") {
			$0
				.declaration("text-box", "trim-both cap alphabetic")
				.padding(.vertical, Length(verticalPadding == 0 ? "calc(\(trimmedSpace))" : "calc(\(verticalPadding) + \(trimmedSpace))"))
		}
	}

	/**
	The text of a `::before` or `::after` pseudo-element.

	- Parameter alternativeText: What screen readers say instead, like an empty string for a decorative separator.
	*/
	public func content(_ text: String, alternativeText: String? = nil) -> Self {
		let quoted = [text, alternativeText].compactMap(\.self).map { "\"\($0.replacing("\\", with: "\\\\").replacing("\"", with: "\\\""))\"" }
		return declaration(.content, CSSValue(quoted.joined(separator: " / ")))
	}
}
