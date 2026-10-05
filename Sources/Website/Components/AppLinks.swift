import Elementary
import Foundation
import SiteKit

/**
The section links of the app page, with the overflow menu. The menu is there also without links, as it has the QR code and sharing.
*/
struct AppLinks: HTML {
	let app: App

	var body: some HTML {
		nav {
			for link in links {
				a(.href(link.destination)) {
					link.title
				}
				.style(Styles.link)
			}

			OverflowMenu.appPage(app, variant: .chip)
		}
		.accessibilityLabel("App links")
		.style(Styles.root)
	}

	/**
	The links of the app, without the trial section, as the “Free Trial” button right above links to it.
	*/
	private var links: [LabeledLink] {
		app.links.filter { $0.destination != .fragment(App.trialSectionID) }
	}

	enum Styles: StyleSet {
		case root
		case link

		var style: Style {
			switch self {
			case .root:
				// Quiet chips, so the download buttons stay the main action. They wrap on phones, so every link is visible.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.margin(.top, .rootEm(2))
			case .link:
				Style().chip()
			}
		}
	}
}
