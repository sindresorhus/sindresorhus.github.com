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

	/**
	What the app collects or sends, without the crash reports.
	*/
	private var statement: String {
		if let privacyNote = app.privacyNote {
			return privacyNote
		}

		return app.hasSentry ? "No personal information is collected by this app." : "No data or personal information is collected by this app."
	}

	var metadata: PageMetadata {
		let crashReports = app.hasSentry ? " Anonymous crash reports are sent to Sentry." : ""
		return PageMetadata(title: "Privacy Policy — \(app.title)", description: "The privacy policy of the \(app.title) app. \(statement)\(crashReports)")
	}

	var body: some HTML {
		ProsePage(title: "Privacy Policy for \(app.title)", backTo: app.isListed ? app : nil) {
			p {
				statement
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
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case contact

		var style: Style {
			switch self {
			case .root:
				// Only below, like the release notes, so the back link is at the same place on all the pages of an app.
				Style().padding(.bottom, .rootEm(4))
			case .contact:
				Style()
					.padding(.top, .rootEm(5))
					.textStyle(.caption)
			}
		}
	}
}
