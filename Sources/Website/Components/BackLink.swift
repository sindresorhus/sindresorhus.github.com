import Elementary
import SiteKit

/**
A “← Back to App” link above a page about an app.
*/
struct BackLink: HTML {
	let app: App

	var body: some HTML {
		a(.href(app.path)) {
			"Back to \(app.title)"
		}
		// The arrow is only on the screen, so the name of the link is its text.
		.style {
			$0
				.secondaryText()
				.fontWeight(.medium)
				.quietLink()
				.before {
					$0.content("←\u{00A0}", alternativeText: "")
				}
		}
	}
}
