import Elementary
import SiteKit

/**
Links to the pages about the app at the end of the app page. The overflow menus are `<select>` elements, which search engines do not follow, so the pages are also linked here.
*/
struct AppFooterLinks: HTML {
	let app: App

	var body: some HTML<HTMLTag.nav> {
		nav {
			for link in app.pageOverflowLinks {
				a(.href(link.destination)) {
					link.title
				}
				.style(Styles.link)
			}
		}
		.accessibilityLabel("More about \(app.title)")
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case link

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.hstack()
					.flexWrap()
					.justifyContent(.center)
					.gap(row: .rootEm(0.5), column: .rootEm(1.5))
					.secondaryText()
					// Larger on phones, so the links are easy to read and to tap.
					.below(.smallTablet) {
						$0
							.textStyle(.body)
							.gap(row: .rootEm(0.75), column: .rootEm(1.5))
					}
			case .link:
				Style()
					.underlineOffset(.pixels(4))
					.hover {
						$0
							.underline()
							.color(.primaryText)
					}
			}
		}
	}
}
