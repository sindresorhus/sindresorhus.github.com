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
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style().font(.sm)
		}
	}
}
