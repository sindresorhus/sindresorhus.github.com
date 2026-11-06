import Foundation
import ImageIO
import Markdown
import RSS
import SiteKit
import SOML

/**
An app, loaded from `content/apps/<slug>/index.md`.
*/
struct App: ContentDocument {
	let markdown: MarkdownDocument
	let decodedFile: DecodedMarkdownFile<Frontmatter>
	let purchase: Purchase
	let pressQuotes: [PressQuote.Resolved]

	/**
	The questions of `content/shared-questions.md` that the app picks, which the build adds to its FAQ section.
	*/
	let sharedQuestions: SharedQuestions

	/**
	Videos (`video*.mp4`) and then screenshots (`screenshot*.png/jpg`) in the page bundle, like `content/apps/<slug>`.
	*/
	let media: [MediaAsset]

	/**
	The rendered `feedbackNote`, for the feedback page, which has it in a template, so its links are checked with the links of the page.
	*/
	let feedbackNote: MarkdownDocument?

	/**
	The shared shortcuts that the page links to, in a card (``ShortcutCard``) or in a sentence, whose icons the site publishes.
	*/
	let shortcuts: [Shortcut]

	/**
	The `icon.png` of the app, or a placeholder when the app has no icon yet, so a new app can be previewed before its icon is done. `website check` warns about the placeholder.
	*/
	var iconPath: RoutePath {
		icon?.path ?? Self.placeholderIconPath
	}

	/**
	The icon as a feed enclosure, with its file size. `nil` when the icon is missing, so the placeholder icon is not an enclosure.
	*/
	var iconEnclosure: Enclosure? {
		icon?.enclosure
	}

	/**
	The JPEG XL copy of the icon, when the app has its own icon.
	*/
	var iconJPEGXL: JPEGXLCopy? {
		icon?.jpegXL
	}

	/**
	The accent of the app: the most common vivid color of the icon, like `#1e88e5`, which the app page uses as its accent (``Color/accent``), for ``Page/tint`` and ``Elementary/HTML/tint(_:)``. `nil` for a gray icon.
	*/
	var tint: Color? {
		icon?.tint
	}

	private let icon: Icon?

	/**
	The root frontmatter order follows the declarations, with status first and related facts together. Missing properties stay absent.
	*/
	static var formattingKeys: [any CodingKey] {
		Frontmatter.CodingKeys.allCases
	}

	static let directory: Project.ContentDirectory = "content/apps"

	// The slug is one component of the path of the page and of the asset directory, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	/**
	An app that reads `content/shared-questions.md` itself when it picks shared questions, like in a test. The site reads the file once for all the apps (``init(file:sharedQuestions:project:)``).
	*/
	init(file: DecodedMarkdownFile<Frontmatter>, project: Project) async throws {
		try await self.init(
			file: file,
			sharedQuestions: file.frontmatter.sharedQuestions.isEmpty ? .empty : SharedQuestions.Library(project: project),
			project: project
		)
	}

	/**
	- Parameter sharedQuestions: The questions of `content/shared-questions.md`, which the app picks from.
	- Parameter loadShortcuts: Loads the shared shortcuts that the page links to (``Shortcut``). Without them, like in a test, the links stay links.
	*/
	init(
		file decodedFile: DecodedMarkdownFile<Frontmatter>,
		sharedQuestions library: SharedQuestions.Library,
		project: Project,
		loadShortcuts: (Set<Shortcut.ID>) async -> [Shortcut.ID: Shortcut] = { _ in [:] }
	) async throws {
		let file = decodedFile.source
		let frontmatter = decodedFile.frontmatter
		self.decodedFile = decodedFile

		do {
			self.purchase = try frontmatter.purchase
		} catch {
			throw decodedFile.error(at: .gumroad, error.reason)
		}

		self.pressQuotes = try frontmatter.pressQuotes.enumerated().map { index, quote in
			do throws(ContentError) {
				return try quote.resolved
			} catch {
				throw decodedFile.error(at: .pressQuotes, index: index, error.reason)
			}
		}

		self.sharedQuestions = try SharedQuestions(pickedBy: decodedFile, from: library)

		// The shortcuts are loaded before the text is rendered, as the text shows them as cards.
		let shortcuts = await loadShortcuts(Document(parsing: file.body, options: .parseBlockDirectives).shortcutIDs)
		self.shortcuts = Array(shortcuts.values)

		let options = MarkdownDocument.Options.appPage(
			file,
			project: project,
			frontmatter: frontmatter,
			sharedQuestions: sharedQuestions,
			shortcuts: shortcuts
		)
		let parsed = file.parsedMarkdown(options: options)
		let body = parsed.document

		// Before the text is rendered, as a question below a level 2 heading after the FAQ heading is not in the FAQ section, so the build adds a common question with its title again, and the error of the duplicate ID would name a question that is fine.
		if let heading = Array(body.blockChildren).headingEndingFAQSection(before: frontmatter.commonQuestionTitles(sharedQuestions: sharedQuestions)) {
			throw file.error(line: file.line(of: heading), "`\(heading.format().trimmingCharacters(in: .whitespacesAndNewlines))` ends the FAQ section (`\(Section.faq.markdown)`), so the questions below it are not in it. Make it a question (`###`), or move it above the FAQ section.")
		}

		self.markdown = try parsed.rendered()

		// The mistakes of the text are reported together, so an app with two mistakes shows both at once.
		var problems = [ContentError]()

		if let error = markdown.titleHeadingError(in: file) {
			problems.append(error)
		}

		for heading in markdown.headings {
			// The FAQ section is found by its ID, so a FAQ heading without it would silently be a plain section.
			if
				heading.level == .h2,
				heading.text == Section.faq.title,
				heading.id != Section.faq.id
			{
				problems.append(file.error(line: heading.line, "The “\(Section.faq.title)” heading needs the ID `\(Section.faq.id)`: `\(Section.faq.markdown)`."))
			}
		}

		// The shared questions are added to the FAQ section, so an app without one would silently not show them.
		if
			!frontmatter.sharedQuestions.isEmpty,
			!markdown.headings.hasFAQSection
		{
			problems.append(decodedFile.error(at: .sharedQuestions, "The shared questions are added to the FAQ section, but the page has none: `\(Section.faq.markdown)`."))
		}

		// The app page knows the directive, as the picked questions have it, but a question of the file goes where it is written. The picked questions have no lines, so a heading with a line is in the file.
		if let heading = markdown.headings.first(where: { $0.line != nil && $0.contains(SharedQuestions.First.self) }) {
			problems.append(file.error(line: heading.line, "`@\(SharedQuestions.First.name)` is only for the questions in `\(SharedQuestions.path)`. A question of the app goes where it is written."))
		}

		// The feedback page suggests the questions of the FAQ section and the tips with a custom ID (``tipHeadings``), so the directives of another heading would silently do nothing, and so would platforms that the app is not on. The picked shared questions have no lines.
		let questionLines = Set((markdown.headings.faqSection.filter { $0.level == .h3 } + markdown.headings.tips).compactMap(\.line))

		for heading in markdown.headings {
			guard let line = heading.line else {
				continue
			}

			if questionLines.contains(line) {
				// A question of the app is about the app, so a platform that the app is not on is a mistake.
				if
					let questionPlatforms = heading[FAQDirectives.Platforms.self],
					frontmatter.platforms.isDisjoint(with: questionPlatforms)
				{
					problems.append(file.error(line: line, "`@\(FAQDirectives.Platforms.name)` of “\(heading.text)” has none of the platforms of the app. Use the platforms of the app that the question is about."))
				}
			} else if heading.hasFAQDirective {
				problems.append(file.error(line: line, "“\(heading.text)” is not a question of the FAQ section or a tip with a custom ID, so the feedback page does not suggest it, and its directives, like `@\(FAQDirectives.Keywords.name)`, do nothing. Remove them."))
			}
		}

		// The questions are level 3 headings, so a level 4 heading would silently be a heading in the answer above it.
		if let heading = markdown.headings.faqSection.first(where: { $0.level > .h3 }) {
			problems.append(file.error(line: heading.line, "The questions of the FAQ section are level 3 headings: `### \(heading.text)`."))
		}

		// A question without an answer would be an empty question on the page, like after a new heading was put above the answer of another question. The shared questions have the same rule in their file (``SharedQuestions``), and the questions that the build adds have no lines. The feedback question can be only a heading, as the build writes its answer.
		let sourceHeadings = body.descendants(of: Markdown.Heading.self)

		for heading in markdown.headings.faqSection where heading.level == .h3 && heading.id != Section.feedbackQuestion.id {
			guard
				let line = heading.line,
				let sourceHeading = sourceHeadings.first(where: { file.line(of: $0) == line }),
				let parent = sourceHeading.parent
			else {
				continue
			}

			// A directive below the question, like `<!-- @faq.keywords … -->`, is not an answer.
			let blocks = Array(parent.children)
			let hasAnswer = blocks.contentOfSection(afterHeadingAt: sourceHeading.indexInParent, level: heading.level) { ($0 as? Markdown.Heading)?.headingLevel }
				.contains { !$0.isCommentOnly }

			if !hasAnswer {
				problems.append(file.error(line: line, "The question “\(heading.text)” has no answer. Write it below the heading."))
			}
		}

		// The note is shown on the feedback page, so its links are resolved and checked like the text of the page. Its problems are reported at its key, as the lines of the SOML value are not the lines of the note.
		var feedbackNote: MarkdownDocument?

		if let note = frontmatter.feedbackNote {
			do {
				let document = try MarkdownDocument(parsing: note, at: .feedbackNote, of: decodedFile, project: project)

				// The note is a box on the feedback page, so a heading would be larger than the title of the page, and a whole sentence in the list of headings of a screen reader.
				if let heading = document.headings.first {
					problems.append(decodedFile.error(at: .feedbackNote, "`feedbackNote` cannot have headings, as it is a box on the feedback page. Write a warning as bold text: `**\(heading.text)**`."))
				}

				feedbackNote = document
			} catch {
				problems += error.errors
			}
		}

		if
			let script = frontmatter.script,
			project.existingPublicFile(script) == nil
		{
			problems.append(decodedFile.error(at: .script, "The `script` \(script) does not exist in `public` or next to the page."))
		}

		guard problems.isEmpty else {
			throw ContentErrors(problems)
		}

		self.feedbackNote = feedbackNote

		self.media = try await MediaAsset.discover(in: Self.assetDirectory(slug: file.slug), project: project)

		self.icon = try await Icon(path: Self.iconPath(slug: file.slug), project: project)
	}
}

extension App {
	/**
	The primary purchase source, keeping Gumroad separate from App Store and free app metadata. Setapp and download links remain independent.
	*/
	enum Purchase: Sendable {
		case appStore(AppStoreID, isPaid: Bool)
		case gumroad(Gumroad)
		case other(isPaid: Bool)

		/**
		Whether the app requires a purchase, including an App Store in-app purchase.
		*/
		var isPaid: Bool {
			switch self {
			case .appStore(_, let isPaid), .other(let isPaid):
				isPaid
			case .gumroad:
				true
			}
		}

		/**
		The authored Gumroad product and price, available only for that purchase source.
		*/
		var gumroad: Gumroad? {
			guard case .gumroad(let product) = self else {
				return nil
			}

			return product
		}

		/**
		The App Store identity, available only for that purchase source.
		*/
		var appStoreID: AppStoreID? {
			guard case .appStore(let identifier, _) = self else {
				return nil
			}

			return identifier
		}
	}

	/**
	The validated payment requirement, resolved when the app loads.
	*/
	var isPaid: Bool {
		purchase.isPaid
	}

	/**
	The App Store identity belongs to the resolved purchase source, independently of Setapp and download links.
	*/
	var appStoreID: AppStoreID? {
		purchase.appStoreID
	}
}

extension App.Frontmatter {
	/**
	Resolves the primary purchase source without changing the authored frontmatter shape.
	*/
	var purchase: App.Purchase {
		get throws(ContentError) {
			if let gumroad {
				guard
					appStoreID == nil,
					writtenIsPaid != false
				else {
					throw ContentError(reason: "`gumroad` is only for paid apps that are not on the App Store. App Store apps get their price from the App Store.")
				}

				return .gumroad(gumroad)
			}

			if let appStoreID {
				return .appStore(appStoreID, isPaid: isPaid)
			}

			return .other(isPaid: isPaid)
		}
	}
}

extension App {
	var iconURL: URL {
		iconPath.absoluteURL
	}

	/**
	The JPEG XL copies of the icon and the screenshots, which the build publishes next to them.
	*/
	var jpegXLCopies: [JPEGXLCopy] {
		[iconJPEGXL].compactMap(\.self) + media.compactMap(\.jpegXL)
	}

	/**
	The screenshots, without the videos, like `screenshot1.png`.
	*/
	var screenshots: [ScreenshotAsset] {
		media.compactMap(\.screenshot)
	}

	/**
	The URLs of the screenshots, without the videos.
	*/
	var screenshotURLs: [URL] {
		screenshots.map(\.path.absoluteURL)
	}

	/**
	The directory with the icon, the screenshots, and the videos of an app, like `/dato`. They are files of its page bundle, so they are next to its page.
	*/
	static func assetDirectory(slug: ContentSlug) -> RoutePath {
		path(slug: slug)
	}

	private static func iconPath(slug: ContentSlug) -> RoutePath {
		assetDirectory(slug: slug).appending("icon.png")
	}

	static let placeholderIconPath = #path("/assets/app-icon-placeholder.png")

	var hasPlaceholderIcon: Bool {
		icon == nil
	}

	/**
	Where on the site an App Store link is, for its campaign token, like `web-download-button`, so App Analytics shows which links bring downloads.
	*/
	enum AppStorePlacement: Hashable {
		case downloadButton
		case whatsNew

		/**
		The “Rate or Review” link, which opens the sheet to rate or review the app in the App Store (``queryItems``).
		*/
		case writeReview

		case qrCode

		/**
		The App Store banner in Safari on iOS.
		*/
		case smartBanner

		/**
		The download button in the box to get the app of the guide with the slug (``AppCallToAction``), so App Analytics shows which guide brings downloads.
		*/
		case guide(ContentSlug)

		/**
		The campaign token, like `web-download-button`, or `guide-convert-video-to-gif-mac` for a guide. Apple allows at most 40 characters, so the slug of a guide is cut.

		Limitation: two guides whose slugs start with the same 34 characters have the same campaign.
		*/
		var campaign: String {
			switch self {
			case .downloadButton:
				"web-download-button"
			case .whatsNew:
				"web-whats-new"
			case .writeReview:
				"web-write-review"
			case .qrCode:
				"web-qr-code"
			case .smartBanner:
				"web-smart-banner"
			case .guide(let slug):
				String("guide-\(slug.value)".prefix(40))
			}
		}

		/**
		The provider token and the campaign, or empty without the provider token.
		*/
		var campaignQueryItems: [URLQueryItem] {
			Site.appStoreProviderToken.map { [URLQueryItem(name: "pt", value: $0), URLQueryItem(name: "ct", value: campaign)] } ?? []
		}

		/**
		The query of the App Store link: the campaign, and for ``writeReview``, the action that Apple documents to open the review sheet at once (`action=write-review`).
		*/
		var queryItems: [URLQueryItem] {
			let actionQueryItems = self == .writeReview ? [URLQueryItem(name: "action", value: "write-review")] : []
			return actionQueryItems + campaignQueryItems
		}
	}

	/**
	The App Store link with a campaign token for where on the site it is. Without the provider token, it is the plain link.
	*/
	func appStoreURL(placement: AppStorePlacement) -> URL? {
		appStoreID?.url(placement: placement)
	}

	/**
	The App Store link for a QR code, which opens the App Store page on an iPhone (``Platform/installsFromPhone``).
	*/
	var qrCodeURL: URL? {
		guard frontmatter.platforms.contains(where: \.installsFromPhone) else {
			return nil
		}

		return appStoreURL(placement: .qrCode)
	}

	/**
	The campaign of the App Store banner in Safari on iOS, for the `affiliate-data` of the `apple-itunes-app` meta tag.
	*/
	static var appStoreBannerCampaign: String? {
		AppStorePlacement.smartBanner.campaignQueryItems.nilIfEmpty?.formEncodedQuery
	}

	var appStoreURL: URL? {
		appStoreID?.url
	}

	/**
	The ID of the app in the structured data of its page, like `https://sindresorhus.com/supercharge#app`, so the structured data of another page can refer to it, like a guide (``Schema/Reference``).
	*/
	var structuredDataID: URL {
		LinkDestination.fragment("app").absoluteURL(on: path)
	}

	/**
	The App Store link that opens the sheet to rate or review the app, for the “Rate or Review” links.
	*/
	var reviewURL: URL? {
		appStoreURL(placement: .writeReview)
	}

	/**
	The page that sharing the app shares: the App Store page, or the app page for apps that are not on the App Store. `nil` for an archived app, which is no longer available, so its page has no sharing and no QR code.
	*/
	var sharedPage: SharedPage? {
		guard !frontmatter.isArchived else {
			return nil
		}

		return SharedPage(title: frontmatter.title, url: appStoreURL ?? path.absoluteURL)
	}

	/**
	The Gumroad page of the app, which opens the checkout (`wanted=true`).
	*/
	var gumroadURL: URL? {
		purchase.gumroad.map { $0.id.url.appending(queryItems: [URLQueryItem(name: "wanted", value: "true")]) }
	}

	var setappURL: URL? {
		frontmatter.setappURL
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

		return ReleaseNotes(repository: repository, appPath: path, title: frontmatter.title)
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
	enum FeedbackReferrer: String, CaseIterable {
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
		var query = [URLQueryItem(name: FeedbackPage.Parameters.product.rawValue, value: appTitle)]

		if let referrer {
			query.append(URLQueryItem(name: FeedbackPage.Parameters.referrer.rawValue, value: referrer.rawValue))
		}

		return .path(.feedback, query: query)
	}

	/**
	For search results and link previews: the custom description, which fits a snippet (``SnippetText``), or the introduction, shortened to 160 characters. The title of the page already has the subtitle, so the description does not begin with it.
	*/
	var description: String {
		frontmatter.description ?? (markdown.introduction ?? frontmatter.subtitle).shortenedForSnippet
	}

	/**
	The Sparkle appcast that the app checks for updates, in the GitHub Pages of its releases repo or of the repo of its download, like `https://sindresorhus.com/quickgpt-meta/appcast.xml`, which is the `SUFeedURL` of the app. Only for apps that are not on the App Store, not archived, and not a redirect to a page elsewhere, as the others have none. The pages of a repo are on the domain of the site, so it assumes a repo of Sindre.
	*/
	var appcastURL: URL? {
		guard
			appStoreID == nil,
			!frontmatter.isArchived,
			!isRedirect,
			let repository = frontmatter.releasesRepository ?? frontmatter.gitHubDownload?.repository
		else {
			return nil
		}

		return Site.url.appending(path: "\(repository.name)/appcast.xml")
	}

	/**
	Whether one purchase on the App Store is for the app on the Mac and on iPhone, iPad, or Apple Vision. An app on several platforms with one App Store ID is one app on the App Store, so it is bought once.
	*/
	var isUniversalPurchase: Bool {
		isPaid
			&& appStoreID != nil
			&& platforms.contains(.macOS)
			&& platforms.contains(where: \.hasAppStoreBanner)
	}

	/**
	What the app collects or sends, without the crash reports, as a sentence, for the privacy policy: the `privacyNote`, or that it collects no data.
	*/
	var privacyStatement: String {
		if let privacyNote = frontmatter.privacyNote {
			return privacyNote
		}

		return frontmatter.hasSentry ? "No personal information is collected by this app." : "No data or personal information is collected by this app."
	}

	/**
	The privacy in a few words, for the link to the privacy policy in the hero, like “No data collected”. An app with a `privacyNote` sends some data, which needs the whole sentence, so the link only says that the policy has the details.
	*/
	var privacySummary: String {
		guard frontmatter.privacyNote == nil else {
			return "Privacy details"
		}

		return frontmatter.hasSentry ? "No personal data collected" : "No data collected"
	}

	/**
	Whether the app page shows the App Store banner (``Platform/hasAppStoreBanner``).
	*/
	var showsAppStoreBanner: Bool {
		!frontmatter.isArchived && frontmatter.platforms.contains(where: \.hasAppStoreBanner)
	}

	/**
	Whether the page has a trial section (`trial`), which the download buttons link to. An archived app has no trial.
	*/
	var hasTrial: Bool {
		!frontmatter.isArchived && frontmatter.trial != nil
	}

	/**
	The most characters of the introduction, which the hero of the app page shows under the name, so it is at most two lines.
	*/
	static let maximumIntroductionLength = 160

	/**
	The first OS version that all the platforms share, as Apple gave them the same version numbers from 26, so one `minimumOSVersion` is enough for all of them.
	*/
	static let firstSharedOSVersion = 26

	/**
	How long the app has been available, like “Since 2019”, for an app that is at least two years old, as a sign that it is maintained. A newer app says nothing, as a recent year is not a sign of anything. It is next to the requirement, like “Requires macOS 26 or later”, or “Available on macOS” when the requirement is unknown, so it does not say “available”.
	*/
	func availableSinceText(at date: Date) -> String? {
		guard date.duration(since: frontmatter.publicationDate.foundationDate) >= .days(365 * 2) else {
			return nil
		}

		return "Since \(frontmatter.publicationDate.year)"
	}

	/**
	Whether the app was published in the last 30 days.

	A day in frontmatter is midnight UTC, and the site is often built from a timezone ahead of UTC, which is hours before the publication day starts. The site shows the app at any date, so it is new from the moment the site shows it, not only from its publication day.

	Do not add a lower bound to the range, like `(.zero..<Duration.days(30))`: then an app has no badge for the first hours of its launch day, when the build runs between local midnight and UTC midnight.
	*/
	func isNew(at date: Date) -> Bool {
		date.duration(since: frontmatter.publicationDate.foundationDate) < .days(30)
	}

	/**
	Whether the app is listed and maintained. Archived apps are still shown in the archive.
	*/
	var isActive: Bool {
		isListed && !frontmatter.isArchived
	}

}

extension App {
	/**
	The four most similar apps (shared platforms, menu bar, price). Many apps are equally similar, so a daily shuffle picks among them, not the publication date, which would show the same few newest apps on most pages. The shuffle changes daily, but builds on the same day are the same.
	*/
	func relatedApps(from candidates: [App], on date: Date) -> [App] {
		struct Candidate {
			let app: App
			let score: Int
		}

		var generator = SeededRandomNumberGenerator.daily(slug.value, on: date)

		// The sort is stable, so equally similar apps keep the shuffled order.
		return candidates
			.filter { $0.slug != slug && !$0.isRedirect }
			.shuffled(using: &generator)
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
			.sorted(using: KeyPathComparator(\.score, order: .reverse))
			.prefix(4)
			.map(\.app)
	}
}

extension App {
	@Frontmatter
	struct Frontmatter: PublishedFrontmatter {
		@TrueOrAbsent var isDraft = false
		@TrueOrAbsent var isUnlisted = false
		@TrueOrAbsent var isArchived = false
		@PlainText var title: String

		/**
		Has no ending punctuation, because `llms.txt` and `llms-full.txt` add a period after it.
		*/
		@PlainText var subtitle: String

		/**
		For search results and link previews. Defaults to the introduction, as the title already has the subtitle.
		*/
		@Snippet var description: String?

		/**
		The calendar date when the app was published.
		*/
		var publicationDate: SOML.Date
		static let publicationDateKey = CodingKeys.publicationDate

		var platforms: Set<Platform>

		// TODO: When all apps require version 27, remove the text about Apple silicon Macs from the app pages, like in `any-text`, `memo-widget`, `photo-widget`, `ai-actions`, `amazing-ai`, and `imago`, as macOS 27 only runs on Apple silicon.

		/**
		The lowest OS version that the app runs on, like `'26'` for “Requires macOS 26 or later”, or `'26.1'`. All the platforms have the same version numbers from 26, so one version is enough, and it must be 26 or later. Only for an app whose version the build cannot get (``AppListing/minimumOSVersion``): an app that is not on the App Store and has no appcast, like an iOS app that is not released yet, or an App Store app while the App Store has no version of 26 or later for it, like before it is released. The other apps get it from the App Store or from their appcast, and `website check` warns when they have it.
		*/
		var minimumOSVersion: OSVersion?

		// Compatibility limits, like Menu Bar Spacing not working on macOS 27, are documented in the app page content.

		/**
		Whether the app is paid: `isPaid` when it is written, else whether it is sold on Gumroad (``gumroad``), so a Gumroad app does not need to repeat it.
		*/
		var isPaid: Bool {
			writtenIsPaid ?? (gumroad != nil)
		}

		@Key("isPaid") private var writtenIsPaid: Bool?

		var isMenuBarApp = false
		var appStoreID: AppStoreID?
		var setappID: SetappID?

		/**
		The product of a paid app that is not on the App Store on Gumroad, where it is sold, like `{id: 'shortcutie', price: 10}`. The page gets a “Buy” button and the price. App Store apps get their price from the App Store.
		*/
		var gumroad: Gumroad?

		/**
		A file of the latest release of a GitHub repo, for a free app that is downloaded there. The page gets a “Download” button.
		*/
		var gitHubDownload: GitHubDownload?

		/**
		The public beta of the app on TestFlight, like `https://testflight.apple.com/join/fJGUrsZx`. The page links to it.
		*/
		@Key("testFlightURL") var testFlight: TestFlightInvitation?

		var repositoryURL: AbsoluteURL?

		/**
		The GitHub repo with the release notes, like `sindresorhus/dato-meta`.
		*/
		var releasesRepository: GitHubRepositoryName?

		var downloadCount: SafeInteger?
		var hasSentry = false

		/**
		A script for the app page, like a demo, as the path of a file in `public` or of the page bundle, like `/googly-eyes/eyes.js`.
		*/
		var script: RoutePath?

		/**
		Hand-picked categories, which is only `shortcuts`. The other categories come from fields, like `isPaid`, `platforms`, and `isMenuBarApp`, so the type has no case for them.
		*/
		var categories = [HandPickedCategory]()

		var links = OrderedMapping<AbsoluteURL>()
		var overflowLinks = OrderedMapping<AbsoluteURL>()

		/**
		Makes the app link to another page, like a GitHub repo, instead of having a page.
		*/
		var redirectURL: AbsoluteURL?

		/**
		Old paths of the app page, like `/old-name`. They redirect to the app page.
		*/
		var redirectFrom = [RoutePath]()
		static let redirectFromKey = CodingKeys.redirectFrom

		/**
		The other names that the app sends to the feedback page, like `['Color Picker']`, so the page finds the app. The apps send their name (`CFBundleDisplayName`, or else `CFBundleName`), which can be shorter than the title, like “Color Picker” for “System Color Picker”. The page also finds the app by its title and its slug, so only a name that differs from the title belongs here. A name of another app, its title, slug, or one of its `feedbackNames`, in any case, is an error, as the page would open one app for both.
		*/
		var feedbackNames = [String]()

		/**
		A free version of the app for users that cannot access the App Store, which the build adds as the “Non-App Store Version” section at the end of the page.
		*/
		var nonAppStoreVersion: NonAppStoreVersion?

		/**
		The trial of the app, like `{url: 'https://example.com/App-trial.zip'}`, which the build adds as the “Trial” section before the first level-2 heading of the page, with the standard text of a trial. The “Free Trial” button links to it. An archived app has no trial.
		*/
		var trial: Trial?

		var announcement: Announcement?

		/**
		The IDs of the questions in `content/shared-questions.md` that the app has, like `suggested-filenames` for apps that save files. The build adds them to the FAQ section (``App/SharedQuestions``).
		*/
		var sharedQuestions = [ElementID]()

		/**
		Free older versions for older macOS versions, newest first, which the app page shows in an “Older Versions” section, like `[{version: '1.2.0', macOS: '13', url: '…'}]`.
		*/
		var olderVersions = [OlderVersion]()

		var pressQuotes = [PressQuote]()

		/**
		What the app sends to other services, like the text sent to an AI service. The privacy policy shows it instead of saying that no data is collected. Plain text, not Markdown.
		*/
		@PlainText var privacyNote: String?

		/**
		Markdown shown on the feedback page when the app is selected.
		*/
		var feedbackNote: String?

		func validate(into problems: inout FrontmatterProblems<Self>) {
			validatePublicationDate(into: &problems)

			if
				let last = subtitle.last,
				".!?".contains(last)
			{
				problems.add("`subtitle` must not end with punctuation, because the default description adds a period after it.", at: .subtitle)
			}

			if platforms.isEmpty {
				problems.add("`platforms` must have at least one platform.", at: .platforms)
			}

			do {
				_ = try purchase
			} catch {
				problems.add(error.reason, at: .gumroad)
			}

			problems.validate(pressQuotes, at: .pressQuotes)

			// An article about the app is not older than the app, so an earlier year is likely the year of another article.
			for (index, pressQuote) in pressQuotes.enumerated() {
				if
					let year = pressQuote.year,
					year < publicationDate.year
				{
					problems.add("The quote of \(pressQuote.source) in `pressQuotes` has the year \(year), which is before the app was published in \(publicationDate.year).", at: .pressQuotes, index: index)
				}

				// Like the App Store reviews of a paid app (``AppListing/reviews``), as it would confuse visitors about the price.
				if
					isPaid,
					pressQuote.quote.callsAppFree
				{
					problems.add("The quote of \(pressQuote.source) in `pressQuotes` calls the app free, but the app is paid. Cut those words with `[…]`, or use another quote.", at: .pressQuotes, index: index)
				}
			}
			problems.addRepeatedItems(of: sharedQuestions, at: .sharedQuestions)
			// In any case, as the feedback page finds the app by a name in any case.
			problems.addRepeatedItems(of: feedbackNames.map(\.feedbackLookupKey), at: .feedbackNames)

			if feedbackNames.contains(where: { $0.feedbackLookupKey == title.feedbackLookupKey }) {
				problems.add("`feedbackNames` has the title, which the feedback page already finds the app by.", at: .feedbackNames)
			}

			// The app page lists the older versions in the order of the frontmatter, so a new version at the end would silently break the order.
			let macOSVersions = olderVersions.map(\.macOS)

			if macOSVersions != MacOSVersion.allCases.reversed().filter(macOSVersions.contains) {
				problems.add("`olderVersions` must be newest first, with one version for each macOS version.", at: .olderVersions)
			}

			if
				let minimumOSVersion,
				minimumOSVersion.major < App.firstSharedOSVersion
			{
				problems.add("`minimumOSVersion` must be \(App.firstSharedOSVersion) or later, as the platforms only share their version numbers from \(App.firstSharedOSVersion), got \(minimumOSVersion).", at: .minimumOSVersion)
			}

			// The name is the text of the link in the header, so an empty name gives a link that is not visible and has no name for screen readers.
			for (key, mapping) in [(CodingKeys.links, links), (.overflowLinks, overflowLinks)] {
				for name in mapping.map(\.key) {
					do {
						_ = try PlainTextString(validating: name)
					} catch {
						problems.add("A link in `\(key.stringValue)` needs a name, like `'Website'`, as plain text. The name “\(name)”: \(error.reason)", at: key)
					}
				}
			}

			problems.validate(nonAppStoreVersion, at: .nonAppStoreVersion)
			problems.validate(trial, at: .trial)
			problems.validate(announcement, at: .announcement)

			if
				nonAppStoreVersion != nil,
				appStoreID == nil
			{
				problems.add("`nonAppStoreVersion` is for apps on the App Store, for users that cannot access it.", at: .nonAppStoreVersion)
			}
		}
	}

	/**
	A free version of an app outside the App Store, which does not update by itself.
	*/
	@Frontmatter
	struct NonAppStoreVersion {
		/**
		The version of the app, like `1.2.0`.
		*/
		var version: NonEmptyString

		/**
		The oldest macOS version that the app version supports, like `26`.

		It is an `Int` on purpose, not a ``MacOSVersion`` like in `olderVersions`. The non-App Store version is always for macOS 26 or later, which has whole version numbers, so the frontmatter is a plain number, like `macOS: 26`. Do not change it to `MacOSVersion`.
		*/
		var macOS: Int

		/**
		The download, usually a zip file.
		*/
		var url: AbsoluteURL

		func validate(into problems: inout FrontmatterProblems<Self>) {
			if macOS < App.firstSharedOSVersion {
				problems.add("`nonAppStoreVersion.macOS` must be \(App.firstSharedOSVersion) or later, got \(macOS). An older version goes in `olderVersions`.", at: .macOS)
			}
		}
	}

	/**
	The trial of an app: a zip file, or a link to TestFlight. The build renders its metadata and standard text as the “Trial” section.
	*/
	@Frontmatter
	struct Trial {
		/**
		The download, like a zip file, or the TestFlight link, like `https://testflight.apple.com/join/…`.
		*/
		var url: AbsoluteURL

		/**
		The oldest macOS version that the trial runs on, like `'26'` or `'26.4'`, which the trial shows next to its button. Only for a trial that needs a newer version than the app, like a trial of a version that is not on the App Store yet. Without it, the trial has the requirement of the app, which the hero shows, so the card shows no requirement of its own. `website check` warns when it is the version of the app.
		*/
		var macOS: OSVersion?

		/**
		The features that the trial limits, as a sentence, like `'The keyboard shortcut inspector works 4 times.'`, which the standard text of the trial says instead of “The only limitation is …”, so the trial does not promise more than it gives. Only for a trial that is not on TestFlight, as a TestFlight trial is the full app.
		*/
		@PlainText var limitations: String?

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// A TestFlight link that is not an invitation would silently be a download (``isTestFlight``), with the text and the button of a zip file.
			if
				!isTestFlight,
				url.value.host() == "testflight.apple.com"
			{
				problems.add("`trial.url` is on TestFlight, but it is not a link to join a beta, like `https://testflight.apple.com/join/fJGUrsZx`, so the trial would be a download.", at: .url)
			}

			if
				limitations != nil,
				isTestFlight
			{
				problems.add("`trial.limitations` is only for a trial that is not on TestFlight, as a TestFlight trial is the full app.", at: .limitations)
			}

			// The standard text of the trial goes on with the next sentence after it (``App/Frontmatter/trialText(of:)``).
			if
				let limitations,
				!limitations.hasSuffix(".")
			{
				problems.add("End `trial.limitations` with a period, as the trial text goes on after it.", at: .limitations)
			}
		}

		/**
		Whether the trial is on TestFlight, which has its own text and button title, as it is the full app for a limited time.
		*/
		var isTestFlight: Bool {
			(try? TestFlightInvitation(validating: url.value)) != nil
		}

		/**
		The text of the button of the trial.
		*/
		var buttonTitle: String {
			isTestFlight ? "Try on TestFlight" : "Download Free Trial"
		}

		/**
		The requirement that the trial shows next to its button, like “Requires macOS 26 or later”, or `nil` without `macOS`, as the requirement of the app is in the hero.
		*/
		var requirementSentence: String? {
			macOS.map { $0.macOSRequirementSentence }
		}
	}

	/**
	A file of the latest release of a GitHub repo, like `App.Buddy.zip` of `sindresorhus/app-buddy-meta`.
	*/
	@Frontmatter
	struct GitHubDownload {
		var repository: GitHubRepositoryName
		var file: GitHubReleaseAssetName

		/**
		The link that always downloads the file of the latest release.
		*/
		var url: URL {
			repository.url.appending(path: "releases/latest/download/\(file.value)")
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
		var version: NonEmptyString

		/**
		The oldest macOS version that the app version supports.
		*/
		var macOS: MacOSVersion

		/**
		The download, usually a zip file.
		*/
		var url: AbsoluteURL
	}

	/**
	A product on Gumroad and its price.
	*/
	@Frontmatter
	struct Gumroad {
		/**
		The product, like `shortcutie` in `https://sindresorhus.gumroad.com/l/shortcutie`.
		*/
		var id: GumroadProductID

		/**
		The price in US dollars, like `20` or `4.99`, which the page shows. `website check` warns when Gumroad has another price.
		*/
		var price: Price
	}

	@Frontmatter
	struct PressQuote {
		@PlainText var quote: String

		/**
		The publication or the person, like `MacStories`, without the language of a translated quote (``translatedFrom``).
		*/
		@PlainText var source: String

		var url: AbsoluteURL?
		var isStarRating = false

		/**
		The year of the article, like `2021`, which the source shows.
		*/
		var year: Int?

		/**
		The language of the article, like `German`, when the quote is translated to English.
		*/
		var translatedFrom: Language?

		/**
		The key phrase of a long quote, like `Dato has stuck around because of its flexibility`, which is marked in the quote, so a reader who skims gets the point. It must be in the quote. Use it rarely, as a page with many marks has none that stands out.
		*/
		@PlainText var highlight: String?

		/**
		Whether the quote is a review of a buyer on Gumroad, which is by a person, like a quote without a link, not an article of a site.
		*/
		var isBuyerReview: Bool {
			url?.value.host() == GumroadProduct.storeURL.host()
		}

		/**
		The quote ready for display, with an article's required date carried by its attribution.
		*/
		var resolved: Resolved {
			get throws(ContentError) {
				let attribution: Attribution

				if let url {
					if isBuyerReview {
						attribution = .buyer(source: source, url: url, year: year)
					} else {
						guard let year else {
							throw ContentError(reason: "The quote of \(source) in `pressQuotes` has a `url`, but no `year`. Add the year of the article.")
						}

						attribution = .article(source: source, url: url, year: year)
					}
				} else {
					attribution = .person(source: source, year: year)
				}

				return Resolved(quote: self, attribution: attribution)
			}
		}

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// The real year, not the year of the build, which the tests fix.
			if
				let year,
				!(2000...Date.now.siteYear).contains(year)
			{
				problems.add("`pressQuotes` has the year \(year), which is not the year of an article.", at: .year)
			}

			// A quote copied with its marks would show them twice, as the page adds them.
			if
				let first = quote.first,
				let last = quote.last,
				first.isQuotationMark,
				last.isQuotationMark
			{
				problems.add("The quote of \(source) in `pressQuotes` starts and ends with a quotation mark. Remove them, as the page adds them.", at: .quote)
			}

			// The page shows the language after the year, like “2023 · Translated from German”.
			if
				source.localizedStandardContains("translated")
					|| Language.allCases.contains(where: { source.contains("(\($0.rawValue))") })
			{
				problems.add("The `source` “\(source)” in `pressQuotes` has the language of the article. Remove it, and use `translatedFrom`, like `translatedFrom: 'German'`.", at: .source)
			}

			// A link to an article dates it, so the page can show its year, which many links have too, like `https://9to5mac.com/2020/01/09/plash/`. A link to Gumroad is a review of a buyer, which has no year, like a quote from a person.
			if
				let year,
				let url,
				!isBuyerReview,
				let urlYear = url.value.pathComponents.lazy.compactMap({ Int($0) }).first(where: { (2000...2100).contains($0) }),
				urlYear != year
			{
				problems.add("The quote of \(source) in `pressQuotes` has the year \(year), but its `url` has the year \(urlYear).", at: .year)
			}

			do {
				_ = try resolved
			} catch {
				problems.add(error.reason, at: .url)
			}

			if
				let highlight,
				!quote.contains(highlight)
			{
				problems.add("The `highlight` of the `pressQuotes` quote from \(source) is not in its quote.", at: .highlight)
			}
		}

		/**
		The language of a translated article.
		*/
		enum Language: String, ContentEnum {
			case german = "German"
			case french = "French"
		}

		/**
		An article has a publication year; a buyer or an unlinked person may have one.
		*/
		enum Attribution: Sendable {
			case article(source: String, url: AbsoluteURL, year: Int)
			case buyer(source: String, url: AbsoluteURL, year: Int?)
			case person(source: String, year: Int?)
		}

		/**
		A quote whose source-specific requirements were resolved before rendering.
		*/
		struct Resolved: Sendable {
			let quote: PressQuote
			let attribution: Attribution
		}
	}

	@Frontmatter
	struct Announcement {
		/**
		Plain text, not Markdown.
		*/
		@PlainText var text: String

		var link: Link?

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// The Markdown copy of the page adds a period after the text (``TextFiles``).
			if
				let last = text.last,
				".!?".contains(last)
			{
				problems.add("`announcement.text` must not end with punctuation, because the Markdown copy of the page adds a period after it.", at: .text)
			}
		}

		/**
		The button of an announcement, like `{url: 'https://example.com/bundle', text: 'Get the Bundle'}`.
		*/
		@Frontmatter
		struct Link {
			var url: LinkDestination
			@NonEmpty var text = "Learn More"
		}
	}
}

extension App {
	/**
	Where the release notes of an app are published.
	*/
	struct ReleaseNotes {
		/**
		The GitHub repo with the releases.
		*/
		let repository: GitHubRepositoryName

		let path: RoutePath
		let feed: FeedLink

		/**
		Derives the page and feed from the app’s route so their destinations cannot disagree.
		*/
		init(repository: GitHubRepositoryName, appPath: RoutePath, title: String) {
			self.repository = repository
			self.path = appPath.appending("release-notes")
			self.feed = FeedLink(title: "\(title) Release Notes", path: appPath.appending("rss.xml"))
		}

		/**
		The release on the release notes page, which has the version as the ID of its heading.
		*/
		func destination(of release: GitHubRelease) -> LinkDestination {
			.path(path, fragment: release.version)
		}
	}
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
	The Setapp page of the app, with the referral of the vendor program. The trial of the app page links to it too, so it is on the frontmatter, which the Markdown options have.
	*/
	var setappURL: URL? {
		setappID?.referralURL
	}
}

extension Character {
	/**
	Whether the character is a quotation mark, like `"`, `“`, or `«` (the Unicode property `Quotation_Mark`).
	*/
	fileprivate var isQuotationMark: Bool {
		unicodeScalars.allSatisfy(\.properties.isQuotationMark)
	}
}

/**
The name of one GitHub release asset, preserving spaces and Unicode while rejecting path components.
*/
struct GitHubReleaseAssetName: PlainValidatedValue, Hashable, Sendable {
	let value: String

	init(validating value: String) throws(ContentError) {
		_ = try NonEmptyString(validating: value)

		guard
			!value.contains("/"),
			value != ".",
			value != ".."
		else {
			throw ContentError(reason: "Must be one release asset filename, without slashes or dot segments.")
		}

		self.value = value
	}
}

/**
A public TestFlight invitation, validated before it becomes a link on an app page.
*/
struct TestFlightInvitation: ValidatedValue, Hashable {
	let url: URL

	/**
	Creates an invitation from an HTTPS join link on TestFlight.
	*/
	init(validating url: URL) throws(ContentError) {
		_ = try AbsoluteURL(validating: url)

		guard
			url.scheme == "https",
			url.host() == "testflight.apple.com",
			url.pathComponents.count == 3,
			url.pathComponents[1] == "join"
		else {
			throw ContentError(reason: "Must be a link to join a beta, like `https://testflight.apple.com/join/fJGUrsZx`, got \(url).")
		}

		self.url = url
	}
}

extension App {
	/**
	The icon of the app and the assets derived from it. `nil` when the app has no icon yet, so its page shows the placeholder.
	*/
	private struct Icon: Sendable {
		let path: RoutePath
		let enclosure: Enclosure?
		let jpegXL: JPEGXLCopy?
		let tint: Color?

		/**
		Loads the icon and its derivatives once. A missing icon is `nil`, so a placeholder has no feed enclosure or JPEG XL copy.
		*/
		init?(path: RoutePath, project: Project) async throws {
			guard let file = project.existingPublicFile(path) else {
				return nil
			}

			let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
			self.path = path
			self.enclosure = fileSize.flatMap { Enclosure(url: path.absoluteURL, length: $0, mimeType: "image/png") }
			self.jpegXL = try await JPEGXLCopy(of: path, project: project)
			self.tint = await file.cachedValue(using: .iconAccentColor)
		}
	}
}


extension FileRead where Value == Color?, Failure == Never {
	/**
	The accent derived from the icon, shared by all uses of a version of the image.
	*/
	fileprivate static var iconAccentColor: Self {
		Self("iconAccentColor") { CGImage.read($0)?.accentColor }
	}
}
