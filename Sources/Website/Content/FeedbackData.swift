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
		The app page, for the button of the message after a send (``FeedbackSuccess``).
		*/
		let url: LinkDestination

		/**
		The accent of the app page (``App/tint``), like `#6448d6` for Dato, which the page takes while the form is for the app. `nil` for a gray icon, which keeps the color of the site.
		*/
		let accent: String?

		/**
		The FAQ section of the app page, when it has one.
		*/
		let faqURL: LinkDestination?
		let repositoryURL: AbsoluteURL?

		/**
		The version of the app for each older macOS version that has one (``AppListing/olderVersion(for:)``), for a visitor whose app says that it runs on that macOS version. So the form and the older versions page give the same version.
		*/
		let olderVersions: [OlderVersion]

		/**
		Whether the app has a Mac version, so the notes about macOS show only for it.
		*/
		let isOnMac: Bool

		/**
		The newest versions of the platforms of the app, like “watchOS 27” for an Apple Watch app, for the note about restarting the device.
		*/
		let newestOSVersions: String
	}

	struct OlderVersion: Encodable {
		let version: NonEmptyString
		let macOS: MacOSVersion
		let url: AbsoluteURL
	}

	let apps: [AppData]

	/**
	The session storage key of a sent message (``FeedbackPage/sentStorageKey``).
	*/
	let sentStorageKey = FeedbackPage.sentStorageKey

	/**
	The session storage key of the title of the app that the sent message was about (``FeedbackPage/sentAppStorageKey``).
	*/
	let sentAppStorageKey = FeedbackPage.sentAppStorageKey

	/**
	The custom property of the accent of a page (``Color/accent``), which `feedback.js` sets to the ``AppData/accent`` of the app.
	*/
	let accentProperty = Color.accent.name.description

	init(listings: [AppListing]) {
		self.apps = listings.map { listing in
			let app = listing.app

			return AppData(
				title: app.title,
				names: app.feedbackLookupNames,
				iconURL: app.iconPath,
				url: app.url,
				accent: app.tint?.description,
				faqURL: app.faqDestination,
				repositoryURL: app.repositoryURL,
				olderVersions: MacOSVersion.allCases.compactMap { macOS in
					listing.olderVersion(for: macOS).map { OlderVersion(version: $0.version, macOS: macOS, url: $0.url) }
				},
				isOnMac: app.platforms.contains(.macOS),
				newestOSVersions: app.platforms.newestVersions
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

extension [Platform] {
	/**
	The newest versions of the platforms, like “macOS 27 and iOS 27”. Apple gives all its platforms the same version number.
	*/
	var newestVersions: String {
		map { "\($0.rawValue) 27" }.formattedList(.and)
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
