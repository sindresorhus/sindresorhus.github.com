import Elementary
import Foundation
import SiteKit

/**
Three similar apps: the best matches by platform, menu bar, and price, shuffled among the top eight.
*/
struct RelatedApps: HTML {
	let relatedApps: [App]

	var body: some HTML {
		div {
			if !relatedApps.isEmpty {
				aside {
					h2 {
						"You Might Also Like"
					}
					.style(Styles.title)

					div {
						for relatedApp in relatedApps {
							a(.href(relatedApp.url)) {
								AppIcon(relatedApp, size: 64, morphsAcrossPages: true)
									.style(Styles.icon)

								span {
									relatedApp.title
								}
								.style(Styles.name)
							}
							.style(Styles.app)
						}
					}
					.style(Styles.list)
				}
				.style(Styles.section)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case section
		case title
		case list
		case app
		case icon
		case name

		var style: Style {
			switch self {
			case .root:
				Style().contentColumn()
			case .section:
				Style()
					.margin(.top, .rem(8))
					.padding(.top, .rem(4))
			case .title:
				Style()
					.margin(.bottom, .rem(2))
					.font(.lg, weight: .semibold)
					.textAlign(.center)
					.color(.secondaryText)
			case .list:
				Style()
					.hstack(spacing: .rem(1.5))
					.justifyContent(.center)
					.breakpoint(.sm) {
						$0.gap(.rem(2.5))
					}
			case .app:
				Style()
					.vstack(alignment: .center, spacing: .rem(0.5))
					.frame(width: .rem(5))
					.breakpoint(.sm) {
						$0
							.gap(.rem(0.75))
							.frame(width: .rem(7))
					}
					.hover {
						$0.nested(Self.icon.selector) {
							$0.scaleEffect(1.1)
						}
					}
			case .icon:
				Style()
					.cornerRadius(.rem(0.75))
					.transition(.transform, duration: .milliseconds(150))
			case .name:
				Style()
					.font(size: .rem(0.75), lineHeight: 1.25)
					.fontWeight(.medium)
					.textAlign(.center)
					.color(.bodyText)
					.breakpoint(.sm) {
						$0.font(size: .rem(0.875))
					}
			}
		}
	}
}
