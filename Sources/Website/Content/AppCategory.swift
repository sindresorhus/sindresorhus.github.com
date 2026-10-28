import Foundation
import SiteKit

/**
A themed list of apps, like the free apps or the menu bar apps.
*/
enum AppCategory: String, ContentEnum, Encodable {
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
		"Apps \(qualifier)"
	}

	/**
	The summary with the number of apps, like “33 apps that live in the menu bar”.
	*/
	func summary(count: Int) -> String {
		"\(count.formatted(counting: "app")) \(qualifier)"
	}

	/**
	For search results and the card of the page: the number of apps and the best known ones, like “33 apps that live in the menu bar, like Dato, Velja, Plash, and Pure Paste, by Sindre Sorhus.”
	*/
	func searchDescription(apps: [App], featuredApps: [App]) -> String {
		"\(summary(count: apps.count))\(apps.examples(featuring: featuredApps)), by \(Site.name)."
	}

	/**
	The platforms of the categories of one platform that have apps, by the names of the categories, like “Mac, iPhone & iPad, Apple Watch, and Apple Vision”.
	*/
	static func platformList(in content: SiteContent) -> String {
		allCases
			.filter { $0.platform != nil && !$0.apps(in: content).isEmpty }
			.map(\.name)
			.formatted(.list(type: .and).locale(.site))
	}

	/**
	What the apps have in common, after “Apps”, like “that are free”.
	*/
	private var qualifier: String {
		switch self {
		case .free:
			"that are free"
		case .paid:
			"that are paid"
		case .setapp:
			"available on Setapp"
		case .macOS:
			"that run on the Mac"
		case .menuBar:
			"that live in the menu bar"
		case .iOS:
			"that run on iPhone and iPad"
		case .watchOS:
			"that run on Apple Watch"
		case .visionOS:
			"that run on Apple Vision"
		case .shortcuts:
			"related to the Shortcuts app"
		case .archived:
			"that are no longer being worked on"
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

	/**
	The platform of a category of the apps of one platform, like `.macOS` for the Mac apps.
	*/
	var platform: Platform? {
		switch self {
		case .macOS:
			.macOS
		case .iOS:
			.iOS
		case .watchOS:
			.watchOS
		case .visionOS:
			.visionOS
		case .free, .paid, .setapp, .menuBar, .shortcuts, .archived:
			nil
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
		case .macOS, .iOS, .watchOS, .visionOS:
			platform.map(app.platforms.contains) ?? false
		case .menuBar:
			app.isMenuBarApp
		case .shortcuts:
			app.categories.contains(.shortcuts)
		case .archived:
			false
		}
	}
}

extension [App] {
	/**
	The titles of the first four apps, the featured ones first (``SiteContent/featuredApps``), after “like”, like “, like Dato, Velja, Plash, and Pure Paste”, for a description of a list of apps. When the titles are all the apps, they are not examples, so they come after a colon, like “: Jiffy, Touch Bar Simulator, and Front Flash”. Empty for no apps.
	*/
	func examples(featuring featuredApps: [App]) -> String {
		let titles = startingWith(featuredApps).prefix(4).map(\.title)

		guard let list = titles.nilIfEmpty?.formatted(.list(type: .and).locale(.site)) else {
			return ""
		}

		return titles.count == count ? ": \(list)" : ", like \(list)"
	}

	/**
	The apps with the given apps first, in their order, like the featured apps (``SiteContent/featuredApps``). A given app that is not one of the apps is left out.
	*/
	func startingWith(_ firstApps: [App]) -> [App] {
		let slugs = Set(map(\.slug))
		let firstSlugs = Set(firstApps.map(\.slug))
		return firstApps.filter { slugs.contains($0.slug) } + filter { !firstSlugs.contains($0.slug) }
	}
}

/**
A category that the frontmatter of an app puts it in (`categories`), as no field of the app says it. The other categories come from fields, like `isPaid`, `platforms`, and `isMenuBarApp`, so they would silently do nothing in `categories`, and the type has no case for them.
*/
enum HandPickedCategory: String, ContentEnum {
	case shortcuts
}
