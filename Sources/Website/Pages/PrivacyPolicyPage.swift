import Elementary
import Foundation
import SiteKit

struct PrivacyPolicyPage: Page {
	let app: App

	var path: RoutePath {
		app.privacyPolicyPath
	}

	var navigation: SiteHeader.Variant {
		.appSubpage
	}

	var metadata: PageMetadata {
		let crashReports = app.hasSentry ? " Anonymous crash reports are sent to Sentry." : ""
		// Search engines do not index the page of an unlisted app, like the page of the app.
		return PageMetadata(title: "Privacy Policy — \(app.title)", description: "The privacy policy of the \(app.title) app. \(app.privacyStatement)\(crashReports)", isIndexed: app.isListed)
	}

	var body: some HTML {
		// The privacy policy of an unlisted app is public before the app launches, as App Review checks it. It has no link back to the app, so a reviewer does not go on to the rest of the site and comment on something there.
		ProsePage(title: "Privacy Policy for \(app.title)", backTo: app.isListed ? app : nil) {
			p {
				app.privacyStatement
			}

			if app.hasSentry {
				p {
					"It sends anonymous crash reports to "
					a(.href("https://sentry.io")) {
						"Sentry"
					}
					" to help fix bugs."
				}
			}

			p {
				"If you have any questions or suggestions regarding this privacy policy, do not hesitate to "
				a(.href(.contact)) {
					"contact me"
				}
				"."
			}
			.style(Styles.contact)
		}
		// Only below, like the release notes, so the back link is at the same place on all the pages of an app.
		.style {
			$0.padding(.bottom, .rootEm(4))
		}
	}

	enum Styles: StyleSet {
		case contact

		var style: Style {
			switch self {
			case .contact:
				Style()
					.padding(.top, .rootEm(5))
					.textStyle(.caption)
			}
		}
	}
}
