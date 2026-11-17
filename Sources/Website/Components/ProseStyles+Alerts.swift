import SiteKit

extension ProseStyles {
	/**
	The color of the underline of the links in an alert, which each alert kind sets.
	*/
	static let alertLinkColor = StyleVariable<Color>("alert-color")

	/**
	The fill of an alert, which each alert kind sets. The question of an open collapsible section in it, like in a box of tips, paints it under its own fill, as it is opaque (``collapsibleSummaryStyle``).
	*/
	static let alertFill = StyleVariable<Color>("alert-fill")

	/**
	The width of the colored line at the leading edge of an alert.
	*/
	private static let alertBorderWidth = Length.rootEm(0.25)

	/**
	The padding at the sides of an alert that has the inset of a box, so its icon and text start where the paragraphs start: the inset, less the colored line at its leading edge.
	*/
	private static let alertInsetPadding = Style()
		.padding(.leading, .boxInset - LengthPercentage(alertBorderWidth))
		.padding(.trailing, .boxInset)

	/**
	GitHub alerts, like `> [!NOTE]`. Where there is space at the sides of the text (``Breakpoint/proseWithGutters``), an alert is a box that hangs into it, so its icon and text start where the paragraphs start. Below tablets, an alert directly in prose is as wide as the screen, for the same reason.
	*/
	static let alertStyle = Style()
		.proseBlockMargin()
		// An alert after the text or the steps is a note apart from it, like the tip about other apps at the end of the features of an app, so it gets twice the space of a block above it. When text also follows it, it has the same space below it, so it does not read as the start of that text. The steps are in `:where()`, so this rule stays less specific than the one of ``Style/proseBlockMargin()`` for an alert below a bold label, which is a paragraph too.
		.directlyAfter("p, ul, ol, :where(\(StepListStyles.root.selector))") {
			$0
				.margin(.top, .em(3.5))
				.nested("&:has(+ :is(p, ul, ol))") {
					$0.margin(.bottom, .em(3.5))
				}
		}
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1.125))
		.border(.leading, width: alertBorderWidth)
		.widerThanProse()
		.from(.proseWithGutters) {
			$0.combined(with: alertInsetPadding)
		}
		// Directly in prose below tablets, as wide as the screen, like the Quick Answer of a guide, with the colored line at the edge of the screen, so its text starts where the paragraphs start. An alert in another box, like an answer of an FAQ, keeps the space at its sides.
		.directlyInside(ProseStyles.root.selector) {
			$0
				.screenWideBelowTablet()
				.below(.tablet) {
					$0.combined(with: alertInsetPadding)
				}
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
				// The first item has no space above it, so the list starts as far below the title as a paragraph, as the space of the item would collapse through the list and win over the space of the box.
				.children("li:first-child") {
					$0.margin(.top, .zero)
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
			// A faint fill of the color of the edge, so the box shows a little on the page and on the gray of an FAQ answer, but stays quiet. The same recipe in both modes, so the kinds have one strength, in the hue of their edge and title.
			.setting(alertFill, to: .lightDark(palette.color(400).opacity(0.06), palette.color(400).opacity(0.1)))
			.background(alertFill.value)
			// The bullets of a list, like in a box of tips, are in the color of the edge, not in the gray of the bullets on the page.
			.nested("li::marker") {
				$0.color(alertLinkColor.value)
			}
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
