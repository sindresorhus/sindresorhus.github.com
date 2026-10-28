import Elementary
import Foundation
import SiteKit

/**
The file picker of the feedback form. Its script lists the picked files with the attachment template, so files can be added in several picks and removed one by one. A file that is too large to send is marked, and the form cannot be sent until it is removed.
*/
struct AttachmentPicker: ScriptedElement {
	static let script = ElementScript()

	/**
	The largest file that Formcarry, which gets the form, accepts, in bytes: 10 MB, in the decimal units of Finder, like the sizes that the picker shows. Formcarry also accepts at most 50 MB in one message, which the picker does not check.
	*/
	static let maximumFileSize = 10_000_000

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.custom(name: "maximum-file-size", value: String(Self.maximumFileSize))]
	}

	var content: some HTML {
		// The label has the input, so it opens the file picker without an ID.
		label {
			Icon.paperclip.size(.rootEm(0.875))
			"Attach Files"
			input(
				.type(.file),
				.name("attachments"),
				.multiple,
				.part(Parts.input)
			)
				.style(VisuallyHidden.Styles.root)
		}
		.style(Styles.picker)

		// The number and the total size of the files, which the script shows when there are two or more, so the visitor sees what is attached without scrolling through the chips. Formcarry accepts at most 50 MB in one message, which the total lets the visitor see before the send.
		span(.part(Parts.summary), .role("status")) {}
			.style(Styles.summary)

		div(.part(Parts.fileList)) {}
			.style(Styles.fileList)

		template(.part(Parts.template)) {
			span {
				// The script keeps the thumbnail for images and the icon for other files.
				img(
					.alt(""),
					.width(28),
					.height(28),
					.part(Parts.thumbnail)
				)
					.style(Styles.thumbnail)

				// The icon is raw SVG, so the span has the part, and it is laid out as if it were not there.
				span(.part(Parts.fileIcon)) {
					Icon.file.size(.rootEm(1))
				}
				.style {
					$0.display(.contents)
				}

				// The name in two parts, so a long name is cut in the middle, like in Finder, and the end and the extension stay visible, where macOS puts the details, like the time of a screen recording. The remove button has the full name in its label.
				span {
					// The start shrinks with an ellipsis, as `overflow: hidden` lets it shrink below its content.
					span(.part(Parts.nameStart)) {}
						.style {
							$0
								.overflow(.hidden)
								.textOverflow(.ellipsis)
								.preservesSpaces()
						}

					span(.part(Parts.nameEnd)) {}
						.style {
							$0
								.flexShrink(0)
								.preservesSpaces()
						}
				}
				.style(Styles.name)

				span(.part(Parts.size)) {}
					.style(Styles.size)

				button(.type(.button), .part(Parts.removeButton)) {
					Icon.close.size(.rootEm(0.75))
				}
				.style(Styles.removeButton)

				// Shown when the file is too large, on a line of its own below the file. The script also uses it for the message of the browser when the form is sent.
				span(.part(Parts.tooLargeNotice)) {
					"Larger than \(Self.maximumFileSize.formatted(.byteCount(style: .file))), so it cannot be sent. Compress it, or share a link to it in the message."
				}
				.style(Styles.tooLargeNotice)
			}
			.style(Styles.attachment)
		}
	}

	enum Parts: String, ElementPartSet {
		case input
		case summary
		case fileList
		case template
		case thumbnail
		case fileIcon
		case nameStart
		case nameEnd
		case size
		case removeButton
		case tooLargeNotice
	}

	enum States: String, ElementStateSet {
		/**
		The file of the chip is larger than ``AttachmentPicker/maximumFileSize``.
		*/
		case tooLarge = "too-large"
	}

	enum Styles: ElementStyleSet {
		case root
		case picker
		case summary
		case fileList
		case attachment
		case thumbnail
		case name
		case size
		case removeButton
		case tooLargeNotice

		var style: Style {
			switch self {
			case .root:
				Style()
					.display(.block)
					.margin(.bottom, .rootEm(2))
			case .picker:
				// A chip, like a small button, as the label opens the file picker. The hidden input inside gets the focus of the keyboard, so the label shows the fill of the chip while the input has it.
				Style()
					.chip(hasIcon: true)
					.cursor(.pointer)
					.nested("&:has(:focus-visible)") {
						$0
							.background(.cardHover)
							.color(.primaryText)
					}
			case .summary:
				Style()
					.margin(.leading, .rootEm(0.75))
					.secondaryText()
					.monospacedDigit()
			case .fileList:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.margin(.top, .rootEm(0.75))
			// A row like the cards of the site, with the corner radius of the fields.
			case .attachment:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.625))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.fieldBox()
					.secondaryText()
					.nested(Icon.selector) {
						$0.flexShrink(0)
					}
					// The edge has the red of the errors of the fields (``FormField``), and the notice wraps to a line of its own.
					.when(States.tooLarge) {
						$0
							.shadow(.edge(.red(500)))
							.flexWrap()
					}
			case .thumbnail:
				Style()
					.flexShrink(0)
					.objectFit(.cover)
					.cornerRadius(.pixels(6))
			case .name:
				// It is the only part that shrinks, as its minimum width lets it shrink below its content.
				Style()
					.hstack()
					.frame(minWidth: .zero)
					.fontWeight(.medium)
					.color(.primaryText)
					// In a row that wraps, a long name would wrap the size and the button to the next line, so it starts from no width and takes the free space.
					.when(ancestorHas: States.tooLarge) {
						$0.flex(1)
					}
			case .size:
				Style()
					.flexShrink(0)
					.monospacedDigit()
			case .removeButton:
				// A round button at the end of the row. The auto margin moves it there.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(size: .rootEm(1.75))
					.margin(.leading, .auto)
					.flexShrink(0)
					.cornerRadius(.capsule)
					.minimumTapArea()
					.color(.secondaryText)
					.hoverFill(.cardHover, color: .primaryText)
			case .tooLargeNotice:
				Style()
					.hidden()
					.frame(width: .percent(100))
					.textStyle(.caption)
					.color(.red(600), dark: .red(400))
					.when(ancestorHas: States.tooLarge) {
						$0.display(.block)
					}
			}
		}
	}
}
