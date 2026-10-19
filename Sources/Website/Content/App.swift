import Foundation
import ImageIO
import Markdown
import RSS
import SiteKit

/**
An app, loaded from `content/apps/<slug>/index.md`.
*/
struct App: ContentDocument {
	let frontmatter: Frontmatter
	let markdown: MarkdownDocument
	let file: MarkdownFile

	/**
	The questions of `content/shared-questions.md` that the app picks, which the build adds to its FAQ section.
	*/
	let sharedQuestions: SharedQuestions

	/**
	Videos (`video*.mp4`) and then screenshots (`screenshot*.png/jpg`) in the page bundle, like `content/apps/<slug>`.
	*/
	let media: [MediaAsset]

	/**
	The `feedbackNote` as HTML, for the feedback page.
	*/
	let feedbackNoteHTML: String?

	/**
	The `icon.png` of the app, or a placeholder when the app has no icon yet, so a new app can be previewed before its icon is done. `website check` warns about the placeholder.
	*/
	let iconPath: RoutePath

	/**
	The icon as a feed enclosure, with its file size. `nil` when the icon is missing, so the placeholder icon is not an enclosure.
	*/
	let iconEnclosure: Enclosure?

	/**
	The accent of the app: the most common vivid color of the icon, like `#1e88e5`, which the app page uses as its accent (``Color/accent``), for ``Page/tint`` and ``Elementary/HTML/tint(_:)``. `nil` for a gray icon.
	*/
	let tint: Color?

	static let directory = "content/apps"

	// The slug is one component of the path of the page and of the asset directory, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	static let sortOrder = [KeyPathComparator(\App.frontmatter.publicationDate, order: .reverse)]

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) async throws {
		self.frontmatter = frontmatter
		self.file = file
		self.sharedQuestions = try SharedQuestions(pickedBy: file, frontmatter: frontmatter, project: project)
		self.markdown = try MarkdownDocument(parsing: file, options: .appPage(file, project: project, frontmatter: frontmatter, sharedQuestions: sharedQuestions))

		for heading in markdown.headings {
			// The FAQ section is found by its ID, so a FAQ heading without it would silently be a plain section.
			if
				heading.level == 2,
				heading.text == Self.faqHeadingTitle,
				heading.id != Self.faqSectionID
			{
				throw ContentError(file: file.url, line: heading.line, reason: "The “\(Self.faqHeadingTitle)” heading needs the ID `\(Self.faqSectionID)`: `## \(Self.faqHeadingTitle) {#\(Self.faqSectionID)}`.")
			}
		}

		// The shared questions are added to the FAQ section, so an app without one would silently not show them.
		if
			!frontmatter.sharedQuestions.isEmpty,
			!markdown.headings.hasFAQSection
		{
			throw ContentError(file: file.url, line: file.line(of: Frontmatter.CodingKeys.sharedQuestions), reason: "The shared questions are added to the FAQ section, but the page has none: `## \(Self.faqHeadingTitle) {#\(Self.faqSectionID)}`.")
		}

		// The app page knows the directive, as the picked questions have it, but a question of the file goes where it is written. The picked questions have no lines, so a heading with a line is in the file.
		if let heading = markdown.headings.first(where: { $0.line != nil && $0.contains(SharedQuestions.First.self) }) {
			throw ContentError(file: file.url, line: heading.line, reason: "`@\(SharedQuestions.First.name)` is only for the questions in `\(SharedQuestions.path)`. A question of the app goes where it is written.")
		}

		// The questions are level 3 headings, so a level 4 heading would silently be a heading in the answer above it.
		if let heading = markdown.headings.faqSection.first(where: { $0.level > 3 }) {
			throw ContentError(file: file.url, line: heading.line, reason: "The questions of the FAQ section are level 3 headings: `### \(heading.text)`.")
		}

		// The note is shown on the feedback page, so its links are resolved and checked like the text of the page. Its problems are reported at its key, as the lines of the SOML value are not the lines of the note.
		let feedbackNote = frontmatter.feedbackNote.map { MarkdownDocument(parsing: $0, options: .content(file, project: project)) }

		if let problems = feedbackNote?.problems, !problems.isEmpty {
			let line = file.line(of: Frontmatter.CodingKeys.feedbackNote)
			throw ContentErrors(problems.map { ContentError(file: file.url, line: line, reason: "`feedbackNote`: \($0.reason)") })
		}

		self.feedbackNoteHTML = feedbackNote?.html

		if
			let script = frontmatter.script,
			project.existingPublicFile(script) == nil
		{
			throw ContentError(file: file.url, line: file.line(of: Frontmatter.CodingKeys.script), reason: "The `script` \(script) does not exist in `public` or next to the page.")
		}

		self.media = try await MediaAsset.discover(in: Self.assetDirectory(slug: file.slug), project: project)

		let icon = project.existingPublicFile(Self.iconPath(slug: file.slug))
		let iconPath = icon == nil ? Self.placeholderIconPath : Self.iconPath(slug: file.slug)
		self.iconPath = iconPath
		self.tint = CGImageSourceCreateWithURL(project.publicFile(iconPath) as CFURL, nil)
			.flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }?
			.accentColor
		let iconSize = icon.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
		self.iconEnclosure = iconSize.map { Enclosure(url: iconPath.absoluteURL, length: $0, mimeType: "image/png") }
	}

	var isDraft: Bool {
		frontmatter.isDraft
	}
}

extension App {
	var redirectURL: URL? {
		frontmatter.redirectURL
	}

	var redirectFrom: [RoutePath] {
		frontmatter.redirectFrom
	}

	var iconURL: URL {
		iconPath.absoluteURL
	}

	/**
	The screenshots, without the videos.
	*/
	var screenshotURLs: [URL] {
		media.filter { $0.kind == .image }.map(\.path.absoluteURL)
	}

	/**
	The directory with the icon, the screenshots, and the videos of an app, like `/dato`. They are files of its page bundle, so they are next to its page.
	*/
	static func assetDirectory(slug: String) -> RoutePath {
		path(slug: slug)
	}

	private static func iconPath(slug: String) -> RoutePath {
		assetDirectory(slug: slug).appending("icon.png")
	}

	static let placeholderIconPath: RoutePath = "/assets/app-icon-placeholder.png"

	var hasPlaceholderIcon: Bool {
		iconPath == Self.placeholderIconPath
	}

	/**
	Where on the site an App Store link is, for its campaign token, like `web-download-button`, so App Analytics shows which links bring downloads.
	*/
	enum AppStorePlacement: String {
		case downloadButton = "download-button"
		case whatsNew = "whats-new"
		case qrCode = "qr-code"

		/**
		The App Store banner in Safari on iOS.
		*/
		case smartBanner = "smart-banner"

		/**
		The provider token and the campaign, or `nil` without the provider token.
		*/
		var campaignQueryItems: [URLQueryItem]? {
			Site.appStoreProviderToken.map { [URLQueryItem(name: "pt", value: $0), URLQueryItem(name: "ct", value: "web-\(rawValue)")] }
		}
	}

	/**
	The App Store link with a campaign token for where on the site it is. Without the provider token, it is the plain link.
	*/
	func appStoreURL(placement: AppStorePlacement) -> URL? {
		guard let campaignQueryItems = placement.campaignQueryItems else {
			return appStoreURL
		}

		return appStoreURL?.appending(queryItems: campaignQueryItems)
	}

	/**
	The App Store link for a QR code, which opens the App Store page on an iPhone. Apple Watch apps are installed from the iPhone too, so they count, unlike for the App Store banner, which is only for apps that run on the device.
	*/
	var qrCodeURL: URL? {
		guard frontmatter.platforms.contains(where: [.iOS, .watchOS, .visionOS].contains) else {
			return nil
		}

		return appStoreURL(placement: .qrCode)
	}

	/**
	The campaign of the App Store banner in Safari on iOS, for the `affiliate-data` of the `apple-itunes-app` meta tag.
	*/
	static var appStoreBannerCampaign: String? {
		AppStorePlacement.smartBanner.campaignQueryItems.flatMap { items in
			var components = URLComponents()
			components.queryItems = items
			return components.percentEncodedQuery
		}
	}

	var appStoreURL: URL? {
		frontmatter.appStoreID?.url
	}

	/**
	The page that sharing the app shares: the App Store page, or the app page for apps that are not on the App Store. `nil` for an archived app, which is no longer available, so its page has no sharing and no QR code.
	*/
	var shareURL: URL? {
		guard !frontmatter.isArchived else {
			return nil
		}

		return appStoreURL ?? path.absoluteURL
	}

	var setappURL: URL? {
		frontmatter.setappID.map { #URL("https://go.setapp.com/stp181").appending(queryItems: [URLQueryItem(name: "refAppID", value: String($0)), URLQueryItem(name: "utm_medium", value: "vendor_program"), URLQueryItem(name: "utm_content", value: "button")]) }
	}

	/**
	The list of older versions in the readme of the repo. Frontmatter with `olderMacOSVersions` needs `repositoryURL`.
	*/
	var olderVersionsURL: URL? {
		frontmatter.repositoryURL.map {
			var components = URLComponents(url: $0, resolvingAgainstBaseURL: true)
			components?.fragment = "download"
			return components?.url ?? $0
		}
	}

	/**
	The release notes page and feed. Archived apps and apps without a releases repo have none.
	*/
	var releaseNotes: ReleaseNotes? {
		guard
			!frontmatter.isArchived,
			let repository = frontmatter.releasesRepository
		else {
			return nil
		}

		return ReleaseNotes(
			repository: repository,
			path: path.appending("release-notes"),
			feed: FeedLink(title: "\(frontmatter.title) Release Notes", path: path.appending("rss.xml"))
		)
	}

	var privacyPolicyPath: RoutePath {
		path.appending("privacy-policy")
	}

	/**
	The feedback form with the app selected.
	*/
	var feedbackURL: LinkDestination {
		Self.feedbackURL(appTitle: frontmatter.title)
	}

	/**
	Where on the site a link to the feedback form is, for the `referrer` that the form sends along, like `Website-FAQ`.
	*/
	enum FeedbackReferrer: String {
		/**
		The feedback question in the FAQ section of an app page.
		*/
		case faq = "Website-FAQ"

		/**
		The list of apps on the feedback page.
		*/
		case appPicker = "Website-Feedback"
	}

	/**
	The feedback form with the app selected, and where the visitor came from.
	*/
	static func feedbackURL(appTitle: String, referrer: FeedbackReferrer? = nil) -> LinkDestination {
		var query = [URLQueryItem(name: "product", value: appTitle)]

		if let referrer {
			query.append(URLQueryItem(name: "referrer", value: referrer.rawValue))
		}

		return .path(.feedback, query: query)
	}

	/**
	For search results and link previews: the custom description, or the subtitle continued by the introduction, shortened to 160 characters.
	*/
	var description: String {
		frontmatter.description ?? [frontmatter.subtitle, markdown.introduction]
			.compactMap(\.self)
			.joined(separator: ". ")
			.shortenedForSnippet
	}

	/**
	The platforms and the requirement, like “Available on macOS, iOS — Requires macOS 15 or later”. The platforms are left out when the requirement already says macOS.
	*/
	var availabilityText: String {
		let requirementMentionsMacOS = frontmatter.requirement?.localizedStandardContains("macOS") == true
		let platformList = requirementMentionsMacOS && frontmatter.platforms == [.macOS] ? nil : "Available on \(operatingSystems)"
		return [platformList, frontmatter.requirement].compactMap(\.self).joined(separator: " — ")
	}

	/**
	When the app page last changed: the last commit of the content file, but never before the app was published.
	*/
	var lastModified: Date {
		max(lastCommitDate ?? frontmatter.publicationDate, frontmatter.publicationDate)
	}

	/**
	Whether the app page shows the App Store banner. Safari shows it on iOS, so only apps that run there get it.
	*/
	var showsAppStoreBanner: Bool {
		!frontmatter.isArchived && frontmatter.platforms.contains { $0 == .iOS || $0 == .visionOS }
	}

	/**
	The price for the app page, like “$4.99, one-time purchase” or “Free”, from the App Store or the `price` frontmatter. A free app that is not on the App Store is “Free” too.
	*/
	func priceText(info: AppStoreInfo?) -> String? {
		info?.priceText(isPaid: frontmatter.isPaid) ?? frontmatter.price?.oneTimePurchaseText ?? (frontmatter.isPaid ? nil : "Free")
	}

	/**
	Whether the page has a trial section (`## Trial {#trial}`), which the download buttons link to.
	*/
	var hasTrial: Bool {
		markdown.headings.contains { $0.id == Self.trialSectionID }
	}

	static let trialSectionID = "trial"

	/**
	The most characters of the introduction, which the hero of the app page shows under the name, so it is at most two lines.
	*/
	static let maximumIntroductionLength = 160

	/**
	Whether the app was published in the last 30 days.
	*/
	func isNew(at date: Date) -> Bool {
		(.zero..<Duration.days(30)).contains(date.duration(since: frontmatter.publicationDate))
	}

	/**
	Whether the app is shown in app lists. Archived apps are still shown in the archive.
	*/
	var isListed: Bool {
		!frontmatter.isUnlisted
	}

	/**
	Whether the app is listed and maintained.
	*/
	var isActive: Bool {
		isListed && !frontmatter.isArchived
	}

	/**
	The macOS versions that have a free older version of the app.
	*/
	var olderMacOSVersions: [MacOSVersion] {
		frontmatter.olderVersions.map(\.macOS) + frontmatter.olderMacOSVersions
	}
}

extension App {
	/**
	Four similar apps: the eight most similar (shared platforms, menu bar, price), shuffled. The shuffle changes daily, but builds on the same day are the same.
	*/
	func relatedApps(from candidates: [App], on date: Date) -> [App] {
		struct Candidate {
			let app: App
			let score: Int
		}

		let similar = candidates
			.filter { $0.slug != slug && !$0.isRedirect }
			.map { candidate in
				var score = candidate.platforms.count(where: frontmatter.platforms.contains) * 3

				if
					candidate.isMenuBarApp,
					frontmatter.isMenuBarApp
				{
					score += 2
				}

				if candidate.isPaid == frontmatter.isPaid {
					score += 1
				}

				return Candidate(app: candidate, score: score)
			}
			.sorted(using: [KeyPathComparator(\.score, order: .reverse), KeyPathComparator(\.app.frontmatter.publicationDate, order: .reverse)])
			.prefix(8)

		var generator = SeededRandomNumberGenerator.daily(slug, on: date)

		return similar
			.shuffled(using: &generator)
			.prefix(4)
			.map(\.app)
	}
}

extension App {
	@Frontmatter
	struct Frontmatter {
		var isDraft = false
		var isUnlisted = false
		var isArchived = false
		@NonEmpty var title: String

		/**
		Has no ending punctuation, because the default description adds a period after it.
		*/
		@NonEmpty var subtitle: String

		/**
		For search results and link previews. Defaults to the subtitle followed by the introduction.
		*/
		@NonEmpty var description: String?

		/**
		When the app was published, at midnight UTC.
		*/
		@CalendarDay var publicationDate: Date

		var platforms: [Platform]
		@Absolute var repositoryURL: URL?
		var appStoreID: AppStoreID?
		@JavaScriptSafe var setappID: Int?
		var isPaid = false
		var isMenuBarApp = false

		/**
		One of the main apps, which the apps page shows first.
		*/
		var isFeatured = false

		/**
		Hand-picked categories, which is only `shortcuts`. The other categories come from fields like `isPaid`.
		*/
		var categories = [AppCategory]()

		/**
		The IDs of the questions in `content/shared-questions.md` that the app has, like `suggested-filenames` for apps that save files. The build adds them to the FAQ section (``App/SharedQuestions``).
		*/
		var sharedQuestions = [String]()

		/**
		Download buttons, in addition to the App Store and Setapp.
		*/
		var mainLinks = OrderedMapping<AbsoluteURL>()

		var links = OrderedMapping<AbsoluteURL>()
		var overflowLinks = OrderedMapping<AbsoluteURL>()
		var showsSupportLink = true

		/**
		Makes the app link to another page, like a GitHub repo, instead of having a page.
		*/
		@Absolute var redirectURL: URL?

		/**
		The GitHub repo in the `sindresorhus` account with the release notes.
		*/
		var releasesRepository: String?

		/**
		Free older versions for older macOS versions, newest first. The app page shows them in an “Older Versions” section.
		*/
		var olderVersions = [OlderVersion]()

		/**
		The macOS versions that have an older version listed elsewhere, like in the readme of the repo (`olderVersionsURL`). Apps with `olderVersions` do not need it.
		*/
		var olderMacOSVersions = [MacOSVersion]()
		@NonEmpty var requirement: String?
		@JavaScriptSafe var downloads: Int?

		/**
		The price in US dollars of a paid app that is not on the App Store, like `20` or `4.99`. App Store apps get their price from the App Store.
		*/
		var price: Price?

		/**
		Markdown shown on the feedback page when the app is selected.
		*/
		var feedbackNote: String?

		/**
		What the app sends to other services, like the text sent to an AI service. The privacy policy shows it instead of saying that no data is collected. Plain text, not Markdown.
		*/
		@NonEmpty var privacyNote: String?

		/**
		Old paths of the app page, like `/old-name`. They redirect to the app page.
		*/
		var redirectFrom = [RoutePath]()

		/**
		A script for the app page, like a demo, as the path of a file in `public` or of the page bundle, like `/googly-eyes/eyes.js`.
		*/
		var script: RoutePath?

		var hasSentry = false
		var pressQuotes = [PressQuote]()
		var announcement: Announcement?

		func validate() throws(ContentError) {
			if
				let last = subtitle.last,
				".!?".contains(last)
			{
				throw ContentError(reason: "`subtitle` must not end with punctuation, because the default description adds a period after it.")
			}

			if platforms.isEmpty {
				throw ContentError(reason: "`platforms` must have at least one platform.")
			}

			// The other categories come from fields, so they would silently do nothing here.
			if categories.contains(where: { $0 != .shortcuts }) {
				throw ContentError(reason: "`categories` can only have `shortcuts`. The other categories come from fields, like `isPaid`, `platforms`, and `isMenuBarApp`.")
			}

			if
				announcement?.linkText != nil,
				announcement?.url == nil
			{
				throw ContentError(reason: "`announcement.linkText` needs `announcement.url`.")
			}

			if
				price != nil,
				appStoreID != nil || !isPaid
			{
				throw ContentError(reason: "`price` is only for paid apps that are not on the App Store. App Store apps get their price from the App Store.")
			}

			if
				!olderVersions.isEmpty,
				!olderMacOSVersions.isEmpty
			{
				throw ContentError(reason: "`olderMacOSVersions` is only for older versions that are listed elsewhere. The macOS versions of `olderVersions` are already known.")
			}

			if
				!olderMacOSVersions.isEmpty,
				repositoryURL == nil
			{
				throw ContentError(reason: "`olderMacOSVersions` needs `repositoryURL`, which has the list of older versions.")
			}

			if Set(olderVersions.map(\.macOS)).count < olderVersions.count {
				throw ContentError(reason: "`olderVersions` must have one version for each macOS version.")
			}
		}
	}

	/**
	A free older version of an app, for users of an older macOS version.
	*/
	@Frontmatter
	struct OlderVersion {
		/**
		The version of the app, like `1.2.0`.
		*/
		@NonEmpty var version: String

		/**
		The oldest macOS version that the app version supports.
		*/
		var macOS: MacOSVersion

		/**
		The download, usually a zip file.
		*/
		@Absolute var url: URL
	}

	@Frontmatter
	struct PressQuote {
		@NonEmpty var quote: String
		@NonEmpty var source: String
		@Absolute var url: URL?
		var isStarRating = false
	}

	@Frontmatter
	struct Announcement {
		/**
		Plain text, not Markdown.
		*/
		@NonEmpty var text: String

		var url: LinkDestination?
		@NonEmpty var linkText: String?
	}
}

extension App {
	/**
	Where the release notes of an app are published.
	*/
	struct ReleaseNotes: Sendable {
		/**
		The GitHub repo in the `sindresorhus` account with the releases.
		*/
		let repository: String

		let path: RoutePath
		let feed: FeedLink

		/**
		The release on the release notes page, which has the version as the ID of its heading.
		*/
		func destination(of release: GitHubRelease) -> LinkDestination {
			.path(path, fragment: release.version)
		}
	}

	/**
	The ID of the feedback question that every FAQ section gets.
	*/
	static let feedbackHeadingID = "feedback"

	/**
	The ID of the menu bar question that the build adds to menu bar apps, which is also the ID of the general question that its answer links to (``LinkDestination/menuBarQuestion``). Its answer only links to the general question, so the feedback page suggests the general question instead.
	*/
	static let addedMenuBarQuestionID = "app-not-showing-in-menu-bar"

	/**
	The ID of the level 2 heading of the FAQ section, which the page, the links, and the feedback page find the section by.
	*/
	static let faqSectionID = "faq"

	/**
	The title of the feedback question that the FAQ of an app gets. A question with this title in the file gets the answer instead.
	*/
	static let feedbackQuestionTitle = "I have a feature request, bug report, or some feedback"

	/**
	The title of the level 2 heading of the FAQ section.
	*/
	static let faqHeadingTitle = "Frequently Asked Questions"
}

extension App {
	/**
	The platforms in the order of ``Platform``, like macOS before iOS, whatever the order of the frontmatter.
	*/
	var platforms: [Platform] {
		Platform.allCases.filter(frontmatter.platforms.contains)
	}

	/**
	The platforms, like “macOS, iOS”.
	*/
	var operatingSystems: String {
		platforms.map(\.rawValue).joined(separator: ", ")
	}
}

extension App.Frontmatter {
	/**
	The Markdown of the app page with what the build adds from the facts of the app: the common questions that apply to it (``CommonQuestion``), the shared questions that it picks, and, unless the app is archived, the feedback question in the FAQ section, and the “Older Versions” section.
	*/
	func addingGeneratedSections(to document: Document, sharedQuestions: App.SharedQuestions) -> Document {
		var blocks = Array(document.blockChildren)
		blocks.addCommonQuestions(CommonQuestion.questions(for: self, sharedQuestions: sharedQuestions))

		// An archived app gets no support, and the feedback page does not list it.
		if !isArchived {
			blocks.addFeedbackQuestion(appTitle: title)
		}

		blocks.addOlderVersions(olderVersions, isPaid: isPaid)
		return Document(blocks)
	}
}

/**
A question that many apps have, like “Can you localize the app into my language?”, or a shared question that an app picks (``App/SharedQuestions``). The build adds it to the FAQ section of each app that it applies to, so the app files do not repeat it. A file that has a question with the same text in its FAQ section keeps its own answer, like one with more details about the app.
*/
private struct CommonQuestion {
	let title: String

	/**
	The question and its answer, as a level 3 heading and the blocks below it, like the questions in the files.
	*/
	let blocks: [any BlockMarkup]

	/**
	Whether the question goes before the questions of the file instead of after them, as visitors with a problem look for it. The feedback question still goes first.
	*/
	var isFirst = false

	/**
	The questions that apply to the app: the menu bar question for menu bar apps, the free question for free apps on the App Store that are not archived, the shared questions that the app picks, and the localization question for all apps.
	*/
	static func questions(for frontmatter: App.Frontmatter, sharedQuestions: App.SharedQuestions) -> [Self] {
		var questions = [Self]()

		if frontmatter.isMenuBarApp {
			questions.append(Self(
				title: "The app does not show up in the menu bar",
				answer: Paragraph(Markdown.Link(destination: LinkDestination.menuBarQuestion.description, Markdown.Text("How to make the app show up in the menu bar"))),
				isFirst: true,
				id: App.addedMenuBarQuestionID
			))
		}

		// The answer asks for a review on the App Store, so archived apps and apps that are not there do not get it.
		if
			!frontmatter.isPaid,
			!frontmatter.isArchived,
			frontmatter.appStoreID != nil
		{
			questions.append(Self(
				title: "Why is this free without ads?",
				answer: Paragraph(Markdown.Text("I just enjoy making apps. Consider leaving a nice review on the App Store."))
			))
		}

		questions += sharedQuestions.questions

		questions.append(Self(
			title: "Can you localize the app into my language?",
			answer: Paragraph(Markdown.Text("I don’t plan to localize the app."))
		))

		return questions
	}
}

extension CommonQuestion {
	/**
	A question with a one-paragraph answer.

	- Parameter id: The ID of the heading, instead of the slug of the title, for a question that code finds.
	*/
	init(title: String, answer: Paragraph, isFirst: Bool = false, id: String? = nil) {
		self.init(
			title: title,
			blocks: [Markdown.Heading(level: 3, Markdown.Text(title + (id.map { " {#\($0)}" } ?? ""))), answer],
			isFirst: isFirst
		)
	}
}

extension App {
	/**
	The questions that an app picks (`sharedQuestions`) from the questions that some apps share, like how to turn off the suggested filenames when saving, in `content/shared-questions.md`. Each question is a level 3 heading, followed by its answer, like in the FAQ of an app, and the answer is Markdown. An app adds a question to its FAQ section with the ID of its heading in `sharedQuestions`, so each heading has a short ID, like `{#suggested-filenames}`. Text before the first question is not shown, so it can explain the file.

	The answers are shown on the app pages, so their links are site paths, like `/apps/faq#refund`, or URLs, not relative links. A mistake in the file is reported for each app that picks a question from it.

	The picked questions go after the questions of the app, but a question with `<!-- @faq.first -->` (``First``) goes before them, like a question about a problem, as visitors with a problem look for it.

	An answer cannot have headings, also not in a block directive, like `@Details`, as the questions are found by their headings, so a heading in an answer is an error.

	Limitation: An answer cannot have inline notes, as their IDs come from their lines, which the added answers do not have, or footnotes, as the parser moves their definitions to the end of the file, which is the last answer.
	*/
	struct SharedQuestions {
		/**
		The path of the file, relative to the root of the project.
		*/
		static let path = "content/shared-questions.md"

		/**
		The question goes before the questions of the app instead of after them, like `<!-- @faq.first -->` below a question about a problem. Only the shared questions have it, as a question of the app goes where it is written.
		*/
		enum First: HeadingDirective {
			static let name = "faq.first"
			typealias Value = HeadingDirectiveFlag
		}

		/**
		The picked questions, in the order of `sharedQuestions`. The file is the source of their Markdown, so they have no lines in the app page.
		*/
		fileprivate let questions: [CommonQuestion]

		/**
		The questions that the app picks. An app that picks none does not read the file. An ID that is not the ID of a question, or that is picked twice, is an error at the `sharedQuestions` key.
		*/
		init(pickedBy file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
			guard !frontmatter.sharedQuestions.isEmpty else {
				self.questions = []
				return
			}

			let questionsByID = try Self.questionsByID(project: project)
			let line = file.line(of: Frontmatter.CodingKeys.sharedQuestions)
			var pickedIDs = Set<String>()

			self.questions = try frontmatter.sharedQuestions.map { id in
				guard let question = questionsByID[id] else {
					throw ContentError(file: file.url, line: line, reason: "`sharedQuestions` has `\(id)`, which is not the ID of a question in `\(Self.path)`.")
				}

				guard pickedIDs.insert(id).inserted else {
					throw ContentError(file: file.url, line: line, reason: "`sharedQuestions` has `\(id)` twice.")
				}

				return question
			}
		}

		/**
		All the questions of the file, by the IDs of their headings.
		*/
		private static func questionsByID(project: Project) throws -> [String: CommonQuestion] {
			let file = try MarkdownFile(url: project.root.appending(path: Self.path))
			var options = MarkdownDocument.Options.content(file, project: project)
			options.headingDirectives.append(First.self)
			let headings = try MarkdownDocument(parsing: file, options: options).headings

			// Each question is a top-level heading and the blocks up to the next one, by the line of the heading.
			var sectionsByLine = [Int: [any BlockMarkup]]()
			var sectionLine: Int?

			for block in Document(parsing: file.body, file: file.url, options: options).blockChildren {
				if block is Markdown.Heading {
					sectionLine = file.line(of: block)
				}

				if let sectionLine {
					sectionsByLine[sectionLine, default: []].append(block)
				}
			}

			var questionsByID = [String: CommonQuestion]()
			var errors = [ContentError]()

			for heading in headings {
				guard heading.level == 3 else {
					errors.append(ContentError(file: file.url, line: heading.line, reason: "The questions are level 3 headings: `### \(heading.text)`."))
					continue
				}

				// A heading in a block directive is not the heading of a question, so it would silently give the questions after it the wrong answers.
				guard
					let line = heading.line,
					let blocks = sectionsByLine[line]
				else {
					errors.append(ContentError(file: file.url, line: heading.line, reason: "An answer cannot have headings, also not in a block directive."))
					continue
				}

				// The IDs are unique, as the parse of the file reports a heading ID that is used twice.
				questionsByID[heading.id] = CommonQuestion(title: heading.text, blocks: blocks, isFirst: heading.contains(First.self))
			}

			guard errors.isEmpty else {
				throw ContentErrors(errors)
			}

			return questionsByID
		}
	}
}

// swift-markdown does not mark its nodes as `Sendable`, but they are immutable values: a node only reads its tree, and a change to a node makes a new tree. The only mutable state is the source ranges, which the parser sets while it parses, before the nodes get here. So the questions can be used on other threads, like the shared questions in the `rewrite` closure of the app page, which must be `@Sendable`. Check this again when swift-markdown is updated.
extension CommonQuestion: @unchecked Sendable {}

extension [any BlockMarkup] {
	/**
	The blocks of the FAQ section of an app page, after its heading. `nil` when the page has no FAQ section.
	*/
	fileprivate var faqSection: Range<Int>? {
		guard let headingIndex = firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			// The custom ID is still in the text, as the IDs are read while rendering.
			return heading.level == 2 && heading.plainText.hasSuffix("{#\(App.faqSectionID)}")
		}) else {
			return nil
		}

		let start = headingIndex + 1
		return start..<(self[start...].firstIndex { (($0 as? Markdown.Heading)?.level ?? 3) <= 2 } ?? endIndex)
	}

	/**
	Where the questions of the FAQ section start: at its first heading, after any text under the FAQ heading.
	*/
	fileprivate func faqQuestionsStart(in section: Range<Int>) -> Int {
		self[section].firstIndex { $0 is Markdown.Heading } ?? section.upperBound
	}

	/**
	Adds the common questions that the FAQ section does not have yet: the first ones before the other questions, and the rest after them.
	*/
	fileprivate mutating func addCommonQuestions(_ questions: [CommonQuestion]) {
		guard let section = faqSection else {
			return
		}

		let questionsStart = faqQuestionsStart(in: section)
		let existingTitles = Set(self[section].compactMap { ($0 as? Markdown.Heading)?.plainText.removingCustomHeadingID })
		let newQuestions = questions.filter { !existingTitles.contains($0.title) }
		// The later position first, so the earlier one stays the same.
		insert(contentsOf: newQuestions.filter { !$0.isFirst }.flatMap(\.blocks), at: section.upperBound)
		insert(contentsOf: newQuestions.filter(\.isFirst).flatMap(\.blocks), at: questionsStart)
	}

	/**
	Adds the feedback question to the FAQ section, or adds the answer to an existing question with the same title.
	*/
	fileprivate mutating func addFeedbackQuestion(appTitle: String) {
		guard let section = faqSection else {
			return
		}

		let answer = Paragraph(
			Markdown.Text("Click the feedback button in the app or "),
			Markdown.Link(destination: App.feedbackURL(appTitle: appTitle, referrer: .faq).absoluteURL.absoluteString, Markdown.Text("send it here."))
		)

		let customID = Markdown.Text(" {#\(App.feedbackHeadingID)}")

		if let questionIndex = self[section].firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 3 && heading.plainText.removingCustomHeadingID == App.feedbackQuestionTitle
		}), let question = self[questionIndex] as? Markdown.Heading {
			// The question gets the feedback ID instead of its own.
			let content = question.inlineChildren.map { child -> any InlineMarkup in
				guard let text = child as? Markdown.Text else {
					return child
				}

				return Markdown.Text(text.string.removingCustomHeadingID)
			}

			self[questionIndex] = Markdown.Heading(level: question.level, content + [customID])

			// After the directives of the question, which must be directly below it.
			let answerIndex = self[(questionIndex + 1)...].firstIndex { !(($0 as? HTMLBlock)?.isOnlyDirectives ?? false) } ?? endIndex
			insert(answer, at: answerIndex)
		} else {
			let question = Markdown.Heading(level: 3, [Markdown.Text(App.feedbackQuestionTitle), customID])
			insert(contentsOf: [question, answer] as [any BlockMarkup], at: faqQuestionsStart(in: section))
		}
	}

	/**
	Adds the “Older Versions” section before the “Non-App Store Version” section, or at the end.
	*/
	fileprivate mutating func addOlderVersions(_ olderVersions: [App.OlderVersion], isPaid: Bool) {
		guard !olderVersions.isEmpty else {
			return
		}

		let nonAppStoreVersionIndex = firstIndex { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 2 && heading.plainText == App.nonAppStoreVersionTitle
		}

		insert(contentsOf: olderVersions.markdownSection(isPaid: isPaid), at: nonAppStoreVersionIndex ?? endIndex)
	}
}

extension [App.OlderVersion] {
	/**
	The “Older Versions” section of an app page.

	The versions of paid apps are free, but they only run on their macOS version, so they do not say “or later” (`+`).
	*/
	func markdownSection(isPaid: Bool) -> [any BlockMarkup] {
		let items = map { olderVersion in
			ListItem(Paragraph(
				Markdown.Link(destination: olderVersion.url.absoluteString, Markdown.Text(olderVersion.version)),
				Markdown.Text(" for macOS \(olderVersion.macOS.rawValue)\(isPaid ? "" : "+")")
			))
		}

		var section: [any BlockMarkup] = [
			Markdown.Heading(level: 2, Markdown.Text("Older Versions")),
			UnorderedList(items),
		]

		if isPaid {
			section.append(Paragraph(Markdown.Text("These are free for everyone but they will not run on newer macOS versions.")))
		}

		return section
	}
}
