import SiteKit

// MARK: Colors

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
			[100: "oklch(93.6% .032 17.717)", 200: "oklch(88.5% .062 18.334)", 400: "oklch(70.4% .191 22.216)", 500: "oklch(63.7% .237 25.331)", 600: "oklch(57.7% .245 27.325)"]
		case .amber:
			[50: "oklch(98.7% .022 95.277)", 100: "oklch(96.2% .059 95.617)", 200: "oklch(92.4% .12 95.746)", 300: "oklch(87.9% .169 91.605)", 400: "oklch(82.8% .189 84.429)", 600: "oklch(66.6% .179 58.318)", 700: "oklch(55.5% .163 48.998)", 800: "oklch(47.3% .137 46.201)", 900: "oklch(41.4% .112 45.904)", 950: "oklch(27.9% .077 45.635)"]
		case .orange:
			[100: "oklch(95.4% .038 75.164)", 200: "oklch(90.1% .076 70.697)"]
		case .teal:
			[100: "oklch(95.3% .051 180.801)", 200: "oklch(91% .096 180.426)"]
		case .sky:
			[100: "oklch(95.1% .026 236.824)", 200: "oklch(90.1% .058 230.902)"]
		case .indigo:
			[50: "oklch(96.2% .018 272.314)", 100: "oklch(93% .034 272.788)", 200: "oklch(87% .065 274.039)", 500: "oklch(58.5% .233 277.117)", 950: "oklch(25.7% .09 281.288)"]
		case .violet:
			[500: "oklch(60.6% .25 292.717)"]
		case .emerald:
			[50: "oklch(97.9% .021 166.113)", 100: "oklch(95% .052 163.051)", 200: "oklch(90.5% .093 164.15)", 400: "oklch(76.5% .177 163.223)", 700: "oklch(50.8% .118 165.612)", 950: "oklch(26.2% .051 172.552)"]
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
		StyleVariable("\(rawValue)-\(shade)")
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
	The light and dark colors, and the colors when the visitor asks for more contrast in the system settings, when they differ. Body text, secondary text, links, and separators get darker in light mode and lighter in dark mode, and the fills of cards get stronger, so a card stands out from the page.
	*/
	private var definition: (color: Color, moreContrast: Color?) {
		switch self {
		case .primaryText:
			(.lightDark(.gray(900), .white), nil)
		case .bodyText:
			(.lightDark(.gray(700), .gray(300)), .lightDark(.gray(800), .gray(200)))
		case .secondaryText:
			(.lightDark(.gray(500), .gray(400)), .lightDark(.gray(700), .gray(300)))
		case .link:
			(.lightDark(.primary(600), .primary(400)), .lightDark(.primary(700), .primary(300)))
		case .separator:
			// Faint, between two shades in light mode, so the lines set things apart without drawing the eye.
			(.lightDark(.gray(200).mix(with: .gray(100), amount: .percent(50)), .gray(800)), .lightDark(.gray(500), .gray(400)))
		// In dark mode, a near black with a tiny blue tint.
		case .pageBackground:
			(Color.lightDark(Self.pageBackgroundColors.light, Self.pageBackgroundColors.dark), nil)
		// See-through, so a card takes a little of the color behind it.
		case .card:
			(.lightDark(.black.opacity(0.035), .white.opacity(0.065)), .lightDark(.black.opacity(0.07), .white.opacity(0.12)))
		case .cardHover:
			(.lightDark(.primary(500).opacity(0.06), .white.opacity(0.095)), .lightDark(.primary(500).opacity(0.12), .white.opacity(0.17)))
		}
	}

	/**
	The page background colors before composition, for browser theme-color metadata.
	*/
	static let pageBackgroundColors = Color.LightDark(light: .white, dark: "oklch(14% .012 264)")

	/**
	The colors when the visitor asks for more contrast, or `nil` when they are the same as the ordinary color.
	*/
	private var moreContrast: Color? {
		definition.moreContrast
	}

	private var variable: StyleVariable<Color> {
		StyleVariable("\(rawValue.kebabCased)")
	}

	var color: Color {
		variable.value
	}

	/**
	The custom properties of every semantic color, for `:root`, and the colors that change when the visitor asks for more contrast.
	*/
	static var customProperties: Style {
		allCases
			.reduce(Style()) { $0.setting($1.variable, to: $1.definition.color) }
			.media(.moreContrast) { style in
				allCases.reduce(style) { style, color in
					guard let colors = color.moreContrast else {
						return style
					}

					return style.setting(color.variable, to: colors)
				}
			}
	}
}

extension Color {
	/**
	The accent of the page, which an app page sets to the color of its icon. The styles that use it give the brand color as the fallback, so other pages look the same.
	*/
	static let accent = StyleVariable<Color>("accent")

	/**
	The accent, or the fallback, with the lightness limited, so it works as a fill with white text or as a line on white.
	*/
	static func accent(fallback: Color, maximumLightness: Double) -> Self {
		Self(raw: "oklch(from \(accent.value(default: fallback)) min(l, \(maximumLightness)) c h)")
	}

	/**
	The accent for small marks on the page background, like the numbers of steps and the current dot of a carousel. It is dark enough on white, and the accent itself in dark mode, so an app page shows the color of its icon in both.
	*/
	static let accentMark = lightDark(.accent(fallback: .primary(600), maximumLightness: 0.6), darkModeAccent)

	/**
	The accent in dark mode, where the lighter brand color is the fallback, so it stands out on the dark background.
	*/
	static let darkModeAccent = accent.value(default: .primary(400))

	/**
	The accent, with the brand color as the fallback, for tints of the accent in both modes, like the light of a card and the fill of a secondary button.
	*/
	static let pageAccent = accent.value(default: .primary(500))

	/**
	A color for light mode and one for dark mode.
	*/
	struct LightDark {
		let light: Color
		let dark: Color
	}

	/**
	The value of a palette shade, like `oklch(18.8% .004 286)` for `.gray(950)`, for places that cannot use custom properties, like the `theme-color` meta tag. Other colors are returned as they are.
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

extension CSSImage {
	/**
	The blue to pink gradient of the site.
	*/
	static let brandGradient = linearGradient(
		.toRight,
		.primary(500),
		.secondary(500),
		in: .oklch
	)

	static let brandGradientHover = linearGradient(
		.toRight,
		.primary(600),
		.secondary(600),
		in: .oklch
	)
}

// MARK: Text

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

	/**
	The size and line height of each step of the scale, kept together.
	*/
	private var metrics: (size: LengthPercentage, lineHeight: Double) {
		switch self {
		case .extraSmall:
			(.rootEm(0.75), 1.3333)
		case .small:
			(.rootEm(0.875), 1.4286)
		case .regular:
			(.rootEm(1), 1.5)
		case .large:
			(.rootEm(1.125), 1.5556)
		case .extraLarge:
			(.rootEm(1.25), 1.4)
		case .extraLarge2:
			(.rootEm(1.5), 1.3333)
		case .extraLarge3:
			(.rootEm(1.875), 1.2)
		case .extraLarge4:
			(.rootEm(2.25), 1.1111)
		case .extraLarge5:
			(.rootEm(3), 1)
		case .extraLarge6:
			(.rootEm(3.75), 1)
		case .extraLarge8:
			(.rootEm(6), 1)
		case .extraLarge9:
			(.rootEm(8), 1)
		}
	}

	var size: LengthPercentage {
		metrics.size
	}

	var lineHeight: Double {
		metrics.lineHeight
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
	The title of a section, like a heading in prose (`h2`) and ``Section``, so a section in prose looks the same as one outside it.
	*/
	case sectionTitle

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

	/**
	The related typography values of each semantic role.
	*/
	private var definition: (size: LengthPercentage, lineHeight: Double, weight: FontWeight?, letterSpacing: Length?) {
		switch self {
		case .largeTitle:
			(.clamp(.rootEm(2.5), .viewportWidth(6), .rootEm(3.75)), 1.04, .bold, .em(-0.032))
		case .title:
			(.clamp(.rootEm(1.875), .viewportWidth(4), .rootEm(2.5)), 1.08, .bold, .em(-0.026))
		case .sectionTitle:
			(.rootEm(1.875), 1.15, .bold, .em(-0.025))
		case .headline:
			(.rootEm(1.1875), 1.3, .semibold, .em(-0.01))
		case .lead:
			(.rootEm(1.125), 1.55, nil, nil)
		case .body:
			(.rootEm(1), 1.55, nil, nil)
		case .caption:
			(.rootEm(0.875), 1.5, nil, nil)
		}
	}

	var size: LengthPercentage {
		definition.size
	}

	var lineHeight: Double {
		definition.lineHeight
	}

	/**
	The weight of titles. Running text has none, so it keeps the weight of its parent, like bold text in a bold link.
	*/
	var weight: FontWeight? {
		definition.weight
	}

	/**
	The letter spacing of titles. Running text has none, so it keeps the letter spacing of its parent.
	*/
	var letterSpacing: Length? {
		definition.letterSpacing
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
		let style = font(size: size.size, lineHeight: CSSNumber(size.lineHeight))
		return weight.map { style.fontWeight($0) } ?? style
	}

	/**
	The size, line height, weight, and letter spacing of a role of text. Prefer it to ``font(_:weight:)`` when a role fits.

	- Parameter weight: Another weight than the one of the role, like a semibold caption.
	*/
	func textStyle(_ textStyle: TextStyle, weight: FontWeight? = nil) -> Self {
		var style = font(size: textStyle.size, lineHeight: CSSNumber(textStyle.lineHeight))

		if let weight = weight ?? textStyle.weight {
			style = style.fontWeight(weight)
		}

		if let letterSpacing = textStyle.letterSpacing {
			style = style.letterSpacing(letterSpacing)
		}

		return style
	}

	/**
	Breaks a word that is wider than its column, like a long name in a large title on a phone with large text: with a hyphen where the browser can hyphenate the word, else anywhere. A title that wraps can also get a hyphen at a line break when its words fit, so use it only on titles, where long names are the problem.
	*/
	func breaksLongWords() -> Self {
		hyphenation(true)
			.overflowWrap(.breakWord)
	}

	/**
	The expanded width of SF Pro on Apple platforms, for large display text, like the name on the home page. Other platforms show their regular sans-serif font.
	*/
	func expandedFont() -> Self {
		fontFamily(.expandable)
			.fontWidth(.expanded)
	}

	/**
	A short label above a title, like “Newest App” on a card: small, semibold, and in the link color, not the accent, as small text in the color of some icons is hard to read.
	*/
	func eyebrow() -> Self {
		textStyle(.caption, weight: .semibold)
			.color(.link)
	}
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

	/**
	New York on Apple platforms, for names in the look of a masthead, like the publications of the press quotes.
	*/
	static let serif: Self = #"ui-serif, "New York", Georgia, serif"#
}

// MARK: Layout

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

extension LengthPercentage {
	/**
	The space between the edge of the screen and the content, like the text of a page, the site name in the header, and the footer (1.5rem, 24px). Inside the width of the header and the footer (``Style/pageWidth()``), it is the space at their sides, so the content lines up with theirs.

	It does not grow with larger text, like the margins of iOS do not grow with Dynamic Type, as on a phone, wider margins would leave the larger text less space.
	*/
	static let pageGutter = min(.rootEm(1.5), .pixels(24))

	/**
	The space between the edge of a box in prose and its text, like the FAQ, a table, code, or an alert. A box hangs into the space at the sides of the text by it (``Style/widerThanProse()``), so its text starts where the paragraphs start. It is the space of the page, so a box that is full width on a phone also has its text in line with the text around it.
	*/
	static let boxInset = pageGutter

	/**
	The space between the parts of a page, like the screenshots, the reviews, and the box to get an app on an app page, from the size in `rem` on larger screens. On phones, where a large space is much of the screen, it is 80% of that, and it grows with the width of the screen to the full size at small tablets (``Breakpoint/smallTablet``).
	*/
	static func partSpacing(rootEm size: Double) -> Self {
		.clamp(.rootEm(size * 0.8), .viewportWidth(size / Breakpoint.smallTablet.minimumWidthInRem * 100), .rootEm(size))
	}
}

extension Style {
	enum ColumnWidth {
		/**
		46.5rem, the width of prose, so the text is 43.5rem wide, about 78 characters per line. Headers of prose pages use it, so they line up with the text.
		*/
		case prose

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

		var maximum: LengthPercentage {
			switch self {
			case .prose:
				.rootEm(46.5)
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
	Wider than the prose it is in by ``LengthPercentage/boxInset`` at each side, for boxes, like tables, code, the FAQ, and alerts. With the inset as the padding of the box, its text starts where the paragraphs start. Below tablets, the box is as wide as the text.
	*/
	func widerThanProse() -> Self {
		from(.tablet) {
			$0.margin(.horizontal, .length(-.boxInset))
		}
	}

	/**
	A centered column of a width, without space at the sides, like a block inside a page that already has it.
	*/
	func centeredColumn(_ width: ColumnWidth) -> Self {
		frame(maxWidth: .length(width.maximum))
			.margin(.horizontal, .auto)
	}

	/**
	The centered column of the content of a page, with the space of the page at the sides (``LengthPercentage/pageGutter``).
	*/
	func contentColumn(_ width: ColumnWidth = .standard) -> Self {
		centeredColumn(width)
			.padding(.horizontal, .pageGutter)
	}

	/**
	A grid of columns where the items of a last row that is not full are centered below the others, like the last two of five items in three columns, so the row has no hole at one side. Each item spans two of twice as many columns, so the items of the last row can start in the middle of a column. A grid can have a smaller count at a smaller screen, like two columns on tablets and three on laptops, as the rules of the larger count replace the rules of the smaller.
	*/
	func balancedColumns(_ count: Int) -> Self {
		var style = gridColumns(count * 2)
			.children("*") {
				$0.gridColumnSpan(2)
			}

		// The rules of the last row are in `:where()`, so they are as specific as the rule of all the items, and the rule of all the items of a larger count replaces them.
		for itemsInLastRow in 1..<count {
			style = style.children(":where(:nth-last-child(\(raw: String(itemsInLastRow))):nth-child(\(raw: String(count))n + 1))") {
				$0.gridColumnSpan(2, from: count - itemsInLastRow + 1)
			}
		}

		return style
	}

	/**
	A row of cards that the visitor swipes on phones, so a few cards do not fill several screens, like the press quotes and the reviews of an app page. Each card is a little narrower than the row, so the next one shows at the side, and the cards snap to the space of the page in front of them (``LengthPercentage/pageGutter``), so the row reaches the edges of the screen when it has the space of the page as its padding. It does not scroll by itself.

	The component makes the row a Tab stop with a name (`tabindex="0"` and `aria-label`), so keyboard users can scroll it, also to a card without a link. The focus of the keyboard shows as a thin edge around the row, as there are no focus rings.
	*/
	func swipeRow(spacing: LengthPercentage) -> Self {
		focusVisible {
			$0.shadow(.edge(.secondaryText))
		}
		.below(.smallTablet) {
			$0
				.hstack(alignment: .start, spacing: spacing)
				.overflow(horizontal: .auto)
				.scrollSnapType(.horizontal, isMandatory: true)
				.scrollPadding(horizontal: .pageGutter)
				// A horizontal swipe on a trackpad at the end does not go back in the history.
				.overscrollBehavior(horizontal: .contain)
				// Room for the shadows of the cards, which the scrolling would cut off.
				.padding(.vertical, .rootEm(1))
				.margin(.vertical, .rootEm(-1))
				.children("*") {
					$0
						.flexShrink(0)
						.frame(width: .percent(84))
						.scrollSnapAlign(.start)
				}
		}
	}

	/**
	Reaches the edges of the screen, out of the space of the page around it (``LengthPercentage/pageGutter``), and has that space as its padding, so its content still starts at the edge of the page, like a row that scrolls sideways on phones, where a cut-off item at the edge of the screen shows that it scrolls.
	*/
	func fullBleed() -> Self {
		padding(.horizontal, .pageGutter)
			.margin(.horizontal, .length(-.pageGutter))
	}

	/**
	The column of the wide parts of an app page, like the press quotes and the reviews in more than two columns, and the box to get the app, so they all have one edge: from laptops as wide as grids (``ColumnWidth/wide``), and on large screens as wide as the content of the header (``ColumnWidth/page``), both less the space of the page at the sides (``LengthPercentage/pageGutter``). The edge is the edge of the box, so a part that has the space of the page as its padding (``contentColumn(_:)``) has no padding there.
	*/
	func wideAppPartColumn() -> Self {
		from(.laptop) {
			$0
				.frame(maxWidth: .length(ColumnWidth.wide.maximum - .pageGutter * 2))
				.margin(.horizontal, .auto)
		}
		.from(.largeDesktop) {
			$0.frame(maxWidth: .length(ColumnWidth.page.maximum - .pageGutter * 2))
		}
	}

	/**
	The centered width of the header, the footer, and other parts that line up with them, 72rem.
	*/
	func pageWidth() -> Self {
		centeredColumn(.page)
			.margin(.vertical, .zero)
	}

	/**
	The space above and below the content of a page, which grows on larger screens. The space below is larger, so the end of the content is clearly apart from the footer.
	*/
	func pagePadding() -> Self {
		padding(top: .rootEm(2), bottom: .rootEm(4))
			.from(.smallTablet) {
				$0.padding(top: .rootEm(4), bottom: .rootEm(6))
			}
			.from(.laptop) {
				$0.padding(top: .rootEm(5), bottom: .rootEm(7))
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
}

// MARK: Corners, shadows, and motion

/**
The corner radii, from large to small. A box inside a box uses the radius of the outer box minus the padding between them, so the corners stay parallel.
*/
extension LengthPercentage {
	/**
	Large panels, like the “Get” block at the end of an app page (1.75rem).
	*/
	static let panelRadius = rootEm(1.75)

	/**
	The space between the edge of a panel (``panelRadius``) and its content at the sides (2rem).
	*/
	static let panelPadding = rootEm(2)

	/**
	Cards, like app cards and quotes (1.5rem).
	*/
	static let cardRadius = rootEm(1.5)

	/**
	The space between the edge of a card (``cardRadius``) and its content, like in a quote, a link card, and the cards of the now page, so cards of the same kind look the same (1.5rem). It is as large as the radius, so the corners of the content are in the curve of the card. Cards with much content, like app cards, and compact cards, like the apps of the feeds page, have their own.
	*/
	static let cardPadding = rootEm(1.5)

	/**
	Smaller boxes, like questions in a FAQ (1.25rem).
	*/
	static let boxRadius = rootEm(1.25)

	/**
	Screenshots and other pictures of windows, and blocks of code (0.75rem).
	*/
	static let windowRadius = rootEm(0.75)

	/**
	Form fields, and the boxes of a form next to them, like the files to attach and the help that the feedback page suggests, so they look like one form (0.75rem).
	*/
	static let fieldRadius = rootEm(0.75)
}

/**
The shadow sizes, from the Tailwind scale.
*/
extension [BoxShadow] {
	static let small = [BoxShadow(y: .pixels(1), blur: .pixels(3), color: .black.opacity(0.1)), BoxShadow(
		y: .pixels(1),
		blur: .pixels(2),
		spread: .pixels(-1),
		color: .black.opacity(0.1)
	)]
	static let medium = [BoxShadow(
		y: .pixels(4),
		blur: .pixels(6),
		spread: .pixels(-1),
		color: .black.opacity(0.1)
	), BoxShadow(
		y: .pixels(2),
		blur: .pixels(4),
		spread: .pixels(-2),
		color: .black.opacity(0.1)
	)]
	static let large = [BoxShadow(
		y: .pixels(10),
		blur: .pixels(15),
		spread: .pixels(-3),
		color: .black.opacity(0.1)
	), BoxShadow(
		y: .pixels(4),
		blur: .pixels(6),
		spread: .pixels(-4),
		color: .black.opacity(0.1)
	)]
	static let extraLarge = extraLarge(color: .black.opacity(0.1))

	/**
	A soft, wide shadow with a thin outline, for things that look like windows, like screenshots and popovers.
	*/
	static let window = [
		// Small enough to fit the padding of the media carousel, which would otherwise cut it off at the sides.
		BoxShadow(
			y: .pixels(16),
			blur: .pixels(40),
			spread: .pixels(-16),
			color: .lightDark("oklch(25% .05 264 / 30%)", .black.opacity(0.7))
		),
		BoxShadow(y: .zero, spread: .pixels(1), color: .lightDark(.black.opacity(0.08), .white.opacity(0.1))),
	]

	static func extraLarge(color: Color) -> Self {
		[BoxShadow(
			y: .pixels(20),
			blur: .pixels(25),
			spread: .pixels(-5),
			color: color
		), BoxShadow(
			y: .pixels(8),
			blur: .pixels(10),
			spread: .pixels(-6),
			color: color
		)]
	}
}

extension BoxShadow {
	/**
	A thin line inside the edge of the element, like the faint edge of a card, which gives a light fill a clear outline, like the materials of Apple platforms.
	*/
	static func edge(_ color: Color) -> Self {
		Self(
			y: .zero,
			spread: .pixels(1),
			color: color,
			isInset: true
		)
	}
}

/**
The theme’s one-run timing values, shared with its animation factories.
*/
extension AnimationTiming {
	/**
	A quick color or state change.
	*/
	static let stateChange = Self.default(duration: .milliseconds(150))

	/**
	A quick overshooting change with the default duration.
	*/
	static let pop = pop(duration: .milliseconds(250))

	/**
	An overshooting change with the given duration.
	*/
	static func pop(duration: Duration) -> Self {
		timingCurve(
			0.34,
			1.56,
			0.64,
			1,
			duration: duration
		)
	}

	/**
	The timing of a collapsible section opening or closing.
	*/
	static let disclosure = Self.default(duration: .milliseconds(250))
}

extension Animation {
	/**
	A quick change from one state to another, like the color of a link while the pointer is over it.
	*/
	static let stateChange = Self(timing: .stateChange)

	/**
	A quick change that goes a little past the end and settles back, like the checkmark of a copy button that grows in.
	*/
	static let pop = Self(timing: .pop)

	/**
	A change that goes a little past the end and settles back (``pop``), with another duration, like a very quick one that follows the pointer.
	*/
	static func pop(duration: Duration) -> Self {
		Self(timing: .pop(duration: duration))
	}

	/**
	Opening and closing something, like a question of a FAQ, so its height and its chevron move together.
	*/
	static let disclosure = Self(timing: .disclosure)
}

// MARK: Surfaces

/**
How strong the light of a hovered card is, from 0 to 1. It is registered, so it can fade.
*/
private let cardLight = RegisteredProperty<CSSNumber>(
	"card-light",
	syntax: .number,
	initialValue: 0,
	inherits: false
)

extension Style {
	/**
	The look of a card: a light, see-through fill with a faint edge. A card that links somewhere looks like glass while the pointer is over it, or while the keyboard is on it or on a link in it, like the link of the title of an app card: a soft light in the accent color shines through it, and it glows around its edges. The accent can be set on the card, like the color of the icon of an app card. Nothing moves. A card that links somewhere has no underline, like a link in prose has.
	*/
	func cardSurface(isInteractive: Bool = true) -> Self {
		// TODO: Add `corner-shape: squircle` when Safari and Firefox support it.
		// A faint edge gives the light fill a clear outline, like the materials of Apple platforms. With more contrast, the edge has the color of the separators, which is strong then.
		let style = background(.card)
			.cornerRadius(.cardRadius)
			.shadow(.edge(.lightDark(.black.opacity(0.04), .white.opacity(0.06))))
			.media(.moreContrast) {
				$0.shadow(.edge(.separator))
			}

		guard isInteractive else {
			return style
		}

		// The light is a gradient in the background of the card, which fades in with a registered property. It is not a layer of its own, as Safari moves the text a little while it animates a layer above or below it.
		let accent = Color.pageAccent

		func light(strength: Int) -> CSSImage {
			CSSImage(raw: "radial-gradient(circle at 15% 40%, color-mix(in oklab, \(accent) calc(\(cardLight.value) * \(strength)%), transparent), transparent 70%)")
		}

		// The same look for the pointer, and for the keyboard on the card or on a link in it.
		func lit(_ style: Style) -> Style {
			style
				.setting(cardLight, to: 1)
				.background(.cardHover)
				// The glow around the card, and a thin light edge, like the rim of glass.
				.shadow(.extraLarge(color: .lightDark(accent.opacity(0.07), accent.opacity(0.12))) + [.edge(.lightDark(accent.opacity(0.12), .white.opacity(0.1)))])
		}

		return style
			.underline(false)
			.setting(cardLight, to: 0)
			.backgroundImage(light(strength: 10), dark: light(strength: 17))
			.transition(.backgroundColor, .shadow, timing: .stateChange)
			.transition(TransitionProperty(cardLight), timing: .default(duration: .milliseconds(300)))
			.hoverOrFocusVisible(lit)
			.descendantFocusVisible(lit)
	}

	/**
	A box next to the fields of a form, like a notice or a file to attach: the fill and the faint edge of a card, with the corners of the fields (``LengthPercentage/fieldRadius``), so they look like one form.
	*/
	func fieldBox() -> Self {
		cardSurface(isInteractive: false)
			.cornerRadius(.fieldRadius)
	}

	/**
	The look of a popover, like a footnote or a QR code: an opaque background, the corners of a window, and the soft shadow and thin outline of a window.
	*/
	func popoverSurface() -> Self {
		cornerRadius(.windowRadius)
			.background(.white, dark: .gray(900))
			.shadow(.window)
	}

	/**
	The dark box of a block of code, like a code block: light text on dark, in both modes.
	*/
	func codeSurface() -> Self {
		padding(vertical: .em(1), horizontal: .boxInset)
			.cornerRadius(.windowRadius)
			.overflow(horizontal: .auto)
			.font(size: ProseStyles.smallTextSize, lineHeight: 1.75)
			.fontWeight(.regular)
			// Code is often indented with tabs, which are 8 spaces wide by default.
			.declaration(.tabSize, 4)
			.color(.gray(200))
			.background(.gray(800))
			// The code is light on dark in both modes, so the scroll bar is too. The dark background is not `light-dark()`, as that would follow this color scheme.
			.colorScheme(.dark)
			.dark {
				// Darker than the page, with the faint edge of the cards, as the near black page and the box are almost the same.
				$0
					.background(.black.opacity(0.5))
					.shadow(.edge(.white.opacity(0.06)))
			}
	}

	/**
	A see-through fill that blurs what is behind it, like the materials of Apple platforms, such as the bar of the site header. When the visitor prefers reduced transparency, the fill is opaque and nothing is blurred.

	- Parameter opaque: The fill with reduced transparency, usually the see-through fill without its opacity.
	*/
	func frostedBackground(_ fill: Color, opaque: Color, blur radius: Length) -> Self {
		background(fill)
			.backdropFilter(.blur(radius: radius))
			.reducedTransparency {
				$0
					.background(opaque)
					.backdropFilter()
			}
	}
}

// MARK: Interaction

extension Style {
	/**
	Changes the text color while the pointer is over the element, with a quick transition.
	*/
	func hoverColor(_ color: Color) -> Self {
		transition(.color, timing: .stateChange)
			.hoverOrFocusVisible {
				$0.color(color)
			}
	}

	/**
	Changes the text color while the pointer is over the element, to one color in light mode and another in dark mode.
	*/
	func hoverColor(_ light: Color, dark: Color) -> Self {
		hoverColor(.lightDark(light, dark))
	}

	/**
	Fills the element while the pointer is over it, or while it has the focus of the keyboard, with a quick transition, like a chip or a row of a list.

	- Parameter color: The text color with the fill, like the primary text color for a control in the secondary color.
	*/
	func hoverFill(_ fill: Color, color: Color? = nil) -> Self {
		let style = transition(.backgroundColor, timing: .stateChange)
			.hoverOrFocusVisible {
				$0.background(fill)
			}

		guard let color else {
			return style
		}

		return style.transition(.color, timing: .stateChange)
			.hoverOrFocusVisible {
				$0.color(color)
			}
	}

	/**
	The fill and the primary text color of the current item of a set (`aria-current`), like the current page in the navigation. The fill replaces the fill of the focus, so the focus of the keyboard shows as a thin edge.
	*/
	func currentFill(_ fill: Color = .cardHover) -> Self {
		current {
			$0
				.background(fill)
				.color(.primaryText)
				.focusVisible {
					$0.shadow(.edge(.secondaryText))
				}
		}
	}

	/**
	A round card fill with the focus of the keyboard, for a link or a button whose look cannot show the focus in another way, like the site name, which already has the strongest text color. There are no focus rings (``SiteLayout``).
	*/
	func focusFill() -> Self {
		cornerRadius(.capsule)
			.focusVisible {
				$0.background(.card)
			}
	}

	/**
	Brightens the element a little while the pointer is over it, and shrinks and darkens it a little while it is pressed, like the App Store badge. Download badges and large buttons use it, so they feel the same next to each other. It does not grow on hover, as that moves the page.

	- Parameter filters: Filters that the element always has, like a drop shadow, as the brightness replaces the filter of the element.
	*/
	func pressEffect(keeping filters: Filter...) -> Self {
		(filters.isEmpty ? self : filter(filters))
			.transition(.scaleEffect, .filter, timing: .default(duration: .milliseconds(200)))
			.hoverOrFocusVisible {
				$0.filter(filters + [.brightness(1.08)])
			}
			.active {
				$0
					.filter(filters + [.brightness(0.95)])
					.scaleEffect(0.985)
			}
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
						.frame(width: .length(.max(.percent(100), .rootEm(2.75))), height: .length(.max(.percent(100), .rootEm(2.75))))
						.offset(x: .percent(-50), y: .percent(-50))
				}
		}
	}
}

// MARK: Links

extension Style {
	/**
	A link that looks like the text around it, without an underline, and has the primary text color under the pointer, like the links of the footer. The parent or the style sets its color, like a secondary color.
	*/
	func quietLink() -> Self {
		underline(false).hoverColor(.primaryText)
	}

	/**
	The look of a link in running text, like in prose or a notice. The underline is in the accent of the page, like the color of the icon on an app page, at half strength, so a list with many links stays calm. It gets the full accent while the pointer is over the link.
	*/
	func textLink() -> Self {
		color(.primaryText)
			.fontWeight(.medium)
			.underline(thickness: .pixels(2))
			.underlineColor(.lightDark(Color.accent(fallback: .primary(500), maximumLightness: 0.65).opacity(0.5), Color.darkModeAccent.opacity(0.55)))
			.underlineOffset(.pixels(4))
			.transition(.underlineColor, timing: .stateChange)
			.hoverOrFocusVisible {
				$0.underlineColor(.accentMark)
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
	A button that looks like a link in the text, for a short choice in a message, like the corrected name in “Did you mean …?”.
	*/
	func linkButton() -> Self {
		color(.link)
			.underline()
			.hoverColor(.primaryText)
	}

	/**
	A link to more of something, like all the posts below a post: semibold, in the link color, and underlined only under the pointer or with the focus of the keyboard.
	*/
	func moreLink() -> Self {
		fontWeight(.semibold)
			.color(.link)
			.underline(false)
			.hoverOrFocusVisible {
				$0.underline()
			}
	}

	/**
	A card that is a link, like the newest app on the now page: its content in a row, without the look of a link in prose, as the whole card is the link, and its icons, like a chevron, in a quiet color.
	*/
	func linkCard() -> Self {
		hstack(alignment: .center, spacing: .rootEm(1.25))
			.padding(.cardPadding)
			.cardSurface()
			.fontWeight(.regular)
			.color(.primaryText)
			.children(Icon.selector) {
				$0
					.flexShrink(0)
					.color(.secondaryText)
			}
	}

	/**
	The pink underline of the link to the current page or section (`aria-current`). It fades in, like when the scroll spy moves to the next section.
	*/
	func currentPageUnderline() -> Self {
		underline(color: .transparent, thickness: .pixels(3))
			.underlineOffset(.pixels(7))
			.transition(.underlineColor, timing: .easeInOut(duration: .milliseconds(500)))
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

// MARK: Pills, chips, and buttons

extension Style {
	/**
	A link in a navigation bar as a pill, like the chips of the site: the card fill under the pointer, and a stronger fill for the current page or section (`aria-current`).

	- Parameter currentFill: The fill of the current link, like a tint of the accent of an app page.
	*/
	func navigationPill(currentFill: Color = .cardHover) -> Self {
		padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
			.cornerRadius(.capsule)
			.fontWeight(.medium)
			.hoverFill(.card, color: .primaryText)
			.currentFill(currentFill)
	}

	/**
	A quiet button or link with only an icon, like the contact link and the menu button of the header: the icon in the secondary color, which only shows a round fill under the pointer or with the focus of the keyboard. On touch screens, it gets a larger target without moving the layout.

	- Parameter hoverFill: The fill under the pointer, like the stronger ``Color/cardHover`` for a button on a card, where the card fill would not show.
	- Parameter isOutset: Whether the fill goes beyond the icon without taking space, so a row with a title and the button stays as high as the title, and the icon lines up with the edge of the text.
	*/
	func iconButton(hoverFill: Color = .card, isOutset: Bool = false) -> Self {
		let padding = LengthPercentage.rootEm(0.375)
		let style = hstack(alignment: .center, isInline: true)
			// As high as the pills of the navigation next to the icon links of the header.
			.padding(padding)
			// A larger target for fingers, without moving the layout.
			.media(.coarsePointer) {
				$0
					.padding(padding * 2)
					.margin(.length(isOutset ? padding * -2 : padding * -1))
			}

		return (isOutset ? style.margin(.length(padding * -1)) : style)
			// Round, like the pills of the navigation next to the icon links of the header.
			.cornerRadius(.capsule)
			.color(.secondaryText)
			.hoverFill(hoverFill, color: .primaryText)
			// Like the current page in the navigation.
			.currentFill()
	}

	/**
	A small, quiet capsule, like a link in a row of links, such as the categories on the apps page and the sections of an app page, so the main button of a page stays the only strong color.

	- Parameter isInteractive: Whether it reacts to the pointer. A chip that is not a link, like a guess in Appdle, does not.
	- Parameter hasIcon: Whether it has an icon before its text, like the social links. The icon is in line with the text, and the chip has a little less padding at the sides, as the icon has some space of its own.
	*/
	func chip(isInteractive: Bool = true, hasIcon: Bool = false) -> Self {
		var style = padding(vertical: .rootEm(0.375), horizontal: .rootEm(hasIcon ? 0.75 : 0.875))
			.cornerRadius(.capsule)
			.textStyle(.caption, weight: .medium)
			.textWrap(.nowrap)
			.color(.bodyText)
			.background(.card)

		if hasIcon {
			style = style.hstack(alignment: .center, spacing: .rootEm(0.375), isInline: true)
		}

		guard isInteractive else {
			return style
		}

		// Without the underline of links in prose.
		return style
			.underline(false)
			.hoverFill(.cardHover, color: .primaryText)
	}

	/**
	A small, quiet capsule with a state, like the date the now page was updated. It is smaller and quieter than ``chip(isInteractive:hasIcon:)``, with secondary text and digits of the same width.
	*/
	func statusChip() -> Self {
		hstack(alignment: .center, isInline: true)
			.margin(.zero)
			.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
			.cornerRadius(.capsule)
			.textStyle(.caption, weight: .medium)
			.monospacedDigit()
			.color(.secondaryText)
			.background(.card)
	}

	/**
	A green dot before the content of the element, like a status light, for something that is current, like the date the now page was updated. It does not move.
	*/
	func statusLight() -> Self {
		before {
			$0
				.content("")
				// A box, also outside of a stack.
				.display(.inlineBlock)
				.frame(size: .rootEm(0.5))
				.margin(.trailing, .rootEm(0.5))
				.cornerRadius(.circle)
				.background(.emerald(700), dark: .emerald(400))
		}
	}

	/**
	The title or the icon of a copy button, which fades out while the button shows that it copied, so the checkmark (``copiedCheckmark(when:)``) can grow in, in the same cell of a grid.
	*/
	func copyLabel(hiddenWhen copied: some ElementStateSet) -> Self {
		stackedInGrid()
			.transition(.opacity, timing: .stateChange)
			.when(ancestorHas: copied) {
				$0.opacity(0)
			}
	}

	/**
	The checkmark of a copy button, which grows in over its title or icon (``copyLabel(hiddenWhen:)``), while the button shows that it copied.
	*/
	func copiedCheckmark(when copied: some ElementStateSet) -> Self {
		stackedInGrid()
			.hstack(alignment: .center, justification: .center)
			.opacity(0)
			.scaleEffect(0.5)
			.transition(.opacity, .scaleEffect, timing: .pop)
			.when(ancestorHas: copied) {
				$0
					.opacity(1)
					.scaleEffect(1)
			}
	}
}
