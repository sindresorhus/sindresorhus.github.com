import SiteKit

extension ProseStyles {
	/**
	GitHub alerts, like `> [!NOTE]`.
	*/
	static let alertStyle = Style()
		.margin(vertical: .rem(1), horizontal: 0)
		.padding(vertical: .rem(0.5), horizontal: .rem(1))
		.border(.leading, width: .rem(0.25))
		.cornerRadius(.rem(0.5))
		.children("*") {
			$0.margin(0)
		}
		.nested("& > * + *") {
			$0.margin(.top, .rem(0.25))
		}
		.nested("a") {
			$0.declaration(.textDecorationColor, .important(.variable("--alert-color")))
		}

	static let alertTitleStyle = Style()
		.hstack(alignment: .center, spacing: .rem(0.5))
		.fontWeight(.semibold)

	static let alertIconStyle = Style()
		.frame(width: .rem(1), height: .rem(1))
		.declaration(.fill, .currentColor)

	/**
	The colors of an alert kind.
	*/
	static func alertStyle(_ kind: MarkdownAlert) -> Style {
		let (color, background, titleColor, darkBackground): (Color, Color, Color, Color) = switch kind {
		case .note:
			("#60a5fa", "#f8faff", "#38bdf8", "#0f172a")
		case .tip:
			("#6ee7b7", "#f8fdf9", "#34d399", "#0a1a17")
		case .important:
			("#c084fc", "#fdf8ff", "#a78bfa", "#1a0a2e")
		case .warning:
			("#fbbf24", "#fffdf5", "#f59e0b", "#1a1408")
		case .caution:
			("#fb7185", "#fef8f8", "#f43f5e", "#1f0a0a")
		}

		return Style()
			.declaration("--alert-color", CSSValue(color))
			.borderColor(color.opacity(0.5))
			.background(background, dark: darkBackground)
			.nested(ProseStyles.alertTitle.selector) {
				$0.color(titleColor)
			}
	}
}

extension MarkdownAlert {
	var style: ProseStyles {
		switch self {
		case .note:
			.alertNote
		case .tip:
			.alertTip
		case .important:
			.alertImportant
		case .warning:
			.alertWarning
		case .caution:
			.alertCaution
		}
	}
}
