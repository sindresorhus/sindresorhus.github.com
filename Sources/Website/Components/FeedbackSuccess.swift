import Elementary
import SiteKit

/**
The message after the feedback is sent. The feedback page shows it in place of the form after a send. It stays until the visitor leaves, so a slow reader does not lose it, and a button leads to the apps. When the message was about an app, `feedback.js` shows the icon of the app in place of the check, and the button leads to the page of the app, in its accent.
*/
struct FeedbackSuccess: HTML {
	var body: some HTML<HTMLTag.div> {
		div {
			div(.id(IDs.icon)) {
				Icon.check.size(.rootEm(2.5))
			}
			.style(Styles.icon)

			// The icon of the app that the message was about, with a small check, which `feedback.js` puts in place of the check above. A template, as an image must have a source.
			template(.id(IDs.appIconTemplate)) {
				span {
					img(.alt(""), .width(80), .height(80), .part(Parts.appIcon))
						.style {
							$0
								.frame(size: .rootEm(5))
								// The shadow of ``AppIcon``, as this image is not one.
								.filter(AppIcon.shadow)
						}

					span {
						Icon.check.size(.rootEm(0.875))
					}
					.style(Styles.checkBadge)
				}
				.style {
					$0
						.position(.relative)
						.display(.block)
				}
			}

			div {
				// Not a second `<h1>`, as the page has the title of the form, which it hides after a send.
				h2 {
					"Message sent!"
				}
				.style(Styles.title)

				p {
					"Thanks for reaching out. I read every message and reply within \(Site.supportReplyTime). When you get my reply, please respond in that email thread instead of sending a new message."
				}
				.style(Styles.message)
			}

			// `feedback.js` changes it to the page of the app that the message was about, like “Back to Dato”.
			Link("Back to the Apps", destination: .path(.apps))
				.buttonStyle(.secondary)
				.attributes(.id(IDs.backLink))
		}
		.style(Styles.root)
	}

	/**
	The IDs that `feedback.js` finds the parts of the message by, to show the app that the message was about.
	*/
	enum IDs: String, ScriptIDSet {
		case icon = "feedback-success-icon"
		case appIconTemplate = "feedback-success-app-icon-template"
		case backLink = "feedback-success-back-link"
	}

	/**
	The elements in the template that `feedback.js` fills.
	*/
	enum Parts: String, ElementPartSet {
		case appIcon
	}

	enum Styles: String, StyleSet {
		case root
		case icon
		case checkBadge
		case title
		case message

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(1.5))
					.frame(minHeight: .smallViewportHeight(60))
					.padding(vertical: .rootEm(4), horizontal: .zero)
					.textAlign(.center)
			case .icon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(size: .rootEm(5))
					.cornerRadius(.capsule)
					.color(.primary(700), dark: .primary(300))
					.background(.primary(600).opacity(0.15))
			case .checkBadge:
				// A green check at the corner of the icon, with a ring of the page background, so it stands out from the icon.
				Style()
					.position(.absolute)
					.bottom(.rootEm(-0.25))
					.trailing(.rootEm(-0.25))
					.hstack(alignment: .center, justification: .center)
					.frame(size: .rootEm(1.75))
					.cornerRadius(.capsule)
					.color(.white)
					.background(.emerald(500))
					.shadow(BoxShadow(y: .zero, spread: .pixels(3), color: .pageBackground))
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.textStyle(.sectionTitle)
					.color(.primaryText)
			case .message:
				Style()
					.frame(maxWidth: .rootEm(24))
					.margin(vertical: .zero, horizontal: .auto)
					.color(.secondaryText)
			}
		}
	}
}
