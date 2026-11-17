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
				.cornerRadius(.smallRadius)
				.padding(vertical: .em(0.1), horizontal: .em(0.45))
				// A key with a name of two words, like “Caps Lock”, goes to the next line as a whole, so the key cap is not cut in two.
				.textWrap(.nowrap)
		}

	/**
	A shortcut of more than one key, which stays on one line, so “Shift +” and “Command” are not on two lines. It is one inline block, which goes to the next line as a whole, and only a shortcut that is wider than the column, like on a phone with large text, breaks between its keys, after a `+`. The keys are inline blocks, not flex items, so a copied shortcut stays “Command+C” on one line.
	*/
	static let keyboardShortcutStyle = Style()
		.inherits(.fontFamily)
		.display(.inlineBlock)
		.frame(maxWidth: .percent(100))
		// The normal line breaking, not the `pretty` wrapping of the paragraph, which can break before a `+`, so a line starts with “+ ⌘ Command”.
		.textWrapStyle(.auto)
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
	A shortcut and the punctuation right before and after it, like a parenthesis and a comma. A line can break before and after an inline block, even after an opening parenthesis and before a comma, so this element is the inline block instead of the shortcut, and keeps the punctuation next to the first and the last key. A shortcut that wraps between its keys is as wide as the column, so punctuation after its inline block would be at the edge of the column, far from the last key.
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
	A modifier key, like Command, with its glyph before its name, like “⌘ Command”, as the menus of macOS show only the glyphs, and the keys of a Mac keyboard show both. The glyph is only in the style, so a copied shortcut stays “Command+C”, and screen readers only read the name.

	In a table on phones, the key only shows its glyph, like “⌘”, so the column of the actions has more space. A table of shortcuts is a reference, where the glyph is enough, like in the menus of macOS, and the text keeps the names, so a new user still learns them. The name stays in the HTML, but its font size is zero.
	*/
	static func modifierKeyStyle(_ modifier: KeyboardKey.Modifier) -> Style {
		Style()
			.before {
				$0
					.content(String(modifier.glyph), alternativeText: "")
					.margin(.trailing, .em(0.3))
			}
			// The padding and the glyph are in `rem`, as `em` is zero here, with the size and the padding of the other keys in the 15 px text of a table (0.8 em), so all the keys of a shortcut have one height. The space at the sides is on the `+` (``keySeparatorStyle``), like for the other keys. The `table` in the selector makes it as specific as the style of the keys (``keyboardKeys``), so it wins over that style.
			.inside("table td, table th") {
				$0.below(.smallTablet) {
					// An inline block, like the keys of a shortcut, as a key alone in a cell, like `++Option++`, is inline, and its line box would be 0 px high.
					$0
						.display(.inlineBlock)
						.lineHeight(1.2)
						.font(size: .zero)
						.padding(vertical: .rootEm(0.075), horizontal: .rootEm(0.3375))
						.before {
							$0
								.font(size: .rootEm(0.75))
								.margin(.zero)
						}
				}
			}
	}

	/**
	The `+` between the keys of a shortcut. It can be selected, so a copied shortcut is “Command+C”, not “CommandC”. Screen readers skip it, as they read each key.

	The space between the keys is on the `+`, not on the keys, so a key has no space at its outer sides, and a comma or a period after a key touches it, like it touches a word.
	*/
	static let keySeparatorStyle = Style()
		.font(size: .em(0.6))
		.margin(.horizontal, .em(0.2))
		.fontWeight(.semibold)
		.color(.secondaryText)
		// In the middle of the labels of the keys, which are capitals and glyphs, not in the middle of the lowercase letters of the text (`middle`).
		.verticalAlign(.em(0.15))
		// A shortcut that is wider than the column can wrap after a `+`, also when it is kept on one line with the punctuation after it, but not in a table.
		.textWrap(.wrap)
		.inside("td, th") {
			$0.textWrap(.nowrap)
		}
}

extension KeyboardKey.Modifier {
	/**
	The style that shows the glyph of the modifier before its name (``ProseStyles/modifierKeyStyle(_:)``).
	*/
	var style: ProseStyles {
		switch self {
		case .control:
			.controlKey
		case .option:
			.optionKey
		case .shift:
			.shiftKey
		case .command:
			.commandKey
		}
	}
}
