import Elementary
import SiteKit

/**
A small colored label, like “paid” or “macOS”.
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
				Style()
					.background(.gray(200).opacity(0.8), dark: .gray(200))
			case .new:
				Style()
					.background(.teal(100), dark: .teal(200))
			case .platform:
				Style()
					.background(.sky(100).opacity(0.9), dark: .sky(200))
			case .archived:
				Style()
					.background(.orange(100), dark: .orange(200))
			}
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
	static let fontSize = StyleVariable("--badge-font-size")

	enum Styles: StyleSet {
		case root

		var style: Style {
			// A block container, so the text box can be trimmed.
			Style()
				.display(.inlineBlock)
				.padding(.horizontal, .rem(0.375))
				.cornerRadius(.rem(0.5))
				.declaration(.fontSize, Badge.fontSize.value(default: .px(10)))
				.bold()
				.trimmedText()
				.color(.black.opacity(0.7), dark: .black)
		}
	}
}
