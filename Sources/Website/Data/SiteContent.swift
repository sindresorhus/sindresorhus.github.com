import Foundation
import SiteKit

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

	let pages: [MarkdownPage]
	private let pagesByPath: [RoutePath: MarkdownPage]

	let appStoreInfo: [AppStoreID: AppStoreInfo]

	/**
	The products of the apps that are sold on Gumroad, by their `gumroadID`.
	*/
	let gumroadProducts: [GumroadProductID: GumroadProduct]

	/**
	Recent five-star reviews by App Store ID, newest first.
	*/
	let appStoreReviews: [AppStoreID: [AppStoreReview]]

	/**
	The releases of each app's releases repo, by the repo (``App/ReleaseNotes/repository``). Pages read them with ``releases(of:)``, so nothing else looks them up by a name.
	*/
	private let releases: [GitHubRepositoryName: [GitHubRelease]]

	let recentRepositories: [GitHubRepository]

	/**
	The repos with the most stars, for the about page. Empty when the request failed.
	*/
	let popularRepositories: [GitHubRepository]

	/**
	The numbers of the GitHub account and the organizations of its projects (``GitHub/owners``), like the repos and the stars, for the about page, and their repos, for the new npm packages of the now page. `nil` when a request failed.
	*/
	let gitHubAccount: GitHub.Account?

	let npmStatistics: NPMStatistics

	/**
	What Sindre did lately on Bluesky and GitHub, for the now page.
	*/
	let recentActivity: RecentActivity

	/**
	The GitHub contributions of each year since 2010, oldest first, for the career quilt. Empty without a GitHub token, or when a request failed.
	*/
	let contributionYears: [ContributionYear]

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
	let warnings: [Warning]

	init(
		apps: [App],
		posts: [BlogPost],
		pages: [MarkdownPage],
		appStoreInfo: [AppStoreID: AppStoreInfo] = [:],
		gumroadProducts: [GumroadProductID: GumroadProduct] = [:],
		appStoreReviews: [AppStoreID: [AppStoreReview]] = [:],
		releases: [GitHubRepositoryName: [GitHubRelease]] = [:],
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
		self.pages = pages
		// The loader rejects two pages with the same path, so the first is the only one.
		self.pagesByPath = Dictionary(pages.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
		self.appStoreInfo = appStoreInfo
		self.gumroadProducts = gumroadProducts
		self.appStoreReviews = appStoreReviews
		self.releases = releases
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
			warnings.add(Warning(message: "Could not read the dates of the last commits with git, so the sitemap and the update dates of posts use other dates."))
		}

		// The mistakes of all content types are reported together.
		func entries<Entry: ContentEntry>(_ type: Entry.Type) async -> (entries: [Entry]?, errors: [ContentError]) {
			do {
				return (try await Entry.load(from: project, lastCommitDates: lastCommitDates), [])
			} catch {
				return (nil, error.errors)
			}
		}

		async let loadingApps = entries(App.self)
		async let loadingPosts = entries(BlogPost.self)
		async let loadingPages = entries(MarkdownPage.self)
		let (loadedApps, loadedPosts, loadedPages) = await (loadingApps, loadingPosts, loadingPages)

		guard
			let apps = loadedApps.entries,
			let posts = loadedPosts.entries,
			let pages = loadedPages.entries
		else {
			throw ContentErrors(loadedApps.errors + loadedPosts.errors + loadedPages.errors)
		}

		let duplicates = duplicateErrors(apps: apps, posts: posts, pages: pages, project: project)

		guard duplicates.isEmpty else {
			throw ContentErrors(duplicates)
		}

		switch externalData {
		case .fetch(let cache):
			return try await fetching(apps: apps, posts: posts, pages: pages, cache: cache, buildDate: buildDate, project: project, warnings: warnings)
		case .none:
			return Self(apps: apps, posts: posts, pages: pages, buildDate: buildDate, project: project, warnings: warnings.all)
		}
	}

	/**
	Two content files that write the same page, like `content/pages/about.md` and `content/apps/about/index.md`, and two apps with one App Store ID, which would share its price, rating, and reviews. The loader reports them, so the rest of the build can assume that a page path and an App Store ID identify one document. A path that two redirects claim is still the publisher's check.
	*/
	private static func duplicateErrors(
		apps: [App],
		posts: [BlogPost],
		pages: [MarkdownPage],
		project: Project
	) -> [ContentError] {
		var errors = [ContentError]()
		let documents: [any ContentDocument] = apps + posts + pages
		let documentsByPath = Dictionary(grouping: documents, by: \.path)

		for (path, documents) in documentsByPath where documents.count > 1 {
			for document in documents.dropFirst() {
				errors.append(ContentError(file: document.file.url, reason: "It is the same page as `\(documents[0].file.url.path(relativeTo: project.root))`, which is at \(path). Rename or remove one of them."))
			}
		}

		var appsByID = [AppStoreID: App]()

		for app in apps {
			guard let id = app.appStoreID else {
				continue
			}

			guard let other = appsByID[id] else {
				appsByID[id] = app
				continue
			}

			errors.append(ContentError(file: app.file.url, reason: "It has the same `appStoreID` as \(other.title), so they would share its price, rating, and reviews."))
		}

		return errors.sorted(using: KeyPathComparator(\.description, comparator: String.StandardComparator.lexical))
	}

	/**
	The content with the data from the App Store, GitHub, npm, and Bluesky. Failures of the release notes and the recent repos on GitHub are errors. Other failures are warnings, as that data is extra: the App Store data, the popular repos, the numbers of the GitHub account, and the npm numbers of the about page, the career quilt, which also has the contribution numbers of the about page, and the activity of the now page.
	*/
	private static func fetching(
		apps: [App],
		posts: [BlogPost],
		pages: [MarkdownPage],
		cache: ResponseCache,
		buildDate: Date,
		project: Project,
		warnings: WarningCollector
	) async throws -> Self {
		let github = GitHub(cache: cache)

		// The info only adds the prices, the ratings, and the versions, like to the app pages and to the numbers of the about and now pages, so a failed lookup does not fail the build.
		async let appStoreInfo = warnings.value(warning: "Could not get the App Store info, so the app pages leave out the prices and the ratings and have less structured data, the about page leaves out the ratings, and the now page leaves out the App Store updates") {
			try await AppStoreInfo.lookup(ids: apps.compactMap(\.appStoreID), cache: cache)
		}
		// Like the App Store info, the ratings and prices of the Gumroad apps only add to the pages.
		async let gumroadProducts = GumroadProduct.load(ids: apps.compactMap(\.frontmatter.gumroadID), cache: cache, warnings: warnings)
		async let appStoreReviews = AppStoreReview.recentFiveStar(appIDs: apps.filter { !$0.isArchived }.compactMap(\.appStoreID), cache: cache, warnings: warnings)
		async let recentRepositories = github.recentRepositories()
		async let popularRepositories = warnings.value(warning: "Could not get the popular GitHub repos, so the about page leaves them out") {
			try await github.popularRepositories()
		}
		async let gitHubAccount = warnings.value(warning: "Could not get the numbers of the GitHub account and its organizations, like the repos and the stars, so the about page leaves them out, and the now page leaves out the new npm packages") {
			try await github.account()
		}
		async let npmStatistics = NPMStatistics.load(cache: cache, warnings: warnings)
		async let recentActivity = RecentActivity.load(github: github, cache: cache, buildDate: buildDate, warnings: warnings)
		// The career quilt is extra, and it is left out without a token.
		async let contributionYears = warnings.value(warning: "Could not get the GitHub contributions of each year, so the career quilt and the contribution numbers of the about page are left out") {
			try await ContributionYear.load(github: github, until: buildDate)
		}

		let releases = try await withThrowingTaskGroup { group in
			for repository in Set(apps.compactMap(\.releaseNotes?.repository)) {
				group.addTask {
					(repository, try await github.releases(repository: repository))
				}
			}

			return try await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
		}

		let loadedAppStoreInfo = await appStoreInfo

		// When the lookup works, an app without a result likely has a wrong App Store ID, so its links go nowhere.
		if let loadedAppStoreInfo {
			for app in apps where !app.isArchived {
				if
					let id = app.appStoreID,
					loadedAppStoreInfo[id] == nil
				{
					warnings.add(Warning(file: app.file.url, message: "The App Store has no app with the ID \(id), which \(app.title) uses. Check its `appStoreID`."))
				}
			}
		}

		let loadedAppStoreReviews = await appStoreReviews
		let loadedRecentRepositories = try await recentRepositories
		let loadedNPMStatistics = await npmStatistics
		let loadedRecentActivity = await recentActivity
		let loadedContributionYears = await contributionYears ?? []
		let loadedPopularRepositories = await popularRepositories ?? []
		let loadedGitHubAccount = await gitHubAccount

		// After all requests, so the cache has all its warnings.
		return Self(
			apps: apps,
			posts: posts,
			pages: pages,
			appStoreInfo: loadedAppStoreInfo ?? [:],
			gumroadProducts: await gumroadProducts,
			appStoreReviews: loadedAppStoreReviews,
			releases: releases,
			recentRepositories: loadedRecentRepositories,
			popularRepositories: loadedPopularRepositories,
			gitHubAccount: loadedGitHubAccount,
			npmStatistics: loadedNPMStatistics,
			recentActivity: loadedRecentActivity,
			contributionYears: loadedContributionYears,
			buildDate: buildDate,
			project: project,
			warnings: warnings.all + cache.warnings
		)
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
		listedApps.map(\.publicationDate).min().map { buildDate.wholeYears(since: $0) }
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
	The published releases of the app, newest first, like on its release notes page. Empty for an app without release notes, like an archived app.
	*/
	func releases(of app: App) -> [GitHubRelease] {
		app.releaseNotes.flatMap { releases[$0.repository] } ?? []
	}

	func appStoreInfo(of app: App) -> AppStoreInfo? {
		app.appStoreID.flatMap { appStoreInfo[$0] }
	}

	func gumroadProduct(of app: App) -> GumroadProduct? {
		app.frontmatter.gumroadID.flatMap { gumroadProducts[$0] }
	}

	/**
	The rating of the app on the App Store, or on Gumroad for an app that is sold there.
	*/
	func rating(of app: App) -> StoreRating? {
		appStoreInfo(of: app)?.rating ?? gumroadProduct(of: app)?.rating
	}

	func appStoreReviews(of app: App) -> [AppStoreReview] {
		app.appStoreID.flatMap { appStoreReviews[$0] } ?? []
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
				appStoreReviews(of: app).map { AppReview(app: app, review: $0) }
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
	The content files that are published at their path: the apps, the blog posts, and the pages.
	*/
	var documents: [any ContentDocument] {
		apps + posts + pages
	}

	/**
	Where a link on a page is written in the content, like `content/apps/dato/index.md:12`. Empty when the link is not in the Markdown of the page.
	*/
	func sourceLocations(ofLink link: String, onPage page: RoutePath) -> [String] {
		documents
			.filter { $0.path == page }
			.flatMap { document in
				document.markdown.links
					.filter { $0.destination == link }
					.map { document.file.url.location(ofLine: $0.line) }
			}
	}

	func page(_ path: RoutePath) -> MarkdownPage? {
		pagesByPath[path]
	}
}
