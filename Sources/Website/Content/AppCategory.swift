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
	case developerTools = "developer-tools"
	case clockAndCalendar = "clock-and-calendar"
	case ai
	case noNetworkAccess = "no-internet"
	case archived

	/**
	The categories that visitors browse, without the archived apps.
	*/
	static var browsable: [Self] {
		allCases.filter { $0 != .archived }
	}

	/**
	The categories that the apps page shows as chips: all that visitors browse, except the Apple Vision apps, as there are only a few of them, and the clock and calendar apps, the AI apps, and the apps that cannot connect, which only some visitors look for. So the chips stay at two balanced rows.
	*/
	static var chips: [Self] {
		browsable.filter { ![.visionOS, .clockAndCalendar, .ai, .noNetworkAccess].contains($0) }
	}

	/**
	The categories that visitors browse that are not chips (``chips``), which the “…” menu next to the chips has.
	*/
	static var menuCategories: [Self] {
		browsable.filter { !chips.contains($0) }
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
		case .developerTools:
			"Dev Tools"
		case .clockAndCalendar:
			"Clock & Calendar"
		case .ai:
			"AI"
		case .noNetworkAccess:
			"No Internet"
		case .archived:
			"Archived"
		}
	}

	/**
	The title of the page, like “Free Apps”. The apps without network access are not “No Internet Apps”, and not “Offline Apps”, as many other apps also work offline.
	*/
	var title: String {
		self == .noNetworkAccess ? "Apps Without Internet Access" : "\(name) Apps"
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
			.formattedList(.and)
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
		case .developerTools:
			"for developers"
		case .clockAndCalendar:
			"that show the time, the date, or your calendar"
		case .ai:
			"that use AI"
		case .noNetworkAccess:
			"that cannot connect to the internet"
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
			"The apps of mine that are on [Setapp](\(SetappID.vendorProgramURL.absoluteString)), a subscription with many Mac apps and a free trial of 7 days. Each app is also a one-time purchase on its own page, without a subscription."
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
		case .developerTools:
			"The apps of mine for developers, from the “Developer Tools” category of the App Store."
		case .clockAndCalendar:
			"The apps of mine that show the time, the date, or your calendar."
		case .ai:
			"The apps of mine that use AI. Some of them run the AI model on your device, so your data stays there. Others send your input to an AI service, like ChatGPT."
		case .noNetworkAccess:
			"The apps of mine that cannot connect to the internet. They have no network permission, so the macOS app sandbox stops all their connections, and your data stays on your Mac. The privacy policy of each app shows how to check it."
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
		case .setapp, .macOS, .iOS, .watchOS, .visionOS, .menuBar, .archived, .shortcuts, .developerTools, .clockAndCalendar, .ai, .noNetworkAccess:
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
		(self == .archived ? content.listedApps : content.activeApps).filter { includes($0, in: content) }
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
		case .free, .paid, .setapp, .menuBar, .shortcuts, .developerTools, .clockAndCalendar, .ai, .noNetworkAccess, .archived:
			nil
		}
	}

	/**
	The names that visitors use for the platform of the category in a path, like `iphone` and `ipad` for the iOS apps, as the slugs are the names of the operating systems. Empty for a category that is not a platform.
	*/
	var otherNames: [String] {
		switch self {
		case .macOS:
			["mac"]
		case .iOS:
			["iphone", "ipad"]
		case .watchOS:
			["apple-watch", "watch"]
		case .visionOS:
			["apple-vision", "vision-pro"]
		case .free, .paid, .setapp, .menuBar, .shortcuts, .developerTools, .clockAndCalendar, .ai, .noNetworkAccess, .archived:
			[]
		}
	}

	/**
	Whether the app is in the category, like on the page of the category. It does not check that the app is active, so use it only for an active app, like `.free`, which is true for an archived free app. ``archived`` is the exception.
	*/
	func includes(_ app: App, in content: SiteContent) -> Bool {
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
		case .noNetworkAccess:
			app.hasNoNetworkAccess
		case .shortcuts, .clockAndCalendar, .ai:
			app.categories.contains { $0.category == self }
		// The category of the App Store, which the build fetches, so an app that is not on the App Store is not in it.
		case .developerTools:
			content.listing(of: app).appStoreInfo?.schemaApplicationCategory == .developer
		case .archived:
			app.isArchived
		}
	}
}

extension [App] {
	/**
	The titles of the first four apps, the featured ones first (``SiteContent/featuredApps``), after “like”, like “, like Dato, Velja, Plash, and Pure Paste”, for a description of a list of apps. When the titles are all the apps, they are not examples, so they come after a colon, like “: Jiffy, Touch Bar Simulator, and Front Flash”. Empty for no apps.
	*/
	func examples(featuring featuredApps: [App]) -> String {
		let titles = startingWith(featuredApps).prefix(4).map(\.title)

		guard let list = titles.nilIfEmpty?.formattedList(.and) else {
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
	case clockAndCalendar = "clock-and-calendar"
	case ai

	/**
	The category of the apps page that the app is in.
	*/
	var category: AppCategory {
		switch self {
		case .shortcuts:
			.shortcuts
		case .clockAndCalendar:
			.clockAndCalendar
		case .ai:
			.ai
		}
	}
}
