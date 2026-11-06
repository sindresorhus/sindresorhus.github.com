import Elementary
import SiteKit

/**
The message after the feedback is sent. The feedback page shows it in place of the form after a send. It stays until the visitor leaves, so a slow reader does not lose it, and a button leads to the apps.
*/
struct FeedbackSuccess: HTML {
	var body: some HTML<HTMLTag.div> {
		div {
			div {
				Icon.check.size(.rootEm(2.5))
			}
			.style(Styles.icon)

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

			Link("Back to the Apps", destination: .path(.apps))
				.buttonStyle(.secondary)
		}
		.style(Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case icon
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
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.font(.extraLarge3, weight: .bold)
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
