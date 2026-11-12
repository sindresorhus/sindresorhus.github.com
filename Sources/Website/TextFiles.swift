import Foundation
import Markdown
import SiteKit
import SOML

/**
The plain files for crawlers, AI assistants, and other tools: `robots.txt`, `humans.txt`, `llms.txt`, `llms-full.txt`, the Markdown copies of the pages, `/apps.json`, the previews of links (``LinkPreview``), WebFinger, and the app site association, and the npm packages and the repos for the buttons of ``ProjectOfTheDay``.
*/
extension Site {
	@RouteBuilder
	var textFileRoutes: [Route] {
		Route.text(#path("/robots.txt")) {
			Self.robots
		}

		Route.text(#path("/humans.txt")) {
			Self.humans
		}

		Route.text(Self.llmsPath) {
			llms(fullTextByteCount: await llmsFull.utf8.count)
		}

		Route.text(Self.llmsFullPath) {
			await llmsFull
		}

		let copies = markdownCopies
		let copiedPages = Set(copies.map(\.page))

		for copy in copies {
			Route.text(copy.page.markdownCopy) {
				copy.markdown(copiedPages)
			}
		}

		Route.file(Self.appsJSONPath) {
			try appsJSON()
		}

		Route.file(LinkPreview.dataPath) {
			LinkPreview.data(for: content)
		}

		Route.file(#path("/.well-known/webfinger")) {
			Self.webFinger()
		}

		if let sharedPuzzlePage = SharedPuzzlePage(apps: content.apps) {
			Route.file(#path("/.well-known/apple-app-site-association")) {
				sharedPuzzlePage.appSiteAssociation
			}
		}

		// Without projects, the about page has no card for them, so its button needs no file.
		for source in ProjectOfTheDay.Source.allCases {
			let projects = source.projects(in: content)

			if !projects.isEmpty {
				Route.file(source.path) {
					ProjectOfTheDay.listJSON(projects)
				}
			}
		}
	}

	static let llmsPath = #path("/llms.txt")

	private static let llmsFullPath = #path("/llms-full.txt")

	/**
	The active apps as data (``appsJSON()``), which `llms.txt` and the head of the apps page link to.
	*/
	static let appsJSONPath = #path("/apps.json")

	/**
	The pages with a Markdown copy (``RoutePath/markdownCopy``), whose `<head>` links to it (`SiteLayout`). A build sets it while it publishes, so a page that renders outside a build has no link.
	*/
	@TaskLocal static var pagesWithMarkdownCopies: Set<RoutePath> = []

	/**
	The pages that this site publishes a Markdown copy of, for ``pagesWithMarkdownCopies``, and for the links of `llms.txt` and of the copies, which go to the copy of a page that has one.
	*/
	var markdownCopyPages: Set<RoutePath> {
		Set(markdownCopies.map(\.page))
	}

	/**
	Every crawler may read every page. The policy for AI is a content signal (`Content-Signal`, which Cloudflare defines), which covers every crawler, not a list of the names of AI crawlers, which would always miss some.
	*/
	private static var robots: String {
		"""
		User-agent: *
		# AI crawlers may use the content, for search and for training.
		Content-Signal: search=yes, ai-input=yes, ai-train=yes
		Allow: /

		Sitemap: \(Sitemap.indexPath.absoluteURL.absoluteString)

		"""
	}

	private static var humans: String {
		"""
		         \\
		          \\
		           \\\\
		            \\\\
		             >\\/7
		         _.-(6'  \\
		        (=___._/` \\
		             )  \\ |
		            /   / |
		           /    > /
		          j    < _\\
		      _.-' :      ``.
		      \\ r=._\\        `.
		     <`\\\\_  \\         .`-.
		      \\ r-7  `-. ._  ' .  `\\
		       \\`,      `-.`7  7)   )
		        \\/         \\|  \\'  / `-._
		                   ||    .'
		                    \\\\  (
		                     >\\  >
		                 ,.-' >.'
		                <.'_.''
		                  <'

		/* TEAM */
		Maker: \(author.name)
		Contact: \(author.email)
		From: Norway
		Site: \(url.absoluteString)

		/* SITE */
		Built with: Swift, Elementary, and swift-markdown
		Source: \(sourceURL.absoluteString)

		"""
	}

	/**
	A summary of the site and every app for AI assistants, following https://llmstxt.org.

	- Parameter fullTextByteCount: The size of `llms-full.txt`, which its link says, as the file does not fit in the context of most AI models, so an assistant reads one page instead.
	*/
	private func llms(fullTextByteCount: Int) -> String {
		var lines = [
			"# \(Self.name)",
			"",
			"> \(Self.description). Maker of macOS and iOS apps and many open-source projects.",
			"",
			"## Apps",
			"",
		]

		// The featured apps first, in the order of `content/site.soml`, as they are the main apps.
		let apps = content.activeAppsWithPages.startingWith(content.featuredApps)

		lines += apps.map(llmsLine(of:))

		// The archived apps still have their pages, which say why they are no longer available, so assistants do not recommend them.
		lines += ["", "## Archived apps", ""]
		lines += archivedAppsWithPages.map(llmsLine(of:))

		lines += ["", "## Pages", ""]
		lines += content.pages.map { page in
			Self.llmsLink(page.title, url: page.llmsURL, description: page.description)
		}

		// The open-source page and the lists of apps have Markdown copies too.
		let copiedPages = markdownCopyPages
		lines += swiftPages.map { page in
			Self.llmsLink(page.metadata.title, url: copiedPages.contains(page.path) ? page.path.markdownCopy.absoluteURL : page.path.absoluteURL, description: page.metadata.description)
		}

		lines += ["", "## Blog", ""]
		// With the year, as a post is advice of its time.
		lines += content.listedPosts.map { post in
			Self.llmsLink(post.title, url: post.llmsURL, description: "\(post.description.map { "\($0) " } ?? "")(\(post.publicationDate.foundationDate.formatted(.site.year())))")
		}

		// A section for each topic, in the order of the list of guides (``GuidesPage``), so an assistant finds the guides of a topic together, like the menu bar guides.
		for topic in Guide.Topic.allCases {
			let guides = content.guides.filter { $0.frontmatter.topic == topic }

			if !guides.isEmpty {
				lines += ["", "## Guides: \(topic.title)", ""]
				lines += guides.map(llmsLine(of:))
			}
		}

		// The shared shortcuts that the app pages link to, with their names from iCloud, as the link texts on the pages are often only “Example shortcut”. A shortcut that several pages link to is listed for the first app. A shortcut that still has the default name of the Shortcuts app, like “New Shortcut 22”, is left out, as the name says nothing. By name, as the shortcuts of an app are loaded in no order.
		var listedShortcuts = Set<Shortcut.ID>()
		var shortcutLines = [String]()

		for app in apps {
			for shortcut in app.shortcuts.sorted(using: KeyPathComparator(\.name)) where !shortcut.name.hasPrefix("New Shortcut") && listedShortcuts.insert(shortcut.id).inserted {
				shortcutLines.append(Self.llmsLink(shortcut.name, url: shortcut.id.url, description: "A shortcut for \(app.llmsURL.markdownLink(app.title))."))
			}
		}

		// Without shortcuts, like in a build that did not load them, the section is left out.
		if !shortcutLines.isEmpty {
			lines += ["", "## Shortcuts", ""] + shortcutLines
		}

		// About 4 bytes for each token, which is an estimate, so it is rounded to 10,000.
		let megabytes = (Double(fullTextByteCount) / 1_000_000).formatted(.number.locale(.site).precision(.fractionLength(1)))
		let tokens = (Int((Double(fullTextByteCount) / 40_000).rounded()) * 10_000).formatted(.siteNumber)

		lines += [
			"",
			"## Optional",
			"",
			Self.llmsLink("Everything", url: Self.llmsFullPath.absoluteURL, description: "All the app pages, lists of apps, guides, pages, open-source projects, and blog posts as Markdown, in one file (\(megabytes) MB, about \(tokens) tokens). To read one page, use its link above."),
			Self.llmsLink("Apps as JSON", url: Self.appsJSONPath.absoluteURL, description: "The facts of each app as data, for a tool that filters the apps: the name, the platforms, the categories, the price, the requirement, the version, the bundle identifier, and the links to the stores, the download, the trial, and the Markdown copy of the page."),
		]
		return lines.joined(separator: "\n") + "\n"
	}

	/**
	An item of a list of links in `llms.txt`, like `- [Dato](https://sindresorhus.com/dato): Calendar in the menu bar.`, without the colon when there is no description.
	*/
	private static func llmsLink(_ title: String, url: URL, description: String?) -> String {
		"- \(url.markdownLink(title))\(description.map { ": \($0)" } ?? "")"
	}

	/**
	The item of an app in `llms.txt`, with its subtitle and its facts (``AppListing/llmsFacts``), like `- [Zone Bar](https://sindresorhus.com/zone-bar.md): World clocks in your menu bar. Price: $4, one-time purchase. …`. The Markdown copies of a guide and of a list of apps have the same item for each of their apps. An archived app has its description instead of the facts, as it is no longer available.
	*/
	private func llmsLine(of app: App) -> String {
		guard !app.isArchived else {
			return Self.llmsLink(app.title, url: app.llmsURL, description: app.description)
		}

		return Self.llmsLink(app.title, url: app.llmsURL, description: "\(app.subtitle). \(content.listing(of: app).llmsFacts)")
	}

	/**
	The item of a guide in `llms.txt`, with its short answer, like in the list of the guides of an app in its Markdown copy.
	*/
	private func llmsLine(of guide: Guide) -> String {
		Self.llmsLink(guide.title, url: guide.llmsURL, description: guide.description)
	}

	/**
	The indexed pages that are written in Swift, not in Markdown, like the open-source page and the older versions of the apps. The home page is the summary at the top, and the apps, the posts, and the guides have their own sections.
	*/
	private var swiftPages: [any Page] {
		specialPages.filter { $0.path != .root && $0.metadata.isIndexed }
	}

	/**
	The apps that are archived and listed, with a page of their own.
	*/
	private var archivedAppsWithPages: [App] {
		content.listedApps.filter { $0.isArchived && !$0.isRedirect }
	}

	/**
	The app pages, the archived app pages, the guides, the pages, the lists of apps, the open-source projects, and the blog posts as Markdown, in the order of `llms-full.txt`.
	*/
	private var markdownCopies: [MarkdownCopy] {
		let project = content.project

		let apps = content.activeAppsWithPages.map { app in
			let listing = content.listing(of: app)
			let facts = [listing.llmsFacts, listing.versionSentence, listing.ratingSentence(at: content.buildDate), listing.terminalInstallSentence, listing.bundleIdentifierSentence].compactMap(\.self).joined(separator: " ")

			// The announcement that the page shows as a banner, like a bundle with a discount, with its link.
			let announcement = app.frontmatter.announcement.map { announcement in
				"\n\n\(announcement.text)." + (announcement.link.map { " \($0.url.absoluteURL(on: app.path).markdownLink($0.text))" } ?? "")
			}

			// The guides of the app, which the page lists at its end (``AppFooterLinks``), with the links of their Markdown copies, like in `llms.txt`.
			let guides = content.guides(about: app).map(llmsLine(of:))
			let guidesSection = guides.isEmpty ? "" : "\n\n## \(App.Section.guides.title)\n\n\(guides.joined(separator: "\n"))"

			return MarkdownCopy(page: app.path) { copiedPages in
				app.exportedMarkdown(
					body: app.fullMarkdown,
					introduction: "\(app.subtitle). \(facts)\(announcement ?? "")",
					project: project,
					copiedPages: copiedPages
				) + guidesSection
			}
		}

		let archivedApps = archivedAppsWithPages.map { app in
			MarkdownCopy(page: app.path) { copiedPages in
				app.exportedMarkdown(
					body: app.fullMarkdown,
					introduction: "\(app.subtitle). The app is archived, so it is no longer available.",
					project: project,
					copiedPages: copiedPages
				)
			}
		}

		let guides = content.resolvedGuides.map { resolved in
			let guide = resolved.guide
			let appLines = resolved.apps.map(llmsLine(of:)).joined(separator: "\n")

			return MarkdownCopy(page: guide.path) { copiedPages in
				// The date that the page shows, as a guide is only useful while its steps are right, and the item of each of its apps in `llms.txt`, with the facts of the app, like on the app page, as the guide recommends them all.
				guide.exportedMarkdown(
					body: guide.file.plainMarkdown,
					introduction: "Updated: \(guide.lastModified.foundationDate.formatted(.siteDay))\n\n\(appLines)",
					project: project,
					copiedPages: copiedPages
				)
			}
		}

		let pages = content.pages.map { page in
			MarkdownCopy(page: page.path) { copiedPages in
				page.exportedMarkdown(body: page.fullMarkdown(today: content.today), project: project, copiedPages: copiedPages)
			}
		}

		// The apps page and the pages of its categories, with the item of each app in `llms.txt`, like the open-source page (``OpenSourcePage/plainMarkdown``), as the pages are only cards. The apps page has the featured apps first, like `llms.txt`, as the page shows other featured apps each day. Limitation: the free and the paid apps are one list, not grouped by platform like on their pages, as each item has its platforms.
		func appListCopy(of page: some Page, apps: [App]) -> MarkdownCopy {
			let markdown = "# \(page.metadata.title)\n\nURL: \(page.path.absoluteURL.absoluteString)\n\n\(page.metadata.description ?? "")\n\n\(apps.map(llmsLine(of:)).joined(separator: "\n"))"

			return MarkdownCopy(page: page.path) { _ in
				markdown
			}
		}

		let appLists = [appListCopy(of: AppsPage(content: content), apps: content.activeApps.startingWith(content.featuredApps))]
			+ AppCategory.allCases.map { category in
				appListCopy(of: AppCategoryPage(category: category, content: content), apps: category.apps(in: content))
			}

		// The projects of the open-source page, grouped like on the page.
		let openSourcePage = OpenSourcePage(content: content)
		let openSource = MarkdownCopy(page: openSourcePage.path) { _ in
			openSourcePage.plainMarkdown
		}

		let posts = content.listedPosts.filter { !$0.isRedirect }.map { post in
			MarkdownCopy(page: post.path) { copiedPages in
				post.exportedMarkdown(
					body: post.file.plainMarkdown,
					introduction: "Published: \(post.publicationDate.foundationDate.formatted(.siteMonth))",
					project: project,
					copiedPages: copiedPages
				)
			}
		}

		return apps + archivedApps + guides + pages + appLists + [openSource] + posts
	}

	/**
	All the app pages, lists of apps, guides, pages, open-source projects, and blog posts as Markdown, in one file. The documents are made at the same time, as the file is the slowest route.
	*/
	private var llmsFull: String {
		get async {
			let copies = markdownCopies
			let copiedPages = Set(copies.map(\.page))
			let documents = await copies.concurrentMap { $0.markdown(copiedPages) }
			return (["# \(Self.name)\n\n> \(Self.description)"] + documents).joined(separator: "\n\n---\n\n") + "\n"
		}
	}

	/**
	The active apps as JSON, for example for the “More apps” menus in the apps, or a tool that filters the apps, like “paid Mac apps with a trial”. `llms.txt` and the head of the apps page link to it. A value that is unknown or that the app does not have is left out.
	*/
	private func appsJSON() throws -> Data {
		struct AppEntry: Encodable {
			let name: String
			let subtitle: String
			let url: URL

			/**
			The Markdown copy of the app page, or `nil` for an app whose page is on another site.
			*/
			let markdownURL: URL?

			let icon: URL
			let platforms: [Platform]

			/**
			The lowest OS version that the app runs on, like `26` or `26.1`, for all its platforms.
			*/
			let minimumOSVersion: OSVersion?

			/**
			The current version, like `1.30.1`.
			*/
			let version: String?

			/**
			The day that the current version was released, like `2026-11-05`.
			*/
			let updated: SOML.Date?

			let isMenuBarApp: Bool

			/**
			The categories of the apps page that the app is in, like `menu-bar`. Each one is a page, like `/apps/menu-bar`.
			*/
			let categories: [AppCategory]

			let appStoreID: AppStoreID?

			/**
			The bundle identifier of the App Store version, like `com.sindresorhus.Dato`. The Setapp version has another one.
			*/
			let bundleIdentifier: String?

			let appStoreURL: URL?
			let setappURL: URL?
			let gumroadURL: URL?

			/**
			The download of the latest version on GitHub, for an app that is in no store, like App Buddy.
			*/
			let downloadURL: URL?

			let isPaid: Bool

			/**
			The price, like “$10”, or `nil` when it is free or unknown.
			*/
			let price: String?

			let hasTrial: Bool

			/**
			The link to get the trial: the invitation on TestFlight, or the trial section of the app page.
			*/
			let trialURL: URL?
		}

		let apps = content.activeApps.map { app in
			let listing = content.listing(of: app)

			return AppEntry(
				name: app.title,
				subtitle: app.subtitle,
				url: app.absoluteURL,
				markdownURL: app.isRedirect ? nil : app.path.markdownCopy.absoluteURL,
				icon: app.iconURL,
				platforms: app.platforms,
				minimumOSVersion: listing.minimumOSVersion,
				version: listing.version,
				updated: listing.currentVersionDate,
				isMenuBarApp: app.frontmatter.isMenuBarApp,
				categories: AppCategory.browsable.filter { $0.includes(app, in: content) },
				appStoreID: app.appStoreID,
				bundleIdentifier: listing.appStoreInfo?.bundleIdentifier,
				appStoreURL: app.appStoreURL,
				setappURL: app.setappURL,
				gumroadURL: app.gumroadURL,
				downloadURL: app.frontmatter.gitHubDownload?.url,
				isPaid: app.isPaid,
				price: listing.paidPriceText,
				hasTrial: app.hasTrial,
				trialURL: app.trialURL
			)
		}

		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return try encoder.encode(apps)
	}

	/**
	WebFinger for the Mastodon account, so searching for `@sindre@sindresorhus.com` (any name) finds it. A static file answers every query with the same account.
	*/
	private static func webFinger() -> Data {
		let handle = author.fediverseHandle

		struct Resource: Encodable {
			struct Link: Encodable {
				let rel: String
				var type: String?
				var href: String?
				var template: String?
			}

			let subject: String
			let aliases: [String]
			let links: [Link]
		}

		let profile = handle.profileURL.absoluteString
		let actor = handle.actorURL.absoluteString

		let resource = Resource(
			subject: "acct:\(handle.account)",
			aliases: [profile, actor],
			links: [
				.init(rel: "http://webfinger.net/rel/profile-page", type: "text/html", href: profile),
				.init(rel: "self", type: "application/activity+json", href: actor),
				.init(rel: "http://ostatus.org/schema/1.0/subscribe", template: "\(handle.server.absoluteString)/authorize_interaction?uri={uri}"),
			]
		)

		return Data(JSONEncoder.pageJSON(resource).utf8)
	}
}

/**
A page of the site as Markdown, for `llms-full.txt` and for its own file next to the page, like `/dato.md` (``RoutePath/markdownCopy``), as the llms.txt proposal suggests, so an assistant can read one page without the whole `llms-full.txt`.
*/
private struct MarkdownCopy: Sendable {
	let page: RoutePath

	/**
	Makes the Markdown with the pages that have a Markdown copy, as a link to one of them goes to its copy (``MarkdownFile/withAbsoluteLinks(_:page:project:copiedPages:)``).
	*/
	let markdown: @Sendable (_ copiedPages: Set<RoutePath>) -> String
}

extension RoutePath {
	/**
	The path of the Markdown copy of the page, like `/dato.md` for `/dato`. The extension is added, not replaced, so `/blog/macos-13.1` has `/blog/macos-13.1.md`.
	*/
	var markdownCopy: Self {
		Self("\(self).md")
	}
}

extension ContentDocument {
	/**
	The link of the document in `llms.txt`: its Markdown copy (``RoutePath/markdownCopy``), or the page elsewhere for a redirect, which has no copy.
	*/
	fileprivate var llmsURL: URL {
		isRedirect ? absoluteURL : path.markdownCopy.absoluteURL
	}
}

extension AppListing {
	/**
	The facts of the app for `llms.txt` and `llms-full.txt`, like “Price: Free. Platforms: macOS, iOS. Get it from: [App Store](https://apps.apple.com/app/id1519522160). Free trial: [download](https://sindresorhus.com/dato#trial). Requires macOS or iOS 26 or later. Free older versions for macOS 15 and 14: [download](https://sindresorhus.com/dato#older-versions).”, as assistants otherwise quote wrong facts from other sites. An app without network access (`hasNoNetworkAccess`) also says that it cannot connect, as assistants are asked whether an app sends data. The stores, the trial, and the older versions are links, so an assistant can give the link without the page, and does not say that the app cannot run on an older macOS version. An app that is in no store links to its download on GitHub, like App Buddy, or else to its page. The price is left out when it is unknown, like for a paid app when the App Store did not answer.
	*/
	fileprivate var llmsFacts: String {
		// Gumroad before Setapp, like the buttons of an app that is not on the App Store, so the first link is the one-time purchase of the price, not the subscription of Setapp.
		var stores = [
			app.appStoreURL?.markdownLink("App Store"),
			app.gumroadURL?.markdownLink("Gumroad"),
			app.setappURL?.markdownLink("Setapp"),
		]
		.compactMap(\.self)

		if
			stores.isEmpty,
			let gitHubDownload = app.frontmatter.gitHubDownload
		{
			stores.append(gitHubDownload.url.markdownLink("download"))
		} else if
			stores.isEmpty,
			app.ownDownloadURL != nil
		{
			stores.append(app.absoluteURL.markdownLink("the app page"))
		}

		let olderMacOSVersions = app.olderVersions.map(\.macOS.rawValue).formattedList(.and)

		return [
			priceText.map { "Price: \($0)." },
			"Platforms: \(app.operatingSystems).",
			stores.isEmpty ? nil : "Get it from: \(stores.joined(separator: ", ")).",
			app.trialURL.map { url in
				let name = if case .testFlight = app.frontmatter.trial?.kind { "TestFlight" } else { "download" }
				return "Free trial: \(url.markdownLink(name))."
			},
			requirementSentence.map { "\($0)." },
			app.olderVersions.isEmpty ? nil : "Free older versions for macOS \(olderMacOSVersions): \(LinkDestination.section(.olderVersions).absoluteURL(on: app.path).markdownLink("download")).",
			app.frontmatter.hasNoNetworkAccess ? App.noNetworkAccessSentence : nil,
		]
		.compactMap(\.self)
		.joined(separator: " ")
	}
}

extension AppListing {
	/**
	The current version and when it was released, like “Version 5.8.4, released November 5, 2026.”, for the Markdown copy of the app page, as assistants are asked for the latest version and whether the app is maintained. Not in `llms.txt`, which would then change with each release. `nil` without a known version.
	*/
	fileprivate var versionSentence: String? {
		guard let version else {
			return nil
		}

		return "Version \(version)\(currentVersionDate.map { ", released \($0.foundationDate.formatted(.siteDay))" } ?? "")."
	}

	/**
	The rating that the facts of the app page show (``rating(at:)``), like “Setapp rating: 99% positive (878 ratings).”, for the Markdown copy of the app page, as assistants are asked whether an app is good. Not in `llms.txt`, which would then change with each build, like the version. `nil` when the page shows no rating.

	- Parameter date: The day of the build, as an app shows a rating only after its first year.
	*/
	fileprivate func ratingSentence(at date: Date) -> String? {
		rating(at: date).map { "\($0.label): \($0.value)." }
	}

	/**
	How to install a Mac app on the App Store from the terminal with mas, and with a Brewfile of Homebrew Bundle, for the Markdown copy of the app page, as an assistant that sets up a Mac cannot click the App Store button. `mas get` gets an app that is free to download, and `mas install` only installs an app that the Apple Account already bought, as mas cannot buy apps. `nil` for an app that the App Store does not list for the Mac, like an iPad app that also runs on Apple silicon Macs, which mas cannot install, or when the price is unknown, as then the command is unknown.
	*/
	fileprivate var terminalInstallSentence: String? {
		guard
			let appStoreInfo,
			appStoreInfo.listedPlatforms.contains(.macOS),
			let price
		else {
			return nil
		}

		let appStoreID = appStoreInfo.id
		let (start, command) = price.isFree ? ("Install", "get") : ("After you buy it on the App Store, install", "install")

		return "\(start) it from the terminal with [mas](https://github.com/mas-cli/mas): `mas \(command) \(appStoreID)`, or with this line in a Brewfile: `mas \"\(app.title)\", id: \(appStoreID)`."
	}

	/**
	The bundle identifier of the App Store version (``AppStoreInfo/bundleIdentifier``), like “Bundle identifier of the App Store version: `com.sindresorhus.Dato`.”, for the Markdown copy of the app page, as scripts, `tccutil`, and device management need it, and it cannot be guessed. The Setapp version has another one.
	*/
	fileprivate var bundleIdentifierSentence: String? {
		appStoreInfo?.bundleIdentifier.map { "Bundle identifier of the App Store version: `\($0)`." }
	}
}

extension App {
	/**
	The link to get the trial: the invitation on TestFlight, or the trial section of the app page. `nil` without a trial.
	*/
	fileprivate var trialURL: URL? {
		switch frontmatter.trial?.kind {
		case .testFlight(let invitation):
			invitation.url
		case .download:
			LinkDestination.section(.trial).absoluteURL(on: path)
		case nil:
			nil
		}
	}

	/**
	The Markdown of the page with what the build adds from the facts of the app, like the common and shared questions and the older versions, where the page shows them (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:renderDownloadCard:)``), without the syntax of the site (``Markdown/Document/plainMarkdown(source:)``).
	*/
	fileprivate var fullMarkdown: String {
		namingShortcuts(in: documentWithGeneratedSections.plainMarkdown(source: file.body))
	}

	/**
	The parsed Markdown of the page with what the build adds from the facts of the app, like the common and shared questions and the older versions, where the page shows them (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:renderDownloadCard:)``).
	*/
	var documentWithGeneratedSections: Document {
		frontmatter.addingGeneratedSections(to: Document(parsing: file.body, options: .parseBlockDirectives), sharedQuestions: sharedQuestions)
	}

	/**
	The Markdown with the name of each shared shortcut after its link, like `[this (iOS)](https://www.icloud.com/shortcuts/…) (shortcut “Transcribe multiple files to Notes (iOS)”)`, when the text of the link does not have the name, as an assistant cannot open the page on iCloud to see what the link adds. The page shows the name on a card or in a preview (``Shortcut``).
	*/
	private func namingShortcuts(in markdown: String) -> String {
		let shortcuts = shortcuts.keyed(by: \.id)

		guard !shortcuts.isEmpty else {
			return markdown
		}

		// Each name goes at the end of its link, so the edit is an empty range there.
		let names = Document(parsing: markdown, options: .parseBlockDirectives).descendants(of: Markdown.Link.self).compactMap { link -> (range: SourceRange, text: String)? in
			guard
				let end = link.range?.upperBound,
				let shortcut = link.shortcutID.flatMap({ shortcuts[$0] }),
				!link.plainText.removingSmartPunctuation.contains(shortcut.name)
			else {
				return nil
			}

			return (end..<end, " (shortcut “\(shortcut.name)”)")
		}

		return markdown.replacingSource(names, range: \.range) { name, _ in
			name.text
		}
	}
}

extension Document {
	/**
	The Markdown of the document without the syntax of the site, like block directives, keyboard shortcuts, and heading IDs (``PlainMarkdownRewriter``), as the file is read outside the site. The blocks without it keep their source, and the others, and the blocks that the build added, are formatted.

	Limitation: the parser leaves link reference definitions and footnote definitions out of the blocks, so they are left out, and it gives a setext heading (underlined with `=` or `-`) directly followed by text a range that has the next line, so that line is there twice. The content files have none.

	- Parameter source: The Markdown that the document was parsed from.
	*/
	fileprivate func plainMarkdown(source: String, blockDirective: @escaping (BlockDirective) -> [any BlockMarkup] = { $0.plainBlocks }) -> String {
		let lines = source.split(separator: "\n", omittingEmptySubsequences: false)

		return blockChildren.compactMap { block -> String? in
			var rewriter = PlainMarkdownRewriter(blockDirective: blockDirective)

			// The rewriter changes the children of the document it gets, so a block directive at the top can be several blocks.
			guard let plainBlock = rewriter.visit(Document(block)) else {
				return nil
			}

			guard
				!rewriter.didChange,
				// Raw HTML is formatted as it is written, and the parser ends the range of an HTML comment of several lines a line early.
				!(block is HTMLBlock),
				// The added blocks have no range, or the source of their own file, like the shared questions.
				let range = block.range,
				range.lowerBound.source == nil
			else {
				let markdown = plainBlock.format()
				return markdown.allSatisfy(\.isWhitespace) ? nil : markdown
			}

			// A top-level block has whole lines.
			return lines[(range.lowerBound.line - 1)..<range.upperBound.line].joined(separator: "\n")
		}
		// Raw HTML ends with its line break, and the range of a list has the blank line after it.
		.lazy.map { $0.trimmingCharacters(in: .newlines) }
		.joined(separator: "\n\n")
	}
}

extension MarkdownFile {
	/**
	The Markdown of the file without the syntax of the site (``Markdown/Document/plainMarkdown(source:)``).
	*/
	fileprivate var plainMarkdown: String {
		Document(parsing: body, options: .parseBlockDirectives).plainMarkdown(source: body)
	}

	// Stored, as this runs for each document of `llms-full.txt`.
	// The root-relative URLs of raw HTML, like `<img src="/dato/icon.png">` and `href="/"`, but not `//example.com`, which is another host.
	nonisolated(unsafe) private static let rootRelativeHTMLURL = /\b(src|href)="(\/(?:[^"\/][^"]*)?)"/

	/**
	The Markdown with the destinations of its links and images, and the root-relative URLs of its raw HTML, as absolute URLs, as the file is read outside the site. A link to a content file, like `donate.md`, goes to its page. A link to a page that has a Markdown copy, like `/menu-drop`, goes to the copy (`https://sindresorhus.com/menu-drop.md`), as the copy is much smaller than the HTML of the page. A link to a section of a page, like `/supercharge#trial`, or with a query, goes to the page, as the copy has no sections.

	Limitation: a link to a page without a leading slash, like `donate`, a full link to the site, like `https://sindresorhus.com/dato`, and a link in raw HTML go to the page.

	- Parameter copiedPages: The pages that have a Markdown copy.
	*/
	fileprivate func withAbsoluteLinks(
		_ markdown: String,
		page: URL,
		project: Project,
		copiedPages: Set<RoutePath>
	) -> String {
		let document = Document(parsing: markdown, options: .parseBlockDirectives)
		let replacements = document.linkReplacements { destination in
			let destination = (try? resolvingLink(destination, project: project)) ?? destination

			guard
				case .path(let path, let query, nil)? = try? LinkDestination(validating: destination),
				query.isEmpty,
				copiedPages.contains(path)
			else {
				return URL(string: destination, relativeTo: page)?.absoluteString ?? destination
			}

			return path.markdownCopy.absoluteURL.absoluteString
		}
		let resolved = markdown.replacingSource(replacements, range: \.range) { replacement, _ in
			replacement.replacementText
		}

		// Most files have no root-relative URL in raw HTML, and the word boundary makes the search slow (about 0.1 s for all the files).
		guard resolved.contains(#"="/"#) else {
			return resolved
		}

		// Only actual HTML, so an HTML example in inline code or a code block stays as written.
		let htmlDocument = Document(parsing: resolved)
		let htmlRanges = (htmlDocument.descendants(of: InlineHTML.self).compactMap(\.range)
			+ htmlDocument.descendants(of: HTMLBlock.self).compactMap(\.range))
			.sorted(using: KeyPathComparator(\.lowerBound))

		return resolved.replacingSource(htmlRanges, range: \.self) { _, htmlBytes in
			String(decoding: htmlBytes, as: UTF8.self).replacing(Self.rootRelativeHTMLURL) { match in
				#"\#(match.1)="\#(URL(string: String(match.2), relativeTo: page)?.absoluteString ?? String(match.2))""#
			}
		}
	}
}

extension MarkdownPage {
	/**
	The Markdown of the page with the sponsors from the frontmatter, where the page shows them, without the syntax of the site. The parsed `@Sponsors` directive places its tiers, so code examples remain literal. A `@Scheduled` block is only its content, and only when the page shows it, or before the first day of a sale, the sentence with its name and dates. A level 1 heading at the start, like “Thanks! 🙌”, is left out, as the copy starts with the title of the page (``ContentDocument/exportedMarkdown(body:introduction:project:copiedPages:)``), and a second title would start a new document.

	- Parameter today: The day of the build, which decides what `@Scheduled` shows.
	*/
	fileprivate func fullMarkdown(today: SOML.Date) -> String {
		var blocks = Array(Document(parsing: file.body, options: .parseBlockDirectives).blockChildren)

		if (blocks.first as? Markdown.Heading)?.level == 1 {
			blocks.removeFirst()
		}

		// The blocks keep their source ranges, so the other blocks keep their source text.
		return Document(blocks).plainMarkdown(source: file.body, blockDirective: { directive in
			switch directive.siteName {
			case .sponsors:
				let sponsors = frontmatter.sponsorTiers.map(\.markdown).joined(separator: "\n\n")
				return Array(Document(parsing: sponsors).blockChildren)
			case .scheduled:
				// The build already reported invalid arguments.
				guard let arguments = directive.scheduled else {
					return []
				}

				if arguments.contains(today) {
					return Array(directive.blockChildren)
				}

				return arguments.saleAnnouncement(on: today).map { [Paragraph(Text($0))] as [any BlockMarkup] } ?? []
			default:
				return directive.plainBlocks
			}
		})
	}
}

extension MarkdownPage.SponsorTier {
	/**
	The tier as a heading and a list of its sponsors, like on the page.
	*/
	fileprivate var markdown: String {
		let sponsors = sponsors.map { sponsor in
			sponsor.url.map { "- \($0.value.markdownLink(sponsor.name))" } ?? "- \(sponsor.name)"
		}

		return "## \(title) \(price)\n\n\(sponsors.joined(separator: "\n"))"
	}
}

extension ContentDocument {
	/**
	Frames a document export with its canonical identity, keeping type-specific introductions and bodies at the call site.

	- Parameter copiedPages: The pages that have a Markdown copy, which the links of the body go to (``MarkdownFile/withAbsoluteLinks(_:page:project:copiedPages:)``).
	*/
	fileprivate func exportedMarkdown(
		body: String,
		introduction: String? = nil,
		project: Project,
		copiedPages: Set<RoutePath>
	) -> String {
		let introduction = introduction.map { "\($0)\n\n" } ?? ""
		let body = file.withAbsoluteLinks(
			body,
			page: absoluteURL,
			project: project,
			copiedPages: copiedPages
		)

		return "# \(frontmatter.title)\n\n\(introduction)URL: \(absoluteURL.absoluteString)\n\n\(body)"
	}
}

extension Markup {
	/**
	The outermost parsed link/image edits. Rewriting a whole subtree handles linked images without overlapping source replacements.
	*/
	fileprivate func linkReplacements(resolving destination: @escaping (String) -> String) -> [Replacement] {
		guard self is Markdown.Link || self is Markdown.Image else {
			return children.flatMap { $0.linkReplacements(resolving: destination) }
		}

		var rewriter = PlainMarkdownRewriter(linkDestination: destination, blockDirective: \.plainBlocks)
		guard
			let range,
			let rewritten = rewriter.visit(self),
			rewriter.didChange
		else {
			return []
		}

		// Formatting an inline replacement must not inherit its surrounding list’s indentation.
		return [Replacement(range: range, replacementText: rewritten.detachedFromParent.format())]
	}
}

extension String {
	/**
	Applies edits at parser-owned UTF-8 ranges from last to first, giving each edit its exact source bytes and preserving every byte outside the changed nodes, including authored list numbers and container prefixes.
	*/
	fileprivate func replacingSource<Edit>(_ edits: [Edit], range: KeyPath<Edit, SourceRange>, replacementText: (Edit, ArraySlice<UInt8>) -> String) -> String {
		var bytes = Array(utf8)
		var lineOffsets = [0]

		for (index, byte) in bytes.enumerated() where byte == 10 {
			lineOffsets.append(index + 1)
		}

		for edit in edits.reversed() {
			let sourceRange = edit[keyPath: range]
			let lower = lineOffsets[sourceRange.lowerBound.line - 1] + sourceRange.lowerBound.column - 1
			let upper = lineOffsets[sourceRange.upperBound.line - 1] + sourceRange.upperBound.column - 1
			let replacement = replacementText(edit, bytes[lower..<upper])
			bytes.replaceSubrange(lower..<upper, with: replacement.utf8)
		}

		return String(decoding: bytes, as: UTF8.self)
	}
}
