import Foundation
import SiteKit

/**
The apps for `feedback.js`. The questions that the form suggests are in ``FAQSuggestions``.
*/
struct FeedbackData: Encodable {
	struct AppData: Encodable {
		let title: String
		let url: LinkDestination
		let iconURL: RoutePath

		/**
		The FAQ section of the app page, when it has one.
		*/
		let faqURL: LinkDestination?
		let repositoryURL: URL?
		let feedbackNote: String?
	}

	let apps: [AppData]

	init(apps: [App]) {
		self.apps = apps.map { app in
			AppData(
				title: app.title,
				url: app.url,
				iconURL: app.iconPath,
				faqURL: app.hasFAQSection ? .path(app.path, fragment: App.faqSectionID) : nil,
				repositoryURL: app.repositoryURL,
				feedbackNote: app.feedbackNoteHTML
			)
		}
	}
}
