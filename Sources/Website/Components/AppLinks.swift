import Elementary
import Foundation
import SiteKit

/**
The section links of the app page, with the overflow menu.
*/
struct AppLinks: HTML {
	let app: App

	var body: some HTML {
		if !app.links.isEmpty {
			nav(.ariaLabel("App links")) {
				for link in app.links {
					a(.href(link.href)) {
						link.title
					}
					.style(Styles.link)
				}

				OverflowMenu.appPage(app, id: "app-links-menu")
			}
			.style(Styles.root)
		}
	}

	enum Styles: StyleSet {
		case root
		case link

		var style: Style {
			switch self {
			case .root:
				Style()
					.hstack(spacing: .rem(1))
					.flexWrap()
					.justifyContent(.center)
					.frame(maxWidth: .rem(28))
					.margin(.top, .rem(2))
					.font(.xl, weight: .semibold)
					.color(.link)
			case .link:
				Style()
					.underline(color: .transparent)
					.underlineOffset(.px(4))
					.transition(.color, .underlineColor, duration: .milliseconds(150))
					.hover {
						$0.underlineColor(.primary(500).opacity(0.5))
					}
					.dark {
						$0.hover {
							$0.color(.primary(300))
						}
					}
			}
		}
	}
}
