import Foundation
import SiteKit

/**
The apps for `feedback.js`. The questions that the form suggests are in ``FAQSuggestions``.
*/
struct FeedbackData: Encodable {
	struct AppData: Encodable {
		let title: String

		/**
		The names that the page finds the app by, in any case: the title, the slug (the URL path), like `supercharge` for “Supercharge”, and the other names that the app sends, like “Color Picker” for “System Color Picker”.
		*/
		let names: [String]

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
				names: app.feedbackLookupNames,
				iconURL: app.iconPath,
				faqURL: app.faqDestination,
				repositoryURL: app.repositoryURL?.value,
				feedbackNote: app.feedbackNoteHTML
			)
		}
	}
}

extension App {
	/**
	The names exported to the feedback page: the title, slug, and authored aliases, preserving their spelling.
	*/
	var feedbackLookupNames: [String] {
		[self.title, slug] + self.feedbackNames
	}
}

extension String {
	/**
	The case-insensitive key used by the feedback page, matching JavaScript’s locale-independent `toLowerCase()`. Display names retain their original spelling.
	*/
	var feedbackLookupKey: String {
		lowercased()
	}
}
