import Foundation
import SiteKit
import SOML

/**
Everything the pages are rendered from: the content and the data fetched from the App Store, GitHub, npm, and Bluesky.

It is loaded once, before any page renders, so rendering is synchronous and cannot fail because of the network.
*/
public struct SiteContent: Sendable {
	/**
	All apps, including unlisted and archived ones, newest first.
	*/
	let apps: [App]

	/**
	All blog posts, including unlisted ones, newest first.
	*/
	let posts: [BlogPost]

	/**
	The how-to guides, by title.
	*/
	let guides: [Guide]

	let pages: [MarkdownPage]

	/**
	The content files that are published at their path: the apps, the blog posts, the guides, and the pages.
	*/
	let documents: [any ContentDocument]

	/**
	The content files by the path of their page (``document(at:)``).
	*/
	private let documentsByPath: [RoutePath: any ContentDocument]

	/**
	The questions that some apps share (`content/shared-questions.md`), read once, like for the checks of `website check`.
	*/
	let sharedQuestions: App.SharedQuestions.Library

	/**
	The values of the whole site that are content, from `content/site.soml`.
	*/
	let settings: SiteSettings

	/**
	The main apps of `featuredApps` in ``settings``, in the order of the file. The apps page shows them in an order that changes every day (``dailyFeaturedApps``).
	*/
	let featuredApps: [App]

	/**
	The guides with their required primary app and optional screenshot resolved, in the order of the guides.
	*/
	let resolvedGuides: [Guide.Resolved]

	/**
	The data fetched for the apps. Pages read it as the listing of an app (``listing(of:)``), so nothing else looks it up by a key.
	*/
	private var appData: AppData

	private(set) var recentRepositories: [GitHubRepository]

	/**
	The repos with the most stars, for the about page. Empty when the request failed.
	*/
	private(set) var popularRepositories: [GitHubRepository]

	/**
	The numbers of the GitHub account and the organizations of its projects (``GitHub/owners``), like the repos and the stars, for the about page, and their repos, for the new npm packages of the now page. `nil` when a request failed.
	*/
	private(set) var gitHubAccount: GitHub.Account?

	private(set) var npmStatistics: NPMStatistics

	/**
	What Sindre did lately on Bluesky and GitHub, for the now page.
	*/
	private(set) var recentActivity: RecentActivity

	/**
	The GitHub contributions of each year since 2010, oldest first, for the career quilt. Empty without a GitHub token, or when a request failed.
	*/
	private(set) var contributionYears: [ContributionYear]

	/**
	When the site is built. Everything that depends on the date uses it, like the “new” badge and the daily related apps, so one build is consistent.
	*/
	let buildDate: Date

	/**
	The project the content is from, like for reading public files.
	*/
	let project: Project

	/**
	Problems that do not fail the build, like an App Store request that failed.
	*/
	private(set) var warnings: [Warning]

	init(
		apps: [App],
		posts: [BlogPost],
		guides: [Guide] = [],
		pages: [MarkdownPage],
		sharedQuestions: App.SharedQuestions.Library = .empty,
		settings: SiteSettings = SiteSettings(),
		featuredApps: [App] = [],
		resolvedGuides: [Guide.Resolved] = [],
		appData: AppData = .none,
		recentRepositories: [GitHubRepository] = [],
		popularRepositories: [GitHubRepository] = [],
		gitHubAccount: GitHub.Account? = nil,
		npmStatistics: NPMStatistics = NPMStatistics(),
		recentActivity: RecentActivity = RecentActivity(),
		contributionYears: [ContributionYear] = [],
		buildDate: Date,
		project: Project,
		warnings: [Warning] = []
	) {
		self.apps = apps
		self.posts = posts
		self.guides = guides
		self.pages = pages
		self.documents = apps + posts + guides + pages
		// The loader rejects two pages with the same path (``duplicatePathErrors(in:project:)``), so the first is the only one.
		self.documentsByPath = Dictionary(documents.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
		self.sharedQuestions = sharedQuestions
		self.settings = settings
		// References are resolved while their diagnostics are collected, not silently filtered here.
		self.featuredApps = featuredApps
		self.resolvedGuides = resolvedGuides
		self.appData = appData
		self.recentRepositories = recentRepositories
		self.popularRepositories = popularRepositories
		self.gitHubAccount = gitHubAccount
		self.npmStatistics = npmStatistics
		self.recentActivity = recentActivity
		self.contributionYears = contributionYears
		self.buildDate = buildDate
		self.project = project
		self.warnings = warnings
	}

	/**
	Loads the content, and the data from the App Store, GitHub, npm, and Bluesky. Content mistakes are thrown together, as ``ContentErrors``.
	*/
	public static func load(from project: Project, externalData: ExternalData, buildDate: Date = .now) async throws -> Self {
		let warnings = WarningCollector()
		let lastCommitDates = await project.lastCommitDates()

		// Git does not say why it failed, so a repository without dates is a warning, but a project that is not a repository, like in a test, has no dates on purpose.
		if
			lastCommitDates.isEmpty,
			project.root.appending(path: ".git").exists
		{
			warnings.add(Warning(.missingCommitDates, "Could not read the dates of the last commits with git, so the sitemap and the update dates of posts use other dates."))
		}

		// The mistakes of all content types are reported together, so a part with mistakes is `nil`, and its mistakes are thrown after the other parts are loaded.
		func loading<Value>(_ load: () throws(ContentErrors) -> Value) -> (value: Value?, errors: [ContentError]) {
			do {
				return (try load(), [])
			} catch {
				return (nil, error.errors)
			}
		}

		func entries<Entry: ContentEntry>(
			_ type: Entry.Type,
			making makeEntry: @escaping @Sendable (MarkdownFile, Entry.Frontmatter) async throws -> Entry = { file, frontmatter in
				try await Entry(file: file, frontmatter: frontmatter, project: project)
			}
		) async -> ContentLoad<Entry> {
			await Entry.load(from: project, lastCommitDates: lastCommitDates, making: makeEntry)
		}

		// Read once for all the apps, so a mistake in the file is reported once, at its line. The apps are not loaded without it, as each app that picks a question would report it again.
		let (sharedQuestions, sharedQuestionsErrors) = loading { () throws(ContentErrors) in
			try App.SharedQuestions.Library(project: project)
		}

		func loadApps() async -> ContentLoad<App> {
			guard let sharedQuestions else {
				return .unavailable(ContentErrors(sharedQuestionsErrors))
			}

			return await entries(App.self) { file, frontmatter in
				try await App(file: file, frontmatter: frontmatter, sharedQuestions: sharedQuestions, project: project)
			}
		}

		async let loadingApps = loadApps()
		async let loadingPosts = entries(BlogPost.self)
		async let loadingGuides = entries(Guide.self)
		async let loadingPages = entries(MarkdownPage.self)
		let (loadedApps, loadedPosts, loadedGuides, loadedPages) = await (loadingApps, loadingPosts, loadingGuides, loadingPages)

		let (settingsFile, settingsErrors) = loading { () throws(ContentErrors) in
			try SOMLFile<SiteSettings>(url: project.root.appending(path: SiteSettings.path))
		}

		// The mistakes between the files are checked with the documents that loaded, so they show in the same run as the mistakes of each file. Without the shared questions, or without a content directory, the apps are not loaded, so these checks wait for the next run.
		let references: (featuredApps: [App], guides: [Guide.Resolved], errors: [ContentError])

		if case .loaded(let apps, let failedSlugs, _) = loadedApps {
			references = Self.resolveReferences(
				apps: apps,
				unloadedAppSlugs: failedSlugs,
				guides: loadedGuides.validEntries,
				settings: settingsFile
			)
		} else {
			references = ([], [], [])
		}

		// Path identity does not depend on whether the apps directory loaded.
		let documents: [any ContentDocument] = loadedApps.validEntries + loadedPosts.validEntries + loadedGuides.validEntries + loadedPages.validEntries
		let pathErrors = duplicatePathErrors(in: documents, project: project)

		// By file and line, so the mistakes of a file are in the order of its lines, also the ones between files.
		let errors = (loadedApps.errors + loadedPosts.errors + loadedGuides.errors + loadedPages.errors + settingsErrors + references.errors + pathErrors)
			.sorted(using: ContentError.locationOrder)

		guard
			errors.isEmpty,
			case .loaded(let apps, _, _) = loadedApps,
			case .loaded(let posts, _, _) = loadedPosts,
			case .loaded(let guides, _, _) = loadedGuides,
			case .loaded(let pages, _, _) = loadedPages,
			let sharedQuestions,
			let settingsFile
		else {
			throw ContentErrors(errors)
		}

		let content = Self(
			apps: apps,
			posts: posts,
			guides: guides,
			pages: pages,
			sharedQuestions: sharedQuestions,
			settings: settingsFile.value,
			featuredApps: references.featuredApps,
			resolvedGuides: references.guides,
			buildDate: buildDate,
			project: project,
			warnings: warnings.all
		)

		switch externalData {
		case .fetch(let cache):
			return try await content.fetching(cache: cache, warnings: warnings)
		case .none:
			return content
		}
	}

	/**
	The page-path collisions among every successfully loaded content type, even when an unrelated directory is unavailable.
	*/
	private static func duplicatePathErrors(in documents: [any ContentDocument], project: Project) -> [ContentError] {
		var errors = [ContentError]()
		let documentsByPath = Dictionary(grouping: documents, by: \.path)

		for (path, documents) in documentsByPath where documents.count > 1 {
			for document in documents.dropFirst() {
				errors.append(document.file.error("It is the same page as `\(documents[0].file.url.path(relativeTo: project.root))`, which is at \(path). Rename or remove one of them."))
			}
		}

		return errors
	}

	/**
	The app identity mistakes and resolved recommendations between the documents, with the documents that loaded. A check that needs a document that did not load is left out, like a slug of an app in `unloadedAppSlugs`, which has its own mistakes.

	Two apps with one App Store ID, which would share its price, rating, and reviews, a name in `feedbackNames` that is a name of another app, which the feedback page would open instead, a site that has two names in the press quotes, and an app of a guide or a featured app (`featuredApps` of `content/site.soml`) that does not exist, or is not active or has no page of its own. The loader reports them, so the rest of the build can assume that an App Store ID identifies one document, and that the apps of a guide and the featured apps exist and are made. A path that two redirects claim is still the publisher's check.
	*/
	private static func resolveReferences(
		apps: [App],
		unloadedAppSlugs: Set<String>,
		guides: [Guide],
		settings: SOMLFile<SiteSettings>?
	) -> (featuredApps: [App], guides: [Guide.Resolved], errors: [ContentError]) {
		var errors = [ContentError]()
		var resolvedGuides = [Guide.Resolved]()

		var appsByID = [AppStoreID: App]()

		for app in apps {
			guard let id = app.appStoreID else {
				continue
			}

			guard let other = appsByID[id] else {
				appsByID[id] = app
				continue
			}

			errors.append(app.file.error("It has the same `appStoreID` as \(other.title), so they would share its price, rating, and reviews."))
		}

		// The feedback page opens the first app that has a name, in any case (``FeedbackData/AppData/names``), so a name of two apps would open the wrong app for one of them.
		var appsByFeedbackName = [String: App]()

		for app in apps {
			for name in [app.title, app.slug] {
				appsByFeedbackName[name.feedbackLookupKey] = appsByFeedbackName[name.feedbackLookupKey] ?? app
			}
		}

		for app in apps {
			for (index, name) in app.feedbackNames.enumerated() {
				if
					let other = appsByFeedbackName[name.feedbackLookupKey],
					other.path != app.path
				{
					errors.append(app.error(at: .feedbackNames, index: index, "`\(name)` is also a name of \(other.title), so the feedback page could open the wrong app."))
				} else {
					appsByFeedbackName[name.feedbackLookupKey] = app
				}
			}
		}

		// A site has one name, so a quote whose `source` is another name of its site, like “Cult Of Mac”, or whose `url` was copied from a quote of another site, is a mistake. The name of a site is the name of most of its quotes. The reviews of buyers on Gumroad are by people, so each has its own name. Limitation: a site where people post under their own names, like a social network, would need the same exception.
		let pressQuotes = apps.flatMap { app in
			app.frontmatter.pressQuotes.enumerated().filter { !$0.element.isBuyerReview }.compactMap { index, pressQuote in
				pressQuote.url?.host().map { host in
					// A host has no letter case, so `CultOfMac.com` is `cultofmac.com`.
					let host = host.lowercased()
					return (host: host.hasPrefix("www.") ? String(host.dropFirst(4)) : host, source: pressQuote.source, app: app, index: index)
				}
			}
		}

		for (host, quotes) in Dictionary(grouping: pressQuotes, by: { $0.host }) {
			// The most common name first, and by the name for a tie, so the error is at the same quote in each build.
			let names = Dictionary(grouping: quotes, by: { $0.source })
				.map { (name: $0.key, count: $0.value.count) }
				.sorted(using: [KeyPathComparator(\.count, order: .reverse), KeyPathComparator(\.name, comparator: String.StandardComparator.lexical)])

			guard
				names.count > 1,
				let name = names.first
			else {
				continue
			}

			for quote in quotes where quote.source != name.name {
				errors.append(quote.app.error(at: .pressQuotes, index: quote.index, "\(host) is “\(name.name)” in \(name.count) \("quote".pluralized(for: name.count)), but “\(quote.source)” in \(quote.app.title). Use one name for the site, or check the `url`."))
			}
		}

		let appsBySlug = Self.appsBySlug(apps)

		/**
		The apps of a list of slugs in a file that recommends them and links to their pages, like the apps of a guide and the featured apps, with the index of each slug. A slug that is not an app is an error, and so is an app that is archived, unlisted, or has no page of its own, like an app before its launch.

		- Parameter use: What the file does with the apps, for the error, like “a guide cannot recommend it”.
		*/
		func recommendedApps(of slugs: [String], in file: some SOMLValueFile, at key: some CodingKey, use: String) -> [(index: Int, app: App)] {
			slugs.enumerated().compactMap { index, slug in
				guard let app = appsBySlug[slug] else {
					if unloadedAppSlugs.contains(slug) {
						return nil
					}

					errors.append(file.error(line: file.line(of: key, index: index), "There is no app with the slug `\(slug)`, like `gifski` for `content/apps/gifski/index.md`."))
					return nil
				}

				let problem: String? = if app.isArchived {
					"is archived"
				} else if !app.isListed {
					"is unlisted"
				} else if app.isRedirect {
					"has no page of its own"
				} else {
					nil
				}

				if let problem {
					errors.append(file.error(line: file.line(of: key, index: index), "\(app.title) \(problem), so \(use)."))
				}

				return (index, app)
			}
		}

		for guide in guides {
			let guideApps = recommendedApps(of: guide.apps, in: guide.file, at: Guide.Frontmatter.CodingKeys.apps, use: "a guide cannot recommend it")

			if let resolved = Guide.Resolved(guide: guide, apps: guideApps.map(\.app)) {
				resolvedGuides.append(resolved)
			}

			if let firstApp = guideApps.first(where: { $0.index == 0 })?.app {
				if let error = guide.quickAnswerLinkError(to: firstApp) {
					errors.append(error)
				}

				// The page shows the screenshot of the first app, so a number that the app does not have would silently show nothing.
				if
					let number = guide.frontmatter.screenshot?.number,
					guide.screenshot(of: firstApp) == nil
				{
					errors.append(guide.error(at: .screenshot, "\(firstApp.title) has no screenshot \(number). It has \(firstApp.screenshots.count), like `screenshot1.png` in `content/apps/\(firstApp.slug)`."))
				}
			}
		}

		let featuredApps = settings.map { settings in
			recommendedApps(of: settings.value.featuredApps, in: settings, at: SiteSettings.CodingKeys.featuredApps, use: "the apps page cannot feature it").map(\.app)
		} ?? []

		return (featuredApps, resolvedGuides, errors)
	}

	/**
	The content with the data from the App Store, Gumroad, the appcasts, Setapp, GitHub, npm, and Bluesky. Failures of the release notes and the recent repos on GitHub are errors. Other failures are warnings, as that data is extra: the App Store data and reviews, the Gumroad products, the appcasts, the Setapp ratings, the popular repos, the numbers of the GitHub account, and the npm numbers of the about page, the career quilt, which also has the contribution numbers of the about page, and the activity of the now page.
	*/
	private func fetching(cache: ResponseCache, warnings: WarningCollector) async throws -> Self {
		let github = GitHub(token: await GitHub.defaultToken(), cache: cache)

		// The info only adds the prices, the ratings, and the versions, like to the app pages and to the numbers of the about and now pages, so a failed lookup does not fail the build.
		async let appStoreInfo = warnings.value(warning: "Could not get the App Store info, so the app pages leave out the prices and the ratings and have less structured data, the about page leaves out the ratings, and the now page leaves out the App Store updates") {
			try await AppStoreInfo.lookup(ids: apps.compactMap(\.appStoreID), cache: cache)
		}
		// Like the App Store info, the ratings and prices of the Gumroad apps only add to the pages.
		async let gumroadProducts = GumroadProduct.load(ids: apps.compactMap(\.frontmatter.gumroad?.id), cache: cache, warnings: warnings)
		// Like the App Store info, the requirements in the appcasts only add to the pages, which fall back to `minimumOSVersion`.
		async let appcasts = Appcast.load(urls: apps.compactMap(\.appcastURL), cache: cache, warnings: warnings)
		// Like the App Store info, the ratings on Setapp only add to the pages. Archived apps are left out, as they are no longer on Setapp.
		async let setappRatings = SetappRating.load(ids: apps.filter { !$0.isArchived }.compactMap(\.setappID), cache: cache, warnings: warnings)
		async let appStoreReviews = AppStoreReview.recentFiveStar(appIDs: apps.filter { !$0.isArchived }.compactMap(\.appStoreID), cache: cache, warnings: warnings)
		async let recentRepositories = github.recentRepositories()
		async let popularRepositories = warnings.value(warning: "Could not get the popular GitHub repos, so the about page leaves them out") {
			try await github.popularRepositories()
		}
		async let gitHubAccount = warnings.value(warning: "Could not get the numbers of the GitHub account and its organizations, like the repos and the stars, so the about page leaves them out, and the now page leaves out the new npm packages") {
			try await github.account()
		}
		async let npmStatistics = NPMStatistics.load(cache: cache, warnings: warnings)
		async let recentActivity = RecentActivity.load(
			github: github,
			cache: cache,
			buildDate: buildDate,
			warnings: warnings
		)
		// The career quilt is extra, and it is left out without a token.
		async let contributionYears = warnings.value(warning: "Could not get the GitHub contributions of each year, so the career quilt and the contribution numbers of the about page are left out") {
			try await ContributionYear.load(github: github, until: buildDate)
		}

		// The first app of each repo, which a repo that does not exist is reported at.
		let appsByReleasesRepository = Dictionary(apps.compactMap { app in app.releaseNotes.map { ($0.repository, app) } }) { first, _ in first }

		let releases = try await appsByReleasesRepository.concurrentMap { repository, app in
			do {
				return (repository, try await github.releases(repository: repository))
			} catch let error as ResponseCache.RequestError where error.statusCode == 404 {
				// The API says 404, not which part, so a typo in the frontmatter would only name a URL.
				throw app.error(at: .releasesRepository, "The `releasesRepository` \(repository) does not exist on GitHub.")
			}
		}

		let loadedAppStoreInfo = await appStoreInfo

		// When the lookup works, an app without a result likely has a wrong App Store ID, so its links go nowhere.
		if let loadedAppStoreInfo {
			for app in apps where !app.isArchived {
				if
					let id = app.appStoreID,
					loadedAppStoreInfo[id] == nil
				{
					warnings.add(app.file.warning(.unknownAppStoreID, "The App Store has no app with the ID \(id), which \(app.title) uses. Check its `appStoreID`."))
				}
			}
		}

		var content = self
		content.appData = await AppData(
			appStoreInfo: loadedAppStoreInfo ?? [:],
			gumroadProducts: gumroadProducts,
			appcasts: appcasts,
			appStoreReviews: appStoreReviews,
			releases: Dictionary(uniqueKeysWithValues: releases),
			setappRatings: setappRatings
		)
		content.recentRepositories = try await recentRepositories
		content.popularRepositories = await popularRepositories ?? []
		content.gitHubAccount = await gitHubAccount
		content.npmStatistics = await npmStatistics
		content.recentActivity = await recentActivity
		content.contributionYears = await contributionYears ?? []
		// After all requests, so the cache has all its warnings.
		content.warnings = warnings.all + cache.warnings
		return content
	}
}

extension SiteContent {
	/**
	Apps that are listed and not archived. These are the apps people browse.
	*/
	var activeApps: [App] {
		apps.filter(\.isActive)
	}

	/**
	The years since the first app launched, like 11, for “11 years of craft”. `nil` without apps.
	*/
	var yearsOfCraft: Int? {
		listedApps.map(\.publicationDate).min().map { buildDate.wholeYears(since: $0.foundationDate) }
	}

	/**
	The years since the first open-source repo of Sindre, like 15, for “15 years of open source”.
	*/
	var yearsOfOpenSource: Int {
		// When he made his first repo.
		buildDate.wholeYears(since: Date(year: 2011, month: 9, day: 6))
	}

	/**
	Active apps that have a page of their own, not a redirect to another site.
	*/
	var activeAppsWithPages: [App] {
		activeApps.filter { !$0.isRedirect }
	}

	/**
	The newest active app with a page of its own.
	*/
	var newestApp: App? {
		activeAppsWithPages.first
	}

	/**
	Apps that are not archived, including unlisted ones. These get support.
	*/
	var maintainedApps: [App] {
		apps.filter { !$0.isArchived }
	}

	/**
	Apps that are listed, including archived ones.
	*/
	var listedApps: [App] {
		apps.filter(\.isListed)
	}

	/**
	Blog posts that are not unlisted.
	*/
	var listedPosts: [BlogPost] {
		posts.filter(\.isListed)
	}

	/**
	The app with the data that the build fetched for it.
	*/
	func listing(of app: App) -> AppListing {
		AppListing(
			app: app,
			appStoreInfo: app.appStoreID.flatMap { appData.appStoreInfo[$0] },
			appcast: app.appcastURL.flatMap { appData.appcasts[$0] },
			gumroadProduct: app.frontmatter.gumroad.flatMap { appData.gumroadProducts[$0.id] },
			setappRating: app.setappID.flatMap { appData.setappRatings[$0] },
			appStoreReviews: app.appStoreID.flatMap { appData.appStoreReviews[$0] } ?? [],
			releases: app.releaseNotes.flatMap { appData.releases[$0.repository] } ?? []
		)
	}

	/**
	The App Store info of the apps, like for the combined rating of the about page.
	*/
	var appStoreInfo: some Collection<AppStoreInfo> {
		appData.appStoreInfo.values
	}

	/**
	An App Store review with its app, for pages with the reviews of many apps.
	*/
	struct AppReview {
		let app: App
		let review: AppStoreReview
	}

	/**
	The recent five-star reviews of the active apps, newest first. Reviews of the same date are in the order of the app titles and the review titles.
	*/
	var activeAppReviews: [AppReview] {
		activeApps
			.flatMap { app in
				listing(of: app).reviews.map { AppReview(app: app, review: $0) }
			}
			.sorted(using: [KeyPathComparator(\.review.date, order: .reverse), KeyPathComparator(\.app.title, comparator: .localizedStandard), KeyPathComparator(\.review.title, comparator: .localizedStandard)])
	}

	/**
	Active apps that change every day, like for “while you’re here” suggestions.
	*/
	func randomApps(count: Int) -> [App] {
		var generator = SeededRandomNumberGenerator.daily("random-app", on: buildDate)
		return Array(activeAppsWithPages.shuffled(using: &generator).prefix(count))
	}

	/**
	The content file that is published at the path, like the app of `/dato`, or `nil` for a page without one, like `/apps`.
	*/
	func document(at path: RoutePath) -> (any ContentDocument)? {
		documentsByPath[path]
	}

	/**
	The content file of the page at the path, like `content/apps/dato/index.md` for `/dato`, or `nil` for a page without one, like `/apps`.
	*/
	public func contentFile(ofPage path: RoutePath) -> URL? {
		document(at: path)?.file.url
	}

	/**
	Where a problem of the page is: its content file (``contentFile(ofPage:)``), or else the page, like `/apps`.
	*/
	func sourceLocation(ofPage path: RoutePath) -> SourceLocation {
		contentFile(ofPage: path).map { .file($0) } ?? .page(path)
	}

	/**
	The guides about the app, like for a link from its page.
	*/
	func guides(about app: App) -> [Guide] {
		resolvedGuides.filter { $0.apps.contains(where: { $0.slug == app.slug }) }.map(\.guide)
	}

	/**
	Where a link on a page is written in the content, like `content/apps/dato/index.md:12`, or `content/shared-questions.md:20` for a link in a shared answer. When the link is not in the Markdown of the page, like a link in raw HTML or in the layout, it is the page (``sourceLocation(ofPage:)``), so it is never empty.
	*/
	func sourceLocations(ofLink link: String, onPage page: RoutePath) -> [SourceLocation] {
		let locations = document(at: page).map { document in
			document.markdown.links
				.filter { $0.destination == link }
				.map { SourceLocation.file($0.otherFile ?? document.file.url, line: $0.line) }
		} ?? []

		return locations.isEmpty ? [sourceLocation(ofPage: page)] : locations
	}

	/**
	The content file of the draft whose page a link of the site would go to, like `content/guides/keep-mac-awake.md` for `/guides/keep-mac-awake#steps`, or `nil` when there is none. The content leaves out the drafts, so it is a file of a type of document at the path of the link, while no document is at it.
	*/
	func draftFile(ofLink link: String) -> URL? {
		let pathText = String(link.prefix { $0 != "#" && $0 != "?" })

		guard
			pathText.hasPrefix("/"),
			let path = try? RoutePath(validating: pathText),
			document(at: path) == nil
		else {
			return nil
		}

		for documentType in contentDocumentTypes {
			let directory = project.root.appending(path: documentType.directory)
			let files = (try? directory.filesRecursively()) ?? []

			if let file = files.first(where: { $0.pathExtension == "md" && documentType.path(slug: MarkdownFile.slug(of: $0, relativeTo: directory)) == path }) {
				return file
			}
		}

		return nil
	}

	/**
	The apps by their slugs, which are unique, as they are the paths of the files.
	*/
	private static func appsBySlug(_ apps: [App]) -> [String: App] {
		Dictionary(apps.map { ($0.slug, $0) }) { first, _ in first }
	}

	func page(_ path: RoutePath) -> MarkdownPage? {
		document(at: path) as? MarkdownPage
	}
}

extension SiteContent {
	/**
	The data that the build fetched for the apps, by the key that each app has for it.
	*/
	struct AppData {
		var appStoreInfo = [AppStoreID: AppStoreInfo]()

		/**
		The products of the apps that are sold on Gumroad, by the ID of their `gumroad`.
		*/
		var gumroadProducts = [GumroadProductID: GumroadProduct]()

		/**
		The appcasts of the apps that are not on the App Store, by their URL (``App/appcastURL``), for the OS versions that the apps need.
		*/
		var appcasts = [URL: Appcast]()

		/**
		Recent five-star reviews by App Store ID, newest first.
		*/
		var appStoreReviews = [AppStoreID: [AppStoreReview]]()

		/**
		The releases of each app's releases repo, by the repo (``App/ReleaseNotes/repository``).
		*/
		var releases = [GitHubRepositoryName: [GitHubRelease]]()

		/**
		The ratings of the apps on Setapp, by their `setappID`.
		*/
		var setappRatings = [SetappID: SetappRating]()

		/**
		No data, like for a build without the network.
		*/
		static let none = Self()
	}
}

extension Warning.Kind {
	static let missingCommitDates = Self("Missing dates of the last commits")
	static let unknownAppStoreID = Self("Unknown App Store ID")
}
