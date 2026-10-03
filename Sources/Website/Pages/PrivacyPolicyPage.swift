import Elementary
import Foundation
import SiteKit

struct PrivacyPolicyPage: Page {
	let app: App

	var path: RoutePath {
		app.privacyPolicyPath
	}

	var metadata: PageMetadata {
		let summary = app.hasSentry
			? "No personal information is collected. Anonymous crash reports are sent to Sentry."
			: "No data or personal information is collected."

		return PageMetadata(title: PageMetadata.titled("Privacy Policy", app.title), description: "The privacy policy of the \(app.title) app. \(summary)")
	}

	var body: some HTML {
		ProsePage(title: "Privacy Policy for \(app.title)", backTo: app.isListed ? app : nil) {
			if app.hasSentry {
				p {
					"No personal information is collected by this app."
					br()
					br()
					"It sends anonymous crash reports to "
					a(.href("https://sentry.io")) {
						"Sentry"
					}
					" to help fix bugs."
				}
			} else {
				p {
					"No data or personal information is collected by this app."
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
				// On the outer section of the page, so the padding keeps the margin of the prose from collapsing.
				Style()
					.pagePadding()
					.nested("h1") {
						$0
							.margin(.bottom, .rem(1))
							.font(.xl3)
					}
					// Like the old site, the larger prose sizes win on wide screens.
					.breakpoint(.lg) {
						$0
							.padding(.top, .rem(2.5))
							.nested("h1") {
								$0
									.margin(.bottom, .em(0.8571))
									.font(size: .em(2.8), lineHeight: 1)
							}
					}
			case .contact:
				Style()
					.padding(.top, .rem(5))
					.font(.sm)
			}
		}
	}
}
