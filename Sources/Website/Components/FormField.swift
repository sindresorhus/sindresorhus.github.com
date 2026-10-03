import Elementary
import SiteKit

/**
A labeled form control, with an optional hint next to the label. When the control is invalid after the visitor used it (`:user-invalid`), the field shows the error message, without JavaScript.

```swift
FormField(label: "Email", controlID: "email", hint: "Only used for replying to you", errorMessage: "Enter a valid email address.") {
	input(.id("email"), .type(.email), .required)
		.style(FormFieldStyles.control)
}
```
*/
struct FormField<Content: HTML>: HTML {
	let label: String
	let controlID: String
	var hint: String?
	var errorMessage: String?
	@HTMLBuilder var content: Content

	/**
	The ID of the hint, for the `aria-describedby` of the control.
	*/
	var hintID: String {
		"\(controlID)-hint"
	}

	var body: some HTML {
		div {
			div {
				Elementary.label(.for(controlID)) {
					label
				}
				.style(FormFieldStyles.label)

				// The control can name it in `aria-describedby`, with ``hintID``.
				if let hint {
					span(.id(hintID)) {
						hint
					}
					.style(FormFieldStyles.hint)
				}
			}
			.style(FormFieldStyles.labelRow)

			content

			if let errorMessage {
				p {
					errorMessage
				}
				.style(FormFieldStyles.errorMessage)
			}
		}
		.style(FormFieldStyles.root)
	}
}

/**
The styles of ``FormField``. They are not nested in the generic type, as each specialization would get its own class names.
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
				.margin(.bottom, .rem(1.5))
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
				.margin(.bottom, .rem(0.5))
		case .label:
			Style()
				.font(.sm, weight: .medium)
				.color(.gray(900), dark: .gray(300))
		case .hint:
			Style()
				.font(.xs)
				.color(.secondaryText)
		case .control:
			Style()
				.display(.block)
				.frame(width: .percent(100))
				.padding(.rem(0.625))
				.border()
				.borderColor(.gray(300), dark: .white.opacity(0.1))
				.cornerRadius(.rem(0.5))
				.font(.lg)
				.color(.primaryText)
				.background(.white.opacity(0.6), dark: .white.opacity(0.06))
				.declaration(.appearance, .none)
				.placeholder {
					$0
						.color(.gray(500), dark: .gray(400))
						.opacity(1)
				}
				.nested("&:focus") {
					$0
						.borderColor(.primary(500))
						.focusRing(.primary(500), width: .px(1))
				}
				.nested("&:user-invalid") {
					$0.borderColor(.red(500))
				}
		case .errorMessage:
			Style()
				.hidden()
				.margin(.top, .rem(0.375))
				.font(.sm)
				.color(.red(600), dark: .red(400))
		}
	}
}
