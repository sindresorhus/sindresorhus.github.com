import Foundation
import ImageIO
import RSS
import SiteKit

/**
An app, loaded from `content/apps/<slug>/index.md`.

Frontmatter values are available directly on the app, like `app.title`.
*/
@dynamicMemberLookup
struct App: ContentDocument {
	let frontmatter: Frontmatter
	let markdown: MarkdownDocument
	let file: MarkdownFile

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
	The icon as a feed enclosure, with its file size. `nil` when the icon is missing.
	*/
	let iconEnclosure: Enclosure?

	/**
	The most common vivid color of the icon, like `#1e88e5`, which the app page uses as its accent (``Color/accent``). `nil` for a gray icon.
	*/
	let accentColor: String?

	/**
	The accent of the app (``accentColor``) as a color, for ``Page/tint`` and ``Elementary/HTML/tint(_:)``.
	*/
	var tint: Color? {
		accentColor.map { Color($0) }
	}

	static let directory = "content/apps"

	// The slug is one component of the path of the page and of the asset directory, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	static let sortOrder = [KeyPathComparator(\App.frontmatter.publicationDate, order: .reverse)]

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) async throws {
		self.frontmatter = frontmatter
		self.file = file
		self.markdown = try MarkdownDocument(parsing: file, options: .appPage(file, project: project, frontmatter: frontmatter))

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

		// The questions are level 3 headings, so a level 4 heading would silently be a heading in the answer above it.
		if
			let faqIndex = markdown.headings.firstIndex(where: { $0.level == 2 && $0.id == Self.faqSectionID }),
			let heading = markdown.headings[(faqIndex + 1)...].prefix(while: { $0.level > 2 }).first(where: { $0.level > 3 })
		{
			throw ContentError(file: file.url, line: heading.line, reason: "The questions of the FAQ section are level 3 headings: `### \(heading.text)`.")
		}

		// The note is shown on the feedback page, so its links are resolved and checked like the text of the page. Its problems are reported at its key, as the lines of the SOML value are not the lines of the note.
		let feedbackNote = frontmatter.feedbackNote.map { MarkdownDocument(parsing: $0, options: .content(file, project: project)) }

		if let problems = feedbackNote?.problems, !problems.isEmpty {
			let line = file.line(ofFrontmatterKey: "feedbackNote")
			throw ContentErrors(problems.map { ContentError(file: file.url, line: line, reason: "`feedbackNote`: \($0.message)") })
		}

		self.feedbackNoteHTML = feedbackNote?.html

		if
			let script = frontmatter.script,
			!project.publicFile(script).isFile
		{
			throw ContentError(file: file.url, line: file.line(ofFrontmatterKey: "script"), reason: "The `script` \(script) does not exist in `public`.")
		}

		self.media = try await MediaAsset.discover(in: Self.assetDirectory(slug: file.slug), project: project)

		let iconPath = project.publicFile(Self.iconPath(slug: file.slug)).isFile ? Self.iconPath(slug: file.slug) : Self.placeholderIconPath
		self.iconPath = iconPath
		self.accentColor = CGImageSourceCreateWithURL(project.publicFile(iconPath) as CFURL, nil)
			.flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }?
			.accentColor
		self.iconEnclosure = (try? project.publicFile(iconPath).resourceValues(forKeys: [.fileSizeKey]).fileSize).map { size in
			Enclosure(url: iconPath.absoluteURL, length: size, mimeType: "image/png")
		}
	}

	var isDraft: Bool {
		frontmatter.isDraft
	}

	subscript<Value>(dynamicMember keyPath: KeyPath<Frontmatter, Value>) -> Value {
		frontmatter[keyPath: keyPath]
	}

	var title: String {
		frontmatter.title
	}

	var subtitle: String {
		frontmatter.subtitle
	}

	var appStoreID: AppStoreID? {
		frontmatter.appStoreID
	}

	var setappID: Int? {
		frontmatter.setappID
	}

	var downloads: Int? {
		frontmatter.downloads
	}
}

extension App {
	static func path(slug: String) -> RoutePath {
		RoutePath.root.appending(slug)
	}

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
	The directory with the icon, the screenshots, and the videos of an app, like `/apps/dato`.
	*/
	static func assetDirectory(slug: String) -> RoutePath {
		RoutePath.apps.appending(slug)
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
	var appStoreBannerCampaign: String? {
		AppStorePlacement.smartBanner.campaignQueryItems.flatMap { items in
			var components = URLComponents()
			components.queryItems = items
			return components.percentEncodedQuery
		}
	}

	var appStoreURL: URL? {
		appStoreID?.url
	}

	/**
	The page that sharing the app shares: the App Store page, or the app page for apps that are not on the App Store or are archived, as the page has no App Store download for them.
	*/
	var shareURL: URL {
		frontmatter.isArchived ? path.absoluteURL : (appStoreURL ?? path.absoluteURL)
	}

	var setappURL: URL? {
		setappID.map { #URL("https://go.setapp.com/stp181").appending(queryItems: [URLQueryItem(name: "refAppID", value: String($0)), URLQueryItem(name: "utm_medium", value: "vendor_program"), URLQueryItem(name: "utm_content", value: "button")]) }
	}

	/**
	The list of older versions in the readme of the repo. Frontmatter with `olderMacOSVersions` needs `repositoryURL`.
	*/
	var olderVersionsURL: URL? {
		frontmatter.repositoryURL.map { URL(string: "\($0.absoluteString)#download") ?? $0 }
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
	The feedback form with the app selected, and where the visitor came from, like `Website-FAQ`.
	*/
	static func feedbackURL(appTitle: String, referrer: String? = nil) -> LinkDestination {
		var query = [URLQueryItem(name: "product", value: appTitle)]

		if let referrer {
			query.append(URLQueryItem(name: "referrer", value: referrer))
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
	var availabilityText: String? {
		let requirementMentionsMacOS = frontmatter.requirement?.localizedStandardContains("macOS") == true
		let platformList = requirementMentionsMacOS && frontmatter.platforms == [.macOS] || frontmatter.platforms.isEmpty ? nil : "Available on \(operatingSystems)"
		let parts = [platformList, frontmatter.requirement].compactMap(\.self).filter { !$0.isEmpty }
		return parts.isEmpty ? nil : parts.joined(separator: " — ")
	}

	/**
	When the app was published, at midnight UTC.
	*/
	var publicationDate: Date {
		frontmatter.publicationDate
	}

	/**
	When the app page last changed: the last commit of the content file, but never before the app was published.
	*/
	var lastModified: Date {
		max(lastCommitDate ?? publicationDate, publicationDate)
	}

	/**
	Whether the app page shows the App Store banner. Safari shows it on iOS, so only apps that run there get it.
	*/
	var showsAppStoreBanner: Bool {
		!frontmatter.isArchived && frontmatter.platforms.contains { $0 == .iOS || $0 == .visionOS }
	}

	/**
	The price for the app page, like “$4.99, one-time purchase” or “Free”, from the App Store or the `price` frontmatter.
	*/
	func priceText(info: AppStoreInfo?) -> String? {
		info?.priceText(isPaid: frontmatter.isPaid) ?? frontmatter.price?.oneTimePurchaseText
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
		date.duration(since: publicationDate) < .days(30)
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
			let publicationDate: Date
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

				return Candidate(app: candidate, score: score, publicationDate: candidate.publicationDate)
			}
			.sorted(using: [KeyPathComparator(\.score, order: .reverse), KeyPathComparator(\.publicationDate, order: .reverse)])
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
		Hand-picked categories, like `shortcuts`. The other categories come from fields like `isPaid`.
		*/
		var categories = [AppCategory]()

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
		var requirement: String?
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
		A script for the app page, like a demo, as a path in `public`.
		*/
		var script: RoutePath?

		var hasSentry = false
		var pressQuotes = [PressQuote]()
		var announcement: Announcement?

		func validate() throws(ContentError) {
			if let last = subtitle.last, ".!?".contains(last) {
				throw ContentError(reason: "`subtitle` must not end with punctuation, because the default description adds a period after it.")
			}

			if announcement?.text.isEmpty == true {
				throw ContentError(reason: "`announcement.text` must not be empty.")
			}

			if platforms.isEmpty {
				throw ContentError(reason: "`platforms` must have at least one platform.")
			}

			if requirement?.allSatisfy(\.isWhitespace) == true {
				throw ContentError(reason: "`requirement` must not be empty.")
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
		var text: String

		var url: LinkDestination?
		var linkText: String?
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
	The schema.org category. Mac apps are utilities.
	*/
	var schemaCategory: String {
		self.platforms.contains(.macOS) ? "UtilitiesApplication" : "MobileApplication"
	}

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
		self.platforms.map(\.rawValue).joined(separator: ", ")
	}
}
