import Foundation
import Markdown
import SiteKit
import SOML

/**
A short how-to for a task, like “How to Convert a Video to a GIF on Mac”, loaded from `content/guides/<slug>.md`. It names the app for the task and the built-in way. The guides are not posts, so they are not in the blog or its feed, and they have a feed of their own (``SiteFeed/newGuides``).
*/
struct Guide: ContentDocument {
	let markdown: MarkdownDocument
	let decodedFile: DecodedMarkdownFile<Frontmatter>

	static let directory: Project.ContentDirectory = "content/guides"

	// The slug is one component of the path of the page, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	static let sortOrder = [KeyPathComparator(\Guide.frontmatter.title, comparator: .localizedStandard)]

	static let pageRoute = RoutePath.guides

	/**
	The title without “How to”, like “Convert a Video to a GIF on Mac”, for a list whose title or label already says that the items are guides, like “More Guides”, the lists of guides (``ArticleRow``), the suggestions of the feedback page, and the name of a “Guide” tag (``task(slug:project:)``). The page of the guide shows the full title.
	*/
	var task: String {
		frontmatter.task
	}

	/**
	Whether the guide is about the app on the iPhone only, so the box to get the app names only the platforms of the iPhone and the Apple Watch, like “iOS 26 or later”, and leaves out a trial that is a download, as that is the Mac app. A guide about the iPhone whose title names the Mac, like “How to Lock Your Mac from iPhone”, needs the app on the Mac too.
	*/
	var isAboutIPhoneOnly: Bool {
		(frontmatter.topic == .iPhone || frontmatter.titleNames("iPhone")) && !frontmatter.titleNamesMac
	}

	/**
	The ``task`` of the guide with the slug, from the frontmatter of its file, like “Find Screenshots on Mac” for `find-screenshots-mac`, so a “Guide” tag is named with it while the documents load, before the guides are loaded (``SiteKit/MarkdownDocument/LinkTag``). `nil` for a guide that does not exist or whose frontmatter has a mistake, which the build reports.
	*/
	static func task(slug: String, project: Project) -> String? {
		guard
			let slug = try? ContentSlug(validating: slug),
			let file = sourceFile(for: slug, in: project)
		else {
			return nil
		}

		return (try? MarkdownFile(url: file).decodeFrontmatter(as: Frontmatter.self))?.task
	}

	/**
	The root frontmatter order follows the declarations, with the draft flag first, like in apps and posts. Missing properties stay absent.
	*/
	static var formattingKeys: [Frontmatter.CodingKeys] {
		Frontmatter.CodingKeys.allCases
	}

	init(file decodedFile: DecodedMarkdownFile<Frontmatter>, project: Project) throws {
		try self.init(file: decodedFile, project: project, appIconCopies: [:])
	}

	/**
	- Parameter appIconCopies: The JPEG XL copies of the icons of the apps (``App/iconJPEGXLCopies(project:)``), for the icons before the links to the app pages. Without them, like in a test, the icons are only PNG.
	*/
	init(file decodedFile: DecodedMarkdownFile<Frontmatter>, project: Project, appIconCopies: [RoutePath: JPEGXLCopy]) throws {
		let file = decodedFile.source
		let frontmatter = decodedFile.frontmatter
		self.decodedFile = decodedFile
		// The byline and the box to get the app already show the apps of the guide, so their links get no icon, but the headings of their sections do, like “With Dato”.
		var options = MarkdownDocument.Options.content(file, project: project)
		options.addAppLinkIcons(project: project, iconCopies: appIconCopies, excluding: Set(frontmatter.apps.map { App.path(slug: $0) }))
		options.addAppHeadingIcons(project: project, iconCopies: appIconCopies, apps: frontmatter.apps)
		// Each section has a link that copies its URL, like on app pages, so a reader can send “Without an app”.
		options.addsHeadingAnchors = true
		self.markdown = try MarkdownDocument(parsing: file, options: options)

		// A draft is not published, so it can be written in any order, but its frontmatter is still checked.
		let errors = frontmatter.isDraft ? [] : shapeErrors()

		guard errors.isEmpty else {
			throw ContentErrors(errors)
		}
	}

	/**
	The mistakes in the shape that every guide has: it starts with the short answer (`@QuickAnswer`), it has the steps (`@Steps`), and it has an honest “Without an app” section (a level 2 heading) with text, so the app box that the page shows before it does not stand alone. The text has no level 1 heading, as the page shows the title as one. The link of the short answer to the first app is checked when the apps are loaded (``quickAnswerLinkError(to:)``).
	*/
	func shapeErrors() -> [ContentError] {
		var errors = [ContentError]()

		if quickAnswerLines == nil {
			errors.append(file.error(line: file.bodyStartLine, "A guide starts with the short answer: `@QuickAnswer { … }`."))
		}

		if !markdown.blocks.contains(where: { $0.siteDirectiveName == .steps }) {
			errors.append(file.error(line: file.bodyStartLine, "A guide needs the steps of the task: `@Steps { 1. … }`."))
		}

		if let error = markdown.titleHeadingError(in: file) {
			errors.append(error)
		}

		if let heading = withoutAppHeading {
			// The blocks of the section, with its subsections, until the next section. A heading is not text, and HTML, like a comment, is a note for the author.
			let sectionBlocks = markdown.blocks.firstIndex { $0.kind == .heading(level: heading.level, id: heading.id) }.map { index in
				markdown.blocks.contentOfSection(afterHeadingAt: index, level: heading.level) { $0.headingLevel }
			} ?? []

			let hasText = sectionBlocks.contains { block in
				switch block.kind {
				case .heading:
					false
				// A comment renders as nothing, but other raw HTML, like a table, is text.
				case .html:
					!block.isEmpty
				default:
					true
				}
			}

			if !hasText {
				errors.append(file.error(line: heading.line, "The section “\(Self.withoutAppTitle)” is empty. Write the built-in way below its heading."))
			}
		} else if let heading = markdown.headings.first(where: { $0.level == .h2 && $0.text.lowercased() == Self.withoutAppTitle.lowercased() }) {
			// Like the title case of the titles, like `## Without An App`.
			errors.append(file.error(line: heading.line, "Write the heading as `## \(Self.withoutAppTitle)`."))
		} else {
			errors.append(file.error(line: file.bodyStartLine, "A guide needs the built-in way, in a section with the heading `## \(Self.withoutAppTitle)`."))
		}

		return errors
	}

	/**
	The lines of the short answer (`@QuickAnswer`), which is the first block. HTML blocks, like comments, which are notes for the author, can come before it. `nil` when the guide does not start with it.
	*/
	private var quickAnswerLines: ClosedRange<SiteKit.SourceLocation.Line>? {
		guard
			let quickAnswer = markdown.blocks.first(where: { $0.kind != .html }),
			quickAnswer.siteDirectiveName == .quickAnswer,
			case .directive(_, let lines?) = quickAnswer.kind
		else {
			return nil
		}

		return lines
	}

	/**
	The short answer (`@QuickAnswer`) must link to the first app of `apps`, which the page names. The loader checks it with the loaded apps (``SiteContent``), so it is checked only for an app that exists, as the message would else ask to change a link that can be right.
	*/
	func quickAnswerLinkError(to app: App) -> ContentError? {
		guard
			!frontmatter.isDraft,
			let lines = quickAnswerLines,
			!markdown.links.contains(where: { link in
				guard
					link.otherFile == nil,
					let line = link.line,
					lines.contains(line)
				else {
					return false
				}

				return (try? LinkDestination(validating: link.destination))?.sitePath == app.path
			})
		else {
			return nil
		}

		return file.error(line: lines.lowerBound, "The `@QuickAnswer` must link to `\(app.slug)`, the first app of `apps`: `[…](/\(app.slug))`.")
	}

	/**
	The heading of the section with the built-in way, which every guide has.
	*/
	static let withoutAppTitle = "Without an app"

	/**
	The heading of the section with the built-in way (``withoutAppTitle``), so the shape check and the page, which shows the app before it, find the same heading. Every guide has it (``shapeErrors``).
	*/
	var withoutAppHeading: SiteKit.Heading? {
		markdown.headings.first { $0.level == .h2 && $0.text == Self.withoutAppTitle }
	}
}

extension Guide {
	@Frontmatter
	struct Frontmatter: PublishedFrontmatter {
		/**
		A draft is not published, and neither are the files of its page bundle.
		*/
		@TrueOrAbsent var isDraft = false

		@PlainText var title: String

		/**
		The short answer, for the list of guides and search results.
		*/
		@Snippet var description: String

		/**
		The calendar date when the guide was published.
		*/
		var publicationDate: SOML.Date
		static let publicationDateKey = CodingKeys.publicationDate

		/**
		The topic of the guide, like `menu-bar`, which groups it on the list of guides.
		*/
		var topic: Topic

		/**
		Whether the guide is about a habit from Windows, like the Delete key that deletes a file, so the page “Mac Guides for Windows Users” lists it too (``Audience/windowsUsers``). The guide stays in its topic.
		*/
		@TrueOrAbsent var isForWindowsUsers = false

		/**
		Whether the guide is about a setting that most people change on a new Mac, like showing hidden files, so the page “Settings to Change on a New Mac” lists it too (``Audience/newMacOwners``). The guide stays in its topic.
		*/
		@TrueOrAbsent var isForNewMacOwners = false

		/**
		The built-in keyboard shortcut that does the task of the guide, like `Shift+Command+.` for showing hidden files, so the page “Mac Keyboard Shortcuts” lists it in its table (``Audience/keyboardShortcuts``). Only for a guide whose built-in way is this one shortcut. The keys have the names and the order of a shortcut in the text, like `++Shift+Command+.++`.
		*/
		@NonEmpty var shortcut: String?

		/**
		The slugs of the apps that the guide is about, like `gifski`. The first one is the app that the page links back to.
		*/
		var apps: [ContentSlug]

		/**
		Old paths of the guide, like `/guides/old-name`. They redirect to the guide.
		*/
		var redirectFrom = [RoutePath]()
		static let redirectFromKey = CodingKeys.redirectFrom

		/**
		The screenshot of the first app that shows the result, like the date in the menu bar, which the page shows after the steps of the app.
		*/
		var screenshot: Screenshot?

		var proseTexts: [ProseText] {
			[
				(title, [CodingKeys.title]),
				(description, [CodingKeys.description]),
				(screenshot?.description, [CodingKeys.screenshot, Screenshot.CodingKeys.description]),
			]
		}

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// The page shows its date next to the link back to the first app, so without an app it would have no date.
			if apps.isEmpty {
				problems.add("A guide needs `apps`, the slugs of the apps that it is about, like `apps: ['gifski']`.", at: .apps)
			}

			problems.addRepeatedItems(of: apps, at: .apps)

			// Usually from a copied frontmatter, like on a guide about the iPhone.
			if !titleNamesMac {
				for audience in Audience.allCases where audience.includes(self) {
					problems.add("The page “\(audience.title)” lists this guide, so its title must say “Mac”.", at: audience.frontmatterKey)
				}
			}

			// The rules of a shortcut in the text, like the names of the keys on the keyboard of a Mac and the order of Apple.
			if let shortcut {
				for problem in MarkdownDocument(parsing: "++\(shortcut)++", options: .site).problems {
					problems.add(problem.reason, at: .shortcut)
				}
			}

			problems.validate(screenshot, at: .screenshot)
			validatePublicationDate(into: &problems)
		}

		/**
		The title without “How to” (``Guide/task``).
		*/
		var task: String {
			String(title.trimmingPrefix("How to "))
		}

		/**
		Whether the title has the word “Mac”, like “How to Lock Your Mac from iPhone”.
		*/
		var titleNamesMac: Bool {
			titleNames("Mac")
		}

		/**
		Whether the title contains the given name as a whole word.
		*/
		func titleNames(_ name: String) -> Bool {
			title.split(whereSeparator: { !$0.isLetter }).contains(name[...])
		}
	}

	/**
	The topic of a guide, which groups it on the list of guides (``GuidesPage``), in the order of the cases. The raw value is the value in the frontmatter, like `topic: 'menu-bar'`, and the ID of its section. A fixed list, unlike free tags, so the topics stay few.
	*/
	enum Topic: String, ContentEnum {
		case menuBar = "menu-bar"
		case finderAndDesktop = "finder-and-desktop"
		case keyboardAndTrackpad = "keyboard-and-trackpad"
		case windowsAppsAndDock = "windows-apps-and-dock"
		case textAndImages = "text-and-images"
		case audioAndVideo = "audio-and-video"
		case browsersLinksAndEmail = "browsers-links-and-email"
		case internetAndNetwork = "internet-and-network"
		case shortcuts
		case lockScreenAndHomeScreen = "lock-screen-and-home-screen"
		case iPhone = "iphone"
		case mac

		/**
		The ID of the section of the topic on the list of guides, which the chips of the list point to.
		*/
		var id: ElementID {
			ElementID(rawValue)
		}

		/**
		The path of the page of the topic (``GuideTopicPage``), like `/guides/menu-bar`.
		*/
		var path: RoutePath {
			RoutePath.guides.appending(rawValue)
		}

		/**
		The name of the guides of the topic, which is the title of its page, and the end of a link to the page with the number of guides, like “All 25 Mac Menu Bar Guides”. With “Mac” where the topic is about the Mac, as a search is often for it.
		*/
		var guidesTitle: String {
			switch self {
			case .menuBar:
				"Mac Menu Bar Guides"
			case .finderAndDesktop:
				"Mac Finder and Desktop Guides"
			case .keyboardAndTrackpad:
				"Mac Keyboard and Trackpad Guides"
			case .windowsAppsAndDock:
				"Mac Window, App, and Dock Guides"
			case .textAndImages:
				"Mac Text and Image Guides"
			case .audioAndVideo:
				"Mac Audio and Video Guides"
			case .browsersLinksAndEmail:
				"Browser, Link, and Email Guides"
			case .internetAndNetwork:
				"Mac Internet and Network Guides"
			case .shortcuts:
				"Shortcuts App Guides"
			case .lockScreenAndHomeScreen:
				"Lock Screen and Home Screen Guides"
			case .iPhone:
				"iPhone and Apple Watch Guides"
			case .mac:
				"Other Mac Guides"
			}
		}

		/**
		What the guides of the topic do, with a few of their tasks, like “Add a calendar, a to-do, and apps to the menu bar of your Mac, group or space its icons, or hide the menu bar.”, for the description of the page of the topic (``GuideTopicPage``), which the social card shows below the title, so it does not repeat the title.
		*/
		var summary: String {
			switch self {
			case .menuBar:
				"Add a calendar, a to-do, and apps to the menu bar of your Mac, group or space its icons, or hide the menu bar."
			case .finderAndDesktop:
				"Copy file paths, cut and paste files, create new files, and do more with files and folders in Finder."
			case .keyboardAndTrackpad:
				"Open apps with keyboard shortcuts, find the mouse pointer, and middle-click on a trackpad."
			case .windowsAppsAndDock:
				"Maximize windows, make the close button quit an app, hide the Dock, and open several apps at once."
			case .textAndImages:
				"Paste without formatting, copy text from images, pick colors from the screen, and change where screenshots go."
			case .audioAndVideo:
				"Record audio and calls, transcribe recordings to text, convert videos to GIFs, and test your microphone."
			case .browsersLinksAndEmail:
				"Change the default browser, open links in a specific browser or profile, and remove tracking from links."
			case .internetAndNetwork:
				"Check your internet speed and connection, flush the DNS cache, and see when your internet drops."
			case .shortcuts:
				"Check the state of your device and filter lists in Shortcuts on iPhone and Mac, and press keyboard shortcuts on Mac."
			case .lockScreenAndHomeScreen:
				"Put text, to-dos, contacts, and apps on the Lock Screen and the Home Screen of your iPhone."
			case .iPhone:
				"Combine videos, scan QR codes, make a tally counter, and put a grocery list on your Apple Watch."
			case .mac:
				"Keep your Mac awake, get reminders to take a break, find week numbers, and do more on your Mac."
			}
		}

		/**
		The text of a link to the page of the topic, with the number of its guides, like “All 25 Mac Menu Bar Guides”.
		*/
		func allGuidesTitle(count: Int) -> String {
			"All \(count.formatted(.siteNumber)) \(guidesTitle)"
		}

		var title: String {
			switch self {
			case .menuBar:
				"Menu Bar"
			case .finderAndDesktop:
				"Finder and Desktop"
			case .keyboardAndTrackpad:
				"Keyboard and Trackpad"
			case .windowsAppsAndDock:
				"Windows, Apps, and Dock"
			case .textAndImages:
				"Text and Images"
			case .audioAndVideo:
				"Audio and Video"
			case .browsersLinksAndEmail:
				"Browsers, Links, and Email"
			case .internetAndNetwork:
				"Internet and Network"
			case .shortcuts:
				"Shortcuts"
			case .lockScreenAndHomeScreen:
				"Lock Screen and Home Screen"
			case .iPhone:
				"iPhone and Apple Watch"
			case .mac:
				"More for the Mac"
			}
		}
	}

	/**
	The people that a list of guides is for, besides the topics, like the people who come from Windows, or the people who look for the built-in keyboard shortcuts. Each has a page with its guides (``AudienceGuidesPage``), and a guide is on it by its frontmatter, like `isForWindowsUsers: true` or a `shortcut`. The guides stay in their topics.
	*/
	enum Audience: CaseIterable {
		case windowsUsers
		case newMacOwners
		case keyboardShortcuts

		/**
		The key of the frontmatter that puts a guide on the page: a flag, or the shortcut of the guide.
		*/
		var frontmatterKey: Frontmatter.CodingKeys {
			switch self {
			case .windowsUsers:
				.isForWindowsUsers
			case .newMacOwners:
				.isForNewMacOwners
			case .keyboardShortcuts:
				.shortcut
			}
		}

		/**
		Whether the page lists the guide, by its key (``frontmatterKey``).
		*/
		func includes(_ frontmatter: Frontmatter) -> Bool {
			switch self {
			case .windowsUsers:
				frontmatter.isForWindowsUsers
			case .newMacOwners:
				frontmatter.isForNewMacOwners
			case .keyboardShortcuts:
				frontmatter.shortcut != nil
			}
		}

		/**
		The path of the page, like `/guides/from-windows`.
		*/
		var path: RoutePath {
			switch self {
			case .windowsUsers:
				#path("/guides/from-windows")
			case .newMacOwners:
				#path("/guides/new-mac")
			case .keyboardShortcuts:
				#path("/guides/keyboard-shortcuts")
			}
		}

		/**
		The title of the page.
		*/
		var title: String {
			switch self {
			case .windowsUsers:
				"Mac Guides for Windows Users"
			case .newMacOwners:
				"Settings to Change on a New Mac"
			case .keyboardShortcuts:
				"Mac Keyboard Shortcuts"
			}
		}

		/**
		The text of the chip on the list of guides (``GuidesPage``), which links to the page.
		*/
		var chipTitle: String {
			switch self {
			case .windowsUsers:
				"For Windows Users"
			case .newMacOwners:
				"New Mac Settings"
			case .keyboardShortcuts:
				"Keyboard Shortcuts"
			}
		}

		/**
		The text of the link to the page at the end of a guide on it (``GuidePage``), like “All 25 Mac Menu Bar Guides” next to it, so a reader from a search finds the other guides for the same situation.
		*/
		var linkTitle: String {
			switch self {
			case .windowsUsers:
				"All Guides for Windows Users"
			case .newMacOwners:
				"All New Mac Settings"
			case .keyboardShortcuts:
				"All Mac Keyboard Shortcuts"
			}
		}

		/**
		Whether the table above the guides has a row for each guide (``introTable(guides:)``), like the shortcuts, so the page shows the guides only in the table, not twice.
		*/
		var tableHasEachGuide: Bool {
			switch self {
			case .windowsUsers, .newMacOwners:
				false
			case .keyboardShortcuts:
				true
			}
		}

		/**
		The page that the end of the page links to, or `nil` for none. A person who comes from Windows has a new Mac, so the guides for Windows users end with the settings to change on a new Mac. The page for a new Mac does not link back, as most people with a new Mac did not come from Windows.
		*/
		var next: Self? {
			switch self {
			case .windowsUsers:
				.newMacOwners
			case .newMacOwners, .keyboardShortcuts:
				nil
			}
		}

		/**
		The introduction below the title of the page, which is also its description for search results.
		*/
		var intro: String {
			switch self {
			case .windowsUsers:
				"New on the Mac? These short guides show how to do the things that you did on Windows, like cut and paste files, with an app for the task and the built-in way."
			case .newMacOwners:
				"Got a new Mac? These short guides show the settings that most people change first, like showing hidden files, with the built-in way and an app for the task."
			case .keyboardShortcuts:
				"The built-in keyboard shortcuts of the Mac that the guides show, each with its task. Each guide also shows an app that does more."
			}
		}

		/**
		The Markdown of a table above the guides of the page, or `nil` for none. A guide in a row is a tag or a link by its slug, like `<guide:cut-and-paste-files-mac>`, which the page resolves (``AudienceGuidesPage``).

		For people who come from Windows, it has the names on a Mac of the things that they know, like Finder for File Explorer, as the guides use the names of the Mac, from the guide of Apple for people who switched from Windows and the keyboard shortcuts of Apple. A row with a guide about the same habit has its tag. The keys of Windows are text, as the keys of the site are the keys of a Mac.

		For the keyboard shortcuts, it has the shortcut and the task of each guide (`shortcut`), so the page is a list of the shortcuts to look up.

		- Parameter guides: The guides of the page.
		*/
		func introTable(guides: [Guide.Resolved]) -> String? {
			switch self {
			case .windowsUsers:
				func tagIfPublished(_ slug: ContentSlug) -> String {
					guides.contains { $0.guide.slug == slug } ? " <guide:\(slug)>" : ""
				}

				return """
				## The Mac Words for What You Know

				The names of the same things on a Mac, from [Apple’s guide for people who switched from Windows](https://support.apple.com/guide/imac/apdd88fdad7a/mac) and [Apple’s keyboard shortcuts](https://support.apple.com/102650).

				| On Windows | On a Mac |
				| --- | --- |
				| File Explorer | Finder\(tagIfPublished("open-finder-shortcut-mac")) |
				| Control Panel | System Settings |
				| Start menu | The Dock |
				| Snipping Tool | The Screenshot app (++Shift+Command+5++) <guide:screenshot-save-and-copy-mac> |
				| Right-click | Secondary click: hold ++Control++ and click |
				| Ctrl in shortcuts, like Ctrl+C | ++Command++, like ++Command+C++ |
				| Alt | ++Option++ |
				| Enter | ++Return++ <guide:open-files-with-enter-finder-mac> |
				| Backspace | ++Delete++, and ++Fn+Delete++ to delete forward <guide:backspace-go-back-mac> |
				| Ctrl+X to cut a file | Copy with ++Command+C++, then move with ++Option+Command+V++ <guide:cut-and-paste-files-mac> |
				| Delete to delete a file | ++Command+Delete++ moves it to the Trash <guide:delete-files-delete-key-mac> |
				| Ctrl+Alt+Delete to force quit | ++Option+Command+Esc++\(tagIfPublished("force-quit-app-mac")) |
				"""
			case .newMacOwners:
				return nil
			case .keyboardShortcuts:
				// By task, so a visitor finds a task in the alphabet.
				let shortcutRows = guides.sorted(using: KeyPathComparator(\.guide.task, comparator: .localizedStandard)).compactMap { resolved -> String? in
					guard let shortcut = resolved.guide.frontmatter.shortcut else {
						return nil
					}

					return "| ++\(shortcut)++ | [\(resolved.guide.task)](guide:\(resolved.guide.slug)) |"
				}

				return """
				## The Shortcuts

				| Shortcut | Task |
				| --- | --- |
				\(shortcutRows.joined(separator: "\n"))
				"""
			}
		}
	}

	/**
	A screenshot of the first app of a guide, like `screenshot: {number: 1, description: 'The date and the week number in the menu bar'}`.
	*/
	@Frontmatter
	struct Screenshot {
		/**
		The number in the file name of the screenshot of the app, like `2` for `screenshot2.png`, not its position on the app page, so the guide keeps its image when another screenshot of the app is removed.
		*/
		var number: Number

		/**
		What the screenshot shows, for screen readers (the `alt` text).
		*/
		@PlainText var description: String

		/**
		A positive screenshot file number, retained after decoding so a guide cannot select zero or a negative number. This is a file number, not an index in the carousel.
		*/
		struct Number: PlainValidatedValue, Hashable, Sendable, CustomStringConvertible, Encodable {
			let value: Int

			/**
			Creates a screenshot selection from its one-based file number.
			*/
			init(validating value: Int) throws(ContentError) {
				guard value >= 1 else {
					throw ContentError(reason: "`screenshot.number` starts at 1, like `1` for the first screenshot of the app, got \(value).")
				}

				self.value = value
			}

			var description: String {
				String(value)
			}
		}
	}

	/**
	The screenshot of the frontmatter (`screenshot`), from the screenshots of the first app of the guide: the file with the number in its name, like `screenshot2.jpg` for `number: 2` (``ScreenshotAsset/number``). A screenshot without a number in its name, like `screenshot.jpg`, has no number. `nil` when the guide has none, or the app has no screenshot file with that number, which the loader reports (``SiteContent``).
	*/
	func screenshot(of app: App) -> ScreenshotAsset? {
		guard let number = frontmatter.screenshot?.number else {
			return nil
		}

		// By the name of the file, not its position, so a removed screenshot does not silently move the guide to the next image.
		return app.screenshots.first { $0.number == number.value }
	}
}

extension Guide {
	/**
	A guide with its app references and screenshot resolved at the content-loading boundary. Pages only accept this complete value.
	*/
	struct Resolved {
		let guide: Guide
		let app: App
		let apps: [App]

		/**
		The content around the required built-in section, resolved once before a page can render it.
		*/
		let parts: (before: MarkdownContent, after: MarkdownContent)

		/**
		The ID of the heading of the built-in section (``Guide/withoutAppHeading``), where ``parts`` are split.
		*/
		let withoutAppHeadingID: ElementID

		let screenshot: (asset: ScreenshotAsset, description: String)?

		/**
		Resolves the required first app and optional screenshot. The loader reports reference mistakes before constructing the published content.
		*/
		init?(guide: Guide, apps: [App]) {
			// Preserve every resolved association in authored order, including secondary apps.
			guard
				apps.map(\.slug) == guide.apps,
				let app = apps.first,
				let headingID = guide.withoutAppHeading?.id,
				let parts = guide.markdown.contentSeparated(beforeHeading: headingID)
			else {
				return nil
			}

			self.guide = guide
			self.app = app
			self.apps = apps
			self.parts = parts
			self.withoutAppHeadingID = headingID

			if let screenshot = guide.frontmatter.screenshot {
				guard let asset = guide.screenshot(of: app) else {
					return nil
				}

				self.screenshot = (asset, screenshot.description)
			} else {
				self.screenshot = nil
			}
		}
	}
}
