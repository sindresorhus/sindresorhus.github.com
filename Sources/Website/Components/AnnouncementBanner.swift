import Elementary
import Foundation
import SiteKit

/**
A highlighted note at the top of the app page, like a sale.
*/
struct AnnouncementBanner: HTML {
	/**
	Plain text, without punctuation at its end.
	*/
	let text: String

	/**
	The button.
	*/
	let link: LabeledLink?

	var body: some HTML<HTMLTag.aside> {
		aside {
			div {
				span {
					Icon.sparkles.size(.rootEm(1))
				}
				.style(Styles.icon)

				p {
					text
				}
				.style(Styles.text)

				if let link {
					a(.href(link.destination)) {
						span {
							link.title
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

	enum Styles: String, StyleSet {
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
					.cornerRadius(.boxRadius)
					.backgroundImage(
						.linearGradient(
							.toBottomRight,
							.lightDark(.primary(100).opacity(0.5), .primary(900).opacity(0.25)),
							.lightDark(.secondary(50).opacity(0.4), .secondary(900).opacity(0.2)),
							.lightDark(.primary(50).opacity(0.5), .primary(950).opacity(0.25))
						)
					)
					.shadow(.small)
					.textAlign(.center)
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.textAlign(.leading)
					}
			case .icon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.flexShrink(0)
					.frame(size: .rootEm(2))
					.cornerRadius(.capsule)
					.color(.white)
					.backgroundImage(.brandGradient)
					.shadow(.small)
					.hidden(below: .smallTablet)
			case .text:
				Style()
					.font(size: .rootEm(0.9375))
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

extension AnnouncementBanner {
	/**
	The announcement of the frontmatter of an app.
	*/
	init(announcement: App.Announcement) {
		self.init(text: announcement.text, link: announcement.link.map { LabeledLink($0.text, destination: $0.url) })
	}

	/**
	The note of a sale that the app is in today, with a link to the page of the sale, like “Black Friday: Dato is on sale through November 30”. It has no price and no discount, as they are on the page of the sale.
	*/
	init(sale: Sale, app: App) {
		self.init(
			text: "\(sale.name): \(app.title) is on sale through \(sale.lastDay.foundationDate.formatted(.siteDayWithoutYear))",
			link: LabeledLink("See the Discounts", destination: .path(sale.page))
		)
	}
}
