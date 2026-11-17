import Elementary
import Foundation
import SiteKit

/**
The file picker of the feedback form. Its script lists the picked files with the attachment template, so files can be added in several picks and removed one by one. A file that is too large to send is marked, and the form cannot be sent until it is removed. A crash report shows its app and version, and a note when it is of another app than the selected app, whose names the page script gives in the `app-names` attribute.
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

		// The limit before the pick, so a visitor does not first pick a large screen recording. The summary of two or more files takes its place.
		span {
			"Up to \(Self.maximumFileSize.formatted(.siteFileSize)) each"
		}
		.style(Styles.limit)

		// The number and the total size of the files, which the script shows when there are two or more, so the visitor sees what is attached without scrolling through the chips. Formcarry accepts at most 50 MB in one message, which the total lets the visitor see before the send.
		span(.part(Parts.summary), .role(.status)) {}
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

				// The icon is raw SVG, so the span has the part. It is as large as a thumbnail, so the names of all files start at the same place.
				span(.part(Parts.fileIcon)) {
					Icon.file.size(.rootEm(1))
				}
				.style {
					$0
						.hstack(alignment: .center, justification: .center)
						.flexShrink(0)
						.frame(size: .rootEm(1.75))
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
					"Larger than \(Self.maximumFileSize.formatted(.siteFileSize)), so it cannot be sent. Compress it, or share a link to it in the message."
				}
				.style(Styles.tooLargeNotice)

				// Shown for a crash report (an `.ips` file), on a line of its own below the file: the app, its version, and the OS, which the script reads from the file, like “Dato 5.8.1 · macOS 27.2”, so the visitor sees that it is the right report.
				span {
					span {
						"Crash Report"
					}
					.style(Styles.crashReportLabel)

					span(.part(Parts.crashReportDetails)) {}
				}
				.style(Styles.crashReportNotice)

				// Shown below the details when the crash report is of another app than the selected app, like Safari for Dato, as the folder of the reports has the reports of all apps. The script writes the names, which the page script gives it in the `app-names` attribute.
				span(.part(Parts.otherAppNotice), .hidden) {}
					.style(Styles.otherAppNotice)
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
		case crashReportDetails
		case otherAppNotice
	}

	enum States: String, ElementStateSet {
		/**
		The file of the chip is larger than ``AttachmentPicker/maximumFileSize``.
		*/
		case tooLarge = "too-large"

		/**
		The file of the chip is a crash report that the script could read. A crash report that is too large only has ``tooLarge``.
		*/
		case crashReport = "crash-report"
	}

	enum Styles: String, ElementStyleSet {
		case root
		case picker
		case limit
		case summary
		case fileList
		case attachment
		case thumbnail
		case name
		case size
		case removeButton
		case tooLargeNotice
		case crashReportNotice
		case crashReportLabel
		case otherAppNotice

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
					.descendantFocusVisible {
						$0
							.background(.cardHover)
							.color(.primaryText)
					}
			case .limit:
				Style()
					.margin(.leading, .rootEm(0.75))
					.secondaryText()
					.nested("&:has(+ :not(:empty))") {
						$0.hidden()
					}
			case .summary:
				Style()
					.margin(.leading, .rootEm(0.75))
					.secondaryText()
					.monospacedDigit()
			case .fileList:
				// The space above is only for the chips, so without files, the button below the picker has the space of the other fields.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.margin(.top, .rootEm(0.75))
					.empty {
						$0.margin(.zero)
					}
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
					// The details of a crash report wrap to a line of their own too.
					.when(States.crashReport) {
						$0.flexWrap()
					}
			case .thumbnail:
				// A square, also for a tall or wide image, as the base styles give images an automatic height, which wins over the height attribute.
				Style()
					.flexShrink(0)
					.frame(size: .rootEm(1.75))
					.objectFit(.cover)
					.cornerRadius(.smallRadius)
			case .name:
				// It is the only part that shrinks, as its minimum width lets it shrink below its content.
				Style()
					.hstack()
					.frame(minWidth: .zero)
					.fontWeight(.medium)
					.color(.primaryText)
					// It starts from no width and takes the free space, so the sizes of all files are in one column at the end, and a long name does not wrap the size and the button to the next line in a row that wraps.
					.flex(1)
			case .size:
				// In the red of the notice of a file that is too large, so the visitor sees which number breaks the limit.
				Style()
					.flexShrink(0)
					.monospacedDigit()
					.when(ancestorHas: States.tooLarge) {
						$0.color(.red(600), dark: .red(400))
					}
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
			case .crashReportNotice:
				// Below the name, with a thin line above it, so it reads as a fact about the file. The label and the details wrap on a phone.
				Style()
					.hidden()
					.frame(width: .percent(100))
					.padding(.top, .rootEm(0.5))
					.border(.top, .separator)
					.textStyle(.caption)
					.when(ancestorHas: States.crashReport) {
						$0
							.hstack(alignment: .center, spacing: .rootEm(0.5))
							.flexWrap()
					}
			case .crashReportLabel:
				// A small tag, like the chips of the site.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.cornerRadius(.capsule)
					.font(size: .rootEm(0.75))
					.fontWeight(.semibold)
					.textWrap(.nowrap)
					.color(.bodyText)
					.background(.cardHover)
			case .otherAppNotice:
				// In the amber of the warning of the email field (``FeedbackPage``), as it is a note, not an error.
				Style()
					.frame(width: .percent(100))
					.textStyle(.caption)
					.color(.amber(700), dark: .amber(400))
			}
		}
	}
}
