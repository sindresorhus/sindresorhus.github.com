import SiteKit

extension ProseStyles {
	/**
	The color of the edge of a key, and of the line at its bottom.
	*/
	private static let keyEdgeColor = Color.lightDark(.gray(300), .white.opacity(0.15))

	/**
	Keys, like ⌘ and K, with a line at the bottom, like a key cap. The colors are see-through in dark mode, so the keys look the same on the page and on cards. A `<kbd>` with keys in it is a shortcut (``keyboardShortcutStyle``), not a key.
	*/
	static let keyboardKeys = Style()
		.nested("kbd:not(:has(kbd))") {
			$0
				.inherits(.fontFamily)
				.font(size: .em(0.8))
				.background(.gray(50), dark: .white.opacity(0.06))
				.color(.bodyText)
				.border(keyEdgeColor)
				.shadow(BoxShadow(y: .pixels(-1), color: keyEdgeColor, isInset: true))
				.cornerRadius(.pixels(5))
				.padding(vertical: .em(0.1), horizontal: .em(0.45))
				.margin(.horizontal, .em(0.15))
		}

	/**
	A shortcut of more than one key, which stays on one line, so “Shift +” and “Command” are not on two lines. It is one inline block, which goes to the next line as a whole, and only a shortcut that is wider than the column, like on a phone with large text, breaks between its keys, after a `+`. The keys are inline blocks, not flex items, so a copied shortcut stays “Command+C” on one line.
	*/
	static let keyboardShortcutStyle = Style()
		.inherits(.fontFamily)
		.display(.inlineBlock)
		.frame(maxWidth: .percent(100))
		// A key with its padding and border is not higher than the line, so a shortcut does not make its line taller, also in a table, which has tighter lines.
		.children("kbd") {
			$0
				.display(.inlineBlock)
				.lineHeight(1.2)
		}
		// In a table, a shortcut stays on one line, and makes its column wider, as the table scrolls instead of the page. Also when it is in another element, like with the punctuation after it.
		.inside("td, th") {
			$0
				.display(.inline)
				.textWrap(.nowrap)
		}

	/**
	A shortcut and the punctuation right after it, like a comma. A line can break after an inline block, even before a comma, so this element is the inline block instead of the shortcut, and keeps the punctuation next to the last key. A shortcut that wraps between its keys is as wide as the column, so punctuation after its inline block would be at the edge of the column, far from the last key.
	*/
	static let keyboardShortcutWithPunctuationStyle = Style()
		.display(.inlineBlock)
		.frame(maxWidth: .percent(100))
		.textWrap(.nowrap)
		// It keeps the text on one line, except after a `+` (``keySeparatorStyle``). Chrome lets the style of the shortcut decide whether a line can break after its last key, not the style of this element, so the shortcut must not wrap.
		.children(ProseStyles.keyboardShortcut.selector) {
			$0.display(.inline)
		}

	/**
	The `+` between the keys of a shortcut. It can be selected, so a copied shortcut is “Command+C”, not “CommandC”. Screen readers skip it, as they read each key.
	*/
	static let keySeparatorStyle = Style()
		.font(size: .em(0.6))
		.fontWeight(.semibold)
		.color(.secondaryText)
		.verticalAlign(.middle)
		// A shortcut that is wider than the column can wrap after a `+`, also when it is kept on one line with the punctuation after it, but not in a table.
		.textWrap(.wrap)
		.inside("td, th") {
			$0.textWrap(.nowrap)
		}
}
