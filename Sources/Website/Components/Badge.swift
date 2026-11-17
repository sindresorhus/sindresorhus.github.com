import Elementary
import SiteKit

/**
A small colored label, like “Paid” or “macOS”.
*/
struct Badge: HTML {
	/**
	The color of the badge.
	*/
	enum Kind: String, StyleSet {
		case standard
		case new
		case platform
		case archived
		// The kinds of the entries of a changelog, like in `@Changelog`.
		case added
		case changed
		case fixed
		case removed

		var style: Style {
			switch self {
			case .standard:
				// Translucent, like in dark mode, so on a card it takes the color of the card, also the accent of the card under the pointer. In dark mode, a light gray is brighter than the colors of the other badges, so it is a weaker tint, and a colored badge next to it, like “New”, leads, like in light mode.
				Self.fill(.black.opacity(0.07), dark: .gray, darkOpacity: 0.13)
			case .new:
				Self.fill(.teal(100), dark: .teal)
			case .platform:
				Self.fill(.sky(100).opacity(0.9), dark: .sky)
			case .archived:
				Self.fill(.orange(100), dark: .orange)
			case .added:
				Self.fill(.emerald(100), dark: .emerald)
			case .changed:
				Self.fill(.indigo(100), dark: .indigo)
			case .fixed:
				Self.fill(.amber(100), dark: .amber)
			case .removed:
				Self.fill(.red(100), dark: .red)
			}
		}

		/**
		A light fill with dark text, and in dark mode a dark tint of the palette (the opacity of a light shade) with light text, so the badge does not outshine the card it is on. The text in dark mode is the lightest shade, so it is easy to read on the tint.
		*/
		private static func fill(_ light: Color, dark palette: Palette, darkOpacity: Double = 0.2) -> Style {
			Style()
				.background(light, dark: palette.color(200).opacity(darkOpacity))
				.color(.black.opacity(0.7), dark: palette.color(100))
		}
	}

	let title: String
	let kind: Kind

	init(_ title: String, kind: Kind = .standard) {
		self.title = title
		self.kind = kind
	}

	var body: some HTML {
		span {
			title
		}
		.style(Styles.root, kind)
	}

	/**
	The font size of the badges inside, which a parent can set, like for a larger badge.
	*/
	static let fontSize = StyleVariable<LengthPercentage>("badge-font-size")

	enum Styles: String, StyleSet {
		case root

		var style: Style {
			// A block container, so the text box can be trimmed.
			Style()
				.display(.inlineBlock)
				.padding(.horizontal, .rootEm(0.375))
				.cornerRadius(.capsule)
				.font(size: Badge.fontSize.value(default: .rootEm(0.6875)))
				.bold()
				.trimmedText()
		}
	}
}
