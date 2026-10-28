import Elementary
import SiteKit

/**
A button that copies a text, like an email address or a link, and shows a checkmark instead of its title for a moment. It is hidden until its script finds that the browser can copy.

The text is the `text` attribute of the element, which the script reads on click, so another script can change it, like Appdle does with the result.
*/
struct CopyButton: ScriptedElement {
	static let script = ElementScript()

	enum Look {
		/**
		A small secondary button, which shows a checkmark instead of its title for a moment after copying.
		*/
		case standard

		/**
		A small square button with a copy icon, on the dark bar of a code block, which shows a checkmark instead of the icon for a moment after copying. The title is only its name for screen readers.
		*/
		case icon

		/**
		The raised gray button of the 1999 page.
		*/
		case retro
	}

	let title: String
	let text: String
	var look = Look.standard

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.hidden, .custom(name: "text", value: text)]
	}

	var content: some HTML {
		switch look {
		case .standard:
			// The title and the checkmark share one grid cell, so the button keeps its width when it shows the checkmark.
			button(.type(.button)) {
				span {
					span {
						title
					}
					.style(Styles.label)

					// A thicker line than other icons, so the checkmark is easy to see in the small button.
					span {
						Icon.check.size(.rootEm(1.125), strokeWidth: 2.75)
					}
					.style(Styles.checkmark)
				}
				.style(Styles.labels)
			}
			.buttonStyle(.secondary, size: .small)
		case .icon:
			// The icon and the checkmark share one grid cell.
			button(.type(.button)) {
				span {
					Icon.copy.size(.rootEm(0.875))
				}
				.style(Styles.icon)

				span {
					Icon.check.size(.rootEm(0.875), strokeWidth: 2.75)
				}
				.style(Styles.iconCheckmark)
			}
			.accessibilityLabel(title)
			.style(Styles.iconButton)
		case .retro:
			button(.type(.button)) {
				title
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
	}

	enum States: String, ElementStateSet {
		case copied
	}

	enum Styles: ElementStyleSet {
		case root
		case labels
		case label
		case checkmark
		case iconButton
		case icon
		case iconCheckmark

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the button is laid out as if it were not there.
				Style().display(.contents)
			case .labels:
				Style().display(.grid)
			case .label:
				// The title fades out, and the checkmark grows in, centered in the space of the title.
				Style().copyLabel(hiddenWhen: States.copied)
			case .checkmark:
				Style().copiedCheckmark(when: States.copied)
			case .iconButton:
				// After copying, the icon fades out, and a green checkmark grows in.
				Style()
					.display(.grid)
					.frame(size: .rootEm(1.75))
					.cornerRadius(CodeBlock.Styles.barRadius)
					.color(.gray(300))
					.background(.white.opacity(0.08))
					.shadow(.edge(.white.opacity(0.1)))
					.hoverFill(.white.opacity(0.16), color: .white)
					.minimumTapArea()
			case .icon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.copyLabel(hiddenWhen: States.copied)
			case .iconCheckmark:
				// Lighter than the checkmark of the standard look, for the dark bar.
				Style()
					.color(.emerald(400))
					.copiedCheckmark(when: States.copied)
			}
		}
	}
}
