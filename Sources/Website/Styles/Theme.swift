import SiteKit

/**
The color palettes of the site, mostly from the Tailwind v4 palette, in OKLCH, which uses the wider P3 color range on screens that have it.

Each shade is a custom property on `:root`, like `--gray-900`, so the stylesheet defines each color once. Use a shade with ``Color/gray(_:)`` and the other palette functions.
*/
enum Palette: String, CaseIterable {
	case gray

	/**
	Blue, the main brand color.
	*/
	case primary

	/**
	Pink, the second brand color.
	*/
	case secondary

	case red
	case amber
	case orange
	case teal
	case sky
	case indigo
	case violet
	case emerald
	case purple
	case rose

	/**
	The shades of the palette, from light (50) to dark (950).
	*/
	var shades: KeyValuePairs<Int, Color> {
		switch self {
		case .gray:
			// Near-neutral grays, like the system grays of Apple platforms, so gray surfaces do not look blue next to the brand blue.
			[50: "oklch(98.5% .002 286)", 100: "oklch(97.1% .003 286)", 200: "oklch(93.2% .007 286)", 300: "oklch(87% .006 286)", 400: "oklch(71.1% .007 286)", 500: "oklch(54% .008 286)", 600: "oklch(44.5% .008 286)", 700: "oklch(37% .006 286)", 800: "oklch(27.4% .006 286)", 900: "oklch(23.2% .004 286)", 950: "oklch(18.8% .004 286)"]
		case .primary:
			[50: "oklch(97% .014 254.604)", 100: "oklch(93.2% .032 255.585)", 200: "oklch(88.2% .059 254.128)", 300: "oklch(80.9% .105 251.813)", 400: "oklch(70.7% .165 254.624)", 500: "oklch(62.3% .214 259.815)", 600: "oklch(54.6% .245 262.881)", 700: "oklch(48.8% .243 264.376)", 800: "oklch(42.4% .199 265.638)", 900: "oklch(37.9% .146 265.522)", 950: "oklch(28.2% .091 267.935)"]
		case .secondary:
			[50: "oklch(97.1% .014 343.198)", 200: "oklch(89.9% .061 343.231)", 400: "oklch(71.8% .202 349.761)", 500: "oklch(65.6% .241 354.308)", 600: "oklch(59.2% .249 .584)", 800: "oklch(45.9% .187 3.815)", 900: "oklch(40.8% .153 2.432)"]
		case .red:
			[400: "oklch(70.4% .191 22.216)", 500: "oklch(63.7% .237 25.331)", 600: "oklch(57.7% .245 27.325)"]
		case .amber:
			[50: "oklch(98.7% .022 95.277)", 200: "oklch(92.4% .12 95.746)", 300: "oklch(87.9% .169 91.605)", 400: "oklch(82.8% .189 84.429)", 600: "oklch(66.6% .179 58.318)", 700: "oklch(55.5% .163 48.998)", 800: "oklch(47.3% .137 46.201)", 900: "oklch(41.4% .112 45.904)", 950: "oklch(27.9% .077 45.635)"]
		case .orange:
			[100: "oklch(95.4% .038 75.164)", 200: "oklch(90.1% .076 70.697)"]
		case .teal:
			[100: "oklch(95.3% .051 180.801)", 200: "oklch(91% .096 180.426)"]
		case .sky:
			[100: "oklch(95.1% .026 236.824)", 200: "oklch(90.1% .058 230.902)"]
		case .indigo:
			[50: "oklch(96.2% .018 272.314)", 200: "oklch(87% .065 274.039)", 500: "oklch(58.5% .233 277.117)", 950: "oklch(25.7% .09 281.288)"]
		case .violet:
			[500: "oklch(60.6% .25 292.717)"]
		case .emerald:
			[50: "oklch(97.9% .021 166.113)", 400: "oklch(76.5% .177 163.223)", 700: "oklch(50.8% .118 165.612)", 950: "oklch(26.2% .051 172.552)"]
		case .purple:
			[50: "oklch(97.7% .014 308.299)", 400: "oklch(71.4% .203 305.504)", 700: "oklch(49.6% .265 301.924)", 950: "oklch(29.1% .149 302.717)"]
		case .rose:
			[50: "oklch(96.9% .015 12.422)", 400: "oklch(71.2% .194 13.428)", 700: "oklch(51.4% .222 16.935)", 950: "oklch(27.1% .105 12.094)"]
		}
	}

	func color(_ shade: Int) -> Color {
		precondition(shades.contains { $0.key == shade }, "The \(rawValue) palette has no shade \(shade).")
		return variable(shade).value
	}

	/**
	The custom property of a shade, like `--gray-900`.
	*/
	private func variable(_ shade: Int) -> StyleVariable<Color> {
		StyleVariable("--\(rawValue)-\(shade)")
	}

	/**
	The custom properties of every shade, for `:root`.
	*/
	static var customProperties: Style {
		allCases.reduce(Style()) { style, palette in
			palette.shades.reduce(style) { $0.setting(palette.variable($1.key), to: $1.value) }
		}
	}
}

/**
Colors named by their role, with a light and a dark value, like SwiftUI's semantic colors. Each is a custom property on `:root`, like `--primary-text`.
*/
enum SemanticColor: String, CaseIterable {
	/**
	Headings and other emphasized text.
	*/
	case primaryText

	/**
	Running text, like paragraphs.
	*/
	case bodyText

	/**
	Less important text, like captions and metadata.
	*/
	case secondaryText

	case link

	/**
	Lines between content, like borders of table rows.
	*/
	case separator

	case pageBackground

	/**
	The see-through fill of a card or a panel, a little darker than the page in light mode and a little lighter in dark mode.
	*/
	case card

	/**
	The fill of a card while the pointer is over it.
	*/
	case cardHover

	/**
	The light and dark colors, and the colors when the visitor asks for more contrast in the system settings, when they differ. Secondary text, links, and separators get darker in light mode and lighter in dark mode.
	*/
	private var definition: (colors: Color.LightDark, moreContrast: Color.LightDark?) {
		switch self {
		case .primaryText:
			(Color.LightDark(light: .gray(900), dark: .white), nil)
		case .bodyText:
			(Color.LightDark(light: .gray(700), dark: .gray(300)), Color.LightDark(light: .gray(800), dark: .gray(200)))
		case .secondaryText:
			(Color.LightDark(light: .gray(500), dark: .gray(400)), Color.LightDark(light: .gray(700), dark: .gray(300)))
		case .link:
			(Color.LightDark(light: .primary(600), dark: .primary(400)), Color.LightDark(light: .primary(700), dark: .primary(300)))
		case .separator:
			// In dark mode, between two shades, so the lines are not brighter than they need to be on the near black background.
			(Color.LightDark(light: .gray(200), dark: .gray(700).mix(with: .gray(800), amount: .percent(50))), Color.LightDark(light: .gray(500), dark: .gray(400)))
		// In dark mode, a near black with a tiny blue tint.
		case .pageBackground:
			(Color.LightDark(light: .white, dark: "oklch(14% .012 264)"), nil)
		// See-through, so a card takes a little of the color behind it.
		case .card:
			(Color.LightDark(light: .black.opacity(0.035), dark: .white.opacity(0.065)), nil)
		case .cardHover:
			(Color.LightDark(light: .primary(500).opacity(0.06), dark: .white.opacity(0.095)), nil)
		}
	}

	var colors: Color.LightDark {
		definition.colors
	}

	var moreContrast: Color.LightDark {
		definition.moreContrast ?? colors
	}

	private var variable: StyleVariable<Color> {
		StyleVariable("--" + rawValue.kebabCased)
	}

	var color: Color {
		variable.value
	}

	/**
	The custom properties of every semantic color, for `:root`.
	*/
	static var customProperties: Style {
		allCases
			.reduce(Style()) { $0.setting($1.variable, to: .lightDark($1.colors.light, $1.colors.dark)) }
			.media(.moreContrast) { style in
				allCases.reduce(style) { $0.setting($1.variable, to: .lightDark($1.moreContrast.light, $1.moreContrast.dark)) }
			}
	}
}

extension Color {
	/**
	The accent of the page, which an app page sets to the color of its icon. The styles that use it give the brand color as the fallback, so other pages look the same.
	*/
	static let accent = StyleVariable<Color>("--accent")

	/**
	The accent, or the fallback, with the lightness limited, so it works as a fill with white text or as a line on white.
	*/
	static func accent(fallback: Color, maximumLightness: Double) -> Self {
		Self("oklch(from \(accent.value(default: fallback)) min(l, \(maximumLightness)) c h)")
	}

	/**
	A color for light mode and one for dark mode.
	*/
	struct LightDark {
		let light: Color
		let dark: Color
	}

	/**
	The value of a palette shade, like `oklch(12.9% .042 264.695)` for `.gray(950)`, for places that cannot use custom properties, like the `theme-color` meta tag. Other colors are returned as they are.
	*/
	var resolved: Self {
		for palette in Palette.allCases {
			for (shade, value) in palette.shades where palette.color(shade) == self {
				return value
			}
		}

		return self
	}

	static let primaryText = SemanticColor.primaryText.color
	static let bodyText = SemanticColor.bodyText.color
	static let secondaryText = SemanticColor.secondaryText.color
	static let link = SemanticColor.link.color
	static let separator = SemanticColor.separator.color
	static let pageBackground = SemanticColor.pageBackground.color
	static let card = SemanticColor.card.color
	static let cardHover = SemanticColor.cardHover.color

	static func gray(_ shade: Int) -> Self {
		Palette.gray.color(shade)
	}

	static func primary(_ shade: Int) -> Self {
		Palette.primary.color(shade)
	}

	static func secondary(_ shade: Int) -> Self {
		Palette.secondary.color(shade)
	}

	static func red(_ shade: Int) -> Self {
		Palette.red.color(shade)
	}

	static func amber(_ shade: Int) -> Self {
		Palette.amber.color(shade)
	}

	static func orange(_ shade: Int) -> Self {
		Palette.orange.color(shade)
	}

	static func teal(_ shade: Int) -> Self {
		Palette.teal.color(shade)
	}

	static func sky(_ shade: Int) -> Self {
		Palette.sky.color(shade)
	}

	static func indigo(_ shade: Int) -> Self {
		Palette.indigo.color(shade)
	}

	static func violet(_ shade: Int) -> Self {
		Palette.violet.color(shade)
	}

	static func emerald(_ shade: Int) -> Self {
		Palette.emerald.color(shade)
	}
}

/**
The text sizes, each with its line height, from the Tailwind scale.
*/
enum TextSize {
	case extraSmall
	case small
	case regular
	case large
	case extraLarge
	case extraLarge2
	case extraLarge3
	case extraLarge4
	case extraLarge5
	case extraLarge6
	case extraLarge8
	case extraLarge9

	var size: Length {
		switch self {
		case .extraSmall:
			.rootEm(0.75)
		case .small:
			.rootEm(0.875)
		case .regular:
			.rootEm(1)
		case .large:
			.rootEm(1.125)
		case .extraLarge:
			.rootEm(1.25)
		case .extraLarge2:
			.rootEm(1.5)
		case .extraLarge3:
			.rootEm(1.875)
		case .extraLarge4:
			.rootEm(2.25)
		case .extraLarge5:
			.rootEm(3)
		case .extraLarge6:
			.rootEm(3.75)
		case .extraLarge8:
			.rootEm(6)
		case .extraLarge9:
			.rootEm(8)
		}
	}

	var lineHeight: Double {
		switch self {
		case .extraSmall:
			1.3333
		case .small:
			1.4286
		case .regular:
			1.5
		case .large:
			1.5556
		case .extraLarge:
			1.4
		case .extraLarge2:
			1.3333
		case .extraLarge3:
			1.2
		case .extraLarge4:
			1.1111
		case .extraLarge5, .extraLarge6, .extraLarge8, .extraLarge9:
			1
		}
	}
}

extension Style {
	/**
	Less important text, like captions and metadata: a smaller size and the secondary text color.
	*/
	func secondaryText(_ textStyle: TextStyle = .caption) -> Self {
		self.textStyle(textStyle).color(.secondaryText)
	}

	/**
	Less important text in a size that no role has, like very small text.
	*/
	func secondaryText(_ size: TextSize) -> Self {
		font(size).color(.secondaryText)
	}

	/**
	A text size from the scale, with its line height.
	*/
	func font(_ size: TextSize, weight: FontWeight? = nil) -> Self {
		let style = font(size: size.size, lineHeight: size.lineHeight)
		return weight.map { style.fontWeight($0) } ?? style
	}
}

/**
The roles of text outside of prose, like the title of a page or the text of a card, so the same kind of text looks the same on every page. Each has a size, a line height, a weight, and a letter spacing that gets tighter for larger text, like the system fonts of Apple platforms. The sizes of titles grow with the screen.
*/
enum TextStyle {
	/**
	The title of a page, like the name of an app.
	*/
	case largeTitle

	/**
	The title of a large part of a page, like the “Get” block at the end of an app page.
	*/
	case title

	/**
	The title of a card.
	*/
	case headline

	/**
	A short text below a title that says what the page is about.
	*/
	case lead

	/**
	Running text outside of prose, like the text of a card or a quote.
	*/
	case body

	/**
	Small text, like details and captions.
	*/
	case caption

	var size: Length {
		switch self {
		case .largeTitle:
			.clamp(.rootEm(2.5), .viewportWidth(6), .rootEm(3.75))
		case .title:
			.clamp(.rootEm(1.875), .viewportWidth(4), .rootEm(2.5))
		case .headline:
			.rootEm(1.1875)
		case .lead:
			.rootEm(1.125)
		case .body:
			.rootEm(1)
		case .caption:
			.rootEm(0.875)
		}
	}

	var lineHeight: Double {
		switch self {
		case .largeTitle:
			1.04
		case .title:
			1.08
		case .headline:
			1.3
		case .lead, .body:
			1.55
		case .caption:
			1.5
		}
	}

	/**
	The weight of titles. Running text has none, so it keeps the weight of its parent, like bold text in a bold link.
	*/
	var weight: FontWeight? {
		switch self {
		case .largeTitle, .title:
			.bold
		case .headline:
			.semibold
		case .lead, .body, .caption:
			nil
		}
	}

	/**
	The letter spacing of titles. Running text has none, so it keeps the letter spacing of its parent.
	*/
	var letterSpacing: Length? {
		switch self {
		case .largeTitle:
			.em(-0.032)
		case .title:
			.em(-0.026)
		case .headline:
			.em(-0.01)
		case .lead, .body, .caption:
			nil
		}
	}
}

extension Style {
	/**
	The size, line height, weight, and letter spacing of a role of text. Prefer it to ``font(_:weight:)`` when a role fits.

	- Parameter weight: Another weight than the one of the role, like a semibold caption.
	*/
	func textStyle(_ textStyle: TextStyle, weight: FontWeight? = nil) -> Self {
		var style = font(size: textStyle.size, lineHeight: textStyle.lineHeight)

		if let weight = weight ?? textStyle.weight {
			style = style.fontWeight(weight)
		}

		if let letterSpacing = textStyle.letterSpacing {
			style = style.letterSpacing(letterSpacing)
		}

		return style
	}
}

/**
The screen widths where the layout changes, named after the devices that are about that wide. Use them with ``Style/from(_:_:)`` and ``Style/below(_:_:)``, like `.below(.smallTablet)` for phones.
*/
extension Breakpoint {
	/**
	The width of a small phone, where fluid sizes start to grow (384px).
	*/
	static let phone = Self(minimumWidthInRem: 24)

	/**
	A small tablet, or a phone in landscape (640px).
	*/
	static let smallTablet = Self(minimumWidthInRem: 40)

	/**
	A tablet in portrait (768px).
	*/
	static let tablet = Self(minimumWidthInRem: 48)

	/**
	A tablet in landscape, or a small laptop (1024px).
	*/
	static let laptop = Self(minimumWidthInRem: 64)

	/**
	A desktop or a large laptop (1280px).
	*/
	static let desktop = Self(minimumWidthInRem: 80)

	/**
	A large desktop screen (1536px).
	*/
	static let largeDesktop = Self(minimumWidthInRem: 96)
}

extension FontFamily {
	static let system: Self = #"-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", "Noto Sans", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji""#
	static let monospace: Self = #"ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace"#

	/**
	SF Pro on Apple platforms, which can be expanded with `font-stretch`.
	*/
	static let expandable: Self = "ui-sans-serif, -apple-system, system-ui, sans-serif"

	/**
	SF Pro Rounded on Apple platforms, for numbers that stand out, like the numbers of feature sections.
	*/
	static let rounded: Self = #"ui-rounded, "SF Pro Rounded", -apple-system, system-ui, sans-serif"#
}

/**
How strong the light of a hovered card is, from 0 to 1. It is registered, so it can fade.
*/
private let cardLight = RegisteredProperty<CSSValue>("--card-light", syntax: "<number>", initialValue: 0, inherits: false)

/**
The corner radii, from large to small. A box inside a box uses the radius of the outer box minus the padding between them, so the corners stay parallel.
*/
extension Length {
	/**
	Large panels, like the “Get” block at the end of an app page (1.75rem).
	*/
	static let panelRadius = rootEm(1.75)

	/**
	Cards, like app cards and quotes (1.5rem).
	*/
	static let cardRadius = rootEm(1.5)

	/**
	Smaller boxes, like questions in a FAQ (1.25rem).
	*/
	static let boxRadius = rootEm(1.25)

	/**
	Screenshots and other pictures of windows (0.75rem).
	*/
	static let windowRadius = rootEm(0.75)
}

extension Length {
	/**
	The space between the edge of the screen and the content, like the text of a page, the site name in the header, and the footer (1.5rem). Inside the width of the header and the footer (``Style/pageWidth()``), it is the space at their sides, so the content lines up with theirs.
	*/
	static let pageGutter = rootEm(1.5)
}

/**
The shadow sizes, from the Tailwind scale.
*/
extension [Shadow] {
	static let small = [Shadow(y: .pixels(1), blur: .pixels(3), color: .black.opacity(0.1)), Shadow(y: .pixels(1), blur: .pixels(2), spread: .pixels(-1), color: .black.opacity(0.1))]
	static let medium = [Shadow(y: .pixels(4), blur: .pixels(6), spread: .pixels(-1), color: .black.opacity(0.1)), Shadow(y: .pixels(2), blur: .pixels(4), spread: .pixels(-2), color: .black.opacity(0.1))]
	static let large = [Shadow(y: .pixels(10), blur: .pixels(15), spread: .pixels(-3), color: .black.opacity(0.1)), Shadow(y: .pixels(4), blur: .pixels(6), spread: .pixels(-4), color: .black.opacity(0.1))]
	static let extraLarge = extraLarge(color: .black.opacity(0.1))

	/**
	A soft, wide shadow with a thin outline, for things that look like windows, like screenshots and popovers.
	*/
	static let window = [
		// Small enough to fit the padding of the media carousel, which would otherwise cut it off at the sides.
		Shadow(y: .pixels(16), blur: .pixels(40), spread: .pixels(-16), color: .lightDark("oklch(25% .05 264 / 30%)", .black.opacity(0.7))),
		Shadow(y: 0, spread: .pixels(1), color: .lightDark(.black.opacity(0.08), .white.opacity(0.1))),
	]

	static func extraLarge(color: Color) -> Self {
		[Shadow(y: .pixels(20), blur: .pixels(25), spread: .pixels(-5), color: color), Shadow(y: .pixels(8), blur: .pixels(10), spread: .pixels(-6), color: color)]
	}
}

extension Animation {
	/**
	A quick change from one state to another, like the color of a link while the pointer is over it.
	*/
	static let stateChange = Self.default(duration: .milliseconds(150))

	/**
	A quick change that goes a little past the end and settles back, like the checkmark of a copy button that grows in.
	*/
	static let pop = Self.timingCurve(0.34, 1.56, 0.64, 1, duration: .milliseconds(250))
}

extension Style {
	/**
	Changes the text color while the pointer is over the element, with a quick transition.
	*/
	func hoverColor(_ color: Color) -> Self {
		transition(.color, animation: .stateChange)
			.hover {
				$0.color(color)
			}
	}

	/**
	Changes the text color while the pointer is over the element, to one color in light mode and another in dark mode.
	*/
	func hoverColor(_ light: Color, dark: Color) -> Self {
		hoverColor(.lightDark(light, dark))
	}
}

extension CSSValue {
	/**
	The blue to pink gradient of the site.
	*/
	static let brandGradient = linearGradient("to right", .primary(500), .secondary(500), in: "oklch")

	static let brandGradientHover = linearGradient("to right", .primary(600), .secondary(600), in: "oklch")
}

extension Style {
	/**
	A link in a navigation bar as a pill, like the chips of the site: the card fill under the pointer, and a stronger fill for the current page or section (`aria-current`).

	- Parameter currentFill: The fill of the current link, like a tint of the accent of an app page.
	*/
	func navigationPill(currentFill: Color = .cardHover) -> Self {
		padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
			.cornerRadius(.capsule)
			.fontWeight(.medium)
			.transition(.color, .backgroundColor, animation: .stateChange)
			.hover {
				$0
					.color(.primaryText)
					.background(.card)
			}
			.current {
				$0
					.color(.primaryText)
					.background(currentFill)
			}
	}

	/**
	The pink underline of the link to the current page or section (`aria-current`). It fades in, like when the scroll spy moves to the next section.
	*/
	func currentPageUnderline() -> Self {
		underline(color: .transparent, thickness: .pixels(3))
			.underlineOffset(.pixels(7))
			.transition(.underlineColor, animation: .easeInOut(duration: .milliseconds(500)))
			.current {
				$0.underlineColor(.secondary(500))
			}
			// Forced colors replace the transparent color, so only the current link keeps an underline.
			.media(.forcedColors) {
				$0.nested("&:not([aria-current])") {
					$0.underline(false)
				}
			}
	}
}

extension Style {
	enum ColumnWidth {
		/**
		46.5rem, the width of prose, so the text is 43.5rem wide, about 78 characters per line. Headers of prose pages use it, so they line up with the text.
		*/
		case prose

		/**
		52rem, for blocks in prose that are not running text, like tables, code, and the FAQ. See ``Style/widerThanProse()``.
		*/
		case proseBlock

		/**
		48rem, for text with other content, like quote cards.
		*/
		case standard

		/**
		64rem, for grids and galleries.
		*/
		case wide

		/**
		72rem, the width of the header and the footer (``Style/pageWidth()``), so the content lines up with theirs, like the app cards.
		*/
		case page

		var maximum: Length {
			switch self {
			case .prose:
				.rootEm(46.5)
			case .proseBlock:
				.rootEm(52)
			case .standard:
				.rootEm(48)
			case .wide:
				.rootEm(64)
			case .page:
				.rootEm(72)
			}
		}
	}

	/**
	The dark box of a block of code, like a code block: light text on dark, in both modes.
	*/
	func codeSurface() -> Self {
		padding(vertical: .em(1), horizontal: .em(1.5))
			.cornerRadius(.rootEm(0.375))
			.overflow(horizontal: .auto)
			.font(size: .em(0.8889), lineHeight: 1.75)
			.fontWeight(.regular)
			// Code is often indented with tabs, which are 8 spaces wide by default.
			.declaration(.tabSize, 4)
			.color(.gray(200))
			.background(.gray(800))
			// The code is light on dark in both modes, so the scroll bar is too. The dark background is not `light-dark()`, as that would follow this color scheme.
			.colorScheme(.dark)
			.dark {
				$0.background(.black.opacity(0.5))
			}
	}

	/**
	Wider than the prose it is in, and centered on it, for blocks that are not running text, like tables, code, and the FAQ. The text keeps its line length, and the blocks get more room. Below tablets, the block is as wide as the text.
	*/
	func widerThanProse() -> Self {
		let width = Length.min(ColumnWidth.proseBlock.maximum, .viewportWidth(100) - .pageGutter * 2)

		return from(.tablet) {
			$0
				.frame(width: width)
				.margin(.horizontal, (.percent(100) - width) * 0.5)
		}
	}

	/**
	The centered column of the content of a page, with the space of the page at the sides (``Length/pageGutter``).
	*/
	func contentColumn(_ width: ColumnWidth = .standard) -> Self {
		frame(maxWidth: width.maximum)
			.margin(.horizontal, .auto)
			.padding(.horizontal, .pageGutter)
	}

	/**
	The centered width of the header, the footer, and other parts that line up with them, 72rem.
	*/
	func pageWidth() -> Self {
		frame(maxWidth: ColumnWidth.page.maximum)
			.margin(vertical: 0, horizontal: .auto)
	}

	/**
	The space above and below the content of a page, which grows on larger screens.
	*/
	func pagePadding() -> Self {
		padding(.vertical, .rootEm(2))
			.from(.smallTablet) {
				$0.padding(.vertical, .rootEm(4))
			}
			.from(.laptop) {
				$0.padding(.vertical, .rootEm(5))
			}
	}

	/**
	The root of a page with a ``PageHeader``: the centered column, the space of the page, and the space between its parts, so the title and the space below it are the same on every page.
	*/
	func pageColumn(_ width: ColumnWidth = .standard) -> Self {
		contentColumn(width)
			.pagePadding()
			.flowSpacing(.rootEm(2.5))
	}

	/**
	The look of a link in running text, like in prose or a notice. The underline is in the accent of the page, like the color of the icon on an app page, at half strength, so a list with many links stays calm. It gets the full accent while the pointer is over the link.
	*/
	func textLink() -> Self {
		color(.primaryText)
			.fontWeight(.medium)
			.underline(thickness: .pixels(2))
			.underlineColor(.lightDark(Color.accent(fallback: .primary(500), maximumLightness: 0.65).opacity(0.5), Color.accent.value(default: .primary(400)).opacity(0.55)))
			.underlineOffset(.pixels(4))
			.transition(.underlineColor, animation: .stateChange)
			.hover {
				$0.underlineColor(.lightDark(.accent(fallback: .primary(500), maximumLightness: 0.6), Color.accent.value(default: .primary(400))))
			}
	}

	/**
	Gives the links in a block of text the look of ``textLink()``, like the links in the introduction of a page.
	*/
	func textLinks() -> Self {
		nested("a") {
			$0.textLink()
		}
	}

	/**
	The look of a card: a light, see-through fill with a faint edge. A card that links somewhere looks like glass while the pointer is over it: a soft light in the accent color shines through it, and it glows around its edges. The accent can be set on the card, like the color of the icon of an app card. Nothing moves. A card that links somewhere has no underline, like a link in prose has.
	*/
	func cardSurface(isInteractive: Bool = true) -> Self {
		// TODO: Add `corner-shape: squircle` when Safari and Firefox support it.
		// A faint edge gives the light fill a clear outline, like the materials of Apple platforms.
		let style = background(.card)
			.cornerRadius(.cardRadius)
			.shadow(Shadow(y: 0, spread: .pixels(1), color: .lightDark(.black.opacity(0.04), .white.opacity(0.06)), isInset: true))

		guard isInteractive else {
			return style
		}

		// The light is a gradient in the background of the card, which fades in with a registered property. It is not a layer of its own, as Safari moves the text a little while it animates a layer above or below it.
		let accent = Color.accent.value(default: .primary(500))

		func light(strength: Int) -> CSSValue {
			CSSValue("radial-gradient(circle at 15% 40%, color-mix(in oklab, \(accent) calc(\(cardLight.value) * \(strength)%), transparent), transparent 70%)")
		}

		return style
			.underline(false)
			.setting(cardLight, to: 0)
			.backgroundImage(light(strength: 10))
			.dark {
				$0.backgroundImage(light(strength: 17))
			}
			.transition(.backgroundColor, .shadow, animation: .stateChange)
			.transition(TransitionProperty(Property(cardLight.name)), animation: .default(duration: .milliseconds(300)))
			.hover {
				$0
					.setting(cardLight, to: 1)
					.background(.cardHover)
					// The glow around the card, and a thin light edge, like the rim of glass.
					.shadow(.extraLarge(color: .lightDark(accent.opacity(0.07), accent.opacity(0.12))) + [Shadow(y: 0, spread: .pixels(1), color: .lightDark(accent.opacity(0.12), .white.opacity(0.1)), isInset: true)])
			}
	}

	/**
	A small, quiet link in a row of links, like the categories on the apps page and the sections of an app page, so the main button of a page stays the only strong color.
	*/
	func chip() -> Self {
		padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.875))
			.cornerRadius(.capsule)
			.textStyle(.caption, weight: .medium)
			.textWrap(.nowrap)
			.color(.bodyText)
			.background(.card)
			.transition(.backgroundColor, .color, animation: .stateChange)
			.hover {
				$0
					.background(.cardHover)
					.color(.primaryText)
			}
	}

	/**
	The look of a popover, like a footnote or a QR code: a light border, an opaque background, and a large shadow.
	*/
	func popoverSurface() -> Self {
		background(.white, dark: .gray(900))
			.shadow(.window)
	}

	/**
	On touch screens, a tap area of at least 2.75rem around the center of a small element, like a footnote reference, without moving the layout. It uses `::before`.
	*/
	func minimumTapArea() -> Self {
		media(.coarsePointer) {
			$0
				.position(.relative)
				.before {
					$0
						.content("")
						.position(.absolute)
						.top(.percent(50))
						.leading(.percent(50))
						.frame(width: .max(.percent(100), .rootEm(2.75)), height: .max(.percent(100), .rootEm(2.75)))
						.offset(x: .percent(-50), y: .percent(-50))
				}
		}
	}

	/**
	Brightens the element a little while the pointer is over it, and shrinks and darkens it a little while it is pressed, like the App Store badge. Download badges and large buttons use it, so they feel the same next to each other. It does not grow on hover, as that moves the page.
	*/
	func pressEffect() -> Self {
		transition(.scaleEffect, .filter, animation: .default(duration: .milliseconds(200)))
			.hover {
				$0.filter(.brightness(1.08))
			}
			.active {
				$0
					.filter(.brightness(0.95))
					.scaleEffect(0.985)
			}
	}
}
