import SiteKit

/**
A themed list of apps, like the free apps or the menu bar apps.
*/
public enum AppCategory: String, CaseIterable, Codable, Sendable {
	case free
	case paid
	case setapp
	case macOS = "macos"
	case iOS = "ios"
	case watchOS = "watchos"
	case visionOS = "visionos"
	case menuBar = "menu-bar"
	case archived
	case shortcuts

	var path: RoutePath {
		RoutePath("/apps").appending(rawValue)
	}

	var title: String {
		switch self {
		case .free:
			"Free Apps"
		case .paid:
			"Paid Apps"
		case .setapp:
			"Setapp Apps"
		case .macOS:
			"Mac Apps"
		case .iOS:
			"iPhone & iPad Apps"
		case .watchOS:
			"Apple Watch Apps"
		case .visionOS:
			"Apple Vision Apps"
		case .menuBar:
			"Menu Bar Apps"
		case .archived:
			"Archived Apps"
		case .shortcuts:
			"Shortcuts Apps"
		}
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
