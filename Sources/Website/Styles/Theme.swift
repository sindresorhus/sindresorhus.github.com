import SiteKit

/**
The color palettes of the site, from the Tailwind palette the old site used.

Each shade is a custom property on `:root`, like `--gray-900`, so the stylesheet defines each color once. Use a shade with ``Color/gray(_:)`` and the other palette functions.
*/
enum Palette: String, CaseIterable {
	case gray
	case slate

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

	/**
	The shades of the palette, from light (50) to dark (950).
	*/
	var shades: KeyValuePairs<Int, Color> {
		switch self {
		case .gray:
			[100: "oklch(96.7% .003 264.542)", 200: "oklch(92.8% .006 264.531)", 300: "oklch(87.2% .01 258.338)", 400: "oklch(70.7% .022 261.325)", 500: "oklch(55.1% .027 264.364)", 600: "oklch(44.6% .03 256.802)", 700: "oklch(37.3% .034 259.733)", 800: "oklch(27.8% .033 256.848)", 900: "oklch(21% .034 264.665)"]
		case .slate:
			[50: "oklch(98.4% .003 247.858)", 200: "oklch(92.9% .013 255.508)", 300: "oklch(86.9% .022 252.894)", 400: "oklch(70.4% .04 256.788)", 500: "oklch(55.4% .046 257.417)", 600: "oklch(44.6% .043 257.281)", 700: "oklch(37.2% .044 257.287)", 800: "oklch(27.9% .041 260.031)", 900: "oklch(20.8% .042 265.755)", 950: "oklch(12.9% .042 264.695)"]
		case .primary:
			[50: "#eff6ff", 100: "#dbeafe", 200: "#bfdbfe", 300: "#93c5fd", 400: "#60a5fa", 500: "#3b82f6", 600: "#2563eb", 700: "#1d4ed8", 800: "#1e40af", 900: "#1e3a8a", 950: "#172554"]
		case .secondary:
			[50: "#fdf2f8", 200: "#fbcfe8", 400: "#f472b6", 500: "#ec4899", 600: "#db2777", 800: "#9d174d", 900: "#831843"]
		case .red:
			[400: "#f87171", 500: "#ef4444", 600: "#dc2626"]
		case .amber:
			[50: "oklch(98.7% .022 95.277)", 200: "oklch(92.4% .12 95.746)", 300: "oklch(87.9% .169 91.605)", 400: "oklch(82.8% .189 84.429)", 600: "oklch(66.6% .179 58.318)", 700: "oklch(55.5% .163 48.998)", 800: "oklch(47.3% .137 46.201)", 900: "oklch(41.4% .112 45.904)"]
		case .orange:
			[100: "oklch(95.4% .038 75.164)", 200: "oklch(90.1% .076 70.697)"]
		case .teal:
			[100: "oklch(95.3% .051 180.801)", 200: "oklch(91% .096 180.426)"]
		case .sky:
			[100: "oklch(95.1% .026 236.824)", 200: "oklch(90.1% .058 230.902)"]
		case .indigo:
			[50: "oklch(96.2% .018 272.314)", 200: "oklch(87% .065 274.039)", 500: "oklch(58.5% .233 277.117)", 950: "oklch(25.7% .09 281.288)"]
		case .violet:
			[500: "#8b5cf6"]
		}
	}

	func color(_ shade: Int) -> Color {
		precondition(shades.contains { $0.key == shade }, "The \(rawValue) palette has no shade \(shade).")
		return Color(CSSValue.variable("--\(rawValue)-\(shade)").description)
	}

	/**
	The custom properties of every shade, for `:root`.
	*/
	static var customProperties: Style {
		allCases.reduce(Style()) { style, palette in
			palette.shades.reduce(style) { $0.declaration(Property("--\(palette.rawValue)-\($1.key)"), CSSValue($1.value)) }
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

	var light: Color {
		switch self {
		case .primaryText:
			.gray(900)
		case .bodyText:
			.gray(700)
		case .secondaryText:
			.gray(500)
		case .link:
			.primary(600)
		case .separator:
			.gray(200)
		case .pageBackground:
			.white
		}
	}

	var dark: Color {
		switch self {
		case .primaryText:
			.white
		case .bodyText:
			.gray(300)
		case .secondaryText:
			.gray(400)
		case .link:
			.primary(400)
		case .separator:
			.gray(700)
		case .pageBackground:
			.slate(950)
		}
	}

	/**
	The colors when the visitor asks for more contrast in the system settings. Secondary text, links, and separators get darker in light mode and lighter in dark mode.
	*/
	var moreContrast: Color.LightDark {
		switch self {
		case .primaryText, .pageBackground:
			Color.LightDark(light: light, dark: dark)
		case .bodyText:
			Color.LightDark(light: .gray(800), dark: .gray(200))
		case .secondaryText:
			Color.LightDark(light: .gray(700), dark: .gray(300))
		case .link:
			Color.LightDark(light: .primary(700), dark: .primary(300))
		case .separator:
			Color.LightDark(light: .gray(500), dark: .gray(400))
		}
	}

	private var propertyName: String {
		"--" + rawValue.replacing(/[A-Z]/) { "-\($0.output.lowercased())" }
	}

	var color: Color {
		Color(CSSValue.variable(propertyName).description)
	}

	/**
	The custom properties of every semantic color, for `:root`.
	*/
	static var customProperties: Style {
		allCases
			.reduce(Style()) { $0.declaration(Property($1.propertyName), CSSValue(Color.lightDark($1.light, $1.dark))) }
			.media(.moreContrast) { style in
				allCases.reduce(style) { $0.declaration(Property($1.propertyName), CSSValue(Color.lightDark($1.moreContrast.light, $1.moreContrast.dark))) }
			}
	}
}

extension Color {
	/**
	A color for light mode and one for dark mode.
	*/
	struct LightDark {
		let light: Color
		let dark: Color
	}

	static let white: Self = "#fff"
	static let black: Self = "#000"
	static let primaryText = SemanticColor.primaryText.color
	static let bodyText = SemanticColor.bodyText.color
	static let secondaryText = SemanticColor.secondaryText.color
	static let link = SemanticColor.link.color
	static let separator = SemanticColor.separator.color
	static let pageBackground = SemanticColor.pageBackground.color

	static func gray(_ shade: Int) -> Self {
		Palette.gray.color(shade)
	}

	static func slate(_ shade: Int) -> Self {
		Palette.slate.color(shade)
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
}

/**
The text sizes, each with its line height, from the Tailwind scale.
*/
enum TextSize {
	case xs
	case sm
	case base
	case lg
	case xl
	case xl2
	case xl3
	case xl4
	case xl5
	case xl6
	case xl8
	case xl9

	var size: Length {
		switch self {
		case .xs:
			.rem(0.75)
		case .sm:
			.rem(0.875)
		case .base:
			.rem(1)
		case .lg:
			.rem(1.125)
		case .xl:
			.rem(1.25)
		case .xl2:
			.rem(1.5)
		case .xl3:
			.rem(1.875)
		case .xl4:
			.rem(2.25)
		case .xl5:
			.rem(3)
		case .xl6:
			.rem(3.75)
		case .xl8:
			.rem(6)
		case .xl9:
			.rem(8)
		}
	}

	var lineHeight: Double {
		switch self {
		case .xs:
			1.3333
		case .sm:
			1.4286
		case .base:
			1.5
		case .lg:
			1.5556
		case .xl:
			1.4
		case .xl2:
			1.3333
		case .xl3:
			1.2
		case .xl4:
			1.1111
		case .xl5, .xl6, .xl8, .xl9:
			1
		}
	}
}

extension Style {
	/**
	A text size from the scale, with its line height.
	*/
	func font(_ size: TextSize, weight: FontWeight? = nil) -> Self {
		let style = font(size: size.size, lineHeight: size.lineHeight)
		return weight.map { style.fontWeight($0) } ?? style
	}
}

extension Breakpoint {
	/**
	The width of a small phone, where fluid sizes start to grow.
	*/
	static let phone = Self(minimumWidthInRem: 24)

	static let sm = Self(minimumWidthInRem: 40)
	static let md = Self(minimumWidthInRem: 48)
	static let lg = Self(minimumWidthInRem: 64)
	static let xl = Self(minimumWidthInRem: 80)
	static let xxl = Self(minimumWidthInRem: 96)
}

extension FontFamily {
	static let system: Self = #"-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", "Noto Sans", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji""#
	static let monospace: Self = #"ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace"#

	/**
	SF Pro on Apple platforms, which can be expanded with `font-stretch`.
	*/
	static let expandable: Self = "ui-sans-serif, -apple-system, system-ui, sans-serif"
}

/**
The shadow sizes, from the Tailwind scale.
*/
extension [Shadow] {
	static let small = [Shadow(y: .px(1), blur: .px(3), color: .black.opacity(0.1)), Shadow(y: .px(1), blur: .px(2), spread: .px(-1), color: .black.opacity(0.1))]
	static let medium = [Shadow(y: .px(4), blur: .px(6), spread: .px(-1), color: .black.opacity(0.1)), Shadow(y: .px(2), blur: .px(4), spread: .px(-2), color: .black.opacity(0.1))]
	static let large = [Shadow(y: .px(10), blur: .px(15), spread: .px(-3), color: .black.opacity(0.1)), Shadow(y: .px(4), blur: .px(6), spread: .px(-4), color: .black.opacity(0.1))]
	static let extraLarge = extraLarge(color: .black.opacity(0.1))

	static func extraLarge(color: Color) -> Self {
		[Shadow(y: .px(20), blur: .px(25), spread: .px(-5), color: color), Shadow(y: .px(8), blur: .px(10), spread: .px(-6), color: color)]
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
	The pink underline of the link to the current page or section (`aria-current`). It fades in, like when the scroll spy moves to the next section.
	*/
	func currentPageUnderline() -> Self {
		underline(color: .transparent, thickness: .px(3))
			.underlineOffset(.px(7))
			.transition(.underlineColor, duration: .milliseconds(500), curve: .easeInOut)
			.nested("&[aria-current]") {
				$0.underlineColor(.secondary(500))
			}
			// Forced colors replace the transparent color, so only the current link keeps an underline.
			.media(.forcedColors) {
				$0.nested("&:not([aria-current])") {
					$0.noUnderline()
				}
			}
	}
}

extension Style {
	/**
	The centered column of the text of a page, 48rem wide, with space at the sides on small screens.
	*/
	func contentColumn() -> Self {
		frame(maxWidth: .rem(48))
			.margin(.horizontal, .auto)
			.padding(.horizontal, .rem(1.5))
	}

	/**
	The centered width of the header, the footer, and other parts that line up with them, 72rem.
	*/
	func pageWidth() -> Self {
		frame(maxWidth: .rem(72))
			.margin(vertical: 0, horizontal: .auto)
	}

	/**
	The space above and below the content of a page, which grows on larger screens.
	*/
	func pagePadding() -> Self {
		padding(.vertical, .rem(2))
			.breakpoint(.sm) {
				$0.padding(.vertical, .rem(4))
			}
			.breakpoint(.lg) {
				$0.padding(.vertical, .rem(5))
			}
	}

	/**
	The look of a card that links somewhere, like a feed: a light border, a soft shadow, and a blue tint while the pointer is over it.
	*/
	func cardSurface() -> Self {
		// TODO: Add `corner-shape: squircle` when Safari and Firefox support it.
		border(.slate(200).opacity(0.8))
			.cornerRadius(.rem(0.5))
			.background(.white.opacity(0.8), dark: .white.opacity(0.03))
			.shadow(.small)
			.transition(.borderColor, .backgroundColor, .shadow, duration: .milliseconds(150))
			.hover {
				$0
					.borderColor(.primary(200))
					.background(.primary(50).opacity(0.5))
					.shadow(.medium)
			}
			.dark {
				$0
					.borderColor(.white.opacity(0.1))
					.hover {
						$0
							.borderColor(.primary(500).opacity(0.4))
							.background(.primary(950).opacity(0.2))
					}
			}
	}
}
