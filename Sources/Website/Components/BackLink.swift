import Elementary
import SiteKit

/**
A “← Back to App” link above a page about an app.
*/
struct BackLink: HTML {
	let app: App

	var body: some HTML {
		a(.href(app.path)) {
			"← Back to \(app.title)"
		}
		.style {
			$0
				.secondaryText()
				.fontWeight(.medium)
				.hoverColor(.primaryText)
		}
	}
}
