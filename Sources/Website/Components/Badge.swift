import Elementary
import SiteKit

/**
A small colored label, like “Paid” or “macOS”.
*/
struct Badge: HTML {
	/**
	The color of the badge.
	*/
	enum Kind: StyleSet {
		case standard
		case new
		case platform
		case archived

		var style: Style {
			switch self {
			case .standard:
				Self.fill(.gray(200).opacity(0.8), dark: .gray)
			case .new:
				Self.fill(.teal(100), dark: .teal)
			case .platform:
				Self.fill(.sky(100).opacity(0.9), dark: .sky)
			case .archived:
				Self.fill(.orange(100), dark: .orange)
			}
		}

		/**
		A light fill with dark text, and in dark mode a dark tint of the palette with light text, so the badge does not outshine the card it is on.
		*/
		private static func fill(_ light: Color, dark palette: Palette) -> Style {
			Style()
				.background(light, dark: palette.color(200).opacity(0.15))
				.color(.black.opacity(0.7), dark: palette.color(200))
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
	static let fontSize = StyleVariable<Length>("--badge-font-size")

	enum Styles: StyleSet {
		case root

		var style: Style {
			// A block container, so the text box can be trimmed.
			Style()
				.display(.inlineBlock)
				.padding(.horizontal, .rootEm(0.375))
				.cornerRadius(.rootEm(0.5))
				.font(size: Badge.fontSize.value(default: .rootEm(0.6875)))
				.bold()
				.trimmedText()
		}
	}
}
