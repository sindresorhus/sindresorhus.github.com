import SiteKit

extension ProseStyles {
	/**
	The color of the underline of the links in an alert, which each alert kind sets.
	*/
	static let alertLinkColor = StyleVariable<Color>("alert-color")

	/**
	The width of the colored line at the leading edge of an alert.
	*/
	private static let alertBorderWidth = Length.rootEm(0.25)

	/**
	GitHub alerts, like `> [!NOTE]`. Where there is space at the sides of the text (``Breakpoint/proseWithGutters``), an alert is a box that hangs into it, so its icon and text start where the paragraphs start.
	*/
	static let alertStyle = Style()
		.proseBlockMargin()
		// An alert after the text is a note apart from it, like the tip about other apps at the end of the features of an app, so it gets twice the space of a block above it.
		.directlyAfter("p, ul, ol") {
			$0.margin(.top, .em(3.5))
		}
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1.125))
		.border(.leading, width: alertBorderWidth)
		.widerThanProse()
		.from(.proseWithGutters) {
			$0
				.padding(.leading, .boxInset - LengthPercentage(alertBorderWidth))
				.padding(.trailing, .boxInset)
		}
		.cornerRadius(.boxRadius)
		.children("*") {
			$0.margin(.zero)
		}
		.flowSpacing(.rootEm(0.25))
		// The text of a list starts where the title starts, after the icon (1rem) and the gap (0.5rem), at all widths.
		.children("ul, ol") {
			$0
				.padding(.leading, .rootEm(1))
				.children("li") {
					$0.padding(.leading, .rootEm(0.5))
				}
				// A list at the end, like the tips of a guide, has no space below its last item, so the box has the same space below a list as below a paragraph.
				.lastChild {
					$0.children("li:last-child") {
						$0.margin(.bottom, .zero)
					}
				}
		}
		// Important, as the hover style of links in the prose is more specific, and would replace the color of the alert. So the underline is thicker under the pointer and with the focus of the keyboard instead, like the links of blog posts.
		.nested("a") {
			$0
				.declaration(raw: .textDecorationColor, alertLinkColor.value, isImportant: true)
				.hoverOrFocusVisible {
					$0.underlineThickness(.pixels(4))
				}
		}

	static let alertTitleStyle = Style()
		.hstack(alignment: .center, spacing: .rootEm(0.5))
		.fontWeight(.semibold)

	static let alertIconStyle = Style()
		.frame(size: .rootEm(1))
		.declaration(raw: .fill, .currentColor)

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
