import Elementary
import Foundation
import SiteKit

struct PrivacyPolicyPage: Page {
	let app: App

	var path: RoutePath {
		app.privacyPolicyPath
	}

	var navigation: SiteHeader.Variant {
		.appSubpage(app)
	}

	/**
	The policy of an unlisted app has no breadcrumb, as it has no link back to the app (``body``).
	*/
	var parents: [LabeledLink] {
		app.isListed ? [.apps, LabeledLink(app.title, path: app.path)] : []
	}

	var breadcrumbTitle: String {
		"Privacy Policy"
	}

	var socialImage: SocialImage {
		.cardOf(app)
	}

	var metadata: PageMetadata {
		let crashReports = app.hasSentry ? " Crash reports in Sentry have no name, email, or IP address." : ""
		/*
		Search engines do not index the privacy policies, so they are also left out of the sitemap. The policies are short and almost the same for every app, so search engines fold them together or skip them, and they would be more than a third of the sitemap. A search for the policy of an app finds the app page, which links to it. The links from the App Store still work.
		*/
		return PageMetadata(
			// The app first, like the release notes, so a tab that cuts a long title still shows the app.
			title: "\(app.title) Privacy Policy",
			description: "The privacy policy of the \(app.title) app. \(app.privacyStatement)\(crashReports)",
			isIndexed: false,
			favicon: app.iconPath
		)
	}

	var body: some HTML {
		// The privacy policy of an unlisted app is public before the app launches, as App Review checks it. It has no link back to the app, so a reviewer does not go on to the rest of the site and comment on something there.
		ProsePage(app: app, title: "Privacy Policy", linksBack: app.isListed) {
			p {
				app.privacyStatement
			}

			// A visitor can check the claim of an app without network access. The command is a code block with a copy button, like the other commands of the site, so it does not break inside its words on a phone.
			if app.hasNoNetworkAccess {
				p {
					"\(App.noNetworkPermissionSentence) To check it, run this in Terminal:"
				}
				.style(ProseStyles.leadIn)

				CodeBlock(source: "codesign -d --entitlements - \"/Applications/\(app.title).app\"", language: .console)

				p {
					"The output does not have "
					code(.notTranslated) {
						"com.apple.security.network.client"
					}
					"."
				}
			}

			if app.hasSentry {
				// The DSNs of all the apps are in one Sentry organization in the US region, and the apps do not set `sendDefaultPii`, so Sentry gets no name or email. All the projects have “Prevent Storing of IP Addresses” on, so Sentry does not store the IP address that a report comes from.
				p {
					"When the app crashes, it sends a crash report to "
					a(.href("https://sentry.io")) {
						"Sentry"
					}
					", a service in the US, so I can fix the bug. The report has technical details, like the app version and where in the code the crash happened, without your name or email. Sentry does not store your IP address. Sentry deletes crash reports automatically after a period that it sets."
				}
			}

			p {
				"The app is made by \(Site.author.name), Norway, who is responsible for this policy. If you have questions about it, or want me to delete data about you, "
				a(.href(.contact)) {
					"contact me"
				}
				"."
			}
			// Below a line, like the footer of the download cards, so it reads as the footnote of the policy.
			.style {
				$0
					.margin(.top, .rootEm(2.5))
					.padding(.top, .rootEm(1))
					.border(.top, .separator)
					.textStyle(.caption)
			}
		}
	}
}
