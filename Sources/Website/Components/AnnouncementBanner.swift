import Elementary
import Foundation
import SiteKit

/**
A highlighted note at the top of the app page, like a sale.
*/
struct AnnouncementBanner: HTML {
	let announcement: App.Announcement

	var body: some HTML<HTMLTag.aside> {
		aside {
			div {
				span {
					Icon.sparkles.size(.rootEm(1))
				}
				.style(Styles.icon)

				p {
					announcement.text
				}
				.style(Styles.text)

				if let url = announcement.url {
					a(.href(url)) {
						span {
							announcement.linkText ?? "Learn More"
						}

						Icon.arrowRight.size(.rootEm(1))
					}
					.buttonStyle(.gradient, size: .small)
					.style(Styles.button)
				}
			}
			.style(Styles.content)
		}
		// A name, as the page can have other asides, like the trial card.
		.accessibilityLabel("Announcement")
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case content
		case icon
		case text
		case button

		var style: Style {
			switch self {
			case .root:
				Style()
					.hstack(justification: .center)
					.padding(.horizontal, .pageGutter)
			case .content:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1))
					.padding(vertical: .rootEm(1), horizontal: .rootEm(1.25))
					.border(.lightDark(.primary(200).opacity(0.4), .primary(700).opacity(0.3)))
					.cornerRadius(.rootEm(1))
					.backgroundImage(.linearGradient("to bottom right", .lightDark(.primary(100).opacity(0.5), .primary(900).opacity(0.25)), .lightDark(.secondary(50).opacity(0.4), .secondary(900).opacity(0.2)), .lightDark(.primary(50).opacity(0.5), .primary(950).opacity(0.25))))
					.shadow(.small)
					.textAlign(.center)
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.textAlign(.leading)
					}
			case .icon:
				Style()
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.flexShrink(0)
					.frame(width: .rootEm(2), height: .rootEm(2))
					.cornerRadius(.capsule)
					.color(.white)
					.backgroundImage(.linearGradient("to bottom right", .primary(500), .secondary(500), in: "oklch"))
					.shadow(.small)
					.hidden(below: .smallTablet)
			case .text:
				Style()
					.font(size: .pixels(15))
					.fontWeight(.medium)
					.color(.bodyText)
					.from(.smallTablet) {
						$0.textStyle(.body)
					}
			case .button:
				Style().flexShrink(0)
			}
		}
	}
}
