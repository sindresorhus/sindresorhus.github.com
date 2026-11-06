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

		for copy in markdownCopies {
			Route.text(copy.page.markdownCopy) {
				copy.markdown()
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
	The pages that this site publishes a Markdown copy of, for ``pagesWithMarkdownCopies``.
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

		lines += apps.map { app in
			Self.llmsLink(app.title, url: app.llmsURL, description: "\(app.subtitle). \(content.listing(of: app).llmsFacts)")
		}

		// The archived apps still have their pages, which say why they are no longer available, so assistants do not recommend them.
		lines += ["", "## Archived apps", ""]
		lines += archivedAppsWithPages.map { app in
			Self.llmsLink(app.title, url: app.llmsURL, description: app.description)
		}

		lines += ["", "## Pages", ""]
		lines += content.pages.map { page in
			Self.llmsLink(page.title, url: page.llmsURL, description: page.description)
		}

		// The open-source page has a Markdown copy too.
		let copiedPages = Set(markdownCopies.map(\.page))
		lines += swiftPages.map { page in
			Self.llmsLink(page.metadata.title, url: copiedPages.contains(page.path) ? page.path.markdownCopy.absoluteURL : page.path.absoluteURL, description: page.metadata.description)
		}

		lines += ["", "## Blog", ""]
		// With the year, as a post is advice of its time.
		lines += content.listedPosts.map { post in
			Self.llmsLink(post.title, url: post.llmsURL, description: "\(post.description.map { "\($0) " } ?? "")(\(post.publicationDate.foundationDate.formatted(.site.year())))")
		}

		lines += ["", "## Guides", ""]
		lines += content.guides.map { guide in
			Self.llmsLink(guide.title, url: guide.llmsURL, description: guide.description)
		}

		// The shared shortcuts that the app pages link to, with their names from iCloud, as the link texts on the pages are often only “Example shortcut”. A shortcut that several pages link to is listed for the first app. A shortcut that still has the default name of the Shortcuts app, like “New Shortcut 22”, is left out, as the name says nothing. By name, as the shortcuts of an app are loaded in no order.
		var listedShortcuts = Set<Shortcut.ID>()
		var shortcutLines = [String]()

		for app in apps {
			for shortcut in app.shortcuts.sorted(using: KeyPathComparator(\.name)) where !shortcut.name.hasPrefix("New Shortcut") && listedShortcuts.insert(shortcut.id).inserted {
				shortcutLines.append(Self.llmsLink(shortcut.name, url: shortcut.id.url, description: "A shortcut for [\(app.title)](\(app.llmsURL.absoluteString))."))
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
			Self.llmsLink("Everything", url: Self.llmsFullPath.absoluteURL, description: "All the app pages, guides, pages, open-source projects, and blog posts as Markdown, in one file (\(megabytes) MB, about \(tokens) tokens). To read one page, use its link above."),
			Self.llmsLink("Apps as JSON", url: Self.appsJSONPath.absoluteURL, description: "The facts of each app as data, for a tool that filters the apps: the name, the platforms, the price, the requirement, the version, and the links to the stores, the trial, and the Markdown copy of the page."),
		]
		return lines.joined(separator: "\n") + "\n"
	}

	/**
	An item of a list of links in `llms.txt`, like `- [Dato](https://sindresorhus.com/dato): Calendar in the menu bar.`, without the colon when there is no description.
	*/
	private static func llmsLink(_ title: String, url: URL, description: String?) -> String {
		"- [\(title)](\(url.absoluteString))\(description.map { ": \($0)" } ?? "")"
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
	The app pages, the archived app pages, the guides, the pages, the open-source projects, and the blog posts as Markdown, in the order of `llms-full.txt`.
	*/
	private var markdownCopies: [MarkdownCopy] {
		let project = content.project

		let apps = content.activeAppsWithPages.map { app in
			let listing = content.listing(of: app)
			let facts = [listing.llmsFacts, listing.versionSentence].compactMap(\.self).joined(separator: " ")

			// The announcement that the page shows as a banner, like a bundle with a discount, with its link.
			let announcement = app.frontmatter.announcement.map { announcement in
				"\n\n\(announcement.text)." + (announcement.link.map { " [\($0.text)](\($0.url.absoluteURL(on: app.path).absoluteString))" } ?? "")
			}

			return MarkdownCopy(page: app.path) {
				app.exportedMarkdown(body: app.fullMarkdown, introduction: "\(app.subtitle). \(facts)\(announcement ?? "")", project: project)
			}
		}

		let archivedApps = archivedAppsWithPages.map { app in
			MarkdownCopy(page: app.path) {
				app.exportedMarkdown(body: app.fullMarkdown, introduction: "\(app.subtitle). The app is archived, so it is no longer available.", project: project)
			}
		}

		let guides = content.resolvedGuides.map { resolved in
			let guide = resolved.guide
			let app = resolved.app
			let appFacts = "\(app.title): \(content.listing(of: app).llmsFacts)"

			return MarkdownCopy(page: guide.path) {
				// The date that the page shows, as a guide is only useful while its steps are right, and the facts of its app, like on the app page, which the page shows in the box to get the app.
				guide.exportedMarkdown(body: guide.file.plainMarkdown, introduction: "Updated: \(guide.lastModified.foundationDate.formatted(.siteDay))\n\n\(appFacts)", project: project)
			}
		}

		let pages = content.pages.map { page in
			MarkdownCopy(page: page.path) {
				page.exportedMarkdown(body: page.fullMarkdown(today: content.today), project: project)
			}
		}

		// The projects of the open-source page, grouped like on the page.
		let openSourcePage = OpenSourcePage(content: content)
		let openSource = MarkdownCopy(page: openSourcePage.path) {
			openSourcePage.plainMarkdown
		}

		let posts = content.listedPosts.filter { !$0.isRedirect }.map { post in
			MarkdownCopy(page: post.path) {
				post.exportedMarkdown(body: post.file.plainMarkdown, introduction: "Published: \(post.publicationDate.foundationDate.formatted(.siteMonth))", project: project)
			}
		}

		return apps + archivedApps + guides + pages + [openSource] + posts
	}

	/**
	All the app pages, guides, pages, open-source projects, and blog posts as Markdown, in one file. The documents are made at the same time, as the file is the slowest route.
	*/
	private var llmsFull: String {
		get async {
			let documents = await markdownCopies.concurrentMap { $0.markdown() }
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
			let minimumOSVersion: String?

			/**
			The current version, like `1.30.1`.
			*/
			let version: String?

			/**
			The day that the current version was released, like `2026-11-05`.
			*/
			let updated: String?

			let isMenuBarApp: Bool
			let appStoreID: AppStoreID?
			let appStoreURL: URL?
			let setappURL: URL?
			let gumroadURL: URL?
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
				minimumOSVersion: listing.minimumOSVersion?.description,
				version: listing.version,
				updated: listing.currentVersionDate?.description,
				isMenuBarApp: app.frontmatter.isMenuBarApp,
				appStoreID: app.appStoreID,
				appStoreURL: app.appStoreURL,
				setappURL: app.setappURL,
				gumroadURL: app.gumroadURL,
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
	let markdown: @Sendable () -> String
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
	The facts of the app for `llms.txt` and `llms-full.txt`, like “Price: Free. Platforms: macOS, iOS. Get it from: [App Store](https://apps.apple.com/app/id1519522160). Free trial: [download](https://sindresorhus.com/dato#trial). Requires macOS or iOS 26 or later. Free older versions for macOS 15 and 14: [download](https://sindresorhus.com/dato#older-versions).”, as assistants otherwise quote wrong facts from other sites. The stores, the trial, and the older versions are links, so an assistant can give the link without the page, and does not say that the app cannot run on an older macOS version. An app that is in no store is downloaded from its page. The price is left out when it is unknown, like for a paid app when the App Store did not answer.
	*/
	fileprivate var llmsFacts: String {
		func link(_ text: String, _ url: URL) -> String {
			"[\(text)](\(url.absoluteString))"
		}

		var stores = [
			app.appStoreURL.map { link("App Store", $0) },
			app.setappURL.map { link("Setapp", $0) },
			app.gumroadURL.map { link("Gumroad", $0) },
		]
		.compactMap(\.self)

		if
			stores.isEmpty,
			app.ownDownloadURL != nil
		{
			stores.append(link("the app page", app.absoluteURL))
		}

		let olderMacOSVersions = app.olderVersions.map(\.macOS.rawValue).formattedList(.and)

		return [
			priceText.map { "Price: \($0)." },
			"Platforms: \(app.operatingSystems).",
			stores.isEmpty ? nil : "Get it from: \(stores.joined(separator: ", ")).",
			app.trialURL.map { "Free trial: \(link(app.frontmatter.trial?.isTestFlight == true ? "TestFlight" : "download", $0))." },
			requirementSentence.map { "\($0)." },
			app.olderVersions.isEmpty ? nil : "Free older versions for macOS \(olderMacOSVersions): \(link("download", LinkDestination.section(.olderVersions).absoluteURL(on: app.path))).",
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
}

extension App {
	/**
	The link to get the trial: the invitation on TestFlight, or the trial section of the app page. `nil` without a trial.
	*/
	fileprivate var trialURL: URL? {
		frontmatter.trial.map { $0.isTestFlight ? $0.url.value : LinkDestination.section(.trial).absoluteURL(on: path) }
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
	The Markdown with the destinations of its links and images, and the root-relative URLs of its raw HTML, as absolute URLs, as the file is read outside the site. A link to a content file, like `donate.md`, goes to its page.
	*/
	fileprivate func withAbsoluteLinks(_ markdown: String, page: URL, project: Project) -> String {
		let document = Document(parsing: markdown, options: .parseBlockDirectives)
		let replacements = document.linkReplacements { destination in
			let destination = (try? resolvingLink(destination, project: project)) ?? destination
			return URL(string: destination, relativeTo: page)?.absoluteString ?? destination
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
	The Markdown of the page with the sponsors from the frontmatter, where the page shows them, without the syntax of the site. The parsed `@Sponsors` directive places its tiers, so code examples remain literal. A `@Scheduled` block is only its content, and only when the page shows it.

	- Parameter today: The day of the build, which decides what `@Scheduled` shows.
	*/
	fileprivate func fullMarkdown(today: SOML.Date) -> String {
		Document(parsing: file.body, options: .parseBlockDirectives).plainMarkdown(source: file.body, blockDirective: { directive in
			switch directive.siteName {
			case .sponsors:
				let sponsors = frontmatter.sponsorTiers.map(\.markdown).joined(separator: "\n\n")
				return Array(Document(parsing: sponsors).blockChildren)
			case .scheduled:
				// The build already reported invalid arguments.
				return (try? directive.arguments(as: ScheduledArguments.self))?.contains(today) == true ? Array(directive.blockChildren) : []
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
			sponsor.url.map { "- [\(sponsor.name)](\($0.value.absoluteString))" } ?? "- \(sponsor.name)"
		}

		return "## \(title) \(price)\n\n\(sponsors.joined(separator: "\n"))"
	}
}

extension ContentDocument {
	/**
	Frames a document export with its canonical identity, keeping type-specific introductions and bodies at the call site.
	*/
	fileprivate func exportedMarkdown(body: String, introduction: String? = nil, project: Project) -> String {
		let introduction = introduction.map { "\($0)\n\n" } ?? ""
		return "# \(frontmatter.title)\n\n\(introduction)URL: \(absoluteURL.absoluteString)\n\n\(file.withAbsoluteLinks(body, page: absoluteURL, project: project))"
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
