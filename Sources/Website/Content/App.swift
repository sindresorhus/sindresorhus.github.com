import Foundation
import RSS
import SiteKit

/**
An app, loaded from `content/apps/<slug>.md`.

Frontmatter values are available directly on the app, like `app.title`.
*/
@dynamicMemberLookup
public struct App: ContentEntry {
	public let slug: String
	public let frontmatter: Frontmatter
	public let markdown: MarkdownDocument

	/**
	When a commit last changed the content file.
	*/
	public let lastCommitDate: Date?

	/**
	The content file, for reporting mistakes at their line.
	*/
	public let file: MarkdownFile

	/**
	Videos (`video*.mp4`) and then screenshots (`screenshot*.png/jpg`) in `public/apps/<slug>`.
	*/
	public let media: [MediaAsset]

	/**
	The `feedbackNote` as HTML, for the feedback page.
	*/
	public let feedbackNoteHTML: String?

	/**
	The icon as a feed enclosure, with its file size. `nil` when the icon is missing.
	*/
	let iconEnclosure: Enclosure?

	/**
	Download buttons: the repo or redirect page as “Learn More”, then the custom links.
	*/
	public internal(set) var mainLinks = [LabeledLink]()

	/**
	The links in the app header: page sections, custom links, and support.
	*/
	public internal(set) var links = [LabeledLink]()

	/**
	The custom overflow links and the “Non-App Store Version” section.
	*/
	public internal(set) var overflowLinks = [LabeledLink]()

	/**
	The overflow links plus the standard pages about the app.
	*/
	public internal(set) var pageOverflowLinks = [LabeledLink]()

	/**
	The places to get the app, in the order they are shown. Archived apps can only be downloaded from their own links.
	*/
	var downloadOptions = [DownloadOption]()

	/**
	The questions of the FAQ section: level 4 headings that are not in a level 3 subsection, except the added feedback question.
	*/
	public internal(set) var faqHeadings = [Heading]()

	public static let directory = "content/apps"

	public static let sortOrder = [KeyPathComparator(\App.frontmatter.publicationDate, order: .reverse)]

	public init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		self.slug = file.slug
		self.frontmatter = frontmatter
		self.lastCommitDate = file.lastCommitDate
		self.file = file
		self.markdown = MarkdownDocument(parsing: file.body, options: .appPage(file, project: project, appTitle: frontmatter.title.value))
		try file.validate(markdown)

		try markdown.checkPlatformDirectives()

		for heading in markdown.headings {
			// The collapsible questions find the section by its ID, and the links by its title, so both must match.
			if
				heading.level == 2,
				heading.text == Self.faqHeadingTitle,
				heading.id != "faq"
			{
				throw FrontmatterError("The “\(Self.faqHeadingTitle)” heading needs the ID `faq`: `## \(Self.faqHeadingTitle) {#faq}`.")
			}
		}

		// The note is shown on the feedback page, so its links are resolved and checked like the text of the page.
		let feedbackNote = frontmatter.feedbackNote.map { MarkdownDocument(parsing: $0, options: .content(file, project: project)) }

		if let problem = feedbackNote?.problems.first {
			throw FrontmatterError("`feedbackNote`: \(problem.message)")
		}

		self.feedbackNoteHTML = feedbackNote?.html

		if
			let script = frontmatter.script,
			!project.publicFile(script.description).isFile
		{
			throw FrontmatterError("The `script` \(script) does not exist in `public`.")
		}

		self.media = try MediaAsset.discover(in: project.publicFile("/apps/\(file.slug)"), publicPath: "/apps/\(file.slug)")

		let iconPath = Self.iconPath(slug: file.slug)
		self.iconEnclosure = (try? project.publicFile(iconPath).resourceValues(forKeys: [.fileSizeKey]).fileSize).map { size in
			Enclosure(url: Site.url.appending(path: iconPath), length: size, mimeType: "image/png")
		}
		computeDerivedData()
	}

	public var isDraft: Bool {
		frontmatter.isDraft
	}

	public subscript<Value>(dynamicMember keyPath: KeyPath<Frontmatter, Value>) -> Value {
		frontmatter[keyPath: keyPath]
	}

	public var title: String {
		frontmatter.title.value
	}

	public var subtitle: String {
		frontmatter.subtitle.value
	}

	public var appStoreID: Int? {
		frontmatter.appStoreID?.value
	}

	public var setappID: Int? {
		frontmatter.setappID?.value
	}

	public var downloads: Int? {
		frontmatter.downloads?.value
	}
}

extension App {
	public var path: RoutePath {
		RoutePath.root.appending(slug)
	}

	/**
	Where links to the app go: the app page, or the external page of a redirect app.
	*/
	public var url: String {
		frontmatter.redirectURL?.absoluteString ?? path.description
	}

	public var isRedirect: Bool {
		frontmatter.redirectURL != nil
	}

	public var iconPath: String {
		Self.iconPath(slug: slug)
	}

	public var iconURL: URL {
		Site.url.appending(path: iconPath)
	}

	/**
	The screenshots, without the videos.
	*/
	public var screenshotURLs: [URL] {
		media.filter { $0.kind == .image }.map { Site.url.appending(path: $0.path) }
	}

	/**
	The absolute URL of the app page, or of the external page of a redirect app.
	*/
	public var absoluteURL: URL {
		self.redirectURL?.url ?? path.absoluteURL(site: Site.url)
	}

	private static func iconPath(slug: String) -> String {
		"/apps/\(slug)/icon.png"
	}

	/**
	The App Store link with a campaign token for where on the site it is, like `web-download-button`, so App Analytics shows which links bring downloads. Without the provider token, it is the plain link.
	*/
	public func appStoreURL(placement: String) -> URL? {
		guard
			let appStoreURL,
			let providerToken = Site.appStoreProviderToken
		else {
			return appStoreURL
		}

		return appStoreURL.appending(queryItems: [URLQueryItem(name: "pt", value: providerToken), URLQueryItem(name: "ct", value: "web-\(placement)")])
	}

	/**
	The campaign of the App Store banner in Safari on iOS, for the `affiliate-data` of the `apple-itunes-app` meta tag.
	*/
	var appStoreBannerCampaign: String? {
		Site.appStoreProviderToken.map { "pt=\($0)&ct=web-smart-banner" }
	}

	public var appStoreURL: URL? {
		appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") }
	}

	public var setappURL: URL? {
		setappID.flatMap { URL(string: "https://go.setapp.com/stp181?refAppID=\($0)&utm_medium=vendor_program&utm_content=button") }
	}

	public var olderVersionsURL: String {
		frontmatter.repositoryURL.map { "\($0.absoluteString)#download" } ?? path.fragment("older-versions")
	}

	/**
	The release notes page and feed. Archived apps and apps without a releases repo have none.
	*/
	public var releaseNotes: ReleaseNotes? {
		guard
			!frontmatter.isArchived,
			let repository = frontmatter.releasesRepository
		else {
			return nil
		}

		return ReleaseNotes(
			repository: repository,
			path: path.appending("release-notes"),
			feed: PageMetadata.Feed(title: "\(frontmatter.title.value) Release Notes", path: path.appending("rss.xml"))
		)
	}

	public var privacyPolicyPath: RoutePath {
		path.appending("privacy-policy")
	}

	/**
	The feedback form with the app selected.
	*/
	public var feedbackPath: String {
		Self.feedbackPath(appTitle: frontmatter.title.value)
	}

	static func feedbackPath(appTitle: String) -> String {
		"/feedback?product=\(appTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? appTitle)"
	}

	/**
	For search results and link previews: the custom description, or the subtitle continued by the introduction, shortened to 160 characters.
	*/
	public var description: String {
		frontmatter.description?.value ?? [frontmatter.subtitle.value, markdown.introduction]
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
	Whether the app was published in the last 30 days.
	*/
	public func isNew(at date: Date) -> Bool {
		date.timeIntervalSince(frontmatter.publicationDate) < 30 * 24 * 60 * 60
	}

	/**
	Whether the app is shown in app lists. Archived apps are still shown in the archive.
	*/
	public var isListed: Bool {
		!frontmatter.isUnlisted
	}

	/**
	Whether the app is listed and maintained.
	*/
	public var isActive: Bool {
		isListed && !frontmatter.isArchived
	}
}

extension App {
	/**
	Three similar apps: the eight most similar (shared platforms, menu bar, price), shuffled. The shuffle changes daily, but builds on the same day are the same.
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
			.prefix(3)
			.map(\.app)
	}
}

extension App {
	@Frontmatter
	public struct Frontmatter {
		@Key("draft")
		public var isDraft: Bool = false
		public var isUnlisted: Bool = false
		public var isArchived: Bool = false
		public var title: NonEmptyString

		/**
		Has no ending punctuation, because the default description adds a period after it.
		*/
		public var subtitle: NonEmptyString

		/**
		For search results and link previews. Defaults to the subtitle followed by the introduction.
		*/
		public var description: NonEmptyString?

		@Key("pubDate")
		public var publicationDate: Date
		public var platforms: [Platform]
		@Key("repoUrl")
		public var repositoryURL: AbsoluteURL?
		@Key("appStoreId")
		public var appStoreID: SafeInteger?
		@Key("setappId")
		public var setappID: SafeInteger?
		public var isPaid: Bool = false
		public var isMenuBarApp: Bool = false

		/**
		Hand-picked categories, like `shortcuts`. The other categories come from fields like `isPaid`.
		*/
		public var categories = [AppCategory]()

		/**
		Download buttons, in addition to the App Store and Setapp.
		*/
		public var mainLinks = OrderedMapping<AbsoluteURL>()

		public var links = OrderedMapping<AbsoluteURL>()
		public var overflowLinks = OrderedMapping<AbsoluteURL>()
		@Key("showSupportLink")
		public var showsSupportLink: Bool = true

		/**
		Makes the app link to another page, like a GitHub repo, instead of having a page.
		*/
		@Key("redirectUrl")
		public var redirectURL: AbsoluteURL?

		/**
		The GitHub repo in the `sindresorhus` account with the release notes.
		*/
		@Key("releasesRepo")
		public var releasesRepository: String?

		public var olderMacOSVersions = [MacOSVersion]()
		public var requirement: String?
		public var downloads: SafeInteger?

		/**
		Markdown shown on the feedback page when the app is selected.
		*/
		public var feedbackNote: String?

		/**
		Old paths of the app page, like `/old-name`. They redirect to the app page.
		*/
		public var redirectFrom = [RoutePath]()

		/**
		A script for the app page, like a demo, as a path in `public`.
		*/
		public var script: RoutePath?

		public var hasSentry: Bool = false
		public var pressQuotes = [PressQuote]()
		public var announcement: Announcement?

		public func validate() throws(FrontmatterError) {
			if let last = subtitle.value.last, ".!?".contains(last) {
				throw FrontmatterError("`subtitle` must not end with punctuation, because the default description adds a period after it.")
			}

			if announcement?.text.isEmpty == true {
				throw FrontmatterError("`announcement.text` must not be empty.")
			}

			if platforms.isEmpty {
				throw FrontmatterError("`platforms` must have at least one platform.")
			}

			if requirement?.allSatisfy(\.isWhitespace) == true {
				throw FrontmatterError("`requirement` must not be empty.")
			}

			if
				announcement?.urlText != nil,
				announcement?.url == nil
			{
				throw FrontmatterError("`announcement.urlText` needs `announcement.url`.")
			}
		}
	}

	@Frontmatter
	public struct PressQuote {
		public var quote: NonEmptyString
		public var source: NonEmptyString
		public var url: AbsoluteURL?
		public var isStarRating: Bool = false
	}

	@Frontmatter
	public struct Announcement {
		/**
		Inline Markdown.
		*/
		public var text: String

		public var url: LinkDestination?
		public var urlText: String?
	}
}

extension App {
	/**
	Where the release notes of an app are published.
	*/
	public struct ReleaseNotes: Sendable {
		/**
		The GitHub repo in the `sindresorhus` account with the releases.
		*/
		public let repository: String

		public let path: RoutePath
		let feed: PageMetadata.Feed
	}

	/**
	The ID of the feedback question that every FAQ section gets.
	*/
	static let feedbackHeadingID = "feedback"

	/**
	The title of the level 2 heading of the FAQ section.
	*/
	static let faqHeadingTitle = "Frequently Asked Questions"
}

extension MarkdownDocument {
	/**
	Throws for an unknown platform in a `<!-- @faq.platforms … -->` comment, which would otherwise be left out without a message, so the question would show for every platform.
	*/
	func checkPlatformDirectives() throws {
		for heading in headings {
			for name in heading.directives["faq.platforms"] where Platform(rawValue: name) == nil {
				throw FrontmatterError("Unknown platform “\(name)” in the `@faq.platforms` comment of “\(heading.text)”.")
			}
		}
	}
}
