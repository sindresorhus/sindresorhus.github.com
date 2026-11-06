import Foundation
import SiteKit

/**
The apps for `feedback.js`. The questions that the form suggests are in ``FAQSuggestions``, and the notes of the apps are templates of ``FeedbackPage``.
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
		let repositoryURL: AbsoluteURL?

		/**
		The version of the app for each older macOS version that has one (``AppListing/olderVersion(for:)``), for a visitor whose app says that it runs on that macOS version. So the form and the older versions page give the same version.
		*/
		let olderVersions: [OlderVersion]
	}

	struct OlderVersion: Encodable {
		let version: NonEmptyString
		let macOS: MacOSVersion
		let url: AbsoluteURL
	}

	let apps: [AppData]

	init(listings: [AppListing]) {
		self.apps = listings.map { listing in
			let app = listing.app

			return AppData(
				title: app.title,
				names: app.feedbackLookupNames,
				iconURL: app.iconPath,
				faqURL: app.faqDestination,
				repositoryURL: app.repositoryURL,
				olderVersions: MacOSVersion.allCases.compactMap { macOS in
					listing.olderVersion(for: macOS).map { OlderVersion(version: $0.version, macOS: macOS, url: $0.url) }
				}
			)
		}
	}
}

extension App {
	/**
	The names exported to the feedback page: the title, slug, and authored aliases, preserving their spelling.
	*/
	var feedbackLookupNames: [String] {
		[self.title, slug.value] + self.feedbackNames
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
