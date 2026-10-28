import Elementary
import SiteKit

/**
The tags that a form field can label and describe directly.
*/
protocol FormFieldControlTag: HTMLTagDefinition, HTMLTrait.Attributes.Global {}

extension HTMLTag.input: FormFieldControlTag {}
extension HTMLTag.textarea: FormFieldControlTag {}
extension HTMLTag.select: FormFieldControlTag {}

/**
A labeled input or text area, with an optional hint next to the label. The field owns the control's base style, ID and descriptions. When the control is invalid after the visitor used it (`:user-invalid`), the field shows the error message, without JavaScript.

```swift
FormField(label: "Email", controlID: ElementID("email"), hint: "Only used for replying to you", errorMessage: "Enter a valid email address.") {
	input(.type(.email), .required)
}
```
*/
struct FormField<Control: HTML, Accessory: HTML>: HTML where Control.Tag: FormFieldControlTag {
	let label: String
	let controlID: ElementID
	let hint: String?
	let errorMessage: String?
	let additionalDescriptionIDs: [ElementID]
	let control: Control
	let accessory: Accessory

	/**
	Creates a field with a single root control and separate content next to it, like suggestions or a live warning.
	*/
	init(label: String, controlID: ElementID, hint: String? = nil, errorMessage: String? = nil, additionalDescriptionIDs: [ElementID] = [], @ContentBuilder control: () -> Control, @ContentBuilder accessory: () -> Accessory) {
		self.label = label
		self.controlID = controlID
		self.hint = hint
		self.errorMessage = errorMessage
		self.additionalDescriptionIDs = additionalDescriptionIDs
		self.control = control()
		self.accessory = accessory()
	}

	/**
	The ID of the hint, for the `aria-describedby` of the control.
	*/
	private var hintID: ElementID {
		ElementID("\(controlID)-hint")
	}

	/**
	The ID of the error message, for the `aria-describedby` of the control, so screen readers say what a valid value is, like “Write at least 20 characters.”, also while the message is hidden. It is the ID of the control with `-error`.
	*/
	private var errorID: ElementID {
		ElementID("\(controlID)-error")
	}

	/**
	The descriptions that exist in this field, followed by any additional descriptions of the control.
	*/
	private var descriptionIDs: [ElementID] {
		var ids = [ElementID]()

		if hint != nil {
			ids.append(hintID)
		}

		if errorMessage != nil {
			ids.append(errorID)
		}

		return ids + additionalDescriptionIDs
	}

	var body: some HTML {
		div {
			div {
				Elementary.label(.for(controlID)) {
					label
				}
				.style(FormFieldStyles.label)

				// The control names it in `aria-describedby`, with ``hintID``, like the error message below, with ``errorID``.
				if let hint {
					span(.id(hintID)) {
						hint
					}
					.style(FormFieldStyles.hint)
				}
			}
			.style(FormFieldStyles.labelRow)

			control
				.style(FormFieldStyles.control)
				.attributes(.id(controlID))
				.attributes(optional: .ariaDescribedBy(descriptionIDs))

			accessory

			if let errorMessage {
				p(.id(errorID)) {
					errorMessage
				}
				.style(FormFieldStyles.errorMessage)
			}
		}
		.style(FormFieldStyles.root)
	}
}

extension FormField where Accessory == EmptyHTML {
	/**
	Creates a field without accessory content.
	*/
	init(label: String, controlID: ElementID, hint: String? = nil, errorMessage: String? = nil, additionalDescriptionIDs: [ElementID] = [], @ContentBuilder control: () -> Control) {
		self.init(label: label, controlID: controlID, hint: hint, errorMessage: errorMessage, additionalDescriptionIDs: additionalDescriptionIDs, control: control) {
			EmptyHTML()
		}
	}
}

/**
The styles of ``FormField``. They are not nested in the generic type, as each specialization would be another style set with the same class names (``StyleSet``).
*/
enum FormFieldStyles: StyleSet {
	case root
	case labelRow
	case label
	case hint

	/**
	A text input or text area in the field.
	*/
	case control

	case errorMessage

	var style: Style {
		switch self {
		case .root:
			// The parent state: the label and the message turn red when the control is invalid.
			Style()
				.margin(.bottom, .rootEm(1.5))
				.nested("&:has(:user-invalid)") {
					$0
						.nested(Self.label.selector) {
							$0.color(.red(600), dark: .red(400))
						}
						.nested(Self.errorMessage.selector) {
							$0.display(.block)
						}
				}
		case .labelRow:
			Style()
				.hstack(alignment: .baseline, justification: .spaceBetween)
				.margin(.bottom, .rootEm(0.5))
		case .label:
			Style()
				.textStyle(.caption, weight: .medium)
				.color(.bodyText)
		case .hint:
			Style()
				.secondaryText(.extraSmall)
		case .control:
			Style()
				.display(.block)
				.frame(width: .percent(100))
				.padding(.rootEm(0.625))
				.border()
				.borderColor(.gray(300), dark: .white.opacity(0.1))
				.cornerRadius(.fieldRadius)
				.textStyle(.lead)
				.color(.primaryText)
				.background(.white.opacity(0.6), dark: .white.opacity(0.06))
				.declaration(.appearance, .none)
				.placeholder {
					$0
						.color(.secondaryText)
						.opacity(1)
				}
				// The ring covers the border, so the focused field has one thicker line, not two lines with a gap.
				.focus {
					$0
						.borderColor(.primary(500))
						.focusRing(.primary(500), width: .pixels(1), offset: .pixels(-1))
				}
				.userInvalid {
					$0.borderColor(.red(500))
				}
		case .errorMessage:
			Style()
				.hidden()
				.margin(.top, .rootEm(0.375))
				.textStyle(.caption)
				.color(.red(600), dark: .red(400))
		}
	}
}
