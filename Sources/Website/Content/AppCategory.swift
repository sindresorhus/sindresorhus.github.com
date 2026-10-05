import SiteKit

/**
A themed list of apps, like the free apps or the menu bar apps.
*/
enum AppCategory: String, CaseIterable, Codable, Sendable {
	// The order of the “Categories” menu of the apps page.
	case free
	case paid
	case setapp
	case macOS = "macos"
	case menuBar = "menu-bar"
	case iOS = "ios"
	case watchOS = "watchos"
	case visionOS = "visionos"
	case shortcuts
	case archived

	/**
	The categories that visitors browse, without the archived apps.
	*/
	static var browsable: [Self] {
		allCases.filter { $0 != .archived }
	}

	var path: RoutePath {
		RoutePath.apps.appending(rawValue)
	}

	/**
	The short name, like “Free”, for menus.
	*/
	var name: String {
		switch self {
		case .free:
			"Free"
		case .paid:
			"Paid"
		case .setapp:
			"Setapp"
		case .macOS:
			"Mac"
		case .menuBar:
			"Menu Bar"
		case .iOS:
			"iPhone & iPad"
		case .watchOS:
			"Apple Watch"
		case .visionOS:
			"Apple Vision"
		case .shortcuts:
			"Shortcuts"
		case .archived:
			"Archived"
		}
	}

	var title: String {
		"\(name) Apps"
	}

	/**
	A short description for links, like “Apps that are free”.
	*/
	var summary: String {
		switch self {
		case .free:
			"Apps that are free"
		case .paid:
			"Apps that are paid"
		case .setapp:
			"Apps available on Setapp"
		case .macOS:
			"Apps that run on the Mac"
		case .menuBar:
			"Apps that live in the menu bar"
		case .iOS:
			"Apps that run on iPhone and iPad"
		case .watchOS:
			"Apps that run on Apple Watch"
		case .visionOS:
			"Apps that run on Apple Vision"
		case .shortcuts:
			"Apps related to the Shortcuts app"
		case .archived:
			"Apps that are no longer being worked on"
		}
	}

	/**
	A link to the page of the category, with the summary.
	*/
	var link: LabeledLink {
		LabeledLink(name, destination: .path(path), description: summary)
	}

	/**
	Markdown.
	*/
	var description: String {
		switch self {
		case .free:
			"The apps of mine that are completely free (without ads!)."
		case .paid:
			"The apps of mine that are paid. One-time payment. Own forever."
		case .setapp:
			"Apps of mine available on **Setapp**."
		case .macOS:
			"The apps of mine that run on the Mac."
		case .iOS:
			"The apps of mine that run on iPhone and iPad."
		case .watchOS:
			"The apps of mine that run on Apple Watch."
		case .visionOS:
			"The apps of mine that run on Apple Vision."
		case .menuBar:
			"I love making menu bar apps."
		case .archived:
			"Apps that are no longer being worked on."
		case .shortcuts:
			"Apps related to the [Shortcuts app](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac)."
		}
	}

	/**
	Markdown after the list of apps, like a link to a related category.
	*/
	var footer: String? {
		switch self {
		case .free:
			"""
			If you like my work, consider leaving a review on the App Store. And also check out my [paid apps](\(Self.paid.path)).

			[Older versions](\(RoutePath.olderVersions)) of paid apps for older macOS versions are available for free.
			"""
		case .paid:
			"You can find my free apps [here](\(Self.free.path))."
		case .setapp, .macOS, .iOS, .watchOS, .visionOS, .menuBar, .archived, .shortcuts:
			nil
		}
	}

	/**
	Whether the list is grouped by platform, as the category has apps for every platform.
	*/
	var isGroupedByPlatform: Bool {
		self == .free || self == .paid
	}

	/**
	The apps in the category, newest first.
	*/
	func apps(in content: SiteContent) -> [App] {
		switch self {
		case .archived:
			content.listedApps.filter(\.isArchived)
		default:
			content.activeApps.filter(includes)
		}
	}

	private func includes(_ app: App) -> Bool {
		switch self {
		case .free:
			!app.isPaid
		case .paid:
			app.isPaid
		case .setapp:
			app.setappID != nil
		case .macOS:
			app.platforms.contains(.macOS)
		case .iOS:
			app.platforms.contains(.iOS)
		case .watchOS:
			app.platforms.contains(.watchOS)
		case .visionOS:
			app.platforms.contains(.visionOS)
		case .menuBar:
			app.isMenuBarApp
		case .shortcuts:
			app.categories.contains(.shortcuts)
		case .archived:
			false
		}
	}
}
