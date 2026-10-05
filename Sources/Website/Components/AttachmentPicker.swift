import Elementary
import SiteKit

/**
The file picker of the feedback form. Its script lists the picked files with the attachment template, so files can be added in several picks and removed one by one.
*/
struct AttachmentPicker: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		// The label has the input, so it opens the file picker without an ID.
		label {
			Icon.paperclip.size(.pixels(14))
			"Attach Files"
			input(.type(.file), .name("attachments"), .multiple, .part(Parts.input))
				.style(VisuallyHidden.Styles.root)
		}
		.style(Styles.picker)

		div(.part(Parts.fileList)) {}
			.style(Styles.fileList)

		template(.part(Parts.template)) {
			span {
				// The script keeps the thumbnail for images and the icon for other files.
				img(.alt(""), .width(28), .height(28))
					.style(Styles.thumbnail)

				Icon.file.size(.pixels(16))

				span(.part(Parts.name)) {}
					.style(Styles.name)

				span(.part(Parts.size)) {}
					.style(Styles.size)

				button(.type(.button)) {
					Icon.close.size(.pixels(12))
				}
				.style(Styles.removeButton)
			}
			.style(Styles.attachment)
		}
	}

	enum Parts: String, ElementPartSet {
		case input
		case fileList
		case template
		case name
		case size
	}

	enum Styles: ElementStyleSet {
		case root
		case picker
		case fileList
		case attachment
		case thumbnail
		case name
		case size
		case removeButton

		var style: Style {
			switch self {
			case .root:
				Style()
					.display(.block)
					.margin(.bottom, .rootEm(2))
			case .picker:
				// A chip, like a small button, as the label opens the file picker.
				Style()
					.chip()
					.hstack(alignment: .center, spacing: .rootEm(0.375), isInline: true)
					.cursor(.pointer)
			case .fileList:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.margin(.top, .rootEm(0.75))
			// A row like the cards of the site, with the corner radius of the fields.
			case .attachment:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.625))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.cornerRadius(.rootEm(0.625))
					.textStyle(.caption)
					.color(.secondaryText)
					.background(.card)
					.nested(Icon.selector) {
						$0.flexShrink(0)
					}
			case .thumbnail:
				Style()
					.flexShrink(0)
					.objectFit(.cover)
					.cornerRadius(.pixels(6))
			case .name:
				// It is the only part that shrinks, as `overflow: hidden` lets it shrink below its content.
				Style()
					.overflow(.hidden)
					.declaration(.textOverflow, "ellipsis")
					.textWrap(.nowrap)
					.fontWeight(.medium)
					.color(.primaryText)
			case .size:
				Style()
					.flexShrink(0)
					.monospacedDigit()
			case .removeButton:
				// A round button at the end of the row. The auto margin moves it there.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(1.75), height: .rootEm(1.75))
					.margin(.leading, .auto)
					.flexShrink(0)
					.cornerRadius(.capsule)
					.color(.secondaryText)
					.transition(.color, .backgroundColor, animation: .stateChange)
					.hover {
						$0
							.color(.primaryText)
							.background(.cardHover)
					}
			}
		}
	}
}
