import SiteKit

extension ProseStyles {
	/**
	The color of the edge of a key, and of the line at its bottom.
	*/
	private static let keyEdgeColor = Color.lightDark(.gray(300), .white.opacity(0.15))

	/**
	Keys, like ⌘ and K, with a line at the bottom, like a key cap. The colors are see-through in dark mode, so the keys look the same on the page and on cards.
	*/
	static let keyboardKeys = Style()
		.nested("kbd") {
			$0
				.declaration(.fontFamily, .inherit)
				.font(size: .em(0.8))
				.background(.gray(50), dark: .white.opacity(0.06))
				.color(.bodyText)
				.border(keyEdgeColor)
				.shadow(Shadow(y: .pixels(-1), color: keyEdgeColor, isInset: true))
				.cornerRadius(.pixels(5))
				.padding(vertical: .em(0.1), horizontal: .em(0.45))
				.margin(.horizontal, .em(0.15))
		}

	/**
	The `+` between the keys of a shortcut.
	*/
	static let keySeparatorStyle = Style()
		.font(size: .em(0.6))
		.fontWeight(.semibold)
		.color(.secondaryText)
		.textSelection(.disabled)
		.verticalAlign(.middle)
}
