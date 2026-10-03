import SiteKit

extension ProseStyles {
	/**
	Keys, like ⌘ and K. They are `!important`, so they win over the code styles of the content around them.
	*/
	static let keyboardKeys = Style()
		.nested("kbd") {
			$0
				.important {
					$0
						.declaration(.fontFamily, .inherit)
						.font(size: .em(0.8))
						.background("#f0f2f5", dark: "#252d3d")
						.color("#2d3748", dark: "#c9d1e0")
						.border("#c4cad4")
						.declaration(.borderBottomWidth, .px(3))
						.cornerRadius(.px(5))
						.padding(vertical: .em(0.1), horizontal: .em(0.45))
						.margin(.horizontal, .em(0.15))
				}
				.dark {
					$0.important {
						$0
							.borderColor("#3d4a5c")
							.declaration(.borderBottomColor, "#111827")
					}
				}
		}

	/**
	The `+` between the keys of a shortcut.
	*/
	static let keySeparatorStyle = Style()
		.font(size: .em(0.6))
		.fontWeight(.semibold)
		.color(.gray(400))
		.textSelection(.disabled)
		.declaration(.verticalAlign, "middle")
}
