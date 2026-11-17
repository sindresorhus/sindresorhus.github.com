import Elementary
import SiteKit

/**
A “← Back to App” link above a page about an app, or a link up to the page above, like “← All Apps” above a category of apps.
*/
struct BackLink: HTML {
	let title: String
	let path: RoutePath

	init(title: String, path: RoutePath) {
		self.title = title
		self.path = path
	}

	init(app: App) {
		self.init(title: "Back to \(app.title)", path: app.path)
	}

	var body: some HTML {
		a(.href(path)) {
			title
		}
		// The arrow is only on the screen, so the name of the link is its text. A long app name can wrap when it is wider than the row, like with enlarged text. The link is alone in its row, so its tap area, which is on `::after` as the arrow is on `::before`, takes no taps from another link.
		.style {
			$0
				.secondaryText()
				.fontWeight(.medium)
				.quietLink()
				.before {
					$0.content("←\u{00A0}", alternativeText: "")
				}
				.minimumTapArea(usesAfter: true)
		}
	}
}
