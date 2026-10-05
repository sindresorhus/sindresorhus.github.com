import SiteKit

extension ProseStyles {
	/**
	The color of the links in an alert, which each alert kind sets.
	*/
	static let alertLinkColor = StyleVariable<Color>("--alert-color")

	/**
	GitHub alerts, like `> [!NOTE]`.
	*/
	static let alertStyle = Style()
		.margin(vertical: blockSpacing, horizontal: 0)
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1.125))
		.border(.leading, width: .rootEm(0.25))
		.cornerRadius(.rootEm(0.5))
		.children("*") {
			$0.margin(0)
		}
		.flowSpacing(.rootEm(0.25))
		// Important, as the hover style of links in the prose is more specific, and would replace the color of the alert.
		.nested("a") {
			$0.important {
				$0.underlineColor(alertLinkColor.value)
			}
		}

	static let alertTitleStyle = Style()
		.hstack(alignment: .center, spacing: .rootEm(0.5))
		.fontWeight(.semibold)

	static let alertIconStyle = Style()
		.frame(width: .rootEm(1), height: .rootEm(1))
		.declaration(.fill, .currentColor)

	/**
	The colors of an alert kind.
	*/
	static func alertStyle(_ kind: MarkdownAlert) -> Style {
		let palette: Palette = switch kind {
		case .note:
			.primary
		case .tip:
			.emerald
		case .important:
			.purple
		case .warning:
			.amber
		case .caution:
			.rose
		}

		return Style()
			.setting(alertLinkColor, to: palette.color(400))
			.borderColor(palette.color(400).opacity(0.5))
			.background(palette.color(50).opacity(0.5), dark: palette.color(950).opacity(0.4))
			.nested(ProseStyles.alertTitle.selector) {
				$0.color(palette.color(700), dark: palette.color(400))
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
