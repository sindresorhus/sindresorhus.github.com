import Elementary
import Foundation
import SiteKit

/**
A highlighted note at the top of the app page, like a sale.
*/
struct AnnouncementBanner: HTML {
	let announcement: App.Announcement

	var body: some HTML {
		aside {
			div {
				span {
					Icon.sparkles.size(.rem(1))
				}
				.style(Styles.icon)

				p {
					HTMLRaw(MarkdownDocument.inlineHTML(announcement.text, options: .site))
				}
				.style(Styles.text)

				if let url = announcement.url {
					a(.href(url.description)) {
						span {
							announcement.urlText ?? "Learn more"
						}

						Icon.arrowRight.size(.rem(1))
					}
					.style(Styles.button)
				}
			}
			.style(Styles.content)
		}
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
					.margin(top: .rem(-2), horizontal: 0, bottom: .rem(8))
					.padding(.horizontal, .rem(1.5))
			case .content:
				Style()
					.vstack(alignment: .center, spacing: .rem(1))
					.padding(vertical: .rem(1), horizontal: .rem(1.25))
					.border(.primary(200).opacity(0.4))
					.cornerRadius(.rem(1))
					.backgroundImage(.linearGradient("to bottom right", .primary(100).opacity(0.5), .secondary(50).opacity(0.4), .primary(50).opacity(0.5)))
					.shadow(.small)
					.textAlign(.center)
					.breakpoint(.sm) {
						$0
							.flexDirection(.row)
							.textAlign(.leading)
					}
					.dark {
						$0
							.borderColor(.primary(700).opacity(0.3))
							.backgroundImage(.linearGradient("to bottom right", .primary(900).opacity(0.25), .secondary(900).opacity(0.2), .primary(950).opacity(0.25)))
					}
			case .icon:
				Style()
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.flexShrink(0)
					.frame(width: .rem(2), height: .rem(2))
					.cornerRadius(.capsule)
					.color(.white)
					.backgroundImage(.linearGradient("to bottom right", .primary(500), .secondary(500), in: "oklch"))
					.shadow(.small)
					.hidden(below: .sm)
			case .text:
				Style()
					.font(size: .px(15))
					.fontWeight(.medium)
					.color(.gray(700), dark: .gray(200))
					.nested("a") {
						$0
							.underline(offset: .px(2))
							.color(.primary(600))
					}
					.nested("strong") {
						$0.fontWeight(.semibold)
					}
					.nested("code") {
						$0
							.padding(.horizontal, .rem(0.25))
							.cornerRadius(.rem(0.25))
							.background(.gray(200))
					}
					.breakpoint(.sm) {
						$0.font(.base)
					}
					.dark {
						$0
							.nested("a") {
								$0.color(.primary(400))
							}
							.nested("code") {
								$0.background(.gray(700))
							}
					}
			case .button:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.flexShrink(0)
					.gap(.rem(0.375))
					.padding(vertical: .rem(0.375), horizontal: .rem(1))
					.cornerRadius(.capsule)
					.font(.sm, weight: .semibold)
					.color(.white)
					.backgroundImage(.brandGradientHover)
					.shadow(.small)
					.transition(.shadow, .filter, duration: .milliseconds(200))
					.nested(Icon.selector) {
						$0.transition(.transform, duration: .milliseconds(200))
					}
					.hover {
						$0
							.shadow(Shadow(y: .px(4), blur: .px(16), spread: .px(-2), color: "rgb(99 102 241 / 40%)"))
							.brightness(1.1)
					}
					.hover {
						$0.nested(Icon.selector) {
							$0.offset(x: .px(2))
						}
					}
			}
		}
	}
}
