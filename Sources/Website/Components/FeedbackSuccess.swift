import Elementary
import SiteKit

/**
The message after the feedback is sent. `feedback.js` shows it in place of the form, and then goes to the apps page.
*/
struct FeedbackSuccess: HTML {
	var body: some HTML {
		div {
			div {
				Icon.check.size(.rootEm(2.5))
			}
			.style(Styles.icon)

			div {
				h1 {
					"Message sent!"
				}
				.style(Styles.title)

				p {
					"Thanks for reaching out. I read every message and will get back to you soon. When you get my reply, please respond in that email thread instead of sending a new message."
				}
				.style(Styles.message)
			}

			p {
				"Taking you to the apps page…"
			}
			.style(Styles.redirect)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case icon
		case title
		case message
		case redirect

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack(alignment: .center, justification: .center)
					.gap(.rootEm(1.5))
					.frame(minHeight: .smallViewportHeight(60))
					.padding(vertical: .rootEm(4), horizontal: 0)
					.textAlign(.center)
			case .icon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(5), height: .rootEm(5))
					.cornerRadius(.capsule)
					.color(.primary(700))
					.background(.primary(600).opacity(0.15))
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.font(.extraLarge3, weight: .bold)
			case .message:
				Style()
					.frame(maxWidth: .rootEm(24))
					.margin(vertical: 0, horizontal: .auto)
					.color(.secondaryText)
			case .redirect:
				Style()
					.textStyle(.caption)
					.color(.gray(400))
			}
		}
	}
}
