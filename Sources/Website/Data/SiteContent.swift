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
	Recent five-star reviews by App Store ID, newest first.
	*/
	let appStoreReviews: [AppStoreID: [AppStoreReview]]

	/**
	The releases of each app's releases repo.
	*/
	let releases: [String: [GitHubRelease]]

	let recentRepositories: [GitHubRepository]

	/**
	The repos with the most stars, for the about page. Empty when the request failed.
	*/
	let popularRepositories: [GitHubRepository]

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

	init(apps: [App], posts: [BlogPost], pages: [MarkdownPage], appStoreInfo: [AppStoreID: AppStoreInfo] = [:], appStoreReviews: [AppStoreID: [AppStoreReview]] = [:], releases: [String: [GitHubRelease]] = [:], recentRepositories: [GitHubRepository] = [], popularRepositories: [GitHubRepository] = [], npmStatistics: NPMStatistics = NPMStatistics(), recentActivity: RecentActivity = RecentActivity(), contributionYears: [ContributionYear] = [], buildDate: Date, project: Project, warnings: [Warning] = []) {
		self.apps = apps
		self.posts = posts
		self.pages = pages
		self.pagesByPath = Dictionary(uniqueKeysWithValues: pages.map { ($0.path, $0) })
		self.appStoreInfo = appStoreInfo
		self.appStoreReviews = appStoreReviews
		self.releases = releases
		self.recentRepositories = recentRepositories
		self.popularRepositories = popularRepositories
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

		switch externalData {
		case .fetch(let cache):
			return try await fetching(apps: apps, posts: posts, pages: pages, cache: cache, buildDate: buildDate, project: project, warnings: warnings)
		case .none:
			return Self(apps: apps, posts: posts, pages: pages, buildDate: buildDate, project: project, warnings: warnings.all)
		}
	}

	/**
	The content with the data from the App Store, GitHub, npm, and Bluesky. Failures of the release notes and the recent repos on GitHub are errors. Other failures are warnings, as that data is extra: the App Store data, the popular repos and the npm numbers of the about page, the career quilt, and the activity of the now page.
	*/
	private static func fetching(apps: [App], posts: [BlogPost], pages: [MarkdownPage], cache: ResponseCache, buildDate: Date, project: Project, warnings: WarningCollector) async throws -> Self {
		let github = GitHub(cache: cache)

		async let appStoreInfo = AppStoreInfo.lookup(ids: apps.compactMap(\.appStoreID), cache: cache)
		async let appStoreReviews = AppStoreReview.recentFiveStar(appIDs: apps.filter { !$0.isArchived }.compactMap(\.appStoreID), cache: cache, warnings: warnings)
		async let recentRepositories = github.recentRepositories()
		async let popularRepositories = github.popularRepositories()
		async let npmStatistics = NPMStatistics.load(cache: cache, warnings: warnings)
		async let recentActivity = RecentActivity.load(github: github, cache: cache, buildDate: buildDate, warnings: warnings)
		async let contributionYears = ContributionYear.load(github: github, until: buildDate)

		let releases = try await withThrowingTaskGroup { group in
			for repository in Set(apps.compactMap(\.releaseNotes?.repository)) {
				group.addTask {
					(repository, try await github.releases(repository: repository))
				}
			}

			return try await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
		}

		// The info only adds structured data and prices to the app pages, so a failed lookup does not fail the build.
		var loadedAppStoreInfo = [AppStoreID: AppStoreInfo]()

		do {
			loadedAppStoreInfo = try await appStoreInfo

			// When the lookup works, an app without a result likely has a wrong App Store ID, so its links go nowhere.
			for app in apps where !app.isArchived {
				if
					let id = app.appStoreID,
					loadedAppStoreInfo[id] == nil
				{
					warnings.add(Warning(location: app.file.location(ofLine: nil, relativeTo: project.root), message: "The App Store has no app with the ID \(id), which \(app.title) uses. Check its `appStoreID`."))
				}
			}
		} catch {
			warnings.add(Warning(message: "Could not get App Store info, so app pages have less structured data: \(error)"))
		}

		let loadedAppStoreReviews = await appStoreReviews
		let loadedRecentRepositories = try await recentRepositories
		let loadedNPMStatistics = await npmStatistics
		let loadedRecentActivity = await recentActivity
		var loadedContributionYears = [ContributionYear]()

		// The career quilt is extra, and it is left out without a token.
		do {
			loadedContributionYears = try await contributionYears ?? []
		} catch {
			warnings.add(Warning(message: "Could not get the GitHub contributions of each year, so the career quilt is left out: \(error)"))
		}
		var loadedPopularRepositories = [GitHubRepository]()

		do {
			loadedPopularRepositories = try await popularRepositories
		} catch {
			warnings.add(Warning(message: "Could not get the popular GitHub repos, so the about page leaves them out: \(error)"))
		}

		// After all requests, so the cache has all its warnings.
		return Self(
			apps: apps,
			posts: posts,
			pages: pages,
			appStoreInfo: loadedAppStoreInfo,
			appStoreReviews: loadedAppStoreReviews,
			releases: releases,
			recentRepositories: loadedRecentRepositories,
			popularRepositories: loadedPopularRepositories,
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
		// Whole years, so the count goes up on the day of the first app, not on January 1.
		listedApps.map(\.publicationDate).min().flatMap { Calendar.site.dateComponents([.year], from: $0, to: buildDate).year }
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

	func releases(of app: App) -> [GitHubRelease] {
		app.releaseNotes.flatMap { releases[$0.repository] } ?? []
	}

	func appStoreInfo(of app: App) -> AppStoreInfo? {
		app.appStoreID.flatMap { appStoreInfo[$0] }
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
					.map { document.file.location(ofLine: $0.line, relativeTo: project.root) }
			}
	}

	func page(_ path: RoutePath) -> MarkdownPage? {
		pagesByPath[path]
	}
}
