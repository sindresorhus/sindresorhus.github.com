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
					// In dark mode, a little of the light brand colors, as a dark shade on the dark page is a dirty color, like maroon. So the banner is a quiet tint, and the icon and the button have the color.
					.backgroundImage(
						.linearGradient(
							.toBottomRight,
							.lightDark(.primary(100).opacity(0.5), .primary(400).opacity(0.09)),
							.lightDark(.secondary(50).opacity(0.4), .secondary(400).opacity(0.05)),
							.lightDark(.primary(50).opacity(0.5), .primary(400).opacity(0.07))
						)
					)
					.shadow(.small)
					.textAlign(.center)
					// In a row, the corners follow the round ends of the button: the padding plus half the height of a small button (2.3125rem).
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.textAlign(.leading)
							.cornerRadius(.rootEm(1 + 2.3125 / 2))
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
				// On phones, the text is centered above the button, so its lines have about the same length, and the last line is not one or two words, like the date of a sale. Not from small tablets, where the text is in a row with the button, and shorter lines would leave a gap before the button.
				Style()
					.font(size: TextSize.callout.size)
					.fontWeight(.medium)
					.color(.bodyText)
					.below(.smallTablet) {
						$0.textWrap(.balance)
					}
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
	The note of a sale that the app is in today, with a link to the page of the sale, like “Black Friday: Dato is on sale through November 30”. It has no price and no discount, as they are on the page of the sale. The link opens the page at the first “Dato” and marks it, which is the line of the app when the block is the first text of the page with its title, like on the discounts page.
	*/
	init(sale: Sale, app: App) {
		self.init(
			text: "\(sale.name): \(app.title) is on sale through \(sale.lastDay.foundationDate.formatted(.siteDayWithoutYear))",
			link: LabeledLink("See the Discounts", destination: .path(sale.page, highlighting: app.title))
		)
	}
}
